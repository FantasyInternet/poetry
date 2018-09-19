function read_bin(offset, len) {
  return wasm.memory.buffer.slice(offset, offset + len)
}
function read_string(offset, len) {
  let dec = new TextDecoder()
  let buf = read_bin(offset, len)
  return dec.decode(buf)
}

let importObject = {
  env: {
    logNumber: console.log,
    log: (offset, len) => {
      console.log(read_string(offset, len))
    }
  }
}

fetch('boot.wasm').then(response =>
  response.arrayBuffer()
).then(bytes =>
  WebAssembly.instantiate(bytes, importObject)
).then(obj => {
  window.wasm = obj.instance.exports
  wasm.init()
  // wasm.init()
  // wasm.init()
}
)

var bits = 1
document.write('<button>do it!</button>')
document.getElementsByTagName("button")[0].addEventListener("click", () => {
  console.log(++bits, max = Math.pow(2, bits))
  for (let i = -8; i < 8; i++) {
    let j = max + i
    console.log(j === wasm.echo(j))
  }
})

function memoryIndex() {
  let mem = new Int32Array(wasm.memory.buffer)
  let mindex = wasm.get_mindex()
  let mindexLen = mem[mindex / 4 - 1]
  let id = 8
  let index = []
  for (let i = mindex; i < mindex + mindexLen; i += 8) {
    let item = {}
    index.push(item)
    item.offset = mem[i / 4]
    item.len = mem[item.offset / 4 - 1]
    item.datatype = mem[i / 4 + 1] / Math.pow(2, 16)
    item.used = item.datatype > 255
    item.datatype %= 256
    try {
      item.value = getValue(id++)
    } catch (error) {
      item.value = undefined
    }
  }
  console.table(index)
}

function getValue(id) {
  if (id < 8) {
    return [null, false, 0, "", undefined, true][id]
  }
  let mem = new Int32Array(wasm.memory.buffer)
  let mindex = wasm.get_mindex()
  id -= 8
  let i = mindex + 8 * id

  let item = {}
  item.offset = mem[i / 4]
  item.len = mem[item.offset / 4 - 1]
  item.datatype = (mem[i / 4 + 1] / Math.pow(2, 16)) % 256
  switch (item.datatype) {
    case 0:
      return null
    case 1:
      return undefined
    case 2:
      return wasm.load_f64(item.offset)
    case 3:
      return read_string(item.offset, item.len)
    case 4:
      let ar = []
      for (let i = item.offset; i < item.offset + item.len; i += 4) {
        ar.push(getValue(mem[i / 4]))
      }
      return ar
    case 5:
      let obj = {}
      for (let i = item.offset; i < item.offset + item.len; i += 8) {
        obj[getValue(mem[i / 4])] = getValue(mem[i / 4 + 1])
      }
      return obj
    case 6:
      return read_bin(item.offset, item.len)

    default:
      return undefined
  }
}

function validateAlloc() {
  let mem = new Int32Array(wasm.memory.buffer)
  let allocs = []
  let offset = 0
  let space = mem[offset / 4]
  while (offset < mem.length - 1) {
    let alloc = {}
    allocs.push(alloc)
    alloc.free = space
    offset += space
    if (space !== mem[offset / 4]) console.error("memory error at", offset)
    offset += 4
    space = mem[offset / 4]

    alloc.offset = offset + 4
    alloc.used = space
    offset += space + 4
    offset = Math.floor(offset / 8) * 8 + 8
    space = mem[offset / 4]
    space = Math.floor(space / 8) * 8
  }
  console.table(allocs)
}