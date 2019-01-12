const fs = require("fs")
const assert = require("assert")
const poetry = require("../index.js")

describe("Poetry", function () {
  this.timeout(32 * 1024)
  describe("compile", function () {
    const examples = "./test/examples/"
    let files = shuffle(fs.readdirSync(examples))

    for (const file of files) {
      if (file.includes(".poem")) {
        it(file, async function () {
          let target
          let result
          try {
            result = new Buffer(await poetry(examples + file))
          } catch (error) {
            result = new Buffer(error.stack)
          }
          try {
            target = fs.readFileSync(examples + file.replace(".poem", ".txt"))
          } catch (error) {
            fs.writeFileSync(examples + file.replace(".poem", ".txt"), result)
          }
          try {
            assert.deepEqual(result, target)
          } catch (error) {
            fs.writeFileSync(examples + file.replace(".poem", ".json"), result)
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