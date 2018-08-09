let importObject = {
  env: {
    logNumber: console.log
  }
}

fetch('boot.wasm').then(response =>
  response.arrayBuffer()
).then(bytes =>
  WebAssembly.instantiate(bytes, importObject)
).then(obj => {
  window.wasm = obj.instance.exports
  obj.instance.exports.test()
  console.log(new Uint32Array(obj.instance.exports.memory))
}
)
