import Tokenizer from "./_lib/Tokenizer"
import CharReader from "./_lib/CharReader"

//@ts-ignore
window.compileFile = async function (filename: string) {
  let src = await (await fetch(filename)).text()
  let tokenizer = new Tokenizer(new CharReader(src))
  let tokens = []
  while (!tokenizer.isEof()) {
    let token = tokenizer.next()
    console.log(token)
    tokens.push(token)
  }
  console.log("dONE!")
  return tokens
}
