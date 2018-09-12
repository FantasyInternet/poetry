<img src="./images/Poetree_256.png" align="right"/>
Poetry
======
A poetically dynamic and simple programming language that compiles to WebAssembly!

Much features! Very hype!
------------------------
 - Easy to learn and use
 - Minimalistic syntax
 - Customizable
 - Full control of wasm imports and exports
 - Bundle multiple source files (including `.wa(s)t`-files!)

Usage
-----
    $ npm i -g poetry-compiler
    $ poetry my_program.poem -b my_program.wasm

Example
-------
    export_memory "memory"
    import "env" "log" _log 2 0

    func log message
      _log (address_of message) (size_of message)

    export "init" init
      log "Hello Poetry! 🌳"

Check the [wiki for documentation](https://github.com/FantasyInternet/poetry/wiki)!
