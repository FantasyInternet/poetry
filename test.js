let importObject = {
  env: {
    logNumber: console.log,
    log: (offset, len) => {
      let dec = new TextDecoder()
      let buf = wasm.memory.buffer.slice(offset, offset + len)
      console.log(dec.decode(buf))
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
}
)
