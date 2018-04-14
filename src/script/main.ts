import CharReader from "./_lib/CharReader"
import Tokenizer from "./_lib/Tokenizer"
import Parser from "./_lib/Parser"
import Reconstructor from "./_lib/Reconstructor"

//@ts-ignore
window.compileFile = async function (filename: string) {
  let src = await (await fetch(filename)).text()
  let reconstructor = new Reconstructor()
  console.log(reconstructor.fromTokenizer(new Tokenizer(new CharReader(src))))
  console.log(reconstructor.fromParser(new Parser(new Tokenizer(new CharReader(src)))))
  console.log("dONE!")
}
