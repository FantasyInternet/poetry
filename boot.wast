(module
      ;; imports
      

      ;; runtime
      (import "env" "logNumber" (func $--logNumber (param f32) ))
(import "env" "log" (func $--log (param $offset i32) (param $len i32) ))

(func $logNumber (param $id i32) (result i32)
  (call $--logNumber (call $-f32 (get_local $id)))
  (i32.const 0)
)
(func $log (param $id i32) (result i32)
  (call $--log (call $-offset (get_local $id)) (call $-len (get_local $id)))
  (i32.const 0)
)


(export "init" (func $init))

;; memory management
(func $-initruntime
  (i32.store (i32.const 0) (i32.sub (i32.mul (i32.const 65536) (current_memory)) (i32.const 8)))
  (set_global $-mindex (call $-alloc (i32.const 8)))
  ;; (i32.store (i32.const 16) (i32.const 100))
)

(global $-calls (mut i32) (i32.const 0))
;; function wrapper
(func $-funcstart
  (if (i32.eqz (get_global $-calls))(then
    (call $-garbagecollect)
  ))
  (set_global $-calls (i32.add (get_global $-calls) (i32.const 1)))
)
(func $-funcend
  (set_global $-calls (i32.sub (get_global $-calls) (i32.const 1)))
)

;; allocate memory
(func $-alloc (param $len i32) (result i32)
  (local $offset i32)
  (local $offset2 i32)
  (local $space i32)
  (local $space2 i32)

  ;; how much space is here at the beginning?
  (set_local $space (i32.load (get_local $offset)))
  ;; round down to nearest multiple of 8
  (set_local $space (i32.mul (i32.div_u (get_local $space) (i32.const 8) ) (i32.const 8) ) )
  (block(loop
    ;; is there enough space here?
    (br_if 1 (i32.gt_u (get_local $space) (i32.add (get_local $len) (i32.const 32))))
    ;; skip the space
    (set_local $offset (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
    ;; how much data is here?
    (set_local $space (i32.load (get_local $offset)))

    ;; is this the end of memory?
    (if (i32.le_u (i32.sub (i32.mul (i32.const 65536) (current_memory)) (get_local $offset)) (i32.const 8))(then
      (drop (grow_memory (i32.const 1)))
      (set_local $offset2 (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
      (set_local $offset2 (i32.add (i32.mul (i32.div_u (get_local $offset2) (i32.const 8)) (i32.const 8)) (i32.const 8)))
      (i32.store (get_local $offset2) (i32.sub (i32.mul (i32.const 65536) (current_memory)) (i32.add (i32.const 8) (get_local $offset2))))
      (call $-dealloc (get_local $offset))
      (set_local $offset (i32.const 4))
      (set_local $space (i32.load (get_local $offset)))
    ))
    
    ;; skip the data
    (set_local $offset (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
    ;; align to next multiple of 8
    (set_local $offset (i32.add (i32.mul (i32.div_u (get_local $offset) (i32.const 8)) (i32.const 8)) (i32.const 8)))
    ;; how much space is here?
    (set_local $space (i32.load (get_local $offset)))
    ;; round down to nearest multiple of 8
    (set_local $space (i32.mul (i32.div_u (get_local $space) (i32.const 8) ) (i32.const 8) ) )
    (br 0)
  ))
  ;; claim the space
  (i32.store (get_local $offset) (i32.const 0))
  (set_local $offset2 (i32.add (get_local $offset) (i32.const 4)))
  (i32.store (get_local $offset2) (get_local $len))

  ;; skip allocation
  (set_local $offset2 (i32.add (i32.add (get_local $offset2) (get_local $len)) (i32.const 4)))
  ;; round down to nearest multiple of 8
  (set_local $offset2 (i32.mul (i32.div_u (get_local $offset2) (i32.const 8)) (i32.const 8)))
  ;; set terminator
  (i64.store (get_local $offset2) (i64.const 0))
  (set_local $offset2 (i32.add (get_local $offset2) (i32.const 8)))
  ;; how much less space is there now?
  (set_local $space2 (i32.sub (get_local $space) (i32.sub (get_local $offset2) (get_local $offset))))
  ;; mark the space at both ends
  (i32.store (get_local $offset2) (get_local $space2))
  (set_local $offset2 (i32.add (get_local $offset2) (get_local $space2)))
  (i32.store (get_local $offset2) (get_local $space2))

  ;; return offset where the data is supposed to begin
  (return (i32.add (i32.const 8) (get_local $offset)))
)

;; deallocate memory
(func $-dealloc (param $offset i32)
  (local $offset i32)
  (local $offset2 i32)
  (local $space i32)
  (local $space2 i32)

  (set_local $offset (i32.sub (i32.mul (i32.div_u (get_local $offset) (i32.const 8)) (i32.const 8)) (i32.const 8)))
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

;; memory index
(global $-mindex (mut i32) (i32.const 0))

;; offset of memory allocation
(func $-offset (param $id i32) (result i32)
  (local $offset i32)
  (if (i32.eq (get_local $id) (i32.const -1))(then
    (set_local $offset (get_global $-mindex))
  )(else
    (if (i32.lt_u (get_local $id) (i32.const 8))(then
      (set_local $offset (i32.const 0))
    )(else
      (set_local $offset (i32.sub (get_global $-mindex) (i32.const 64)))
      (set_local $offset (i32.add (get_local $offset) (i32.mul (i32.const 8) (get_local $id))))
      (set_local $offset (i32.load (get_local $offset)))
    ))
  ))
  (set_local $offset (i32.mul (i32.div_u (get_local $offset) (i32.const 8)) (i32.const 8)))
  (get_local $offset)
)

;; type of memory allocation
(func $-datatype (param $id i32) (result i32)
  (local $datatype i32)
  (if (i32.eq (get_local $id) (i32.const -1))(then
    (set_local $datatype (i32.const 7))
  )(else
    (if (i32.lt_u (get_local $id) (i32.const 8))(then
      (set_local $datatype (i32.and (get_local $id) (i32.const 3)))
    )(else
      (set_local $datatype (i32.sub (get_global $-mindex) (i32.const 64)))
      (set_local $datatype (i32.add (get_local $datatype) (i32.mul (i32.const 8) (get_local $id))))
      (set_local $datatype (i32.load (get_local $datatype)))
    ))
  ))
  (set_local $datatype (i32.and (get_local $datatype) (i32.const 7)))
  (get_local $datatype)
)

;; length of memory allocation
(func $-len (param $id i32) (result i32)
  (local $offset i32)
  (local $len i32)
  (set_local $offset (call $-offset (get_local $id)))
  (if (get_local $offset)(then
    (set_local $len (i32.load (i32.sub (get_local $offset) (i32.const 4))))
  ))
  (get_local $len)
)

;; resize memory allocation
(func $-resize (param $id i32) (param $len i32)
  (local $offset i32)
  (local $datatype i32)
  (local $newoffset i32)
  (set_local $offset (call $-offset (get_local $id)))
  (set_local $datatype (call $-datatype (get_local $id)))
  (if (get_local $offset)(then
    (set_local $newoffset (call $-alloc (get_local $len)))
    (call $-memcopy (get_local $offset) (get_local $newoffset) (get_local $len))
    (call $-dealloc (get_local $offset))
    (if (i32.eq (get_local $id) (i32.const -1))(then
      (set_global $-mindex (get_local $newoffset))
    )(else
      (call $-write32 (i32.const -1) (i32.mul (i32.sub (get_local $id) (i32.const 8)) (i32.const 8)) (i32.add (get_local $newoffset) (get_local $datatype)))
    ))
  ))
)


;; read from memory allocation
(func $-read8 (param $id i32) (param $pos i32) (result i32)
  (local $offset i32)
  (local $data i32)
  (set_local $offset (call $-offset (get_local $id)))
  (if (i32.lt_u (get_local $pos) (call $-len (get_local $id)))(then
    (set_local $data (i32.load8_u (i32.add (get_local $offset) (get_local $pos))))
  ))
  (get_local $data)
)
(func $-read16 (param $id i32) (param $pos i32) (result i32)
  (local $offset i32)
  (local $data i32)
  (set_local $offset (call $-offset (get_local $id)))
  (if (i32.lt_u (i32.add (get_local $pos) (i32.const 1)) (call $-len (get_local $id)))(then
    (set_local $data (i32.load16_u (i32.add (get_local $offset) (get_local $pos))))
  ))
  (get_local $data)
)
(func $-read32 (param $id i32) (param $pos i32) (result i32)
  (local $offset i32)
  (local $data i32)
  (set_local $offset (call $-offset (get_local $id)))
  (if (i32.lt_u (i32.add (get_local $pos) (i32.const 3)) (call $-len (get_local $id)))(then
    (set_local $data (i32.load (i32.add (get_local $offset) (get_local $pos))))
  ))
  (get_local $data)
)
;; write to memory allocation
(func $-write8 (param $id i32) (param $pos i32) (param $data i32)
  (local $offset i32)
  (set_local $offset (call $-offset (get_local $id)))
  (if (get_local $offset)(then
    (if (i32.ge_u (get_local $pos) (call $-len (get_local $id)))(then
      (call $-resize (get_local $id) (i32.add (get_local $pos) (i32.const 1)))
      (set_local $offset (call $-offset (get_local $id)))
    ))
    (i32.store8 (i32.add (get_local $offset) (get_local $pos)) (get_local $data))
  ))
)
(func $-write16 (param $id i32) (param $pos i32) (param $data i32)
  (local $offset i32)
  (set_local $offset (call $-offset (get_local $id)))
  (if (get_local $offset)(then
    (if (i32.ge_u (i32.add (get_local $pos) (i32.const 1)) (call $-len (get_local $id)) )(then
      (call $-resize (get_local $id) (i32.add (get_local $pos) (i32.const 2)))
      (set_local $offset (call $-offset (get_local $id)))
    ))
    (i32.store16 (i32.add (get_local $offset) (get_local $pos)) (get_local $data))
  ))
)
(func $-write32 (param $id i32) (param $pos i32) (param $data i32)
  (local $offset i32)
  (set_local $offset (call $-offset (get_local $id)))
  (if (get_local $offset)(then
    (if (i32.ge_u (i32.add (get_local $pos) (i32.const 3)) (call $-len (get_local $id)) )(then
      (call $-resize (get_local $id) (i32.add (get_local $pos) (i32.const 4)))
      (set_local $offset (call $-offset (get_local $id)))
    ))
    (i32.store (i32.add (get_local $offset) (get_local $pos)) (get_local $data))
  ))
)

;; make room for a new value
(func $-newvalue (param $datatype i32) (param $len i32) (result i32)
  (local $offset i32)
  (local $id i32)
  (set_local $offset (call $-alloc (get_local $len)))
  (block(loop
    (br_if 1 (i32.eqz (call $-read32 (i32.const -1) (i32.mul (get_local $id) (i32.const 8)))))
    (set_local $id (i32.add (get_local $id) (i32.const 1)))
    (br 0)
  ))
  (call $-write32 (i32.const -1) (i32.mul (get_local $id) (i32.const 8)) (i32.add (get_local $offset) (get_local $datatype)))
  (i32.add (get_local $id) (i32.const 8))
)

;; register reference
(func $-ref (param $id i32)
  (local $refs i32)
  (if (call $-offset (get_local $id))(then
    (set_local $id (i32.sub (get_local $id) (i32.const 8)))
    (set_local $refs (call $-read32 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 4))))
    (call $-write32 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 4)) (i32.add (get_local $refs) (i32.const 1)))
  ))
)
;; deregister reference
(func $-deref (param $id i32)
  (local $refs i32)
  (local $datatype i32)
  (local $offset i32)
  (if (call $-offset (get_local $id))(then
    (set_local $datatype (call $-datatype (get_local $id)))
    (set_local $id (i32.sub (get_local $id) (i32.const 8)))
    (set_local $refs (call $-read32 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 4))))
    (if (get_local $refs)(then
      (call $-write32 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 4)) (i32.sub (get_local $refs) (i32.const 1)))
      (if (i32.eq (get_local $refs) (i32.const 1))(then
        ;; if array or object, dereference recursively
        (if (i32.or (i32.eq (get_local $datatype) (i32.const 4)) (i32.eq (get_local $datatype) (i32.const 5)))(then
          (set_local $offset (i32.div_u (call $-len (get_local $id)) (i32.const 4)))
          (block(loop
            (br_if 1 (i32.eqz (get_local $offset)))
            (set_local $offset (i32.sub (get_local $offset) (i32.const 1)))
            (call $-deref (call $-read32 (get_local $id) (i32.mul (get_local $offset) (i32.const 8))))
            (br 0)
          ))
        ))
      ))
    ))
  ))
)
;; replace reference
(func $-reref (param $oldid i32) (param $newid i32) (result i32)
  (call $-ref (get_local $newid))
  (call $-deref (get_local $oldid))
  (get_local $newid)
)

;; garbage collector
(func $-garbagecollect
  (local $id i32)
  (local $refs i32)
  (local $offset i32)

  (set_local $id (i32.div_u (call $-len (i32.const -1)) (i32.const 8)))
  (block(loop
    (br_if 1 (i32.eqz (get_local $id)))
    (set_local $id (i32.sub (get_local $id) (i32.const 1)))
    (set_local $refs (call $-read32 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 4))))
    (if (i32.eqz (get_local $refs))(then
      (set_local $offset (call $-read32 (i32.const -1) (i32.mul (get_local $id) (i32.const 8))))
      (if (get_local $offset)(then
        (call $-dealloc (get_local $offset))
        (call $-write32 (i32.const -1) (i32.mul (get_local $id) (i32.const 8)) (i32.const 0))
      ))
    ))
    (br 0)
  ))
)

(func $-truthy (param $id i32) (result i32)
  (local $truthy i32)
  (if (i32.gt_u (get_local $id) (i32.const 4))(then
    (set_local $truthy (i32.const 1))
  ))
  (get_local $truthy)
)

(func $-add (param $id1 i32) (param $id2 i32) (result i32)
  (call $-number (f32.add (call $-f32 (get_local $id1)) (call $-f32 (get_local $id2))))
)

(func $-f32 (param $id i32) (result f32)
  (local $val f32)
  (if (i32.gt_u (get_local $id) (i32.const 4))(then
    (set_local $val (f32.load (call $-offset (get_local $id))))
  ))
  (get_local $val)
)

(func $-number (param $val f32) (result i32)
  (local $id i32)
  (set_local $id (i32.const 2))
  (if (f32.ne (get_local $val) (f32.const 0))(then
    (set_local $id (call $-newvalue (i32.const 2) (i32.const 1)))
    (f32.store (call $-offset (get_local $id)) (get_local $val))
  ))
  (get_local $id)
)

(func $-string (param $offset i32) (param $len i32)
  (local $id i32)
  (set_local $id (call $-newvalue (i32.const 3) (get_local $len)))
  (call $-memcopy (get_local $offset) (call $-offset (get_local $id)) (get_local $len))
  (call $-ref (get_local $id))
)









      ;; memory
      (memory $-memory 2)  (export "memory" (memory $-memory))
(data (i32.const 65536) "Hello world! :)")


      ;; globals
      (global $meaning_of_life (mut i32) (i32.const 0))
(global $meaning_of_life2 (mut i32) (i32.const 0))
(global $name (mut i32) (i32.const 0))


      ;; functions
      (func $sum (param $a i32) (param $b i32) (result i32)
(local $-ret i32)(call $-funcstart)(block
(return (tee_local $-ret (call $-add (call $-add (get_local $a) (get_local $b)) (get_global $meaning_of_life))))

)
(call $-funcend)(get_local $-ret))

(func $init (result i32)
(local $-ret i32)(call $-funcstart)(block
(drop (call $logNumber (call $sum (call $-number (f32.const 2)) (get_global $meaning_of_life2) ) ))

(drop (call $log (get_global $name) ))

)
(call $-funcend)(get_local $-ret))



      ;; start
      (func $-start
      (call $-initruntime)
(call $-string (i32.const 65536) (i32.const 15))
(set_global $meaning_of_life (call $-reref (get_global $meaning_of_life) (call $-number (f32.const 42))))
(set_global $meaning_of_life2 (call $-reref (get_global $meaning_of_life2) (call $-number (f32.const 43))))
(set_global $name (call $-reref (get_global $name) (i32.const 8)))
)
      (start $-start)
      
      ;; exports
      
    )