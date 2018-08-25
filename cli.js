#!/usr/bin/env node
const compile = require("./index"),
  program = require('commander')

program
  .arguments('<file>')
  .option('-b, --wasm <file>', 'Compile to wasm binary')
  .option('-t, --wast <file>', 'Compile to wast text file')
  .option('--debug', '(spit out some debugging stuff)')
  .action(function (file) {
    compile(file, program)
  })
  .parse(process.argv)
