/**
 * Character reader for reading strings one character at a time.
 */
export default class Reader {
  pos: number = 0
  line: number = 1
  column: number = 0

  constructor(public src: string) {
    this.src = this.src.replace(/\r/g, "")
  }

  next() {
    let char = this.src[this.pos++]
    if (char === "\n") {
      this.line++
      this.column = 0
    } else {
      this.column++
    }
    return char
  }

  peek() {
    return this.src[this.pos]
  }

  isEof() {
    return this.pos >= this.src.length
  }

  error(msg: string) {
    throw `${msg} at line ${this.line}, column ${this.column}`
  }
}
