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
  compilation.namespaces = { "": [] }
  while (compilation.bundle[compilation.ns]) {
    compilation.path = compilation.bundle[compilation.ns]
    compilation.src = ("\n" + fs.readFileSync(compilation.path)).replace(/\r/g, "") + "\n;;~end`\n;"
    compilation.config = findConfig(compilation.path)
    compilation.metaphors = compilation.config.metaphors
    if (compilation.config.includes) {
      for (let include of compilation.config.includes) {
        if (!compilation.bundle.includes(include)) {
          compilation.namespaces[""].push("ns" + compilation.bundle.length + "\\")
          compilation.bundle.push(include)
        }
      }
    }

    rewind(compilation)
    if (compilation.path.match(/.+\.was?t$/)) {
      compilation.tokenTree = compilation.tokenTree.concat(createWastTokenTree(compilation))
    } else {
      compilation.tokenTree = compilation.tokenTree.concat(createTokenTree(compilation))
    }
    compilation.ns++
  }

  compilation.globals = scanForGlobals(compilation.tokenTree)
  if (options.debug) {
    fs.writeFileSync(options.debug, JSON.stringify(compilation, null, 2))
  }
  compilation.globals["-namespaces"] = compilation.namespaces
  let wast = compileModule(compilation)
  if (options.wast) {
    fs.writeFileSync(options.wast, wast)
  }
  if (options.debug) {
    fs.writeFileSync(options.debug, JSON.stringify(compilation, null, 2))
  }
  if (options.wasm) {
    let wasm = compileWast(wast)
    fs.writeFileSync(options.wasm, wasm)
  }
}

function findConfig(dir) {
  let config = {}
  let tries = dir.split(path.sep).length + 1
  while (tries--) {
    try {
      config = { ...require(path.join(dir, "poetry.json")), ...config }
      if (config.includes) {
        for (let i = 0; i < config.includes.length; i++) {
          config.includes[i] = require.resolve(config.includes[i], { paths: [dir] })
        }
      }
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
function isWast(token) { return token && typeof token === "object" && ["import", "global", "func", "export"].includes(token[0]) }

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
      if (token === "`") {
        end = token
        token = " "
      }
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
        let end = "\n"
        nextChar(c)
        char = nextChar(c)
        if (char === "`") {
          end = char
          char = " "
        }
        while (char !== end) {
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
    token = '"' + token.substr(1, token.length - 2).replace(/(^|[^\\])"/g, '$1\\"') + '"'
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
function nextWastToken(c) {
  let token = " "
  let char
  while (token.charCodeAt(0) <= 32) {
    token = nextChar(c)
    if (!token) return
    if (token === ";" && nextChar(c, true) === ";") {
      token = nextChar(c)
      while (token !== "\n") {
        token = nextChar(c)
      }
    }
  }

  if (token.match(/[\w]/)) {
    char = nextChar(c, true)
    while (char.match(/[^\(\)\s]/)) {
      token += nextChar(c)
      char = nextChar(c, true)
    }
  } else if (token.match(/[\$]/)) {
    char = nextChar(c, true)
    while (char.match(/[^\(\)\s]/)) {
      token += nextChar(c)
      char = nextChar(c, true)
    }
  } else if (token.match(/[0-9.]/)) {
    let dot = token === "."
    char = nextChar(c, true)
    while (char.match(/[0-9x]/) || (char === "." && !dot)) {
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
    token = '"' + token.substr(1, token.length - 2).replace(/(^|[^\\])"/g, '$1\\"') + '"'
  }

  if (token[0] === "$" && isIdentifier(token.substr(1))) {
    token = "$ns" + c.ns + "\\" + token.substr(1)
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
function createWastTokenTree(c) {
  let token
  let tree = []
  while ((token = nextWastToken(c)) && (token !== ")")) {
    if (token === "(") {
      token = createWastTokenTree(c)
    }
    tree.push(token)
  }
  return tree
}

function scanForGlobals(tokenTree) {
  let globals = []

  let statement = []
  for (let token of tokenTree) {
    if (isWast(token)) {
      if (token[0] === "global") {
        if (isIdentifier(token[1].substr(1))) {
          if (globals[token[1].substr(1)]) throw `duplicate identifier "${token[1].substr(1)}"`
          globals[token[1].substr(1)] = true
        }
      }
      if (token[0] === "import") {
        token = token[3]
      }
      if (token[0] === "func") {
        if (isIdentifier(token[1].substr(1))) {
          if (globals[token[1].substr(1)]) throw `duplicate identifier "${token[1].substr(1)}"`
          let locals = []
          for (let i = 2; (typeof token === "object") && (token[i][0] === "param"); i++) {
            if (isIdentifier(token[i][1].substr(1))) {
              if (locals.includes(token[i][1].substr(1))) throw `duplicate parameter "${token[i][1].substr(1)}"`
              locals.push(token[i][1].substr(1))
            }
          }
          globals[token[1].substr(1)] = locals
        }
      }
    } else if (";}".includes(token)) {
      if (statement[0] === "@var") {
        if (isIdentifier(statement[1])) {
          if (globals[statement[1]]) throw `duplicate identifier "${statement[1]}"`
          globals[statement[1]] = true
        }
      }
      if (statement[0] === "@func" || statement[0] === "@import" || statement[0] === "@export") {
        if (statement[0] === "@import") {
          statement.splice(1, 2)
        }
        if (statement[0] === "@export") {
          statement.splice(1, 1)
        }
        if (isIdentifier(statement[1])) {
          if (globals[statement[1]]) throw `duplicate identifier "${statement[1]}"`
          let locals = []
          if (statement[0] === "@import") {
            let params = parseInt(statement[2])
            for (let i = 0; i < params; i++) {
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
  let gc = ""

  let offset = 1024 * 64
  start += `(call $-resize (i32.const -1) (i32.const ${8 * c.strings.length}))`
  for (let i = 8; i < c.strings.length; i++) {
    let len = Buffer.byteLength(c.strings[i], 'utf8')
    memory += `(data (i32.const ${offset}) "${escapeStr(c.strings[i])}")\n`
    start += `(call $-string (i32.const ${offset}) (i32.const ${len}))\n`
    offset += len
    offset = Math.floor(offset / 8) * 8 + 16
  }
  start += `(call $-zerorefs)\n`
  c.globals["-string"] = c.strings
  c.globals["-table"] = []

  let statement = []
  for (let token of c.tokenTree) {
    if (isWast(token)) {
      if (token[0] === "import") imports += compileWastTokens(token)
      if (token[0] === "global") globals += compileWastTokens(token)
      if (token[0] === "func") functions += compileWastTokens(token)
      if (token[0] === "export") exports += compileWastTokens(token)
    } else if (";}".includes(token)) {
      if (statement[0] === "@var") {
        globals += `(global $${statement[1]} (mut i32) (i32.const 0))\n`
        statement.shift()
      }
      if (statement[0] === "@export") {
        exports += `(func $--${statement[2]}\n`
        for (let i = 3; i < statement.length - 1; i++) {
          exports += `(param $${statement[i]} f64)`
        }
        exports += `(result f64)(call $-funcstart)`
        exports += `(call $-f64 (call $${statement[2]}`
        for (let i = 3; i < statement.length - 1; i++) {
          exports += `(call $-number (get_local $${statement[i]}))`
        }
        exports += `))(call $-funcend))(export ${statement[1]} (func $--${statement[2]}))\n`
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
        let prefix = statement[2] || ""
        let ns = c.bundle.indexOf(filename)
        if (ns >= 0) {
          c.globals["-namespaces"][prefix] = c.globals["-namespaces"][prefix] || []
          c.globals["-namespaces"][prefix].push("ns" + ns + "\\")
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
  if (!table) table = `(table $-table ${c.globals["-table"].length * 2} anyfunc)\n`
  for (let i = 0; i < c.globals["-table"].length; i++) {
    table += `(elem (i32.const ${i * 2}) $--${c.globals["-table"][i]})\n`
    table += `(elem (i32.const ${i * 2 + 1}) $${c.globals["-table"][i]})\n`

    exports += `(func $--${c.globals["-table"][i]}\n`
    for (let p = 0; p < c.globals[c.globals["-table"][i]].length; p++) {
      exports += `(param $${c.globals[c.globals["-table"][i]][p]} f64)`
    }
    exports += `(result f64)(call $-funcstart)`
    exports += `(call $-f64 (call $${c.globals["-table"][i]}`
    for (let p = 0; p < c.globals[c.globals["-table"][i]].length; p++) {
      exports += `(call $-number (get_local $${c.globals[c.globals["-table"][i]][p]}))`
    }
    exports += `))(call $-funcend))\n`
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
      wast += `(local $-ret i32)(local $-success i32)`
      wast += block
      wast += `(get_local $-ret)`
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

  if (tokenTree[0] === "@var" || tokenTree[0] === "@for") {
    if (!locals.includes(tokenTree[1])) {
      locals.push(tokenTree[1])
    }
    if (tokenTree[0] === "@var") tokenTree.shift()
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
  } else if (tokenTree[0] === "@for") {
    let fori = allocVar(locals, "-fori")
    let forl = allocVar(locals, "-forl")
    let fora = allocVar(locals, "-fora")
    let item = tokenTree[1]
    let array = tokenTree.slice(3, tokenTree.length - 1)
    wast += `(set_local $${fora} ${compileExpression(array, globals, locals)} )`
    wast += `(set_local $${forl} (i32.div_u (call $-len (get_local $${fora}) ) (i32.const 4)) )`
    wast += `(block(loop`
    globals["-blocks"] += 2
    wast += `(br_if 1 (i32.ge_u (get_local $${fori}) (get_local $${forl}) ) )`
    wast += `(set_local $${item} (call $-getFromObj (get_local $${fora}) (call $-integer_u (get_local $${fori}) )))`
    wast += ` ${compileBlock(tokenTree[tokenTree.length - 1], globals, locals)}`
    wast += `(set_local $${fori} (i32.add (get_local $${fori}) (i32.const 1)))(br 0)))`
    globals["-blocks"] -= 2
  } else if (tokenTree[0] === "@return") {
    wast += `(set_local $-ret ${compileExpression(tokenTree.slice(1), globals, locals)})(br ${globals["-blocks"]})\n`
  } else {
    let expr = compileExpression(tokenTree, globals, locals)
    if (expr) wast += `(drop ${expr})\n`
  }

  return wast
}

function compileExpression(tokenTree, globals, locals, list) {
  let wast = ""
  let _values, values = deparens(tokenTree)
  if (values[0] === "{") return compileObjLit(tokenTree, globals, locals)

  for (let i = 0; i < values.length; i++) {
    let token = values[i]
    if (token === "#") {
      let operand = values[i + 1]
      if (isIdentifier(operand) && typeof globals[resolveIdentifier(operand, globals)] === "object" && !locals.includes(operand)) {
        let name = resolveIdentifier(operand, globals)
        if (!globals["-table"].includes(name)) globals["-table"].push(name)
        values.splice(i, 1)
        values[i] = `(call $-integer_u (i32.const ${globals["-table"].indexOf(name) * 2}))`
      } else {
        let index = compileExpression([operand], globals, locals)
        let a = values.slice(0, i)
        let b = values.slice(i + 2, values.length)
        values = a
        let args = compileExpression(b, globals, locals, true)
        let wast = `(call_indirect `
        for (let i = 0; i < args.length; i++) {
          wast += `(param i32) `
        }
        wast += `(result i32)\n`
        wast += args.join(" ")
        wast += `(i32.add (i32.const 1) (call $-i32_u ${index})))`

        values.push(wast)
      }
    }
    if (isIdentifier(token) && typeof globals[resolveIdentifier(token, globals)] === "object" && !locals.includes(token)) {
      let name = resolveIdentifier(token, globals)
      let a = values.slice(0, i)
      let b = values.slice(i + 1, values.length)
      values = a
      let args = compileExpression(b, globals, locals, true)

      while (args.length > globals[name].length) args.pop()
      while (args.length < globals[name].length) args.push("(i32.const 0)")
      values.push(`(call $${name} ${args.join(" ")})`)
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
      let prop = compileExpression(values.pop(), globals, locals)
      let obj = values.pop()
      values.push(`(call $-getFromObj ${obj} ${prop})`)
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
      values.push(`(call $-mul ${operand1} ${operand2})`)
    }
    if (values[values.length - 2] === "/") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-div ${operand1} ${operand2})`)
    }
    if (values[values.length - 2] === "%") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-mod ${operand1} ${operand2})`)
    }
  }
  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (values[values.length - 1] === "++") {
      values.pop()
      values.push(`+=`)
      values.push(`(call $-integer_s (i32.const 1))`)
    }
    if (values[values.length - 1] === "--") {
      values.pop()
      values.push(`-=`)
      values.push(`(call $-integer_s (i32.const 1))`)
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
      values.push(`(call $-add ${operand1} ${operand2})`)
    }
    if (values[values.length - 2] === "-") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop() || "(i32.const 2)"
      values.push(`(call $-sub ${operand1} ${operand2})`)
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
      values.push(`(call $-lt ${operand1} ${operand2})`)
    }
    if (values[values.length - 2] === "<=") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-le ${operand1} ${operand2})`)
    }
    if (values[values.length - 2] === ">") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-gt ${operand1} ${operand2})`)
    }
    if (values[values.length - 2] === ">=") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-ge ${operand1} ${operand2})`)
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
      values.push(`(call $-equal ${operand1} ${operand2})`)
    }
    if (values[values.length - 2] === "!=") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-unequal ${operand1} ${operand2})`)
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
      values.push(`(call $-and ${operand1} ${operand2})`)
    }
    if (values[values.length - 2] === "||") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-or ${operand1} ${operand2})`)
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

  if (list) return values
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

function compileWastTokens(tokens, indent = "\n") {
  wast = ""
  for (let token of tokens) {
    if (typeof token === "object") {
      wast += compileWastTokens(token, indent + "  ")
    } else {
      wast += token + " "
    }
  }
  return `${indent}(${wast})`
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
  let ns = identifier.substr(0, identifier.indexOf("\\") + 1)
  let name = identifier.substr(identifier.indexOf("\\") + 1)
  if (globals[identifier]) {
    return identifier
  } else {
    for (let prefix in globals["-namespaces"]) {
      let namespaces = globals["-namespaces"][prefix]
      prefix = prefix || ns
      for (let namespace of namespaces) {
        if (identifier.substr(0, prefix.length) === prefix &&
          globals[identifier.replace(prefix, namespace)]) {
          return identifier.replace(prefix, namespace)
        }
      }
    }
  }
  return identifier
}

function allocVar(pool, prefix) {
  let i = 0
  while (pool.includes(prefix + i)) i++
  pool.push(prefix + i)
  return prefix + i
}

module.exports = compile
