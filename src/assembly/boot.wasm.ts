import "allocator/buddy"

declare namespace env {
  function pushFromMemory(offset: i32, length: i32): void
  function setDisplayMode(mode: i32, width: i32, height: i32): void
  function logNumber(x: i32): void
  function print(): void
}

let myNum: i32 = 42
let myStr: string = "Hello world!"

export function init(): void {
  env.setDisplayMode(0, 80, 20)
  let str8 = utf16to8(myStr)
  //@ts-ignore
  env.pushFromMemory(<i32>str8 + 4, load<i32>(str8))
  env.print()
  env.logNumber(myNum)
}

function utf16to8(str: string): usize {
  let out = memory.allocate(str.length + 4)
  //@ts-ignore
  let p16 = <i32>str
  let p8 = <i32>out
  store<i32>(p8, load<i32>(p16))
  p8 += 4; p16 += 4
  for (let i = 0; i < str.length; i++) {
    store<i8>(p8, load<i16>(p16))
    p8 += 1; p16 += 2
  }
  return out
}
