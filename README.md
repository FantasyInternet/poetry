Poetry
======
A poetically dynamic and simple programming language that compiles to WebAssembly!

*This project is still in early development! Use at your own risk!*

Much features! Very hype!
-------------------------
 - Easy to learn and use
 - Minimalistic syntax
 - Customizable
 - Full control of wasm imports and exports

Example
-------

    @export_memory "memory"
    @import "env" "log" _log 2 0

    @func log message
      _log (address_of message) (size_of message)

    @export "init" init
      log "Hello Poetry! 😇"

Usage
-----
    $ npm i -g poetry-compiler
    $ poetry -b my_program.poem
