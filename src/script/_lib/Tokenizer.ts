import CharReader from "./CharReader"

/**
 * Convert character stream into token stream.
 */
export default class Tokenizer {
  keywords: string[] = ["if", "else", "function", "let", "while", "for", "in",
    "is", "isnt", "be", "return", "true", "false", "null", "class",
    "constructor", "integer", "float", "boolean", "string"]
  flowControl: string[] = ["if", "else", "while", "for", "function", "class", "constructor"]

  constructor(private charReader: CharReader) {
  }

  next() {
    if (this.buffer.length) {
      return this.buffer.shift()
    }
    let char = this.charReader.peek()
    let token = {
      type: "unknown",
      val: ""
    }
    if (this.charReader.isEof() && this.indents.length) {
      token.type = "outdent"
      while (this.indents.length) {
        this.indents.pop()
        this.buffer.push(this.nlToken)
        this.buffer.push(token)
      }
      this.buffer.push(this.nlToken)
      token = this.buffer.shift()
    } else if (this.charReader.isEof()) {
      return
    } else if (char === "\n") {
      let indentDelta = 0
      token.type = "newline"
      while (this.charReader.peek() === "\n") {
        this.charReader.next()
        token.val = this.readWhile(this.isWhitespace)
      }
      if (this.expectBlock > 0) {
        this.expectBlock = 0
        while (this.currentIndent() > token.val.length) {
          this.indents.pop()
          indentDelta--
        }
        if (this.currentIndent() < token.val.length) {
          this.indents.push(token.val.length)
          indentDelta++
        }
        if (indentDelta !== 0) {
          while (indentDelta > 0) {
            token.type = "indent"
            this.buffer.push(token)
            indentDelta--
          }
          while (indentDelta < 0) {
            token.type = "outdent"
            this.buffer.push(this.nlToken)
            this.buffer.push(token)
            indentDelta++
          }
          this.buffer.push(this.nlToken)
          token = this.next()
        }
      } else {
        if (token.val.length > this.currentIndent()) {
          token = this.next()
        } else {
          this.expectBlock = 0
          if (token.val.length < this.currentIndent()) {
            while (this.currentIndent() > token.val.length) {
              this.indents.pop()
              token.type = "outdent"
              this.buffer.push(this.nlToken)
              this.buffer.push(token)
            }
            this.buffer.push(this.nlToken)
            token = this.next()
          }
        }
      }
    } else if (this.isWhitespace(char)) {
      token.type = "whitespace"
      token.val = this.readWhile(this.isWhitespace)
    } else if (this.isCommentStart(char)) {
      token.type = "comment"
      token.val = this.readWhile(this.isComment)
    } else if (this.isPunctuation(char)) {
      token.type = "punctuation"
      token.val = this.charReader.next()
      this.readWhile(this.isWhitespace)
    } else if (this.isOperator(char)) {
      token.type = "operator"
      token.val = this.readWhile(this.isOperator)
      this.readWhile(this.isWhitespace)
    } else if (this.isNumber(char)) {
      token.type = "number"
      token.val = this.readWhile(this.isNumber)
      this.readWhile(this.isWhitespace)
    } else if (this.isWordStart(char)) {
      token.type = "word"
      token.val = this.charReader.next() + this.readWhile(this.isWord)
      if (this.keywords.indexOf(token.val) >= 0) {
        token.type = "keyword"
      } else {
        token.type = "name"
      }
      if (this.expectBlock === 0) {
        if (this.flowControl.indexOf(token.val) >= 0) {
          this.expectBlock = 1
        } else {
          this.expectBlock = -1
        }
      }
      this.readWhile(this.isWhitespace)
    } else if (this.isQuote(char)) {
      token.type = "string"
      token.val = this.charReader.next()
      while (!this.isQuote(this.charReader.peek())) {
        if (this.charReader.peek() === "\\") {
          token.val += this.charReader.next()
        }
        token.val += this.charReader.next()
      }
      token.val += this.charReader.next()
      this.readWhile(this.isWhitespace)
    } else {
      token.val = this.charReader.next()
      this.readWhile(this.isWhitespace)
    }
    return token
  }

  peek() {
    if (!this.buffer.length) this.buffer.push(this.next())
    while (!this.buffer[0] && this.buffer.length) this.buffer.shift()
    return this.buffer[0]
  }

  isEof() {
    return this.charReader.isEof() && this.buffer.length === 0 && this.indents.length === 0
  }

  error(msg: string) {
    return this.charReader.error(msg)
  }

  isWhitespace(str: string) {
    return " \t".includes(str)
  }
  isWordStart(str: string) {
    return (/[a-z_]/i).test(str)
  }
  isWord(str: string) {
    return (/[0-9a-z_]/i).test(str)
  }
  isNumberStart(str: string) {
    return "0123456789.-".includes(str)
  }
  isNumber(str: string) {
    return "0123456789.".includes(str)
  }
  isOperator(str: string) {
    return "+-*/&%=|<>.".includes(str)
  }
  isPunctuation(str: string) {
    return "()[]{},;".includes(str)
  }
  isQuote(str: string) {
    return "\"".includes(str)
  }
  isCommentStart(str: string) {
    return str === "!"
  }
  isComment(str: string) {
    return str !== "\n"
  }

  currentIndent() {
    return this.indents[this.indents.length - 1] || 0
  }

  /* _privates */
  private indents: number[] = []
  private buffer: any[] = []
  private expectBlock: number = 0
  private nlToken: any = { type: "newline", val: "" }

  private readWhile(test: Function, not: boolean = false) {
    let str = ""
    while (!this.charReader.isEof() && test(this.charReader.peek()) != not) {
      str += this.charReader.next()
    }
    return str
  }


}
