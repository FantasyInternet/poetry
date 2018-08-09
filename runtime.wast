(import "env" "logNumber" (func $logNumber (param i32) ))

(memory $-memory 1)
  (export "memory" (memory $-memory))

(func $-number (param $num f32) (result i32)
  (i32.trunc_s/f32 (get_local $num))
)

(func $-add (param $a i32) (param $b i32) (result i32)
  (return (i32.add (get_local $a) (get_local $b)))
)

;; memory management

;; allocate memory
(func $-alloc (param $len i32) (result i32)
  (local $offset i32)
  (local $offset2 i32)
  (local $space i32)
  (local $space2 i32)

  (block(loop
    (br_if 1 (i32.gt_u (get_local $space) (i32.add (get_local $len) (i32.const 32))))
    (set_local $offset (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
    (set_local $space (i32.load (get_local $offset)))

    (if (i32.le_u (i32.sub (i32.mul (i32.const 65536) (current_memory)) (get_local $offset)) (i32.const 8))(then
      (drop (grow_memory (i32.const 1)))
      (set_local $offset2 (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
      (set_local $offset2 (i32.add (i32.mul (i32.div_u (get_local $offset2) (i32.const 8)) (i32.const 8)) (i32.const 8)))
      (i32.store (get_local $offset2) (i32.sub (i32.mul (i32.const 65536) (current_memory)) (i32.add (i32.const 8) (get_local $offset2))))
      (call $-dealloc (get_local $offset))
      (set_local $offset (i32.const 4))
      (set_local $space (i32.load (get_local $offset)))
    ))
    
    (set_local $offset (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
    (set_local $offset (i32.add (i32.mul (i32.div_u (get_local $offset) (i32.const 8)) (i32.const 8)) (i32.const 8)))
    (set_local $space (i32.load (get_local $offset)))
    (set_local $space (i32.mul (i32.div_u (get_local $space) (i32.const 8) ) (i32.const 8) ) )
    (br 0)
  ))
  (i32.store (get_local $offset) (i32.const 0))
  (set_local $offset2 (i32.add (get_local $offset) (i32.const 4)))
  (i32.store (get_local $offset2) (get_local $len))

  (set_local $offset2 (i32.add (i32.add (get_local $offset2) (get_local $len)) (i32.const 4)))
  (set_local $offset2 (i32.add (i32.mul (i32.div_u (get_local $offset2) (i32.const 8)) (i32.const 8)) (i32.const 8)))
  (set_local $space2 (i32.sub (get_local $space) (i32.sub (get_local $offset2) (get_local $offset))))
  (i32.store (get_local $offset2) (get_local $space2))
  (set_local $offset2 (i32.add (get_local $offset2) (get_local $space2)))
  (i32.store (get_local $offset2) (get_local $space2))

  (return (i32.add (i32.const 4) (get_local $offset)))
)

;; deallocate memory
(func $-dealloc (param $offset i32)
  (local $offset i32)
  (local $offset2 i32)
  (local $space i32)
  (local $space2 i32)

  (set_local $offset (i32.sub (get_local $offset) (i32.const 4)))
  (set_local $space (i32.load (get_local $offset)))
  (set_local $space (i32.mul (i32.div_u (get_local $space) (i32.const 8) ) (i32.const 8) ) )
  (set_local $offset (i32.sub (get_local $offset) (get_local $space)))

  (set_local $offset2 (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
  (set_local $space2 (i32.load (get_local $offset2)))  
  (set_local $offset2 (i32.add (i32.add (get_local $offset2) (get_local $space2)) (i32.const 4)))
  (set_local $offset2 (i32.add (i32.mul (i32.div_u (get_local $offset2) (i32.const 8)) (i32.const 8)) (i32.const 8)))
  (set_local $space2 (i32.load (get_local $offset2)))
  (set_local $space2 (i32.mul (i32.div_u (get_local $space2) (i32.const 8) ) (i32.const 8) ) )
  (set_local $offset2 (i32.add (get_local $offset2) (get_local $space2)))

  (set_local $space (i32.sub (get_local $offset2) (get_local $offset)))
  (i32.store (get_local $offset) (get_local $space))
  (i32.store (get_local $offset2) (get_local $space))
)

;; resize memory
(func $-memresize (param $offset i32) (param $len i32) (result i32)
  (local $newoffset i32)
  (set_local $newoffset (call $-alloc (get_local $len)))
  (call $-memcopy (i32.add (i32.const 4)(get_local $offset)) (i32.add (i32.const 4)(get_local $offset)) (get_local $len))
  (call $-dealloc (get_local $offset))
  (return (get_local $newoffset))
)

;; copy memory
(func $-memcopy (param $from i32) (param $to i32) (param $len i32)
  (block(loop
    (br_if 1 (i32.lt_s (get_local $len) (i32.const 0)))
    (i64.store (get_local $to) (i64.load (get_local $from)))
    (set_local $from  (i32.add (get_local $from)  (i32.const 8)))
    (set_local $to    (i32.add (get_local $to)    (i32.const 8)))
    (set_local $len   (i32.sub (get_local $len)   (i32.const 8)))
    (br 0)
  ))
)

(global $-mindex (mut i32) (i32.const 0))

;; length of memory allocation
(func $-len (param $id i32) (result i32)
)









(func $test
  (local $a i32)
  (local $b i32)
  (local $c i32)

  (i32.store (i32.const 16) (i32.sub (i32.mul (i32.const 65536) (current_memory)) (i32.const 24)))
  ;; (i32.store (i32.const 16) (i32.const 100))
  (set_local $a (call $-alloc (i32.const 17)))
  (call $logNumber (get_local $a))
  (set_local $b (call $-alloc (i32.const 55)))
  (call $logNumber (get_local $b))
  (set_local $c (call $-alloc (i32.const 22)))
  (call $logNumber (get_local $c))

  (call $-dealloc (get_local $b))
  (set_local $b (call $-alloc (i32.const 68024)))
  (call $logNumber (get_local $b))
  (set_local $b (call $-memresize (get_local $b) (i32.const 1025)))
  (call $logNumber (get_local $b))
)
(export "test" (func $test))
