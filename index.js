const fs = require("fs"),
  wabt = require("wabt")

function compile(path) {
  let compilation = {
    path: path,
    src: ("" + fs.readFileSync(path)).replace(/\r/g, "") + "\n~end\n;",
    position: 0,
    line: 1,
    col: 1,
    indents: [0],
    lastNl: 0,
    metaphors: {},
    strings: [null, false, 0, "", null, true, true, true]
  }
  let token
  let line = ""
  let level = 0
  compilation.tokenTree = createTokenTree(compilation)
  compilation.globals = scanForGlobals(compilation.tokenTree)
  // console.log(JSON.stringify(compilation, null, 2))
  let wast = compileModule(compilation)
  fs.writeFileSync(path.replace(".poem", ".wast"), wast)
  let wasm = compileWast(wast)
  fs.writeFileSync(path.replace(".poem", ".wasm"), wasm)
}

function isKeyword(token) { return typeof token === "string" && (token[0] === "@") }
function isIdentifier(token) { return typeof token === "string" && (token[0].match(/[\$A-Z_a-z]/) || token.charCodeAt(0) > 127) }
function isNumber(token) { return typeof token === "string" && (token[0].match(/[0-9]/)) }
function isString(token) { return typeof token === "string" && (token[0].match(/["']/)) }
function isSymbol(token) { return typeof token === "string" && (token[0].match(/[!#%&*+,\-/:;<=>?\\^|]/)) }
function isAssigner(token) { return typeof token === "string" && (token.substr(-1) === "=") }

function nextChar(c, peek) {
  let char = c.src[c.position]
  if (!peek) {
    c.position++
    c.col++
    if (char === "\n") {
      c.line++
      c.col = 1
      c.lastNl = c.position - 1
    }
  }
  return char
}
function rewind(c) {
  c.position = 0
  c.line = 1
  c.col = 1
  c.indents = [0]
  c.lastNl = 0
}
function rewindToNl(c) {
  c.position = c.lastNl
  c.line--
}
function croak(c, msg) {
  throw `${msg} at ${c.path}[${c.line}:${c.col}]!`
}

function escapeStr(str) {
  let buf = new Buffer(str)
  str = ""
  for (let i = 0; i < buf.length; i++) {
    if (buf[i] === 32 || buf[i] === 33) {
      str += String.fromCharCode(buf[i])
    } else if (buf[i] > 34 && buf[i] < 127) {
      str += String.fromCharCode(buf[i])
    } else {
      str += "\\" + buf[i].toString(16)
    }
  }
  return str
}

function nextToken(c) {
  let token = " "
  let char
  while (" \t".includes(token)) {
    token = nextChar(c)
    if (!token) return
    if (token === "~") {
      while (token !== "\n") {
        token = nextChar(c)
      }
    }
  }

  if (token.match(/\n/)) {
    let i = 0
    char = nextChar(c, true)
    while (!char.trim()) {
      nextChar(c)
      i++
      if (char === "\n") i = 0
      char = nextChar(c, true)
      if (char === "~") {
        while (char !== "\n") {
          nextChar(c)
          char = nextChar(c, true)
        }
      }
    }
    if (i > c.indents[c.indents.length - 1]) {
      c.indents.push(i)
      token = "{"
    } else if (i < c.indents[c.indents.length - 1]) {
      c.indents.pop()
      token = "}"
      rewindToNl(c)
    } else {
      token = ";"
    }
  } else if (token.match(/[\@]/)) {
    char = nextChar(c, true)
    while (char.match(/[_a-z]/)) {
      token += nextChar(c)
      char = nextChar(c, true)
    }
  } else if (token.match(/[\$A-Z_a-z]/) || token.charCodeAt(0) > 127) {
    char = nextChar(c, true)
    while (char.match(/[\$A-Z_a-z0-9]/) || char.charCodeAt(0) > 127) {
      token += nextChar(c)
      char = nextChar(c, true)
    }
  } else if (token.match(/[0-9.]/)) {
    let dot = token === "."
    char = nextChar(c, true)
    while (char.match(/[0-9]/) || (char === "." && !dot)) {
      if (char === ".") dot = true
      token += nextChar(c)
      char = nextChar(c, true)
    }
    if (token.length > 1 && token[0] === ".") token = "0" + token
  } else if (token.match(/["']/)) {
    while (char !== token[0]) {
      if (char === "\\") token += nextChar(c)
      char = nextChar(c)
      token += char
    }
  } else if (token.match(/[\{\(\[\;\]\)\}]/)) {
  } else while (token.substr(-1) === nextChar(c, true) || nextChar(c, true) === "=") {
    token += nextChar(c)
  }

  if (c.metaphors[token]) token = c.metaphors[token]
  if (isString(token)) {
    let str = JSON.parse(token)
    if (str) {
      c.strings.push(str)
    }
  }
  return token
}

function createTokenTree(c) {
  let token
  let tree = []
  while ((token = nextToken(c)) && ("])}".includes(token) === false)) {
    if ("{([".includes(token)) {
      token = [token].concat(createTokenTree(c))
    } else if (isSymbol(tree[tree.length - 1]) && token === "-") {
      token = [token, nextToken(c)]
    }
    tree.push(token)
  }
  tree.push(token)
  return tree
}

function scanForGlobals(tokenTree) {
  let globals = require("./stdlib.json")

  let statement = []
  for (let token of tokenTree) {
    if (";}".includes(token)) {
      if (statement[0] === "@set") {
        if (isIdentifier(statement[1])) {
          if (globals[statement[1]]) throw `duplicate identifier "${statement[1]}"`
          globals[statement[1]] = true
        }
      }
      if (statement[0] === "@func" || statement[0] === "@import" || statement[0] === "@export") {
        if (statement[0] === "@import") {
          statement.shift()
          statement.shift()
        }
        if (statement[0] === "@export") {
          statement.shift()
        }
        if (isIdentifier(statement[1])) {
          if (globals[statement[1]]) throw `duplicate identifier "${statement[1]}"`
          let locals = []
          if (statement[0] === "@import") {
            let params = parseInt(statement[2])
            for (let i = 2; i < params; i++) {
              locals.push("p" + i)
            }
          } else {
            for (let i = 2; i < statement.length; i++) {
              if (isIdentifier(statement[i])) {
                if (locals.includes(statement[i])) throw `duplicate parameter "${statement[i]}"`
                locals.push(statement[i])
              }
            }
          }
          globals[statement[1]] = locals
          /* for (let local in globals[statement[1]]) {
            if (globals[local]) globals[statement[1]][local] = false
          } */
        }
      }
      statement = []
    } else {
      statement.push(token)
    }
  }

  return globals
}


function compileModule(c) {
  let imports = ""
  let stdlib = fs.readFileSync("stdlib.wast")
  let runtime = fs.readFileSync("runtime.wast")
  let memory = `(memory $-memory 2) \n`
  let table = ""
  let globals = ""
  let functions = ""
  let start = "(call $-initruntime)\n"
  let startLocals = []
  let exports = ""

  let offset = 1024 * 64
  for (let i = 8; i < c.strings.length; i++) {
    let len = Buffer.byteLength(c.strings[i], 'utf8')
    memory += `(data (i32.const ${offset}) "${escapeStr(c.strings[i])}")\n`
    start += `(call $-string (i32.const ${offset}) (i32.const ${len}))\n`
    offset += len
    offset = Math.floor(offset / 8) * 8 + 8
  }
  c.globals["-string"] = c.strings
  c.globals["-table"] = []

  let statement = []
  for (let token of c.tokenTree) {
    if (";}".includes(token)) {
      if (statement[0] === "@set") {
        globals += `(global $${statement[1]} (mut i32) (i32.const 0))\n`
      }
      if (statement[0] === "@export") {
        exports += `(func $--${statement[2]}\n`
        for (let i = 3; i < statement.length - 1; i++) {
          exports += `(param $${statement[i]} f64)`
        }
        exports += `(result f64)`
        exports += `(call $-f64 (call $${statement[2]}`
        for (let i = 3; i < statement.length - 1; i++) {
          exports += `(call $-number (get_local $${statement[i]}))`
        }
        exports += `)))(export ${statement[1]} (func $--${statement[2]}))\n`
        statement.shift()
        statement[0] = "@func"
      }
      if (statement[0] === "@import") {
        let name = statement[3]
        imports += `(import ${statement[1]} ${statement[2]}  (func $--${name} `
        let params = parseInt(statement[4])
        let results = parseInt(statement[5])
        for (let i = 0; i < params; i++) {
          imports += `(param f64) `
        }
        for (let i = 0; i < results; i++) {
          imports += `(result f64) `
        }
        imports += `))\n`

        functions += `(func $${name}`
        for (let i = 0; i < params; i++) {
          functions += `(param $p${i} i32) `
        }
        functions += `(result i32)\n`
        functions += `(call $--${name} `
        for (let i = 0; i < params; i++) {
          functions += `(call $-f64 (call $-toNumber (get_local $p${i}))) `
        }
        functions += `)`
        if (results) {
          functions += `(call $-number)`
        } else {
          functions += `(i32.const 0)`
        }
        functions += `)\n`
      } else if (statement[0] === "@import_memory") {
        imports += `(import ${statement[1]} ${statement[2]} (memory 2))\n`
        memory = memory.substr(memory.indexOf(")") + 1)
      } else if (statement[0] === "@export_memory") {
        exports += `(export ${statement[1]} (memory $-memory))\n`
      } else if (statement[0] === "@import_table") {
        table += `(import ${statement[1]} ${statement[2]} (table $-table 1 anyfunc))\n`
      } else if (statement[0] === "@export_table") {
        exports += `(export ${statement[1]} (table $-table))\n`
      } else if (statement[0] === "@func") {
        functions += compileFunction(statement, c.globals) + "\n"
      } else {
        start += compileStatement(statement, c.globals, startLocals)
      }
      statement = []
    } else {
      statement.push(token)
    }
  }
  for (let i = 0; i < startLocals.length; i++) {
    start = `(local $${startLocals[i]} i32)` + start
  }
  if (!table) table = `(table $-table ${c.globals["-table"].length} anyfunc)\n`
  for (let i = 0; i < c.globals["-table"].length; i++) {
    table += `(elem (i32.const ${i}) $--${c.globals["-table"][i]})\n`

    exports += `(func $--${c.globals["-table"][i]}\n`
    for (let p = 0; p < c.globals[c.globals["-table"][i]].length; p++) {
      exports += `(param $${c.globals[c.globals["-table"][i]][p]} f64)`
    }
    exports += `(result f64)`
    exports += `(call $-f64 (call $${c.globals["-table"][i]}`
    for (let p = 0; p < c.globals[c.globals["-table"][i]].length; p++) {
      exports += `(call $-number (get_local $${c.globals[c.globals["-table"][i]][p]}))`
    }
    exports += `)))\n`
  }

  return `
    (module
      ;; imports
      ${imports}

      ;; stdlib
      ${stdlib}

      ;; runtime
      ${runtime}

      ;; memory
      ${memory}

      ;; table
      ${table}

      ;; globals
      ${globals}

      ;; functions
      ${functions}

      ;; start
      (func $-start
        (local $-success i32)
      ${start})
      (start $-start)
      
      ;; exports
      ${exports}
    )
  `.trim()
}

function compileFunction(tokenTree, globals) {
  let wast = ""
  let locals = []
  tokenTree = deparens(tokenTree, true)

  wast += `(func $${tokenTree[1]} `
  for (let i = 2; i < tokenTree.length; i++) {
    if (isIdentifier(tokenTree[i])) {
      wast += `(param $${tokenTree[i]} i32) `
      locals.push(tokenTree[i])
    }
    if (tokenTree[i][0] === "{") {
      wast += `(result i32)\n`
      let paramlength = locals.length
      let block = compileBlock(tokenTree[i], globals, locals)
      for (let i = paramlength; i < locals.length; i++) {
        wast += `(local $${locals[i]} i32)`
      }
      wast += `(local $-ret i32)(local $-success i32)(call $-funcstart)`
      wast += block
      wast += `(call $-funcend)(get_local $-ret)`
    }
  }
  wast += `)\n`

  return wast
}

function compileBlock(tokenTree, globals, locals) {
  let wast = "(block\n"
  tokenTree = deparens(tokenTree, true)

  let statement = []
  for (let token of tokenTree) {
    if (";}".includes(token)) {
      wast += compileStatement(statement, globals, locals) + "\n"
      statement = []
    } else {
      statement.push(token)
    }
  }
  if (statement.length) {
    wast += compileStatement(statement, globals, locals) + "\n"
  }
  wast += "(set_local $-success (i32.const 1)))\n"
  return wast
}

function compileStatement(tokenTree, globals, locals) {
  let wast = ""
  tokenTree = deparens(tokenTree, true)

  if (isIdentifier(tokenTree[0])) {
    wast += `(drop ${compileExpression(tokenTree, globals, locals)})\n`
  } else if (tokenTree[0] === "@set") {
    tokenTree.shift()
    let variable = []
    while (!isAssigner(tokenTree[0])) {
      variable.push(tokenTree.shift())
    }
    let assigner = tokenTree.shift()
    let setter = ``
    if (variable.length > 1) {
      setter = `call $-setToObj ${compileExpression(variable.slice(0, variable.length - 1), globals, locals)} ${compileExpression(variable.slice(variable.length - 1), globals, locals)}`
    } else if (locals.includes(variable[0])) {
      setter = `set_local $${variable[0]}`
    } else if (globals[variable[0]]) {
      if (typeof globals[variable[0]] === "object") {
        throw "attempt to assign value to function"
      } else {
        setter = `set_global $${variable[0]}`
      }
    } else {
      locals.push(variable[0])
      setter = `set_local $${variable[0]}`
    }
    wast += `(${setter} (call $-reref ${compileExpression(variable, globals, locals)}`
    if (assigner[0] !== "=") {
      tokenTree.unshift(assigner[0])
      tokenTree.unshift(variable)
    }
    wast += ` ${compileExpression(tokenTree, globals, locals)}))\n`
  } else if (tokenTree[0] === "@if") {
    wast += `(if (call $-truthy ${compileExpression(tokenTree.slice(1, tokenTree.length - 1), globals, locals)})\n`
    wast += `(then ${compileBlock(tokenTree[tokenTree.length - 1], globals, locals)})`
    wast += `(else (set_local $-success (i32.const 0))))`
  } else if (tokenTree[0] === "@elsif") {
    wast += `(if (i32.xor (get_local $-success) (call $-truthy ${compileExpression(tokenTree.slice(1, tokenTree.length - 1), globals, locals)}))\n`
    wast += `(then ${compileBlock(tokenTree[tokenTree.length - 1], globals, locals)}))`
  } else if (tokenTree[0] === "@else") {
    wast += `(if (i32.eqz (get_local $-success))\n`
    wast += `(then ${compileBlock(tokenTree[tokenTree.length - 1], globals, locals)}))`
  } else if (tokenTree[0] === "@while") {
    wast += `(block(loop`
    wast += `(br_if 1 (call $-falsy ${compileExpression(tokenTree.slice(1, tokenTree.length - 1), globals, locals)}))`
    wast += ` ${compileBlock(tokenTree[tokenTree.length - 1], globals, locals)}`
    wast += `(br 0)))`
  } else if (tokenTree[0] === "@return") {
    wast += `(return (tee_local $-ret ${compileExpression(tokenTree.slice(1), globals, locals)}))\n`
  }

  return wast
}

function compileExpression(tokenTree, globals, locals) {
  let wast = ""
  let _values, values = deparens(tokenTree)
  if (values[0] === "{") return compileObjLit(tokenTree, globals, locals)

  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (values[values.length - 2] === "#") {
      let operand2 = values.pop()
      values.pop()
      if (!globals["-table"].includes(operand2)) globals["-table"].push(operand2)
      values.push(`(call $-number (f64.const ${globals["-table"].indexOf(operand2)}))`)
    }
  }
  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (values[values.length - 2] === "*") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-mul ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
    if (values[values.length - 2] === "/") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-div ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
    if (values[values.length - 2] === "%") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-mod ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
  }
  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (values[values.length - 2] === "+") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-add ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
    if (values[values.length - 2] === "-") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop() || "0"
      values.push(`(call $-sub ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
  }
  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (values[values.length - 2] === "<") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-lt ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
    if (values[values.length - 2] === "<=") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-le ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
    if (values[values.length - 2] === ">") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-gt ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
    if (values[values.length - 2] === ">=") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-ge ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
  }
  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (values[values.length - 2] === "==") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-equal ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
    if (values[values.length - 2] === "!=") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-unequal ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
  }
  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (values[values.length - 2] === "&&") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-and ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
    if (values[values.length - 2] === "||") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-or ${compileExpression([operand1], globals, locals)} ${compileExpression([operand2], globals, locals)})`)
    }
  }
  _values = values
  values = []
  let calls = 0
  for (let token of _values) {
    values.push(token)
    if (typeof token === "object") {
      values.pop()
      values.push(compileExpression(token, globals, locals))
    }
    if (isIdentifier(token)) {
      let id = values.pop()
      if (locals.includes(token)) {
        values.push(`(get_local $${id})`)
      } else if (globals[token]) {
        if (typeof globals[token] === "object") {
          values.push(`(call $${id}`)
          calls++
        } else {
          values.push(`(get_global $${id})`)
        }
      } else {
        values.push(`(i32.const 0)`)
      }
    }
    if (token === "@null") {
      values.pop()
      values.push(`(i32.const 0)`)
    }
    if (token === "@false") {
      values.pop()
      values.push(`(i32.const 1)`)
    }
    if (token === "@true") {
      values.pop()
      values.push(`(i32.const 5)`)
    }
    if (isNumber(token)) {
      let num = values.pop()
      values.push(`(call $-number (f64.const ${num}))`)
    }
    if (isString(token)) {
      let str = JSON.parse(values.pop())
      values.push(`(i32.const ${globals["-string"].indexOf(str)})`)
    }
  }
  if (calls) {
    for (let i = 0; i < calls; i++) {
      values.push(")")
    }
  } else if (values.length > 1) {
    _values = values
    values = [_values.shift()]
    for (let token of _values) {
      values.unshift(`(call $-getFromObj`)
      values.push(token)
      values.push(")")
    }
  }

  return values.join(" ")
}

function compileObjLit(tokenTree, globals, locals) {
  let wast = ""
  let datatype = 5
  let index = 0
  tokenTree = deparens(tokenTree, true)
  tokenTree.push(";")

  let name = 0
  while (locals.includes("-obj" + name)) name++
  locals.push(name = "-obj" + name)

  let statement = []
  for (let token of tokenTree) {
    if (";}".includes(token)) {
      if (statement.length > 1 && isString(statement[0])) {
        wast += `(call $-setToObj (get_local $${name}) ${compileExpression(statement.slice(0, 1), globals, locals)} ${compileExpression(statement.slice(1), globals, locals)})\n`
        index += 2
      } else {
        wast += `(call $-setToObj (get_local $${name}) (call $-number (f64.const ${index})) ${compileExpression(statement, globals, locals)})\n`
        index++
        datatype = 4
      }
      statement = []
    } else {
      statement.push(token)
    }
  }
  wast = `(tee_local $${name} (call $-newValue (i32.const ${datatype}) (i32.const 0)))\n` + wast


  return wast
}

function deparens(tokens, all) {
  let start = tokens[0]
  let end = tokens[tokens.length - 1]
  if (tokens.length === 1 && typeof start === "object") return deparens(start, all)
  if (all && start === "{" && end === "}") return deparens(tokens.slice(1, tokens.length - 1), all)
  if (start === "(" && end === ")") return deparens(tokens.slice(1, tokens.length - 1), all)
  if (start === "[" && end === "]") return deparens(tokens.slice(1, tokens.length - 1), all)
  return tokens.slice()
}

function compileWast(wast) {
  return wabt.parseWat("boot", wast).toBinary({ write_debug_names: true }).buffer
}

compile("boot.poem")
