#!/usr/bin/env node
const compile = require("./old_compiler"),
  program = require('commander')

program
  .arguments('<file>')
  .option('-b, --wasm <file>', 'Compile to wasm binary')
  .option('-t, --wast <file>', 'Compile to wast text file')
  .option('--debug <file>', '(dump some debugging stuff to file)')
  .action(function (file) {
    compile(file, program)
  })
  .parse(process.argv)
