import CharReader from "./CharReader"

/**
 * Convert character stream into token stream.
 */
export default class Tokenizer {
  keywords: string[] = ["if", "else", "function", "let", "while", "for", "in",
    "is", "isnt", "be", "return", "true", "false", "null", "class",
    "constructor", "integer", "float", "boolean", "string"]

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
        this.buffer.push(token)
      }
      token = this.buffer.shift()
    } else if (char === "\n") {
      let indentDelta = 0
      while (this.charReader.peek() === "\n") {
        this.charReader.next()
        token.type = "newline"
        token.val = this.readWhile(this.isWhitespace)
      }
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
          this.buffer.push(token)
          indentDelta++
        }
        token = this.buffer.shift()
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

  isEof() {
    return this.charReader.isEof() && this.buffer.length === 0 && this.indents.length === 0
  }

  error(msg: string) {
    this.charReader.error(msg)
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

  /* _privates */
  private indents: number[] = []
  private buffer: any[] = []

  private readWhile(test: Function, not: boolean = false) {
    let str = ""
    while (test(this.charReader.peek()) != not) {
      str += this.charReader.next()
    }
    return str
  }

  private currentIndent() {
    return this.indents[this.indents.length - 1] || 0
  }

}
