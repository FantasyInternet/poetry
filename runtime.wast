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
(func $-newValue (param $datatype i32) (param $len i32) (result i32)
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
(func $-falsy (param $id i32) (result i32)
  (i32.eqz (call $-truthy (get_local $id)))
)

(func $-equal (param $id1 i32) (param $id2 i32) (result i32)
  (local $success i32)
  (local $len i32)
  (if (i32.eq (get_local $id1) (get_local $id2))(then
    (set_local $success (i32.const 5))
  )(else
    (if (i32.ne (call $-datatype (get_local $id1)) (call $-datatype (get_local $id2)))(then
      (set_local $success (i32.const 1))
    )(else
      (if (i32.ne (call $-len (get_local $id1)) (call $-len (get_local $id2)))(then
        (set_local $success (i32.const 1))
      )(else
        (if (i32.ge_u (call $-datatype (get_local $id1)) (i32.const 4))(then
          (set_local $success (i32.const 1))
        )(else
          (set_local $len (call $-len (get_local $id1)))
          (set_local $success (i32.const 5))
          (block(loop
            (br_if 1 (i32.eqz (get_local $len)))
            (set_local $len (i32.sub (get_local $len) (i32.const 1)))
            (if (i32.ne (call $-read8 (get_local $id1) (get_local $len)) (call $-read8 (get_local $id2) (get_local $len)))(then
              (set_local $success (i32.const 1))
              (set_local $len (i32.const 0))
            ))
            (br 0)
          ))
        ))
      ))
    ))
  ))
  (get_local $success)
)
(func $-unequal (param $id1 i32) (param $id2 i32) (result i32)
  (i32.add (i32.mul (call $-falsy (call $-equal (get_local $id1) (get_local $id2))) (i32.const 4)) (i32.const 1))
)
(func $-lt (param $id1 i32) (param $id2 i32) (result i32)
  (local $success i32)
  (set_local $success (i32.const 1))
  (if (f64.lt (call $-f64 (get_local $id1)) (call $-f64 (get_local $id2)))(then
    (set_local $success (i32.const 5))
  ))
  (get_local $success)
)
(func $-le (param $id1 i32) (param $id2 i32) (result i32)
  (local $success i32)
  (set_local $success (i32.const 1))
  (if (f64.le (call $-f64 (get_local $id1)) (call $-f64 (get_local $id2)))(then
    (set_local $success (i32.const 5))
  ))
  (get_local $success)
)
(func $-gt (param $id1 i32) (param $id2 i32) (result i32)
  (local $success i32)
  (set_local $success (i32.const 1))
  (if (f64.gt (call $-f64 (get_local $id1)) (call $-f64 (get_local $id2)))(then
    (set_local $success (i32.const 5))
  ))
  (get_local $success)
)
(func $-ge (param $id1 i32) (param $id2 i32) (result i32)
  (local $success i32)
  (set_local $success (i32.const 1))
  (if (f64.ge (call $-f64 (get_local $id1)) (call $-f64 (get_local $id2)))(then
    (set_local $success (i32.const 5))
  ))
  (get_local $success)
)
(func $-and (param $id1 i32) (param $id2 i32) (result i32)
  (local $success i32)
  (set_local $success (i32.const 1))
  (if (i32.and (call $-truthy (get_local $id1)) (call $-truthy (get_local $id2)))(then
    (set_local $success (i32.const 5))
  ))
  (get_local $success)
)
(func $-or (param $id1 i32) (param $id2 i32) (result i32)
  (local $success i32)
  (set_local $success (i32.const 1))
  (if (i32.or (call $-truthy (get_local $id1)) (call $-truthy (get_local $id2)))(then
    (set_local $success (i32.const 5))
  ))
  (get_local $success)
)

(func $-concat (param $id1 i32) (param $id2 i32) (result i32)
  (local $len1 i32)
  (local $len2 i32)
  (local $datatype i32)
  (local $id3 i32)
  (local $offset i32)
  (set_local $len1 (call $-len (get_local $id1)))
  (set_local $len2 (call $-len (get_local $id2)))
  (set_local $datatype (call $-datatype (get_local $id1)))
  (set_local $id3 (call $-newValue (get_local $datatype) (i32.add (i32.add (get_local $len1) (get_local $len2)) (i32.const 8))))
  (call $-memcopy (call $-offset (get_local $id1)) (call $-offset (get_local $id3)) (get_local $len1))
  (call $-memcopy (call $-offset (get_local $id2)) (i32.add (call $-offset (get_local $id3)) (get_local $len1)) (get_local $len2))
  (call $-resize (get_local $id3) (i32.add (get_local $len1) (get_local $len2)))
  ;; if array or object, reference all members
  (if (i32.or (i32.eq (get_local $datatype) (i32.const 4)) (i32.eq (get_local $datatype) (i32.const 5)))(then
    (set_local $offset (i32.div_u (call $-len (get_local $id3)) (i32.const 4)))
    (block(loop
      (br_if 1 (i32.eqz (get_local $offset)))
      (set_local $offset (i32.sub (get_local $offset) (i32.const 1)))
      (call $-ref (call $-read32 (get_local $id3) (i32.mul (get_local $offset) (i32.const 8))))
      (br 0)
    ))
  ))
  (get_local $id3)
)

(func $-toNumber (param $id i32) (result i32)
  (local $datatype i32)
  (local $id3 i32)
  (set_local $datatype (call $-datatype (get_local $id)))
  (set_local $id3 (i32.const 2))
  (if (i32.eq (get_local $id) (i32.const 0))(then
    (set_local $id3 (i32.const 2))
  ))
  (if (i32.eq (get_local $id) (i32.const 1))(then
    (set_local $id3 (i32.const 2))
  ))
  (if (i32.eq (get_local $id) (i32.const 5))(then
    (set_local $id3 (call $-number (f64.const 1)))
  ))
  (if (i32.eq (get_local $datatype) (i32.const 2))(then
    (set_local $id3 (get_local $id))
  ))
  (get_local $id3)
)

(func $-toString (param $id i32) (result i32)
  (local $datatype i32)
  (local $id3 i32)
  (local $digit f64)
  (local $decimals i32)
  (local $pos i32)
  (set_local $datatype (call $-datatype (get_local $id)))
  (set_local $id3 (get_local $id))
  (if (i32.eq (get_local $id) (i32.const 0))(then
    (set_local $id3 (call $-newValue (i32.const 3) (i32.const 4)))
    (call $-write32 (get_local $id3) (i32.const 0) (i32.const 0x6c6c756e));;null
  ))
  (if (i32.eq (get_local $id) (i32.const 1))(then
    (set_local $id3 (call $-newValue (i32.const 3) (i32.const 5)))
    (call $-write32 (get_local $id3) (i32.const 0) (i32.const 0x736c6166));;fals
    (call $-write8 (get_local $id3) (i32.const 4) (i32.const 0x65));;e
  ))
  (if (i32.eq (get_local $id) (i32.const 5))(then
    (set_local $id3 (call $-newValue (i32.const 3) (i32.const 4)))
    (call $-write32 (get_local $id3) (i32.const 0) (i32.const 0x65757274));;true
  ))
  (if (i32.eq (get_local $datatype) (i32.const 2))(then
    (set_local $id3 (call $-newValue (i32.const 3) (i32.const 0)))
    ;; TODO: convert number to string
    (set_local $digit (call $-f64 (get_local $id)))
    (if (f64.lt (get_local $digit) (f64.const 0))(then
      (call $-write8 (get_local $id3) (get_local $pos) (i32.const 0x2d));; -
      (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
      (set_local $digit (f64.mul (get_local $digit) (f64.const -1)))
    ))
    (block(loop
      (br_if 1 (f64.lt (get_local $digit) (f64.const 10)))
      (set_local $digit (f64.div (get_local $digit) (f64.const 10)))
      (set_local $decimals (i32.sub (get_local $decimals) (i32.const 1)))
      (br 0)
    ))
    (block(loop
      (br_if 1 (i32.ge_s (get_local $decimals) (i32.const 10)))
      (call $-write8 (get_local $id3) (get_local $pos) (i32.add (i32.const 0x30) (i32.trunc_s/f64 (f64.trunc (get_local $digit)))))
      (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
      (if (i32.eq (get_local $decimals) (i32.const 0))(then
        (set_local $digit (f64.abs (call $-f64 (get_local $id))))
        (set_local $digit (f64.sub (get_local $digit) (f64.trunc (get_local $digit))))
        (if (f64.gt (get_local $digit) (f64.const 0.00001))(then
          (call $-write8 (get_local $id3) (get_local $pos) (i32.const 0x2e));; .
          (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
        )(else
          (set_local $decimals (i32.const 1024))
        ))
      ))
      (set_local $digit (f64.sub (get_local $digit) (f64.trunc (get_local $digit))))
      (set_local $digit (f64.mul (get_local $digit) (f64.const 10)))
      (if (i32.gt_s (get_local $decimals) (i32.const 0))(then
        (if (f64.le (get_local $digit) (f64.const 0.00001))(then
          (set_local $decimals (i32.const 1024))
        ))
      ))
      (set_local $decimals (i32.add (get_local $decimals) (i32.const 1)))
      (br 0)
    ))
  ))
  (if (i32.eq (get_local $datatype) (i32.const 4))(then
    (set_local $id3 (call $-newValue (i32.const 3) (i32.const 5)))
    (call $-write32 (get_local $id3) (i32.const 0) (i32.const 0x61727261));;arra
    (call $-write8 (get_local $id3) (i32.const 4) (i32.const 0x79));;y
  ))
  (if (i32.eq (get_local $datatype) (i32.const 5))(then
    (set_local $id3 (call $-newValue (i32.const 3) (i32.const 6)))
    (call $-write32 (get_local $id3) (i32.const 0) (i32.const 0x656a626f));;obje
    (call $-write16 (get_local $id3) (i32.const 4) (i32.const 0x7463));;ct
  ))
  (if (i32.eq (get_local $datatype) (i32.const 6))(then
    (set_local $id3 (call $-concat (i32.const 3) (get_local $id)))
  ))
  (get_local $id3)
)

(func $-add (param $id1 i32) (param $id2 i32) (result i32)
  (local $datatype1 i32)
  (local $datatype2 i32)
  (local $id3 i32)
  (set_local $datatype1 (call $-datatype (get_local $id1)))
  (set_local $datatype2 (call $-datatype (get_local $id2)))
  ;; numerical values
  (if (i32.and (i32.lt_u (get_local $datatype1) (i32.const 3)) (i32.lt_u (get_local $datatype2) (i32.const 3)))(then
    (set_local $id3
      (call $-number
        (f64.add
          (call $-f64 (call $-toNumber(get_local $id1)) )
          (call $-f64 (call $-toNumber(get_local $id2)) )
        )
      )
    )
  )(else
    ;; is one of them a string?
    (if (i32.or (i32.eq (get_local $datatype1) (i32.const 3)) (i32.eq (get_local $datatype2) (i32.const 3)))(then
      (set_local $id3 (call $-concat
        (call $-toString (get_local $id1))
        (call $-toString (get_local $id2))
      ))
    )(else
      ;; both the same datatype?
      (if (i32.eq (get_local $datatype1) (get_local $datatype2) )(then
        (set_local $id3 (call $-concat
          (get_local $id1)
          (get_local $id2)
        ))
      ))
    ))
  ))
  (get_local $id3)
)
(func $-sub (param $id1 i32) (param $id2 i32) (result i32)
  (local $datatype1 i32)
  (local $datatype2 i32)
  (local $id3 i32)
  (set_local $datatype1 (call $-datatype (get_local $id1)))
  (set_local $datatype2 (call $-datatype (get_local $id2)))
  ;; numerical values
  (if (i32.and (i32.lt_u (get_local $datatype1) (i32.const 3)) (i32.lt_u (get_local $datatype2) (i32.const 3)))(then
    (set_local $id3
      (call $-number
        (f64.sub
          (call $-f64 (call $-toNumber(get_local $id1)) )
          (call $-f64 (call $-toNumber(get_local $id2)) )
        )
      )
    )
  ))
  (get_local $id3)
)
(func $-mul (param $id1 i32) (param $id2 i32) (result i32)
  (local $datatype1 i32)
  (local $datatype2 i32)
  (local $id3 i32)
  (set_local $datatype1 (call $-datatype (get_local $id1)))
  (set_local $datatype2 (call $-datatype (get_local $id2)))
  ;; numerical values
  (if (i32.and (i32.lt_u (get_local $datatype1) (i32.const 3)) (i32.lt_u (get_local $datatype2) (i32.const 3)))(then
    (set_local $id3
      (call $-number
        (f64.mul
          (call $-f64 (call $-toNumber(get_local $id1)) )
          (call $-f64 (call $-toNumber(get_local $id2)) )
        )
      )
    )
  ))
  (get_local $id3)
)
(func $-div (param $id1 i32) (param $id2 i32) (result i32)
  (local $datatype1 i32)
  (local $datatype2 i32)
  (local $id3 i32)
  (set_local $datatype1 (call $-datatype (get_local $id1)))
  (set_local $datatype2 (call $-datatype (get_local $id2)))
  ;; numerical values
  (if (i32.and (i32.lt_u (get_local $datatype1) (i32.const 3)) (i32.lt_u (get_local $datatype2) (i32.const 3)))(then
    (set_local $id3
      (call $-number
        (f64.div
          (call $-f64 (call $-toNumber(get_local $id1)) )
          (call $-f64 (call $-toNumber(get_local $id2)) )
        )
      )
    )
  ))
  (get_local $id3)
)
(func $-mod (param $id1 i32) (param $id2 i32) (result i32)
  (local $datatype1 i32)
  (local $datatype2 i32)
  (local $f1 f64)
  (local $f2 f64)
  (local $f3 f64)
  (local $id3 i32)
  (set_local $datatype1 (call $-datatype (get_local $id1)))
  (set_local $datatype2 (call $-datatype (get_local $id2)))
  ;; numerical values
  (if (i32.and (i32.lt_u (get_local $datatype1) (i32.const 3)) (i32.lt_u (get_local $datatype2) (i32.const 3)))(then
    (set_local $f1 (call $-f64 (call $-toNumber(get_local $id1)) ))
    (set_local $f2 (f64.abs (call $-f64 (call $-toNumber(get_local $id2)) )))
    (set_local $f3 (f64.trunc (f64.div (get_local $f1) (get_local $f2))))
    (set_local $f1 (f64.sub (get_local $f1) (f64.mul (get_local $f2) (get_local $f3))))
    (set_local $id3 (call $-number (get_local $f1) ) )
  ))
  (get_local $id3)
)

(func $-f64 (param $id i32) (result f64)
  (local $val f64)
  (if (i32.gt_u (get_local $id) (i32.const 4))(then
    (set_local $val (f64.load (call $-offset (get_local $id))))
  ))
  (get_local $val)
)

(func $-number (param $val f64) (result i32)
  (local $id i32)
  (set_local $id (i32.const 2))
  (if (f64.ne (get_local $val) (f64.const 0))(then
    (set_local $id (call $-newValue (i32.const 2) (i32.const 1)))
    (f64.store (call $-offset (get_local $id)) (get_local $val))
  ))
  (get_local $id)
)

(func $-string (param $offset i32) (param $len i32)
  (local $id i32)
  (set_local $id (call $-newValue (i32.const 3) (get_local $len)))
  (call $-memcopy (get_local $offset) (call $-offset (get_local $id)) (get_local $len))
  (call $-ref (get_local $id))
)

(func $-getFromObj (param $objId i32) (param $indexId i32) (result i32)
  (local $elem i32)
  (local $index i32)
  (if (i32.eq (call $-datatype (get_local $indexId)) (i32.const 2))(then
    (set_local $index (i32.trunc_u/f64 (call $-f64 (get_local $indexId))))
    (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
  )(else
    (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
    (block(loop
      (br_if 1 (call $-truthy (call $-equal (get_local $elem) (get_local $indexId))))
      (set_local $index (i32.add (get_local $index) (i32.const 2)))
      (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
      (if (i32.eqz (get_local $elem))(then
        (set_local $elem (get_local $indexId))
      ))
      (br 0)
    ))
    (set_local $index (i32.add (get_local $index) (i32.const 1)))
    (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
  ))
  (get_local $elem)
)
(func $-setToObj (param $objId i32) (param $indexId i32) (param $valId i32)
  (local $elem i32)
  (local $index i32)
  (if (i32.eq (call $-datatype (get_local $indexId)) (i32.const 2))(then
    (set_local $index (i32.trunc_u/f64 (call $-f64 (get_local $indexId))))
    (call $-write32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4)) (get_local $valId))
  )(else
    (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
    (block(loop
      (br_if 1 (call $-truthy (call $-equal (get_local $elem) (get_local $indexId))))
      (set_local $index (i32.add (get_local $index) (i32.const 2)))
      (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
      (if (i32.eqz (get_local $elem))(then
        (call $-write32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4)) (get_local $indexId))
        (set_local $elem (get_local $indexId))
      ))
      (br 0)
    ))
    (set_local $index (i32.add (get_local $index) (i32.const 1)))
    (call $-write32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4)) (get_local $valId))
  ))
)





