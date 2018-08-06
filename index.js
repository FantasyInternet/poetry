const fs = require("fs")

function compile(path) {
  let compilation = {
    path: path,
    src: ("" + fs.readFileSync(path)).replace(/\r/g, "") + "\n~end\n;",
    position: 0,
    line: 1,
    col: 1,
    indents: [0],
    lastNl: 0,
    metaphors: {}
  }
  let token
  let line = ""
  let level = 0
  /* while (token = nextToken(compilation)) {
    line += token + " "
    if ("{;}".includes(token)) {
      console.log(line, line = "")
      if (token === "{") level++
      if (token === "}") level--
      for (let i = 0; i < level; i++)line += "  "
    }
  } */
  console.log(JSON.stringify(compilation.tokenTree = createTokenTree(compilation), null, 2))
  compilation.globals = scanForGlobals(compilation.tokenTree)
  fs.writeFileSync(path.replace(".poem", ".wast"), compileModule(compilation))
}

function isKeyword(token) { return typeof token === "string" && (token[0] === "@") }
function isIdentifier(token) { return typeof token === "string" && (token[0].match(/[\$A-Z_a-z]/) || token.charCodeAt(0) > 127) }
function isNumber(token) { return typeof token === "string" && (token[0].match(/[0-9]/)) }
function isString(token) { return typeof token === "string" && (token[0].match(/["']/)) }

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
    while (char.match(/[a-z]/)) {
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
    if (token[0] === ".") token = "0" + token
  } else if (token.match(/["']/)) {
    while (char !== token[0]) {
      if (char === "/") token += nextChar(c)
      char = nextChar(c)
      token += char
    }
  } else if (token.match(/[\{\(\[\;\]\)\}]/)) {
  } else while (token.substr(-1) === nextChar(c, true) || nextChar(c, true) === "=") {
    token += nextChar(c)
  }

  if (c.metaphors[token]) token = c.metaphors[token]
  return token
}

function createTokenTree(c) {
  let token
  let tree = []
  while ((token = nextToken(c)) && ("])}".includes(token) === false)) {
    if ("{([".includes(token)) {
      token = [token].concat(createTokenTree(c))
    }
    tree.push(token)
  }
  tree.push(token)
  return tree
}

function scanForGlobals(tokenTree) {
  let globals = {}

  let statement = []
  for (let token of tokenTree) {
    if (";}".includes(token)) {
      if (statement[0] === "@set") {
        if (isIdentifier(statement[1])) {
          if (globals[statement[1]]) throw `duplicate identifier "${statement[1]}"`
          globals[statement[1]] = true
        }
      }
      if (statement[0] === "@func") {
        if (isIdentifier(statement[1])) {
          if (globals[statement[1]]) throw `duplicate identifier "${statement[1]}"`
          globals[statement[1]] = scanForLocals(statement, {})
          for (let local in globals[statement[1]]) {
            if (globals[local]) globals[statement[1]][local] = false
          }
        }
      }
      statement = []
    } else {
      statement.push(token)
    }
  }

  return globals
}
function scanForLocals(tokenTree, locals) {

  let statement = []
  for (let token of tokenTree) {
    if (typeof token === "object") {
      scanForLocals(token, locals)
    } else if (";}".includes(token)) {
      if (statement[0] === "@set") {
        if (isIdentifier(statement[1])) {
          if (locals[statement[1]]) throw `duplicate identifier "${statement[1]}"`
          locals[statement[1]] = true
        }
      }
      if (statement[0] === "@func") {
        for (let i = 2; i < statement.length; i++) {
          if (isIdentifier(statement[i])) {
            if (locals[statement[i]]) throw `duplicate identifier "${statement[i]}"`
            locals[statement[i]] = true
          }
        }
      }
      statement = []
    } else {
      statement.push(token)
    }
  }

  return locals
}

function compileModule(c) {
  let imports = ""
  let runtime = ""
  let globals = ""
  let functions = ""
  let exports = ""

  let statement = []
  for (let token of c.tokenTree) {
    if (";}".includes(token)) {
      if (statement[0] === "@set") {
        globals += `(global $${statement[1]} (mut i32) (i32.const 0))\n`
      }
      if (statement[0] === "@func") {
        functions += compileFunction(statement, c.globals) + "\n"
      }
      statement = []
    } else {
      statement.push(token)
    }
  }

  return `
    (module
      ;; imports
      ${imports}
      ;; runtime
      ${runtime}
      ;; globals
      ${globals}
      ;; functions
      ${functions}
      ;; exports
      ${exports}
    )
  `.trim()
}

function compileFunction(tokenTree, globals) {
  let wast = ""
  tokenTree = deparens(tokenTree)

  wast += `(func $${tokenTree[1]} `
  for (let i = 2; i < tokenTree.length; i++) {
    if (isIdentifier(tokenTree[i])) {
      wast += `(param $${tokenTree[i]} i32) `
    }
    if (tokenTree[i][0] === "{") {
      wast += `(result i32)\n`
      wast += compileBlock(tokenTree[i], globals)
    }
  }
  wast += `)\n`

  return wast
}

function compileBlock(tokenTree, globals) {
  let wast = ""
  tokenTree = deparens(tokenTree)

  let statement = []
  for (let token of (tokenTree)) {
    if (";}".includes(token)) {
      wast += compileStatement(statement, globals) + "\n"
      statement = []
    } else {
      statement.push(token)
    }
  }
  if (statement.length) {
    wast += compileStatement(statement, globals) + "\n"
  }
  return wast
}

function compileStatement(tokenTree, globals) {
  let wast = ""
  tokenTree = deparens(tokenTree)

  if (isIdentifier(tokenTree[0])) {
    wast += `(drop ${compileExpression(tokenTree, globals)})\n`
  } else if (tokenTree[0] === "@if") {
    wast += `(if ${compileExpression(tokenTree[1], globals)} (then ${compileBlock(tokenTree[2], globals)}))`
  } else if (tokenTree[0] === "@return") {
    wast += `(return ${compileExpression(tokenTree.slice(1), globals)})\n`
  }

  return wast
}

function compileExpression(tokenTree, globals) {
  let wast = ""
  let _values, values = deparens(tokenTree)

  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (values[values.length - 2] === "*") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-mul ${compileExpression([operand1], globals)} ${compileExpression([operand2], globals)})`)
    }
    if (values[values.length - 2] === "/") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-div ${compileExpression([operand1], globals)} ${compileExpression([operand2], globals)})`)
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
      values.push(`(call $-add ${compileExpression([operand1])} ${compileExpression([operand2])})`)
    }
    if (values[values.length - 2] === "-") {
      let operand2 = values.pop()
      values.pop()
      let operand1 = values.pop()
      values.push(`(call $-sub ${compileExpression([operand1])} ${compileExpression([operand2])})`)
    }
  }
  _values = values
  values = []
  for (let token of _values) {
    values.push(token)
    if (isIdentifier(token)) {
      if (globals[token]) {
        if (typeof globals[token] === "object") {
          values.push(`(call $${values.pop()}`)
          _values.push(")")
        } else {
          values.push(`(get_global $${values.pop()})`)
        }
      } else {
        values.push(`(get_local $${values.pop()})`)
      }
    }
    if (isNumber(token)) {
      values.push(`(call $-number (f32.const ${values.pop()}))`)
    }
  }

  /* if (isIdentifier(tokenTree[0])) {
    if (typeof globals[tokenTree[0]] === "object") {
      wast += `(call $${tokenTree[0]}`
    } else if (globals[tokenTree[0]]) {
      wast += `(get_global $${tokenTree[0]})`
    } else {
      wast += `(get_local $${tokenTree[0]})`
    }
  } else if (tokenTree[0] === "(") {
    wast += compileExpression(tokenTree[0], globals)
  } */

  return values.join(" ")
}

function deparens(tokens) {
  let start = tokens[0]
  let end = tokens[tokens.length - 1]
  if (tokens.length === 1 && typeof start === "object") return deparens(start)
  if (start === "{" && end === "}") return deparens(tokens.slice(1, tokens.length - 1))
  if (start === "(" && end === ")") return deparens(tokens.slice(1, tokens.length - 1))
  if (start === "[" && end === "]") return deparens(tokens.slice(1, tokens.length - 1))
  return tokens
}

compile("test.poem")
