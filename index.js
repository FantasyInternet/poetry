const fs = require("fs"),
  path = require("path"),
  wabt = require("wabt")

function compile(filename, options = {}) {
  let compilation = {
    tokenTree: [],
    strings: [null, false, 0, "", null, true, true, true],
    bundle: []
  }
  compilation.bundle.push(require.resolve(filename, { paths: [path.dirname(filename)] }))
  compilation.ns = 0
  while (compilation.bundle[compilation.ns]) {
    compilation.path = compilation.bundle[compilation.ns]
    compilation.src = ("\n" + fs.readFileSync(compilation.path)).replace(/\r/g, "") + "\n~end\n;"
    compilation.config = findConfig(compilation.path)
    compilation.metaphors = compilation.config.metaphors

    rewind(compilation)
    compilation.tokenTree = compilation.tokenTree.concat(createTokenTree(compilation))
    compilation.ns++
  }

  compilation.globals = { ...require("./stdlib.json"), ...scanForGlobals(compilation.tokenTree) }
  compilation.globals["-namespaces"] = {}
  if (options.debug) {
    console.log(JSON.stringify(compilation, null, 2))
  }
  let wast = compileModule(compilation)
  if (options.wast) {
    fs.writeFileSync(options.wast, wast)
  }
  if (options.wasm) {
    let wasm = compileWast(wast)
    fs.writeFileSync(options.wasm, wasm)
  }
}

function findConfig(dir) {
  let config
  while (!config) {
    try {
      config = require(path.join(dir, "poetry.json"))
    } catch (error) { }
    if (dir !== path.dirname(dir)) {
      dir = path.dirname(dir)
    } else {
      dir = __dirname
    }
  }
  return config
}

function isKeyword(token) { return token && typeof token === "string" && (token[0] === "@") }
function isProperty(token) { return token && typeof token === "string" && (token[0] === ":") }
function isIdentifier(token) { return token && typeof token === "string" && (token[0].match(/[\$A-Z_a-z]/) || token.charCodeAt(0) > 127) }
function isNumber(token) { return token && typeof token === "string" && (token[0].match(/[0-9]/)) }
function isString(token) { return token && typeof token === "string" && (token[0].match(/["']/)) }
function isSymbol(token) { return token && typeof token === "string" && (token[0].match(/[!#%&*+,\-/;<=>?^|]/)) }
function isAssigner(token) { return token && typeof token === "string" && (token.substr(-1) === "=") }

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
      str += "\\" + ("0" + buf[i].toString(16)).substr(-2)
    }
  }
  return str
}

function nextToken(c) {
  let token = " "
  let char
  while (" \t`".includes(token)) {
    token = nextChar(c)
    if (!token) return
    if (token === "~") {
      let end = "\n"
      token = nextChar(c)
      if (token === "`") end = token
      while (token !== end) {
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
  } else if (token.match(/[\:]/)) {
    char = nextChar(c, true)
    while (char.match(/[\$A-Z_a-z0-9.\\]/) || char.charCodeAt(0) > 127) {
      token += nextChar(c)
      char = nextChar(c, true)
    }
  } else if (token.match(/[\$A-Z_a-z]/) || token.charCodeAt(0) > 127) {
    char = nextChar(c, true)
    while (char.match(/[\$A-Z_a-z0-9.\\]/) || char.charCodeAt(0) > 127) {
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
  if (isProperty(token)) {
    let str = token.substr(1)
    if (isNaN(str) && !c.strings.includes(str)) {
      c.strings.push(str)
    }
  }
  if (c.lastToken === "@import") {
  } else if (c.lastToken === "@export") {
  } else if (c.lastToken === "@include") {
    let filename = require.resolve(JSON.parse(token), { paths: [path.dirname(c.path)] })
    if (!c.bundle.includes(filename)) {
      c.bundle.push(filename)
    }
    token = JSON.stringify(filename)
  } else if (isString(token)) {
    let str = JSON.parse(token)
    if (str && !c.strings.includes(str)) {
      c.strings.push(str)
    }
  }
  if (isIdentifier(token)) {
    token = "ns" + c.ns + "\\" + token
  }
  if (c.lastToken === "@import") {
    c.lastToken = "@export"
  } else {
    c.lastToken = token
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
  let globals = []

  let statement = []
  for (let token of tokenTree) {
    if (";}".includes(token)) {
      if (statement[0] === "@var") {
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
  let memory = `(memory $-memory 2) \n`
  let table = ""
  let globals = ""
  let functions = ""
  let start = "(call $-initruntime)\n"
  let startLocals = ["-ret"]
  let exports = ""
  let runtime = fs.readFileSync(path.join(__dirname, "runtime.wast"))
  let stdlib = fs.readFileSync(path.join(__dirname, "stdlib.wast"))
  let gc = ""

  let offset = 1024 * 64
  for (let i = 8; i < c.strings.length; i++) {
    let len = Buffer.byteLength(c.strings[i], 'utf8')
    memory += `(data (i32.const ${offset}) "${escapeStr(c.strings[i])}")\n`
    start += `(call $-string (i32.const ${offset}) (i32.const ${len}))\n`
    offset += len
    offset = Math.floor(offset / 8) * 8 + 8
  }
  start += `(call $-zerorefs)\n`
  c.globals["-string"] = c.strings
  c.globals["-table"] = []

  let statement = []
  for (let token of c.tokenTree) {
    if (";}".includes(token)) {
      if (statement[0] === "@var") {
        globals += `(global $${statement[1]} (mut i32) (i32.const 0))\n`
        statement.shift()
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
          functions += `(call $-f64 (call $-to_number (get_local $p${i}))) `
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
      } else if (statement[0] === "@include") {
        let filename = JSON.parse(statement[1])
        let ns = c.bundle.indexOf(filename)
        if (ns >= 0) {
          c.globals["-namespaces"][statement[2]] = "ns" + ns + "\\"
        }
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
  gc += `(func $-traceGC\n`
  gc += `(call $-zerorefs)\n`
  for (let g in c.globals) {
    if (c.globals[g] === true) {
      gc += `(call $-reftree (get_global $${g}))\n`
    }
  }
  gc += `(call $-garbagecollect)\n`
  gc += `)\n`

  return `
    (module
      ;; imports
      ${imports}
      
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
      
      ;; runtime
      ${runtime}
      
      ;; stdlib
      ${stdlib}
      
      ;; gc
      ${gc}
    )
  `.trim()
}

function compileFunction(tokenTree, globals) {
  let wast = ""
  let locals = []
  tokenTree = deparens(tokenTree, true)
  globals["-blocks"] = -1

  wast += `\n;; function $${tokenTree[1]} \n`
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
  globals["-blocks"]++
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
  globals["-blocks"]--
  return wast
}

function compileStatement(tokenTree, globals, locals) {
  let wast = ""
  tokenTree = deparens(tokenTree, true)

  if (tokenTree[0] === "@var") {
    tokenTree.shift()
    if (!locals.includes(tokenTree[0])) {
      locals.push(tokenTree[0])
    }
  }
  if (tokenTree[0] === "@if") {
    wast += `(if (call $-truthy ${compileExpression(tokenTree.slice(1, tokenTree.length - 1), globals, locals)})\n`
    wast += `${compileBlock(tokenTree[tokenTree.length - 1], globals, locals)}`.replace("(block", "(then")
    wast += `(else (set_local $-success (i32.const 0))))`
  } else if (tokenTree[0] === "@elsif") {
    wast += `(if (i32.xor (get_local $-success) (call $-truthy ${compileExpression(tokenTree.slice(1, tokenTree.length - 1), globals, locals)}))\n`
    wast += `${compileBlock(tokenTree[tokenTree.length - 1], globals, locals)})`.replace("(block", "(then")
  } else if (tokenTree[0] === "@else") {
    wast += `(if (i32.eqz (get_local $-success))\n`
    wast += `${compileBlock(tokenTree[tokenTree.length - 1], globals, locals)})`.replace("(block", "(then")
  } else if (tokenTree[0] === "@while") {
    wast += `(block(loop`
    globals["-blocks"] += 2
    wast += `(br_if 1 (call $-falsy ${compileExpression(tokenTree.slice(1, tokenTree.length - 1), globals, locals)}))`
    wast += ` ${compileBlock(tokenTree[tokenTree.length - 1], globals, locals)}`
    wast += `(br 0)))`
    globals["-blocks"] -= 2
  } else if (tokenTree[0] === "@return") {
    wast += `(set_local $-ret ${compileExpression(tokenTree.slice(1), globals, locals)})(br ${globals["-blocks"]})\n`
  } else {
    let expr = compileExpression(tokenTree, globals, locals)
    if (expr) wast += `(drop ${expr})\n`
  }

  return wast
}

function compileExpression(tokenTree, globals, locals) {
  let wast = ""
  let _values, values = deparens(tokenTree)
  if (values[0] === "{") return compileObjLit(tokenTree, globals, locals)

  for (let i = 0; i < values.length; i++) {
    let token = values[i]
    if (token === "#") {
      let operand2 = values[i + 1]
      if (!globals["-table"].includes(operand2)) globals["-table"].push(operand2)
      values.splice(i, 1)
      values[i] = `(call $-number (f64.const ${globals["-table"].indexOf(operand2)}))`
    }
    if (isIdentifier(token) && typeof globals[resolveIdentifier(token, globals)] === "object" && !locals.includes(token)) {
      let a = values.slice(0, i)
      let b = values.slice(i + 1, values.length)
      values = a
      values.push(`(call $${resolveIdentifier(token, globals)} ${compileExpression(b, globals, locals)})`)
    }
  }

  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (typeof token === "object" && token[0] !== "[") {
      values.pop()
      values.push(compileExpression(token, globals, locals))
    }
    if (isIdentifier(token)) {
      let id = resolveIdentifier(values.pop(), globals)
      if (locals.includes(token)) {
        values.push(`(get_local $${token})`)
      } else if (globals[id]) {
        if (typeof globals[id] === "object") {
          values.push(id)
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
    if (token === "@array") {
      values.pop()
      values.push(`(call $-new_value (i32.const 4) (i32.const 0))`)
    }
    if (token === "@object") {
      values.pop()
      values.push(`(call $-new_value (i32.const 5) (i32.const 0))`)
    }
    if (token === "@binary") {
      values.pop()
      values.push(`(call $-new_value (i32.const 6) (i32.const 0))`)
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
  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (isProperty(token)) {
      let prop = values.pop().substr(1)
      let obj = values.pop()
      if (isNaN(prop)) {
        prop = `(i32.const ${globals["-string"].indexOf(prop)})`
      } else {
        prop = `(call $-number (f64.const ${prop}))`
      }
      values.push(`(call $-getFromObj ${obj} ${prop})`)
    }
    if (typeof token === "object" && token[0] === "[") {
      let prop = compileExpression(values.pop())
      let obj = values.pop()
      values.push(`(call $-getFromObj ${obj} ${prop})`)
    }
    /* if (values[values.length - 2] === "#") {
      let operand2 = values.pop()
      values.pop()
      if (!globals["-table"].includes(operand2)) globals["-table"].push(operand2)
      values.push(`(call $-number (f64.const ${globals["-table"].indexOf(operand2)}))`)
    } */
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
  for (let token of _values) {
    values.push(token)
    if (isAssigner(values[values.length - 2])) {
      let operand2 = values.pop()
      let op = values.pop()
      let operand1 = values.pop()
      let setter = operand1
      if (setter.indexOf(`(get_local `) === 0) {
        setter = setter.replace(`(get_local `, `(set_local `)
      } else if (setter.indexOf(`(get_global `) === 0) {
        setter = setter.replace(`(get_global `, `(set_global `)
      } else if (setter.indexOf(`(call $-getFromObj `) === 0) {
        setter = setter.replace(`(call $-getFromObj `, `(call $-setToObj `)
      } else {
        throw `cannot assign to ${setter}`
      }
      if (op[0] === "+") {
        operand2 = `(call $-add ${operand1} ${operand2})`
      }
      if (op[0] === "-") {
        operand2 = `(call $-sub ${operand1} ${operand2})`
      }
      if (op[0] === "*") {
        operand2 = `(call $-mul ${operand1} ${operand2})`
      }
      if (op[0] === "/") {
        operand2 = `(call $-div ${operand1} ${operand2})`
      }
      if (op[0] === "%") {
        operand2 = `(call $-mod ${operand1} ${operand2})`
      }
      setter = setter.substr(0, setter.lastIndexOf(")"))
      operand2 += ")"
      values.push(`${setter} ${operand2} ${operand1}\n`)
    }
  }
  /*  _values = values
   values = []
   let calls = 0
   for (let token of _values) {
     values.push(token)
     if (isIdentifier(token)) {
       let id = values.pop()
       if (typeof globals[token] === "object") {
         values.push(`(call $${id}`)
         calls++
       }
     }
   }
 
   for (let i = 0; i < calls; i++) {
     values.push(")")
   } */

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
      if (statement.length > 1 && isProperty(statement[0])) {
        statement.unshift(`(get_local $${name})`)
        wast += `(drop ${compileExpression(statement, globals, locals)})\n`
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
  wast = `(tee_local $${name} (call $-new_value (i32.const ${datatype}) (i32.const 0)))\n` + wast


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

function resolveIdentifier(identifier, globals) {
  let stdlib = require("./stdlib.json")
  let ns = identifier.substr(0, identifier.indexOf("\\") + 1)
  let name = identifier.substr(identifier.indexOf("\\") + 1)
  if (stdlib[name]) {
    return name
  } else {
    for (let prefix in globals["-namespaces"]) {
      if (identifier.substr(0, prefix.length) === prefix) {
        identifier = identifier.replace(prefix, globals["-namespaces"][prefix])
      }
    }
  }
  return identifier
}

module.exports = compile
