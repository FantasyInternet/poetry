const fs = require("fs")

var json = {}
var wast = "" + fs.readFileSync("./stdlib.wast")

var funcs = wast.split("(func")
funcs.shift()

for (let func of funcs) {
  let params = func.split("(param")
  let funcname = params.shift().trim().replace("$", "")
  json[funcname] = []
  for (let param of params) {
    let vars = param.trim().split(" ")
    let paramname = vars.shift().trim().replace("$", "")
    json[funcname].push(paramname)
  }
}

fs.writeFileSync("./stdlib.json", JSON.stringify(json, null, 2))
