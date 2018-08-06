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
  console.log(createTokenTree(compilation))
}

function isKeyword(token) { return token[0] === "@" }
function isIdentifier(token) { return token[0].match(/[\$A-Z_a-z]/) || token.charCodeAt(0) > 127 }
function isNumber(token) { return token[0].match(/[0-9]/) }
function isString(token) { return token[0].match(/["']/) }

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
    tree.push(token)
    if ("{([".includes(token)) {
      tree.push(createTokenTree(c))
    }
  }
  tree.push(token)
  return tree
}

function scanForGlobals(tokenTree) {
  let globals = {}

  let statement = []
  for (let token of tokenTree) {
    if (";}".includes(token)) {
      if (statement[0] === "@let") {
        if (isIdentifier(statement[1])) {
          if (globals[statement[1]]) throw `duplicate identifier "${statement[1]}"`
          globals[statement[1]] = true
        }
      }
      if (statement[0] === "@function") {
        if (globals[statement[1]]) throw `duplicate identifier "${statement[1]}"`
        globals[statement[1]] = scanForLocals(statement, {})
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
      if (statement[0] === "@let") {
        if (locals[statement[1]]) throw `duplicate identifier "${statement[1]}"`
        locals[statement[1]] = true
      }
      if (statement[0] === "@function") {
        for (let i = 2; i < statement.length; i++) {
          if (locals[statement[i]]) throw `duplicate identifier "${statement[i]}"`
          locals[statement[i]] = true
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

  let token
  while (token = nextToken(c)) {
    if (token === "let") {
      let varname = nextToken(c)
      if (!token.match(/[\$A-Z_a-z]/) && token.charCodeAt(0) <= 127) croak("Expected identifier")
      if (keywords.includes(varname)) croak("Invalid variable name")
      let op = nextToken(c)
      if (op === "be") {
        let expr = compileExpression(c)
      } else croak("Expected assignmed operator")
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

function compileExpression(c) {
  let wast = ""

  return wast
}

compile("concept.poem")
