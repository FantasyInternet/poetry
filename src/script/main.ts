import Reader from "./_lib/Reader"
import Tokenizer from "./_lib/Tokenizer"
import Parser from "./_lib/Parser"
import Reconstructor from "./_lib/Reconstructor"

//@ts-ignore
window.compileFile = async function (filename: string) {
  let src = await (await fetch(filename)).text()
  let reconstructor = new Reconstructor()
  console.log(reconstructor.fromTokenizer(new Tokenizer(new Reader(src))))
  console.log(reconstructor.fromParser(new Parser(new Tokenizer(new Reader(src)))))
  console.log("dONE!")
}
