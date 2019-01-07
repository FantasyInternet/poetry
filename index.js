const path = require("path")
const fs = require("fs")
const { StringDecoder } = require('string_decoder');

const imports = {
  env: {
    "pushFromMemory": (offset, len) => {
      bufferStack.push(poetry.memory.buffer.slice(offset, offset + len))
    },
    "popToMemory": (offset) => {
      let ar = new Uint8Array(poetry.memory.buffer)
      ar.set(new Uint8Array(bufferStack.pop()), offset)
    },
    "log": () => {
      console.log("  🌳\t" + new Buffer(bufferStack.pop()))
    },
    "logNumber": (num) => {
      console.log("  🌼\t" + num + "\t0x" + num.toString(16))
    },
    "getInput": () => {
      let buf = Uint8Array.from(Buffer.from(input)).buffer
      bufferStack.push(buf)
      return buf.byteLength
    },
    "sendOutput": () => {
      output = bufferStack.pop()
    },
    "sendError": () => {
      error = "" + new Buffer(bufferStack.pop())
    },
    "read": (callback) => {
      let reqId = nextReqId++
      let path = "" + new Buffer(bufferStack.pop())
      fs.readFile(path, (err, data) => {
        if (err) {
          callback(false, null, reqId)
        } else {
          let buf = Uint8Array.from(data).buffer
          bufferStack.push(buf)
          callback(true, buf.byteLength, reqId)
        }
      })
      return reqId
    },
    "list": (callback) => {
      let reqId = nextReqId++
      let path = "" + new Buffer(bufferStack.pop())
      fs.readdir(path, (err, files) => {
        if (err) {
          callback(false, null, reqId)
        } else {
          let list = ""
          for (let file of files) {
            if (fs.statSync(path + "/" + file).isDirectory()) {
              list += file + "/\n"
            } else {
              list += file + "\n"
            }
          }
          let buf = Uint8Array.from(Buffer.from(list)).buffer
          bufferStack.push(buf)
          callback(true, buf.byteLength, reqId)
        }
      })
      return reqId
    },
    "write": (callback) => {
      let reqId = nextReqId++
      let data = new Buffer(bufferStack.pop())
      let path = "" + new Buffer(bufferStack.pop())
      fs.writeFile(path, data, (err) => {
        if (err) {
          callback(false, reqId)
        } else {
          callback(true, reqId)
        }
      })
      return reqId
    },
    "finish": () => {
      let output = new Buffer(bufferStack.pop())
      finishCB(output)
    }
  }
}
let nextReqId = 1
let bufferStack = []
let input = ""
let output
let error
let finishCB
let poetry = WebAssembly.instantiate(fs.readFileSync(path.join(__dirname, "./index.wasm")), imports)
poetry.then((result) => {
  poetry = result.instance.exports
})

let last_mem = 0
async function compile(path, options = {}) {
  error = null
  output = null
  if (!poetry.init) await poetry
  input = path
  poetry.init()
  if (poetry.memory.buffer.byteLength !== last_mem) {
    last_mem = poetry.memory.buffer.byteLength
    // console.log("Memory:", last_mem / (1024 * 1024), "MiB")
  }
  if (error) throw new Error(error)
  return output
}
module.exports = compile