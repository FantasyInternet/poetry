import Parser from "./Parser"
import Tokenizer from "./Tokenizer"

/**
 * Reconstruct original source code from parser tree.
 */
export default class Reconstructor {
  constructor() {
  }

  fromTokenizer(tokenizer: Tokenizer) {
    this.indents = 0
    let out = ""
    let token: any
    while (token = tokenizer.next()) {
      if (token.type === "newline") {
        out += ";" + this.writeNL()
      } else if (token.type === "indent") {
        this.indents++
        out += "{" + this.writeNL()
      } else if (token.type === "outdent") {
        this.indents--
        out += "}" + this.writeNL()
      } else {
        out += token.val + " "
      }
      //console.log(JSON.stringify(token))
    }
    return out
  }
  fromParser(parser: Parser) {
    this.indents = 0
    let block = parser.nextBlock()
    console.log(JSON.stringify(block, null, 2))
    return this.writeBlock(block)
  }

  /* _privates */
  private indents: number = 0

  private writeBlock(block: any) {
    if (block.type !== "block") throw "not a block!"
    let out = ""
    for (let statement of block.statements) {
      out += this.writeStatement(statement) + this.writeNL()
    }
    return out
  }

  private writeStatement(statement: any) {
    if (statement.type !== "statement") throw "not a statement!"
    let out = ""
    for (let token of statement.tokens) {
      if (token.type === "block") {
        this.indents++
        out += this.writeNL() + this.writeBlock(token)
        this.indents--
      } else if (token.type === "statement") {
        out += "(" + this.writeStatement(token) + ")"
      } else {
        out += token.val + " "
      }
    }
    return out//.trim()
  }

  private writeNL() {
    let out = "\n"
    for (let i = 0; i < this.indents; i++) {
      out += "  "
    }
    return out
  }
}
