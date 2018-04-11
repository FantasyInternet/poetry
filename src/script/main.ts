import Tokenizer from "./_lib/Tokenizer"
import CharReader from "./_lib/CharReader"

async function compileFile(filename: string) {
  let src = "" + (await fetch(filename)).text()
  let tokenizer = new Tokenizer(new CharReader(src))
  let tokens = []
  while (!tokenizer.isEof()) {
    tokens.push(tokenizer.next())
  }
  return tokens
}
