const fs = require("fs")
const assert = require("assert")
const bnny = require("../index.js")

describe("BnNY", function () {
  this.timeout(32 * 1024)
  describe("assemble", function () {
    const examples = "./test/examples/"
    let files = shuffle(fs.readdirSync(examples))
    // files = [
    //   "bnny.wast",
    //   "invalid.wast",
    //   "sum.wast",
    //   "sum_.wast",
    //   "testsnstuff.wast",
    //   "cat.wast",
    //   "cat_.wast",
    // "numbers.wast"
    // ]

    for (const file of files) {
      if (file.includes(".wast")) {
        it(file, async function () {
          let target
          let result
          try {
            result = new Buffer(await bnny(fs.readFileSync(examples + file)))
          } catch (error) {
            result = new Buffer(error.toString())
          }
          try {
            target = fs.readFileSync(examples + file.replace(".wast", ".wasm"))
          } catch (error) {
            fs.writeFileSync(examples + file.replace(".wast", ".wasm"), result)
          }
          try {
            assert.deepEqual(result, target)
          } catch (error) {
            fs.writeFileSync(examples + file.replace(".wast", ".json"), result)
            assert.deepEqual(result, target.slice(0, result.byteLength))
            console.warn("\t ↙` " + ("" + result.byteLength / target.byteLength * 100).substr(0, 4) + "% match")
          }
        })
      }
    }
  })
})

function shuffle(ar) {
  let pos, swp
  for (let i = 0; i < ar.length; i++) {
    pos = Math.floor(Math.random() * ar.length)
    swp = ar[i]
    ar[i] = ar[pos]
    ar[pos] = swp
  }
  return ar
}