(import "env" "logNumber" (func $logNumber (param i32) ))

(memory $-memory 1)
  (export "memory" (memory $-memory))

(func $-number (param $num f32) (result i32)
  (i32.trunc_s/f32 (get_local $num))
)

(func $-add (param $a i32) (param $b i32) (result i32)
  (return (i32.add (get_local $a) (get_local $b)))
)

(func $-alloc (param $len i32) (result i32)
  (local $offset i32)
  (local $space i32)
  (set_local $offset (i32.const 0))
  (set_local $space  (i32.const 0))

  (block(loop
    (br_if 1 (i32.gt_u (get_local $space) (get_local $len)))
    (set_local $offset (i32.add (get_local $offset) (get_local $space)))
    (set_local $offset (i32.add (i32.mul (i32.div_u (get_local $offset) (i32.const 8)) (i32.const 8)) (i32.const 4)))
    (set_local $space (i32.load (get_local $offset)))
    
    (set_local $offset (i32.add (get_local $offset) (get_local $space)))
    (set_local $offset (i32.add (i32.mul (i32.div_u (get_local $offset) (i32.const 8)) (i32.const 8)) (i32.const 8)))
    (set_local $space (i32.load (get_local $offset)))
    (br 0)
  ))

  (return (get_local $offset))
)
