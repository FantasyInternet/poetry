/*jshint node:true */
/*globals complete, fail, jake, namespace, task, watchTask */
let os = require("os"),
  fs = require("fs"),
  path = require("path"),
  http = require("http"),
  Watcher = require("file-watch"),
  livereload = require("livereload"),
  pug = require("pug"),
  htmlmin = require("htmlmin"),
  less = require("less"),
  cssmin = require("cssmin"),
  browserify = require("browserify"),
  tsify = require("tsify"),
  jsmin = require("jsmin").jsmin,
  walt = require("walt-compiler").default,
  wabt = require("wabt"),
  FtpClient = require("ftp"),
  md5 = require("md5")

/**
* Jakefile.js
* For building web apps
*
* @date 10-apr-2018
*/
let srcDir = "./src/",
  outDir = "./build/",
  staticFiles = null,
  debug = false,
  staticEnabled = true,
  reloadServer,
  watchThrottle = {}

task("default", ["clean", "html:pug", "html:md", "css:less", "js:ts", "wasm:walt", "wasm:wast", "static:json", "static:all"])

task("watch", function () {
  http.get("http://localhost:8000/").on("error", function () { })
  console.log("\nWatching...")
  debug = true
  startWatching(".pug", "html:pug")
  startWatching(".md", "html:md")
  startWatching(".less", "css:less")
  startWatching(".ts", "js:ts")
  startWatching(".walt", "wasm:walt")
  startWatching(".wast", "wasm:wast")
  startWatching(".json", "static:json")
  startWatching("", "static:all")

  reloadServer = livereload.createServer()
  reloadServer.watch(outDir)

  jake.exec("statify", { printStderr: true })
})

task("deploy", ["default"], { async: true }, function () {
  console.log("\nDeploying to FTP...")
  let ftp = new FtpClient(),
    servers = require(os.homedir() + "/ftp_servers.json"),
    deploy = require("./deploy.json"),
    localDir = path.normalize(outDir + ".") + "/",
    ftpDir = servers[deploy.server].rootPath + deploy.path,
    files = new jake.FileList(),
    hashes = {},
    deletedFiles = []

  try {
    hashes = require(outDir + "_hashes.json")
  } catch (err) {
    hashes = {}
  }
  files.include([localDir, localDir + "**/*", localDir + "**/.*"])
  files = excludeIgnoredFiles(files).sort()
  for (let file in hashes) {
    if (files.indexOf(file) < 0) deletedFiles.push(file)
  }
  let upload = function () {
    let localFile = files.shift(),
      ftpFile = ftpDir + localFile.substr(localDir.length)

    if (deletedFiles.indexOf(localFile) >= 0) deletedFiles.splice(deletedFiles.indexOf(localFile), 1)
    if (fs.statSync(localFile).isDirectory()) {
      let oldHash = hashes[localFile]
      let newHash = "dir"
      if (oldHash !== newHash) {
        console.log("MKDIR", localFile, "...")
        ftp.mkdir(ftpFile, true, cb)
        hashes[localFile] = newHash
      } else {
        cb()
      }
    } else {
      let oldHash = hashes[localFile]
      let newHash = md5(fs.readFileSync(localFile))
      if (oldHash !== newHash) {
        console.log("PUT", localFile, "...")
        ftp.put(localFile, ftpFile, cb)
        hashes[localFile] = newHash
      } else {
        cb()
      }
    }
  }
  let emptyTrash = function () {
    let localFile = deletedFiles.pop(),
      ftpFile = ftpDir + localFile.substr(localDir.length)

    if (hashes[localFile] === "dir") {
      console.log("RMDIR", localFile, "...")
      ftp.rmdir(ftpFile, true, cb)
    } else {
      console.log("DELETE", localFile, "...")
      ftp.delete(ftpFile, cb)
    }
    delete hashes[localFile]
  }
  let cb = function (err) {
    if (err && err.code !== 550) {
      fail(err)
    } else if (deletedFiles.length) {
      emptyTrash()
    } else if (files.length) {
      upload()
    } else {
      ftp.end()
      console.log("...dONE!")
      fs.writeFileSync(outDir + "_hashes.json", JSON.stringify(hashes, null, 2))
      complete()
    }
  }
  ftp.on("ready", function () {
    upload()
  })
  ftp.connect(servers[deploy.server])
})

task("clean", function () {
  console.log("\nCleaning build dir...")
  jake.mkdirP(outDir)
  let files = new jake.FileList()
  files.include(outDir + "*")
  files.include(outDir + ".*")
  excludeIgnoredFiles(files).forEach(function (file) {
    jake.rmRf(file)
  })
  console.log("...dONE!")
})

namespace("html", function () {
  let data = {}, partials = {}
  try {
    data = require(srcDir + "data.json")
    data.pkg = require("./package.json")
    let readme = ("" + fs.readFileSync("./README.md")).trim().split("\n")
    data.appTitle = readme[0]
    data.description = readme[2]
    data.servers = require(os.homedir() + "/ftp_servers.json")
    data.deploy = require("./deploy.json")
    data.baseUrl = data.servers[data.deploy.server].rootUrl + data.deploy.path
  } catch (e) { }
  let pug_opts = {
    pretty: true
  }
  let htmlmin_opts = {}

  task("pug", function () {
    console.log("\nCompiling Pug...")
    data.files = fileList(srcDir)
    fileTypeList(".pug").forEach(function (inFile) {
      let outFile = outputFile(inFile, ".html"),
        output = "" + fs.readFileSync(inFile)
      console.log(inFile, "->", outFile)

      setActive(outFile, data)
      pug_opts.filename = inFile
      output = pug.compile(output, pug_opts)
      output = output(data)

      if (!debug) {
        try {
          output = htmlmin(output, htmlmin_opts)
        } catch (error) {
          console.log("Could not minify HTML!")
        }
      }
      jake.mkdirP(path.dirname(outFile))
      fs.writeFileSync(outFile, output)
    })
    console.log("...dONE!")
  })
  task("md", function () {
    jake.Task["html:pug"].invoke()
    console.log("\nCompiling Markdown...")
    data.files = fileList(srcDir)
    fileTypeList(".md").forEach(function (inFile) {
      let outFile = outputFile(inFile, ".html"),
        output = "" + fs.readFileSync(inFile)
      console.log(inFile, "->", outFile)

      setActive(outFile, data)
      let lines = output.trim().split("\n")
      data.title = lines[0].trim()
      pug_opts.filename = inFile
      output = output.replace(/\n/g, "\n    ")
      output = "include _markdown\n  :markdown-it\n    " + output
      output = pug.compile(output, pug_opts)
      output = output(data)

      if (!debug) { output = htmlmin(output, htmlmin_opts); }
      jake.mkdirP(path.dirname(outFile))
      fs.writeFileSync(outFile, output)
    })
    console.log("...dONE!")
  })
})

namespace("css", function () {
  let less_opts = {}

  task("less", { async: true }, function () {
    console.log("\nCompiling LESS...")
    let filesLeft = fileTypeList(".less").length
    if (!filesLeft) { console.log("...dONE!"); complete(); }
    fileTypeList(".less").forEach(function (inFile) {
      let outFile = outputFile(inFile, ".css"),
        output = "" + fs.readFileSync(inFile)
      console.log(inFile, "->", outFile)

      less_opts.filename = inFile
      less.render(output, less_opts).then(
        function (o) {
          let output = o.css
          if (!debug) { output = cssmin(output); }
          jake.mkdirP(path.dirname(outFile))
          fs.writeFileSync(outFile, output)
          if (--filesLeft === 0) { console.log("...dONE!"); complete(); }
        },
        function (err) {
          console.log("\u0007LESS compilation failed!\t" + err)
          fail()
        }
      )
    })
  })
})

namespace("js", function () {
  let browserify_opts = {
    bare: true,
    debug: true
  },
    tsify_opts = require("./tsconfig.json").compilerOptions

  task("ts", { async: true }, function () {
    console.log("\nCompiling TypeScript...")
    let filesLeft = fileTypeList(".ts").length
    if (!filesLeft) { console.log("...dONE!"); complete(); }
    fileTypeList(".ts").forEach(function (inFile) {
      let outFile = outputFile(inFile, ".js")
      console.log(inFile, "->", outFile)

      browserify(browserify_opts)
        .add(inFile)
        .plugin(tsify, tsify_opts)
        .bundle(function (err, buf) {
          if (err) {
            fail("\u0007TypeScript err!\t" + err)
          } else {
            let output = "" + buf
            if (!debug) { output = jsmin(output); }
            jake.mkdirP(path.dirname(outFile))
            fs.writeFileSync(outFile, output)
            if (--filesLeft <= 0) {
              console.log("...dONE!")
              formatTs()
              jake.exec("typedoc --module commonjs --target es6 --excludePrivate --gitRevision HEAD --theme markdown --out ./docs")
              complete()
            }
          }
        })

    })
  })
})

namespace("wasm", function () {
  let wabt_opts = {

  }

  task("wast", function () {
    console.log("\nCompiling Wast...")
    fileTypeList([".wast", ".wat"]).forEach(function (inFile) {
      let outFile = outputFile(inFile, ".wasm"),
        output = "" + fs.readFileSync(inFile)
      console.log(inFile, "->", outFile)

      let module = wabt.parseWat(inFile, output)
      output = module.toBinary(wabt_opts).buffer

      jake.mkdirP(path.dirname(outFile))
      fs.writeFileSync(outFile, new Uint8Array(output))
    })
    console.log("...dONE!")
  })
  task("walt", function () {
    console.log("\nCompiling Walt...")
    fileTypeList(".walt").forEach(function (inFile) {
      let outFile = outputFile(inFile, ".wasm"),
        output = "" + fs.readFileSync(inFile)
      console.log(inFile, "->", outFile)

      output = walt(output)

      jake.mkdirP(path.dirname(outFile))
      fs.writeFileSync(outFile, new Uint8Array(output))
    })
    console.log("...dONE!")
  })
})

namespace("static", function () {
  task("json", function () {
    console.log("\nReencoding JSON...")
    fileTypeList(".json").forEach(function (inFile) {
      let outFile = outputFile(inFile, ".json"),
        output = "" + fs.readFileSync(inFile)
      console.log(inFile, "->", outFile)

      if (debug) {
        output = JSON.stringify(JSON.parse(output.trim()), null, 2)
      } else {
        output = JSON.stringify(JSON.parse(output.trim()))
      }

      jake.mkdirP(path.dirname(outFile))
      fs.writeFileSync(outFile, output)
    })
    fileTypeList(".json.js").forEach(function (inFile) {
      let outFile = outputFile(inFile, ".json"),
        output = "" + fs.readFileSync(inFile)
      console.log(inFile, "->", outFile)

      if (debug) {
        output = JSON.stringify(eval("(" + output.trim() + ")"), null, 2)
      } else {
        output = JSON.stringify(eval("(" + output.trim() + ")"))
      }

      jake.mkdirP(path.dirname(outFile))
      fs.writeFileSync(outFile, output)
    })
    console.log("...dONE!")
  })

  task("all", function () {
    console.log("\nCopying static files...")
    fileTypeList([".pug", ".md", ".less", ".ts", ".walt", ".wast"])
    staticFiles.resolve()
    excludeIgnoredFiles(staticFiles.toArray()).forEach(function (inFile) {
      let outFile = outputFile(inFile)
      if (fs.statSync(inFile).isFile()) {
        jake.mkdirP(path.dirname(outFile))
        jake.cpR(inFile, outFile)
      }
    })
    console.log("...dONE!")
  })
})

task("upgrade", { async: true }, function () {
  console.log("\nUpgrading packages...")
  let packages = require("./package.json")
  let commands = []
  for (let pkg in packages.dependencies) {
    commands.push("npm -S remove " + pkg)
  }
  for (let pkg in packages.devDependencies) {
    commands.push("npm -D remove " + pkg)
  }
  commands.push("rm package-lock.json || del package-lock.json")
  for (let pkg in packages.dependencies) {
    commands.push("npm -S install " + pkg)
  }
  for (let pkg in packages.devDependencies) {
    commands.push("npm -D install " + pkg)
  }
  jake.exec(commands, { printStdout: true, printStderr: true }, function () {
    console.log("...dONE!")
    complete()
  })
})


/*** Helper functions ***/

function fileTypeList(suffixes, inverse) {
  let files = new jake.FileList()
  if (typeof suffixes === "string") {
    suffixes = [suffixes]
  }
  if (!staticFiles) {
    staticFiles = new jake.FileList()
    staticFiles.include(srcDir + "**/*")
    staticFiles.include(srcDir + "**/.*")
  }
  suffixes.forEach(function (suffix) {
    files.include(srcDir + "**/*" + suffix)
    files.include(srcDir + "**/.*" + suffix)
    if (suffix) {
      staticFiles.exclude(srcDir + "**/*" + suffix)
      staticFiles.exclude(srcDir + "**/.*" + suffix)
    }
  })
  return excludeIgnoredFiles(files.toArray(), inverse)
}

function excludeIgnoredFiles(files, inverse) {
  let included = [],
    excluded = []
  files.forEach(function (file) {
    if (file.indexOf("/_") === -1) {
      included.push(file)
    } else {
      excluded.push(file)
    }
  })
  if (inverse) {
    return excluded
  } else {
    return included
  }
}

function outputFile(file, suffix) {
  let basename = path.basename(file),
    dir = path.dirname(file) + path.sep
  dir = path.normalize(dir)
  dir = path.normalize(outDir) + dir.substr(path.normalize(srcDir).length)
  if (suffix) {
    if (basename.indexOf(".") !== -1) {
      basename = basename.substr(0, basename.lastIndexOf("."))
    }
    if (basename.indexOf(".") === -1) {
      basename += suffix
    }
  }
  return dir + basename
}

function startWatching(suffix, task) {
  let watchFiles = new jake.FileList(),
    watcher = new Watcher()
  watchFiles.include(srcDir + "**/*" + suffix)
  watcher.watch(task, watchFiles.toArray())
  watcher.on(task, function () {
    clearTimeout(watchThrottle[task])
    clearTimeout(watchThrottle["static:all"])
    watchThrottle[task] = setTimeout(function () {
      clearTimeout(watchThrottle["static:all"])
      jake.Task[task].execute()
    }, 100)
  })
  return watcher
}

function setActive(file, data) {
  if (!data.nav) return
  let thisFile = path.parse(file)
  data.nav.forEach(function (link) {
    if (!link.href) return
    let linkFile = path.parse(link.href)
    if (linkFile.name === thisFile.name) {
      link.active = true
      data.title = link.label
    } else if (linkFile.name === "." && thisFile.name === "index") {
      link.active = true
      data.title = link.label
    } else {
      link.active = false
    }
  })
}

function fileList(dir) {
  let files = fs.readdirSync(dir),
    out = { "*": [] }
  files.forEach(function (file) {
    let stat = fs.statSync(dir + file)
    if (stat.isDirectory()) {
      out[file] = fileList(dir + file + "/")
    } else {
      let dot = file.length,
        suf = ""
      while (dot != -1) {
        suf = file.substr(dot) + suf
        file = file.substr(0, dot)
        out["*" + suf] = out["*" + suf] || []
        out["*" + suf].push(file)
        dot = file.lastIndexOf(".")
      }
    }
  })
  return out
}

function formatTs() {
  let files = new jake.FileList()
  files.include(srcDir + "**/*.ts")
  files.include(srcDir + "**/*.js")
  files.forEach((inFile) => {
    let input = "" + fs.readFileSync(inFile)
    let output = input.trim() + "\n"
    output = output.replace(/\;\n/gi, "\n")
    output = output.replace(/\n([ \t]*)var /gi, "\n$1let ")
    output = output.replace(/\(var /gi, "(let ")
    if (output !== input) {
      fs.writeFileSync(inFile, output)
    }
  })
}
