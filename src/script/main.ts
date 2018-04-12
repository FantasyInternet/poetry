import CharReader from "./_lib/CharReader"
import Tokenizer from "./_lib/Tokenizer"
import Parser from "./_lib/Parser"

//@ts-ignore
window.compileFile = async function (filename: string) {
  let src = await (await fetch(filename)).text()
  let parser = new Parser(new Tokenizer(new CharReader(src)))
  console.log(parser.nextBlock())
  console.log("dONE!")
}
