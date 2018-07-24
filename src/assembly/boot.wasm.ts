declare namespace env {
  function logNumber(x: i32): void
}

export function init(): void {
  env.logNumber(1337)
}
