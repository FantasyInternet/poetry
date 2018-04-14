import Tokenizer from "./Tokenizer"

/**
 * Converting token stream into syntax tree.
 */
export default class Parser {

  constructor(private tokenizer: Tokenizer) {
  }

  nextStatement() {
    let statement: any = {
      type: "statement",
      tokens: []
    }
    //let hasBlock = false
    let end = false
    let indents = 0
    while (!end) {
      end = this.tokenizer.isEof()
      let token = this.tokenizer.peek()
      if (!token) {
        end = true
      } else if (token.type === "indent") {
        this.tokenizer.next()
        //if (hasBlock) {
        //  hasBlock = false
        statement.tokens.push(this.nextBlock())
        let token = this.tokenizer.next()
        if (token && token.type !== "outdent") this.error(`1unexpected token '${token.val}'`)
        /*} else {
          indents++
        }*/
        /*} else if (token.type === "outdent") {
          if (--indents <= 0) {
            end = true
          } else {
            this.tokenizer.next()
          }*/
      } else if (token.type === "newline") {
        //if (indents <= 0) {
        end = true
        //} else {
        //this.tokenizer.next()
        //}
      } else if (token.type === "punctuation" && token.val === "(") {
        this.tokenizer.next()
        statement.tokens.push(this.nextStatement())
        let token = this.tokenizer.next()
        if (token && token.val !== ")") this.error(`2unexpected token '${token.val}'`)
      } else if (token.type === "punctuation" && token.val === ")") {
        end = true
      } else {
        statement.tokens.push(this.tokenizer.next())
        /*if (statement.tokens.length === 1 && statement.tokens[0].type === "keyword" && this.flowControl.indexOf(statement.tokens[0].val) >= 0) {
          hasBlock = true
        }*/
      }
    }
    console.log(statement)
    return statement
  }

  nextBlock() {
    let block: any = {
      type: "block",
      statements: []
    }
    let baseIndent = this.tokenizer.currentIndent()
    let end = false
    while (!end) {
      end = this.tokenizer.isEof()
      let token = this.tokenizer.peek()
      if (!token) {
        end = true
        /*} else if (token.type === "indent") {
          this.tokenizer.next()
          block.statements.push(this.nextBlock())
          let token = this.tokenizer.next()
          if (token && token.type !== "outdent") this.error(`3unexpected token '${token.val}'`)*/
      } else if (token.type === "outdent") {
        end = true
      } else {
        block.statements.push(this.nextStatement())
        let token = this.tokenizer.next()
        if (token && token.type !== "newline") this.error(`4unexpected token '${token.val.trim() || token.type}'`)
        //if (token.type === "outdent") end = true
        //if (token.type === "newline") this.tokenizer.next()
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

}
