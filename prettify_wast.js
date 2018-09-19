
function prettify(wast) {
  let out = ""
  let indent = true
  let tokens = tokenize(wast.trim() + "\n")
  //return JSON.stringify(tokens,null,2)
  let stack = []
  tokens = tokens[0]
  while (tokens) {
    let token = tokens.shift()
    if (typeof token === "object") {
      if (indent) {
        out += "\n"
        for (let i = 0; i < stack.length; i++) out += "  "
      }
      out += "("
      stack.push(tokens)
      tokens = token
      //out += countArrays(tokens)
      indent = countArrays(tokens) > 1
    } else if (token.substr(0, 2) === ";;") {
      if (indent) {
        out += "\n\n"
        for (let i = 0; i < stack.length; i++) out += "  "
      }
      out += token + " "
    } else {
      out += token + " "
    }
    while (tokens && !tokens.length) {
      out += ") "
      tokens = stack.pop()
      indent = true
      //indent = countArrays(tokens) > 1
    }
  }
  return trimLineEnds(out.substr(0, out.lastIndexOf(")")))
}

function tokenize(wast) {
  let stack = []
  let tokens = []
  let pos = 0
  let char = ""
  while (pos < wast.length) {
    //console.log(pos)
    let token = ""
    while (char && !char.trim()) {
      char = wast[pos++]
    }
    if (char === ";" && wast[pos] === ";") {
      //token="\n\n"
      while (char && char !== "\n") {
        token += char
        char = wast[pos++]
      }
      token += char
      char = wast[pos++]
    } else if (char === "(" && wast[pos] === ";") {
      while (char && token.substr(-2) !== ";)") {
        token += char
        char = wast[pos++]
      }
    } else if ("(".includes(char)) {
      stack.push(tokens)
      tokens.push(tokens = [])
      char = wast[pos++]
    } else if (")".includes(char)) {
      tokens = stack.pop()
      char = wast[pos++]
    } else if ("\"\'".includes(char)) {
      while (char && char !== token[0]) {
        if (char === "\\") {
          token += char
          char = wast[pos++]
        }
        token += char
        char = wast[pos++]
      }
      token += char
      char = wast[pos++]
    } else {
      do {
        token += char
        char = wast[pos++]
      } while (char && char.trim() && !"(\";\')".includes(char))
    }
    token && tokens.push(token)
    //console.log(token)
  }
  while (stack.length) tokens = stack.pop()
  return tokens
}

function countArrays(arr) {
  if (!arr) return 0
  let count = 0
  for (let elem of arr) {
    if (typeof elem === "object") count++
  }
  return count
}

function trimLineEnds(txt) {
  while (txt.includes(" \n")) {
    txt = txt.replace(/ \n/g, "\n");
  }
  return txt.trim() + "\n"
}

module.exports = prettify