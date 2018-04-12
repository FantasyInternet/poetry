import Tokenizer from "./Tokenizer"

/**
 * Converting token stream into syntax tree.
 */
export default class Parser {
  flowControl: string[] = ["if", "else", "while", "for", "function", "class", "constructor"]

  constructor(private tokenizer: Tokenizer) {
  }

  nextStatement() {
    let statement: any = {
      type: "statement",
      tokens: []
    }
    let hasBlock = false
    let end = false
    let indents = 0
    while (!end) {
      end = this.tokenizer.isEof()
      let token = this.tokenizer.peek()
      console.log(token)
      if (!token) {
        end = true
      } else if (token.type === "indent") {
        this.tokenizer.next()
        if (hasBlock) {
          statement.tokens.push(this.nextBlock())
          let token = this.tokenizer.peek()
          if (token && token.type !== "outdent") this.error(`unexpected token`)
        } else {
          indents++
        }
      } else if (token.type === "outdent") {
        if (--indents === 0) {
          end = true
        } else {
          this.tokenizer.next()
        }
      } else if (token.type === "newline") {
        if (indents === 0) {
          end = true
        } else {
          this.tokenizer.next()
        }
      } else if (token.type === "punctuation" && token.val === "(") {
        this.tokenizer.next()
        statement.tokens.push(this.nextStatement())
        let token = this.tokenizer.next()
        if (token && token.val !== ")") this.error(`unexpected token`)
      } else if (token.type === "punctuation" && token.val === ")") {
        end = true
      } else {
        statement.tokens.push(this.tokenizer.next())
        if (statement.tokens.length === 1 && statement.tokens[0].type === "keyword" && this.flowControl.indexOf(statement.tokens[0].val) >= 0) {
          hasBlock = true
        }
      }
    }
    return statement
  }

  nextBlock() {
    let block: any = {
      type: "block",
      statements: []
    }
    let end = false
    while (!end) {
      end = this.tokenizer.isEof()
      let token = this.tokenizer.peek()
      if (!token) {
        end = true
      } else if (token.type === "indent") {
        this.tokenizer.next()
        block.statements.push(this.nextBlock())
        let token = this.tokenizer.next()
        if (token && token.type !== "outdent") this.error(`unexpected token`)
      } else if (token.type === "outdent") {
        end = true
      } else {
        block.statements.push(this.nextStatement())
        let token = this.tokenizer.next()
        if (token && token.type !== "outdent" && token.type !== "newline") this.error(`unexpected token`)
      }
    }
    return block
  }

  isEof() {
    return this.tokenizer.isEof()
  }

  error(msg: string) {
    return this.tokenizer.error(msg)
  }


  isStatementEnd(token: any) {
    if (token.type === "newline") {
      return true
    } else if (token.type === "outdent") {
      return true
    } else if (token.type === "punctuation") {
      return token.val === ")" || token.val === ";"
    }
  }

  /* _privates */
  private readWhile(test: Function, not: boolean = false) {
    let tokens: any[] = []
    while (test(this.tokenizer.peek()) != not) {
      tokens.push(this.tokenizer.next())
    }
    return tokens
  }

  private readStatement() {
    let tokens: any[] = []
    let baseIndent = this.tokenizer.currentIndent()
    do {
      tokens.concat(...this.readWhile((token: any) => { return token.type === "newline" || token.type === "outdent" }, true))
    } while (baseIndent !== this.tokenizer.currentIndent())
    return tokens
  }
}
