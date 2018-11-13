;; memory management
(global $-totmem (mut i32) (i32.const 0))
(func $-initruntime
  (set_global $-totmem (i32.mul (i32.const 65536) (current_memory)))
  (i32.store (i32.const 0) (i32.sub (i32.mul (i32.const 65536) (current_memory)) (i32.const 8)))
  (set_global $-mindex (call $-alloc (i32.const 8)))
)

;; function wrapper
(global $-calls (mut i32) (i32.const 0))
(func $-funcstart
  (if (i32.eqz (get_global $-calls))(then
    (call $-traceGC)
  ))
  (set_global $-calls (i32.add (get_global $-calls) (i32.const 1)))
)
(func $-funcend
  (if (get_global $-calls) (then
    (set_global $-calls (i32.sub (get_global $-calls) (i32.const 1)))
  ))
)

;; allocate memory
(global $-last_alloc (mut i32) (i32.const 0))
(func $-alloc (param $len i32) (result i32)
  (local $offset i32)
  (local $offset2 i32)
  (local $space i32)
  (local $space2 i32)
  (local $totmem i32)
  (local $allowgrow i32)

  (if (get_global $-last_alloc)(then
    (set_local $offset (i32.sub (get_global $-last_alloc) (i32.const 8)))
    (set_local $offset (i32.sub (get_local $offset) (i32.load (get_local $offset))))
  )(else
    (set_local $allowgrow (i32.const 1))
  ))
  ;; how much space is here at the beginning?
  (set_local $space (i32.load (get_local $offset)))
  ;; round down to nearest multiple of 8
  (set_local $space (i32.and (get_local $space) (i32.const -8) ) )
  (block(loop
    ;; is there enough space here?
    (br_if 1 (i32.gt_u (get_local $space) (i32.add (get_local $len) (i32.const 32))))
    ;; skip the space
    (set_local $offset (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
    ;; how much data is here?
    (set_local $space (i32.load (get_local $offset)))

    ;; is this the end of memory?
    (if (i32.le_u (i32.sub (get_global $-totmem) (get_local $offset)) (i32.const 8))(then
      ;; are we allowed to grow memory?
      (if (get_local $allowgrow)(then
        (set_local $offset2 (i32.add (get_global $-totmem) (i32.const 8)))
        (drop (grow_memory (current_memory)))
        (set_global $-totmem (i32.mul (i32.const 65536) (current_memory)))
        (i32.store (get_local $offset2) (i32.sub (get_global $-totmem) (i32.add (i32.const 8) (get_local $offset2))))
        (call $-dealloc (i32.sub (get_local $offset2) (i32.const 8)))
        (set_local $space (i32.load (i32.const 0)))
        (set_local $offset (i32.add  (get_local $space) (i32.const 4)))
        (set_local $space (i32.load (get_local $offset)))
      )(else ;; first time? start from beginning
        (set_local $allowgrow (i32.const 1))
        (set_local $offset (i32.const 0))
        (set_local $space (i32.load (get_local $offset)))
        (set_local $space (i32.and (get_local $space) (i32.const -8) ) )
        (set_local $offset (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
        (set_local $space (i32.load (get_local $offset)))
      ))
    ))
    
    ;; skip the data
    (set_local $offset (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
    ;; align to next multiple of 8
    (set_local $offset (i32.add (i32.and (get_local $offset) (i32.const -8)) (i32.const 8)))
    ;; how much space is here?
    (set_local $space (i32.load (get_local $offset)))
    ;; round down to nearest multiple of 8
    (set_local $space (i32.and (get_local $space) (i32.const -8) ) )
    (br 0)
  ))
  ;; claim the space
  (i32.store (get_local $offset) (i32.const 0))
  (set_local $offset2 (i32.add (get_local $offset) (i32.const 4)))
  (i32.store (get_local $offset2) (get_local $len))

  ;; skip allocation
  (set_local $offset2 (i32.add (i32.add (get_local $offset2) (get_local $len)) (i32.const 4)))
  ;; round down to nearest multiple of 8
  (set_local $offset2 (i32.and (get_local $offset2) (i32.const -8)))
  ;; set terminator
  (i64.store (get_local $offset2) (i64.const 0))
  (set_local $offset2 (i32.add (get_local $offset2) (i32.const 8)))
  ;; how much less space is there now?
  (set_local $space2 (i32.sub (get_local $space) (i32.sub (get_local $offset2) (get_local $offset))))
  ;; mark the space at both ends
  (i32.store (get_local $offset2) (get_local $space2))
  (set_local $offset2 (i32.add (get_local $offset2) (get_local $space2)))
  (i32.store (get_local $offset2) (get_local $space2))

  ;; zerofill allocation
  (set_local $offset (i32.add (i32.const 8) (get_local $offset)))
  (call $-memzero (get_local $offset) (get_local $len))

  ;; return offset where the data is supposed to begin
  (set_global $-last_alloc (get_local $offset))
  (return (get_local $offset))
)

;; deallocate memory
(func $-dealloc (param $offset i32)
  (local $offset i32)
  (local $offset2 i32)
  (local $space i32)
  (local $space2 i32)

  (if (i32.eq (get_local $offset) (get_global $-last_alloc))(then
    (set_global $-last_alloc (i32.const 0))
  ))
  (set_local $offset (i32.sub (i32.and (get_local $offset) (i32.const -8)) (i32.const 8)))
  (set_local $space (i32.load (get_local $offset)))
  (set_local $space (i32.and (get_local $space) (i32.const -8) ) )
  (set_local $offset (i32.sub (get_local $offset) (get_local $space)))

  (set_local $offset2 (i32.add (i32.add (get_local $offset) (get_local $space)) (i32.const 4)))
  (set_local $space2 (i32.load (get_local $offset2)))  
  (set_local $offset2 (i32.add (i32.add (get_local $offset2) (get_local $space2)) (i32.const 4)))
  (set_local $offset2 (i32.add (i32.and (get_local $offset2) (i32.const -8)) (i32.const 8)))
  (set_local $space2 (i32.load (get_local $offset2)))
  (set_local $space2 (i32.and (get_local $space2) (i32.const -8) ) )
  (set_local $offset2 (i32.add (get_local $offset2) (get_local $space2)))

  (set_local $space (i32.sub (get_local $offset2) (get_local $offset)))
  (i32.store (get_local $offset) (get_local $space))
  (i32.store (get_local $offset2) (get_local $space))
)

;; zerofill memory
(func $-memzero (param $offset i32) (param $len i32)
  (block(loop (br_if 1 (i32.lt_u (get_local $len) (i32.const 8)))
    (i64.store (get_local $offset) (i64.const 0))
    (set_local $offset (i32.add (get_local $offset) (i32.const 8)))
    (set_local $len (i32.sub (get_local $len) (i32.const 8)))
  (br 0)))
  (block(loop (br_if 1 (i32.eqz (get_local $len)))
    (i32.store8 (get_local $offset) (i32.const 0))
    (set_local $offset (i32.add (get_local $offset) (i32.const 1)))
    (set_local $len (i32.sub (get_local $len) (i32.const 1)))
  (br 0)))
)

;; copy memory
(func $-memcopy (param $from i32) (param $to i32) (param $len i32)
  (local $delta i32)
  (if (i32.lt_u (get_local $from) (get_local $to))(then
    (set_local $delta (i32.const -8))
    (set_local $from  (i32.add (get_local $from)  (get_local $len)))
    (set_local $to    (i32.add (get_local $to)    (get_local $len)))
    (block(loop (br_if 1 (i32.lt_s (get_local $len) (i32.const 8)))
      (set_local $from  (i32.add (get_local $from)  (get_local $delta)))
      (set_local $to    (i32.add (get_local $to)    (get_local $delta)))
      (i64.store (get_local $to) (i64.load (get_local $from)))
      (set_local $len   (i32.sub (get_local $len)   (i32.const 8)))
    (br 0) ))
    (set_local $delta (i32.const -1))
    (block(loop (br_if 1 (i32.lt_s (get_local $len) (i32.const 1)))
      (set_local $from  (i32.add (get_local $from)  (get_local $delta)))
      (set_local $to    (i32.add (get_local $to)    (get_local $delta)))
      (i32.store8 (get_local $to) (i32.load8_u (get_local $from)))
      (set_local $len   (i32.sub (get_local $len)   (i32.const 1)))
    (br 0) ))
  )(else
    (set_local $delta (i32.const 8))
    (block(loop (br_if 1 (i32.lt_s (get_local $len) (i32.const 8)))
      (i64.store (get_local $to) (i64.load (get_local $from)))
      (set_local $from  (i32.add (get_local $from)  (get_local $delta)))
      (set_local $to    (i32.add (get_local $to)    (get_local $delta)))
      (set_local $len   (i32.sub (get_local $len)   (i32.const 8)))
    (br 0) ))
    (set_local $delta (i32.const 1))
    (block(loop (br_if 1 (i32.lt_s (get_local $len) (i32.const 1)))
      (i32.store8 (get_local $to) (i32.load8_u (get_local $from)))
      (set_local $from  (i32.add (get_local $from)  (get_local $delta)))
      (set_local $to    (i32.add (get_local $to)    (get_local $delta)))
      (set_local $len   (i32.sub (get_local $len)   (i32.const 1)))
    (br 0) ))
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
      (set_local $id (i32.sub (get_local $id) (i32.const 8)))
      (if (i32.gt_u (call $-len (i32.const -1)) (i32.mul (i32.const 8) (get_local $id)))(then
        (set_local $offset (i32.add (get_global $-mindex) (i32.mul (i32.const 8) (get_local $id))))
        (set_local $offset (i32.load (get_local $offset)))
      ))
    ))
  ))
  (set_local $offset (i32.and (get_local $offset) (i32.const -8)))
  (get_local $offset)
)

;; datatype of memory allocation
(func $-datatype (param $id i32) (result i32)
  (local $datatype i32)
  (if (i32.eq (get_local $id) (i32.const -1))(then
    (set_local $datatype (i32.const 7))
  )(else
    (if (i32.lt_u (get_local $id) (i32.const 8))(then
      (set_local $datatype (i32.and (get_local $id) (i32.const 3)))
    )(else
      (set_local $datatype (i32.sub (get_global $-mindex) (i32.const 64)))
      (set_local $datatype (i32.add (get_local $datatype) (i32.add (i32.mul (i32.const 8) (get_local $id)) (i32.const 6))))
      (set_local $datatype (i32.load8_u (get_local $datatype)))
    ))
  ))
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
(func $-resize (param $id i32) (param $newlen i32)
  (local $offset i32)
  (local $len i32)
  (local $spaceafter i32)
  (local $newoffset i32)
  (if (i32.eq (get_local $id) (i32.const -1))(then
    (set_local $len (i32.const 1))
    (block(loop (br_if 1 (i32.ge_u (get_local $len) (get_local $newlen)))
      (set_local $len (i32.mul (get_local $len) (i32.const 2)))
    (br 0)))
    (set_local $newlen (get_local $len))
  ))
  (set_local $offset (call $-offset (get_local $id)))
  (if (get_local $offset)(then ;; the value is in memory
    (set_local $len (i32.load (i32.sub (get_local $offset) (i32.const 4))))
    (if (i32.eq
      (i32.and (get_local $len) (i32.const -8))
      (i32.and (get_local $newlen) (i32.const -8))
    )(then ;; the old and new lengths are (almost) the same
      (i32.store (i32.sub (get_local $offset) (i32.const 4)) (get_local $newlen))
      (if (i32.gt_u (get_local $len) (get_local $newlen))(then ;; shrink
        (call $-memzero
          (i32.add (get_local $offset) (get_local $newlen))
          (i32.sub (get_local $len) (get_local $newlen))
        )
      )(else ;; grow
        (call $-memzero
          (i32.add (get_local $offset) (get_local $len))
          (i32.sub (get_local $newlen) (get_local $len))
        )
      ))
    )(else
      (set_local $spaceafter
        (i32.load
          (i32.add
            (get_local $offset)
            (i32.add (i32.and (get_local $len) (i32.const -8)) (i32.const 8))
          )
        )
      )
      (if (i32.or
        (i32.gt_u (get_local $len) (get_local $newlen))
        (i32.gt_u (get_local $spaceafter) (i32.sub (get_local $newlen) (get_local $len)))
      )(then ;; we can resize in-place
        (set_local $spaceafter (i32.add
          (get_local $spaceafter)
          (i32.sub
            (i32.and (get_local $len) (i32.const -8))
            (i32.and (get_local $newlen) (i32.const -8))
          )
        ))
        (i32.store (i32.sub (get_local $offset) (i32.const 4)) (get_local $newlen))
        (if (i32.gt_u (get_local $len) (get_local $newlen))(then ;; shrink
          (call $-memzero
            (i32.add (get_local $offset) (get_local $newlen))
            (i32.sub (get_local $len) (get_local $newlen))
          )
        )(else ;; grow
          (call $-memzero
            (i32.add (get_local $offset) (get_local $len))
            (i32.sub (get_local $newlen) (get_local $len))
          )
        ))
        (i32.store
          (i32.add
            (get_local $offset)
            (i32.add (i32.and (get_local $newlen) (i32.const -8)) (i32.const 8))
          )
          (get_local $spaceafter)
        )
        (i32.store
          (i32.add
            (i32.add
              (get_local $offset)
              (i32.add (i32.and (get_local $newlen) (i32.const -8)) (i32.const 8))
            )
            (get_local $spaceafter)
          )
          (get_local $spaceafter)
        )
      )(else ;; we need to re-allocate
        (set_local $newoffset (call $-alloc (i32.mul (get_local $newlen) (i32.const 2))))
        (call $-memcopy (get_local $offset) (get_local $newoffset) (get_local $len))
        (call $-dealloc (get_local $offset))
        (if (i32.eq (get_local $id) (i32.const -1))(then
          (set_global $-mindex (get_local $newoffset))
        )(else
          (call $-write32 (i32.const -1) (i32.mul (i32.sub (get_local $id) (i32.const 8)) (i32.const 8)) (get_local $newoffset))
        ))
        (drop (call $-new_value (i32.const 6) (i32.const 1)))
        (drop (call $-new_value (i32.const 6) (i32.const 1)))
        (call $-resize (get_local $id) (get_local $newlen))
      ))
    ))
  ))
)

;; set datatype of memory allocation
(func $-set_datatype (param $id i32) (param $datatype i32) (result i32)
  (local $offset i32)
  (if (i32.eq (get_local $id) (i32.const -1))(then
    (set_local $datatype (i32.const 7))
  )(else
    (if (i32.lt_u (get_local $id) (i32.const 8))(then
      (set_local $datatype (i32.and (get_local $id) (i32.const 3)))
    )(else
      (set_local $offset (i32.sub (get_global $-mindex) (i32.const 64)))
      (set_local $offset (i32.add (get_local $offset) (i32.add (i32.mul (i32.const 8) (get_local $id)) (i32.const 6))))
      (i32.store8 (get_local $offset) (get_local $datatype))
    ))
  ))
  (get_local $id)
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
(func $-write_to (param $id i32) (param $pos i32) (param $data_id i32)
  (local $offset i32)
  (local $len i32)
  (set_local $offset (call $-offset (get_local $id)))
  (set_local $len (call $-len (get_local $data_id)))
  (if (get_local $offset)(then
    (if (i32.gt_u (i32.add (get_local $pos) (get_local $len)) (call $-len (get_local $id)) )(then
      (call $-resize (get_local $id) (i32.add (get_local $pos) (get_local $len)))
      (set_local $offset (call $-offset (get_local $id)))
    ))
    (call $-memcopy (call $-offset (get_local $data_id)) (i32.add (get_local $offset) (get_local $pos)) (get_local $len))
  ))
)

;; make room for a new value
(global $-next_id (mut i32) (i32.const 0))
(func $-new_value (param $datatype i32) (param $len i32) (result i32)
  (local $offset i32)
  (local $id i32)
  (set_local $id (get_global $-next_id))
  (set_local $offset (call $-alloc (get_local $len)))
  (block(loop
    (br_if 1 (i32.eqz (call $-read32 (i32.const -1) (i32.mul (get_local $id) (i32.const 8)))))
    (set_local $id (i32.add (get_local $id) (i32.const 1)))
    (br 0)
  ))
  (call $-write32 (i32.const -1) (i32.mul (get_local $id) (i32.const 8)) (get_local $offset))
  (call $-write32 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 4)) (i32.const 0))
  (call $-write8  (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 6)) (get_local $datatype))
  (set_global $-next_id (i32.add (get_local $id) (i32.const 1)))
  (i32.add (get_local $id) (i32.const 8))
)

;; mark id as referenced
(func $-ref (param $id i32)
  (local $refs i32)
  (if (call $-offset (get_local $id))(then
    (set_local $id (i32.sub (get_local $id) (i32.const 8)))
    (call $-write8 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 7)) (i32.const 1))
  ))
)
(global $-hard_value (mut i32) (i32.const 0))
;; (global $-high_id (mut i32) (i32.const 0))
;; clear all references in index
(func $-zerorefs
  (local $id i32)
  (if (i32.eqz (get_global $-hard_value))(then
    (set_global $-hard_value (get_global $-next_id))
  ))
  (set_local $id (i32.div_u (call $-len (i32.const -1)) (i32.const 8)))
  ;; (set_global $-high_id (get_global $-hard_value))
  (block(loop (br_if 1 (i32.eqz (get_local $id)))
    (set_local $id (i32.sub (get_local $id) (i32.const 1)))
    (if (i32.lt_u (get_local $id) (get_global $-hard_value))(then
      (call $-write8 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 7)) (i32.const 1))
    )(else
      (call $-write8 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 7)) (i32.const 0))
    ))
  (br 0)))
)
;; register reference recursively (if unregistered)
(func $-reftree (param $id i32)
  (local $offset i32)
  (local $datatype i32)
  (local $refs i32)
  (set_local $offset (call $-offset (get_local $id)))
  ;; is it even in memory?
  (if (get_local $offset) (then
    (set_local $id (i32.sub (get_local $id) (i32.const 8)))
    (set_local $refs (call $-read8 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 7))))
    ;; is it unreferenced?
    (if (i32.eqz (get_local $refs))(then
      (call $-write8 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 7)) (i32.const 1))
      (set_local $datatype (call $-read8 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 6))))
      (set_local $id (i32.add (get_local $id) (i32.const 8)))
      ;; (if (i32.gt_u (get_local $id) (get_global $-high_id))(then
      ;;   (set_global $-high_id (get_local $id))
      ;; ))
      ;; is it array/object?
      (if (i32.eq (i32.and (get_local $datatype) (i32.const 6)) (i32.const 4))(then
        (set_local $offset (call $-len (get_local $id)))
        (block(loop (br_if 1 (i32.eqz (get_local $offset)))
          (set_local $offset (i32.sub (get_local $offset) (i32.const 4)))
          (call $-reftree (call $-read32 (get_local $id) (get_local $offset)))
        (br 0)))
      ))
    ))
  ))
)

;; garbage collector
(func $-garbagecollect
  (local $id i32)
  (local $refs i32)
  (local $offset i32)

  (set_local $id (i32.div_u (call $-len (i32.const -1)) (i32.const 8)))
  (block(loop (br_if 1 (i32.eqz (get_local $id)))
    (set_local $id (i32.sub (get_local $id) (i32.const 1)))
    (set_local $refs (call $-read8 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 7))))
    (if (i32.eqz (get_local $refs))(then
      (set_local $offset (call $-read32 (i32.const -1) (i32.mul (get_local $id) (i32.const 8))))
      (if (get_local $offset)(then
        (call $-dealloc (get_local $offset))
        (call $-write32 (i32.const -1)          (i32.mul (get_local $id) (i32.const 8))                (i32.const 0))
        (call $-write32 (i32.const -1) (i32.add (i32.mul (get_local $id) (i32.const 8)) (i32.const 4)) (i32.const 0))
      ))
    ))
  (br 0)))
  (set_global $-last_alloc (i32.const 0))
  (set_global $-next_id (i32.const 0))
  ;; (call $-resize (i32.const -1) (i32.mul (i32.add (get_global $-high_id) (i32.const 1)) (i32.const 8)))
)

(func $-truthy (param $id i32) (result i32)
  (local $datatype i32)
  (local $truthy i32)
  (if (i32.gt_u (get_local $id) (i32.const 4))(then
    (set_local $truthy (i32.const 1))
    (set_local $datatype (call $-datatype (get_local $id)))
    (if (i32.and
      (i32.eq (get_local $datatype) (i32.const 2))
      (f64.eq (call $-f64 (get_local $id)) (f64.const 0))
    )(then
      (set_local $truthy (i32.const 0))
    ))
    (if (i32.and
      (i32.eq (get_local $datatype) (i32.const 3))
      (i32.eq (call $-len (get_local $id)) (i32.const 0))
    )(then
      (set_local $truthy (i32.const 0))
    ))
  ))
  (get_local $truthy)
)
(func $-falsy (param $id i32) (result i32)
  (i32.eqz (call $-truthy (get_local $id)))
)
(func $-compare (param $id1 i32) (param $id2 i32) (result i32)
  (local $res f64)
  (local $len i32)
  (local $pos i32)
  ;; equal reference
  (if (i32.eq (get_local $id1) (get_local $id2))(then
    (return (i32.const 0))
  ))
  ;; equal datatype
  (if (i32.eq (call $-datatype (get_local $id1)) (call $-datatype (get_local $id2)))(then
    ;; array/object
    (if (i32.eq
      (i32.and (call $-datatype (get_local $id1)) (i32.const 6))
      (i32.const 4)
    )(then
      (return (i32.sub
        (get_local $id1)
        (get_local $id2)
      ))
    ))
    ;; numerical values
    (if (i32.lt_u (call $-datatype (get_local $id1)) (i32.const 3))(then
      (set_local $res (f64.sub
        (call $-f64 (call $-to_number (get_local $id1)))
        (call $-f64 (call $-to_number (get_local $id2)))
      ))
      (if (f64.eq (get_local $res) (f64.const 0))(then
        (return (i32.const 0))
      ))
      (if (f64.gt (get_local $res) (f64.const 0))(then
        (return (i32.const 1))
      ))
      (if (f64.lt (get_local $res) (f64.const 0))(then
        (return (i32.const -1))
      ))
    )(else ;; strings/binaries
      (set_local $pos (i32.const 0))
      (if (i32.lt_u
        (call $-len (get_local $id1))
        (call $-len (get_local $id2))
      )(then
        (set_local $len (call $-len (get_local $id1)))
      )(else
        (set_local $len (call $-len (get_local $id2)))
      ))
      (block(loop (br_if 1 (i32.eqz (get_local $len)))
        (if (i32.ne
          (call $-read8 (get_local $id1) (get_local $pos))
          (call $-read8 (get_local $id2) (get_local $pos))
        )(then
          (return (i32.sub
            (call $-read8 (get_local $id1) (get_local $pos))
            (call $-read8 (get_local $id2) (get_local $pos))
          ))
        ))
        (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
        (set_local $len (i32.sub (get_local $len) (i32.const 1)))
      (br 0)))
      (return (i32.sub
        (call $-len (get_local $id1))
        (call $-len (get_local $id2))
      ))
    ))
  )(else ;; unequal datatypes
    (return (i32.sub
      (call $-datatype (get_local $id1))
      (call $-datatype (get_local $id2))
    ))
  ))
  (return (i32.const 0))
)

(func $-equal (param $id1 i32) (param $id2 i32) (result i32)
  (if (call $-compare (get_local $id1) (get_local $id2)) (then
    (return (i32.const 1))
  ))
  (i32.const 5)
)
(func $-unequal (param $id1 i32) (param $id2 i32) (result i32)
  (i32.sub (i32.const 6) (call $-equal (get_local $id1) (get_local $id2)))
)
(func $-lt (param $id1 i32) (param $id2 i32) (result i32)
  (if (i32.lt_s (call $-compare (get_local $id1) (get_local $id2)) (i32.const 0))(then
    (return (i32.const 5))
  ))
  (i32.const 1)
)
(func $-le (param $id1 i32) (param $id2 i32) (result i32)
  (if (i32.le_s (call $-compare (get_local $id1) (get_local $id2)) (i32.const 0))(then
    (return (i32.const 5))
  ))
  (i32.const 1)
)
(func $-gt (param $id1 i32) (param $id2 i32) (result i32)
  (if (i32.gt_s (call $-compare (get_local $id1) (get_local $id2)) (i32.const 0))(then
    (return (i32.const 5))
  ))
  (i32.const 1)
)
(func $-ge (param $id1 i32) (param $id2 i32) (result i32)
  (if (i32.ge_s (call $-compare (get_local $id1) (get_local $id2)) (i32.const 0))(then
    (return (i32.const 5))
  ))
  (i32.const 1)
)
(func $-and (param $id1 i32) (param $id2 i32) (result i32)
  (local $success i32)
  (set_local $success (i32.const 1))
  (if (call $-truthy (get_local $id1))(then
    (set_local $success (get_local $id2))
  )(else
    (set_local $success (get_local $id1))
  ))
  (get_local $success)
)
(func $-or (param $id1 i32) (param $id2 i32) (result i32)
  (local $success i32)
  (set_local $success (i32.const 1))
  (if (call $-truthy (get_local $id1))(then
    (set_local $success (get_local $id1))
  )(else
    (set_local $success (get_local $id2))
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
  (set_local $id3 (call $-new_value (get_local $datatype) (i32.add (get_local $len1) (get_local $len2))))
  (call $-memcopy (call $-offset (get_local $id1)) (call $-offset (get_local $id3)) (get_local $len1))
  (call $-memcopy (call $-offset (get_local $id2)) (i32.add (call $-offset (get_local $id3)) (get_local $len1)) (get_local $len2))
  ;; (call $-resize (get_local $id3) (i32.add (get_local $len1) (get_local $len2)))
  (get_local $id3)
)

(func $-to_number (param $id i32) (result i32)
  (local $datatype i32)
  (local $id3 i32)
  (set_local $datatype (call $-datatype (get_local $id)))
  (set_local $id3 (i32.const 2))
  (if (i32.lt_u (get_local $id) (i32.const 2))(then
    (set_local $id3 (i32.const 2))
  ))
  (if (i32.eq (get_local $id) (i32.const 5))(then
    (set_local $id3 (call $-integer_u (i32.const 1)))
  ))
  (if (i32.eq (get_local $datatype) (i32.const 2))(then
    (set_local $id3 (get_local $id))
  ))
  (get_local $id3)
)

(func $-to_string (param $id i32) (result i32)
  (local $datatype i32)
  (local $id3 i32)
  (local $digit f64)
  (local $decimals i32)
  (local $pos i32)
  (set_local $datatype (call $-datatype (get_local $id)))
  (set_local $id3 (get_local $id))
  (if (i32.eq (get_local $id) (i32.const 0))(then
    (set_local $id3 (call $-new_value (i32.const 3) (i32.const 4)))
    (call $-write32 (get_local $id3) (i32.const 0) (i32.const 0x6c6c756e));;null
  ))
  (if (i32.eq (get_local $id) (i32.const 1))(then
    (set_local $id3 (call $-new_value (i32.const 3) (i32.const 5)))
    (call $-write32 (get_local $id3) (i32.const 0) (i32.const 0x736c6166));;fals
    (call $-write8 (get_local $id3) (i32.const 4) (i32.const 0x65));;e
  ))
  (if (i32.eq (get_local $id) (i32.const 5))(then
    (set_local $id3 (call $-new_value (i32.const 3) (i32.const 4)))
    (call $-write32 (get_local $id3) (i32.const 0) (i32.const 0x65757274));;true
  ))
  (if (i32.eq (get_local $datatype) (i32.const 2))(then
    (set_local $id3 (call $-new_value (i32.const 3) (i32.const 0)))
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
    (set_local $id3 (call $-new_value (i32.const 3) (i32.const 5)))
    (call $-write32 (get_local $id3) (i32.const 0) (i32.const 0x61727261));;arra
    (call $-write8 (get_local $id3) (i32.const 4) (i32.const 0x79));;y
  ))
  (if (i32.eq (get_local $datatype) (i32.const 5))(then
    (set_local $id3 (call $-new_value (i32.const 3) (i32.const 6)))
    (call $-write32 (get_local $id3) (i32.const 0) (i32.const 0x656a626f));;obje
    (call $-write16 (get_local $id3) (i32.const 4) (i32.const 0x7463));;ct
  ))
  (if (i32.eq (get_local $datatype) (i32.const 6))(then
    (set_local $id3 (call $-concat (i32.const 3) (get_local $id)))
  ))
  (get_local $id3)
)

(func $-to_hex (param $int i32) (param $digits i32) (result i32)
  (local $str i32)
  (local $dig i32)
  (set_local $str (call $-new_value (i32.const 3) (get_local $digits)))
  (block(loop (br_if 1 (i32.eqz (get_local $digits)))
    (set_local $digits (i32.sub (get_local $digits) (i32.const 1)))
    (set_local $dig (i32.and (get_local $int) (i32.const 0xf)))
    (set_local $int (i32.div_u (get_local $int) (i32.const 0x10)))
    (if (i32.lt_u (get_local $dig) (i32.const 0xa))(then
      (call $-write8 (get_local $str) (get_local $digits) (i32.add (i32.const 0x30) (get_local $dig)))
    )(else
      (call $-write8 (get_local $str) (get_local $digits) (i32.add (i32.const 0x57) (get_local $dig)))
    ))
  (br 0)))
  (get_local $str)
)
(func $-from_hex (param $str i32) (result i32)
  (local $int i32)
  (local $dig i32)
  (local $pos i32)
  (local $len i32)
  (set_local $len (call $-len (get_local $str)))
  (block(loop (br_if 1 (i32.ge_u (get_local $pos) (get_local $len)))
    (set_local $int (i32.mul (get_local $int) (i32.const 0x10)))
    (set_local $dig (call $-read8 (get_local $str) (get_local $pos)))
    (if (i32.gt_u (get_local $dig) (i32.const 0x5f))(then
      (set_local $dig (i32.sub (get_local $dig) (i32.const 0x20)))
    ))
    (if (i32.lt_u (get_local $dig) (i32.const 0x40))(then
      (set_local $int (i32.add (get_local $int) (i32.sub (get_local $dig) (i32.const 0x30))))
    )(else
      (set_local $int (i32.add (get_local $int) (i32.sub (get_local $dig) (i32.const 0x37))))
    ))
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
  (br 0)))
  (get_local $int)
)

(func $-inc (param $num i32) (param $delta f64) (result i32)
  (local $offset i32)
  (local $float f64)
  (set_local $offset (call $-offset (get_local $num)))
  (if (get_local $offset)(then
    (set_local $float (f64.load (get_local $offset)))
    (f64.store (get_local $offset) (f64.add (get_local $float) (get_local $delta)))
  )(else
    (set_local $num (call $-number (get_local $delta)))
  ))
  (get_local $num)
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
          (call $-f64 (call $-to_number(get_local $id1)) )
          (call $-f64 (call $-to_number(get_local $id2)) )
        )
      )
    )
  )(else
    ;; is one of them a string?
    (if (i32.or (i32.eq (get_local $datatype1) (i32.const 3)) (i32.eq (get_local $datatype2) (i32.const 3)))(then
      (set_local $id3 (call $-concat
        (call $-to_string (get_local $id1))
        (call $-to_string (get_local $id2))
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
          (call $-f64 (call $-to_number(get_local $id1)) )
          (call $-f64 (call $-to_number(get_local $id2)) )
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
          (call $-f64 (call $-to_number(get_local $id1)) )
          (call $-f64 (call $-to_number(get_local $id2)) )
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
          (call $-f64 (call $-to_number(get_local $id1)) )
          (call $-f64 (call $-to_number(get_local $id2)) )
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
    (set_local $f1 (call $-f64 (call $-to_number(get_local $id1)) ))
    (set_local $f2 (f64.abs (call $-f64 (call $-to_number(get_local $id2)) )))
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
(func $-i32_s (param $id i32) (result i32)
  (i32.trunc_s/f64 (call $-f64 (get_local $id)))
)
(func $-i32_u (param $id i32) (result i32)
  (i32.trunc_u/f64 (call $-f64 (get_local $id)))
)

(func $-number (param $val f64) (result i32)
  (local $id i32)
  (set_local $id (i32.const 2))
  (if (f64.ne (get_local $val) (f64.const 0))(then
    (set_local $id (call $-new_value (i32.const 2) (i32.const 0)))
    (f64.store (call $-offset (get_local $id)) (get_local $val))
  ))
  (get_local $id)
)
(func $-integer_s (param $val i32) (result i32)
  (call $-number (f64.convert_s/i32 (get_local $val)))
)
(func $-integer_u (param $val i32) (result i32)
  (call $-number (f64.convert_u/i32 (get_local $val)))
)

(func $-string (param $offset i32) (param $len i32) (result i32)
  (local $id i32)
  (set_local $id (call $-new_value (i32.const 3) (get_local $len)))
  (call $-memcopy (get_local $offset) (call $-offset (get_local $id)) (get_local $len))
  (call $-ref (get_local $id))
  (get_local $id)
)
(func $-char_size (param $byte i32) (result i32)
  (local $size i32)
  (if (i32.ge_u (get_local $byte) (i32.const 0x01))(then
    (set_local $size (i32.add (get_local $size) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xc0))(then
    (set_local $size (i32.add (get_local $size) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xe0))(then
    (set_local $size (i32.add (get_local $size) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xf0))(then
    (set_local $size (i32.add (get_local $size) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xf8))(then
    (set_local $size (i32.add (get_local $size) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xfc))(then
    (set_local $size (i32.add (get_local $size) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xfe))(then
    (set_local $size (i32.add (get_local $size) (i32.const 1)))
  ))
  (if (i32.ge_u (get_local $byte) (i32.const 0xff))(then
    (set_local $size (i32.add (get_local $size) (i32.const 1)))
  ))
  (get_local $size)
)
(func $-bytes_to_chars (param $start i32) (param $bytes i32) (result i32)
  (local $pos i32)
  (local $len i32)
  (local $charlen i32)
  (local $chars i32)
  (set_local $pos (get_local $start))
  (set_local $len (get_local $bytes))
  (block(loop (br_if 1 (i32.le_s (get_local $len) (i32.const 0)))
    (set_local $charlen (call $-char_size (i32.load8_u (get_local $pos))))
    (if (get_local $charlen)(then
      (set_local $len (i32.sub (get_local $len) (get_local $charlen)))
      (set_local $pos (i32.add (get_local $pos) (get_local $charlen)))
      (set_local $chars (i32.add (get_local $chars) (i32.const 1)))
    )(else
      (set_local $len (i32.const 0))
    ))
  (br 0) ))
  (get_local $chars)
)
(func $-chars_to_bytes (param $start i32) (param $chars i32) (result i32)
  (local $pos i32)
  (local $byte i32)
  (set_local $pos (get_local $start))
  (block(loop (br_if 1 (i32.le_s (get_local $chars) (i32.const 0)))
    (set_local $byte (i32.load8_u (get_local $pos)))
    (set_local $pos (i32.add (get_local $pos) (call $-char_size (get_local $byte))))
    (set_local $chars (i32.sub (get_local $chars) (i32.const 1)))
  (br 0) ))
  (i32.sub (get_local $pos) (get_local $start))
)
(func $-char (param $code i32) (result i32)
  (local $str i32)
  (local $pos i32)
  (local $max i32)
  (local $charlen i32)
  (if (i32.lt_u (get_local $code) (i32.const 0x80))(then
    (set_local $str (call $-new_value (i32.const 3) (i32.const 1)))
    (call $-write8 (get_local $str) (get_local $pos) (get_local $code))
  )(else
    (set_local $max (i32.const 1))
    (block(loop (br_if 1 (i32.gt_u (get_local $max) (get_local $code)))
      (set_local $charlen (i32.add (get_local $charlen) (i32.const 1)))
      (set_local $max     (i32.shl (get_local $max)     (i32.const 5)))
    (br 0)))
    (set_local $str (call $-new_value (i32.const 3) (get_local $charlen)))
    (block(loop (br_if 1 (i32.eqz (get_local $charlen)))
      (set_local $charlen (i32.sub (get_local $charlen) (i32.const 1)))
      (call $-write8 (get_local $str) (get_local $charlen) (i32.or
        (i32.const 128)
        (i32.and
          (get_local $code)
          (i32.const 0x3f)
        )
      ))
      (set_local $code (i32.shr_u (get_local $code) (i32.const 6)))
    (br 0)))
    (set_local $max (i32.const 0xffff00))
    (set_local $max (i32.shr_u (get_local $max) (call $-len (get_local $str))))
    (call $-write8 (get_local $str) (get_local $charlen) (i32.or
      (get_local $max)
      (call $-read8 (get_local $str) (get_local $charlen))
    ))
  ))
  (get_local $str)
)
(func $-char_code (param $offset i32) (result i32)
  (local $code i32)
  (local $charlen i32)
  (local $mask i32)
  (set_local $charlen (call $-char_size (i32.load8_u (get_local $offset))))
  (set_local $mask (i32.const 0xff))
  (set_local $mask (i32.shr_u (get_local $mask) (get_local $charlen)))
  (block(loop (br_if 1 (i32.eqz (get_local $charlen)))
    (set_local $code (i32.shl (get_local $code) (i32.const 6)))
    (set_local $code (i32.add
      (get_local $code)
      (i32.and
        (i32.load8_u (get_local $offset))
        (get_local $mask)
      )
    ))
    (set_local $mask (i32.const 0x3f))
    (set_local $offset     (i32.add (get_local $offset)     (i32.const 1)))
    (set_local $charlen (i32.sub (get_local $charlen) (i32.const 1)))
  (br 0)))
  (get_local $code)
)


(func $-get_from_obj (param $objId i32) (param $indexId i32) (result i32)
  (local $elem i32)
  (local $index i32)
  (if (i32.eq (call $-datatype (get_local $indexId)) (i32.const 2))(then
    (set_local $index (call $-i32_u (get_local $indexId)))
    (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
  )(else
    (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
    (block(loop
      (if (i32.eqz (get_local $elem))(then
        (set_local $elem (get_local $indexId))
      ))
      (br_if 1 (call $-truthy (call $-equal (get_local $elem) (get_local $indexId))))
      (set_local $index (i32.add (get_local $index) (i32.const 2)))
      (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
    (br 0)))
    (set_local $index (i32.add (get_local $index) (i32.const 1)))
    (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
  ))
  (get_local $elem)
)
(func $-set_to_obj (param $objId i32) (param $indexId i32) (param $valId i32)
  (local $elem i32)
  (local $index i32)
  (local $len i32)
  (if (i32.eq (call $-datatype (get_local $indexId)) (i32.const 2))(then
    (set_local $index (call $-i32_u (get_local $indexId)))
    (call $-write32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4)) (get_local $valId))
  )(else
    (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
    (block(loop 
      (if (i32.eqz (get_local $elem))(then
        (call $-write32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4)) (get_local $indexId))
        (set_local $elem (get_local $indexId))
      ))
      (br_if 1 (call $-truthy (call $-equal (get_local $elem) (get_local $indexId))))
      (set_local $index (i32.add (get_local $index) (i32.const 2)))
      (set_local $elem (call $-read32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4))))
    (br 0)))
    (set_local $index (i32.add (get_local $index) (i32.const 1)))
    (call $-write32 (get_local $objId) (i32.mul (get_local $index) (i32.const 4)) (get_local $valId))
    (if (i32.eqz (get_local $valId))(then
      (set_local $len (call $-len (get_local $objId)))
      (set_local $len (i32.sub (get_local $len) (i32.mul (get_local $index) (i32.const 4))))
      (call $-memcopy
        (i32.add (call $-offset (get_local $objId)) (i32.mul (i32.add (get_local $index) (i32.const 1)) (i32.const 4)))
        (i32.add (call $-offset (get_local $objId)) (i32.mul (i32.sub (get_local $index) (i32.const 1)) (i32.const 4)))
        (get_local $len)
      )
      (call $-resize (get_local $objId) (i32.sub (call $-len (get_local $objId)) (i32.const 8)))
    ))
  ))
)
