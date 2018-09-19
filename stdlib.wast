;; general value functions
(func $address_of (param $value i32) (result i32)
  (call $-integer_u (call $-offset (get_local $value)))
)
(func $size_of (param $value i32) (result i32)
  (call $-integer_u (call $-len (get_local $value)))
)
(func $datatype_of (param $value i32) (result i32)
  (call $-integer_u (call $-datatype (get_local $value)))
)

;; binary functions
(func $binary_string (param $len i32) (result i32)
  (call $-new_value (i32.const 6) (call $-i32_u (get_local $len)))
)
(func $binary_slice (param $binary i32) (param $start i32) (param $len i32) (result i32)
  (local $out i32)
  (set_local $start (call $-i32_u (get_local $start)))
  (set_local $len (call $-i32_u (get_local $len)) )
  (if (i32.lt_u (call $-len (get_local $binary)) (get_local $start))(then
    (set_local $start (call $-len (get_local $binary)))
  ))
  (if (i32.lt_u (i32.sub (call $-len (get_local $binary)) (get_local $start)) (get_local $len))(then
    (set_local $len (i32.sub (call $-len (get_local $binary)) (get_local $start)))
  ))
  (set_local $out (call $-new_value (i32.const 6) (get_local $len)))
  (call $-memcopy
    (i32.add (call $-offset (get_local $binary)) (get_local $start))
    (call $-offset (get_local $out))
    (get_local $len)
  )
  (get_local $out)
)
(func $binary_search (param $binary i32) (param $subbin i32) (param $start i32) (result i32)
  (local $sub i32)
  (if (i32.lt_u (call $-len (get_local $binary)) (call $-len (get_local $subbin))) (then
    (return (i32.const 0))
  ))
  (set_local $start (call $-i32_u (get_local $start)))
  (set_local $sub (call $-new_value (i32.const 3) (call $-len (get_local $subbin))))
  (block(loop
    (br_if 1 (i32.ge_u (get_local $start) (i32.sub (call $-len (get_local $binary)) (call $-len (get_local $subbin)))))
    (call $-memcopy
      (i32.add (call $-offset (get_local $binary)) (get_local $start))
      (call $-offset (get_local $sub))
      (call $-len (get_local $sub))
    )
    (if (call $-equal (get_local $sub) (get_local $subbin)) (then
      (return (call $-integer_u (get_local $start)))
    ))
    (set_local $start (i32.add (get_local $start) (i32.const 1)))
    (br 0)
  ))
  (i32.const 0)
)
(func $binary_read (param $binary i32) (param $pos i32) (result i32)
  (if (i32.ge_u (call $-i32_u (get_local $pos)) (call $-len (get_local $binary)))(then
    (return (i32.const 0))
  ))
  (call $-integer_u (call $-read8 (get_local $binary) (call $-i32_u (get_local $pos))))
)
(func $binary_write (param $binary i32) (param $pos i32) (param $data i32) (result i32)
  (local $subbin i32)
  (local $len i32)
  (set_local $pos (call $-i32_u (get_local $pos)))
  (if (i32.lt_u (call $-datatype (get_local $data)) (i32.const 3))(then
    (set_local $subbin (call $-new_value (i32.const 6) (i32.const 4)))
    (call $-write32 (get_local $subbin) (i32.const 0) (call $-i32_u (get_local $data)))
    (if (i32.eqz (call $-read8 (get_local $subbin) (i32.const 3)))(then
      (if (i32.eqz (call $-read8 (get_local $subbin) (i32.const 2)))(then
        (if (i32.eqz (call $-read8 (get_local $subbin) (i32.const 1)))(then
          (call $-resize (get_local $subbin) (i32.const 1))
        )(else
          (call $-resize (get_local $subbin) (i32.const 2))
        ))
      )(else
        (call $-resize (get_local $subbin) (i32.const 3))
      ))
    ))
    (set_local $data (get_local $subbin))
  ))
  (set_local $len (i32.add (get_local $pos) (call $-len (get_local $data))))
  (if (i32.lt_u (call $-len (get_local $binary)) (get_local $len) )(then
    (call $-resize (get_local $binary) (get_local $len))
  ))
  (call $-memcopy
    (call $-offset (get_local $data))
    (i32.add (call $-offset (get_local $binary)) (get_local $pos))
    (call $-len (get_local $data))
  )
  (i32.const 0)
)


;; string functions
(func $string_length (param $str i32) (result i32)
  (call $-integer_u (call $-count_chars (get_local $str)))
)
(func $string_slice (param $string i32) (param $start i32) (param $len i32) (result i32)
  (set_local $start (call $-chars_to_bytes
    (call $-offset (get_local $string))
    (call $-i32_u (get_local $start))
  ))
  (set_local $len (call $-chars_to_bytes
    (i32.add (call $-offset (get_local $string)) (get_local $start))
    (call $-i32_u (get_local $len))
  ))
  (call $-set_datatype (call $binary_slice
    (get_local $string)
    (call $-integer_u (get_local $start))
    (call $-integer_u (get_local $len))
  ) (i32.const 3))
)
(func $string_search (param $string i32) (param $substr i32) (param $start i32) (result i32)
  (set_local $start (call $-chars_to_bytes
    (call $-offset (get_local $string))
    (call $-i32_u (get_local $start))
  ))
  (call $binary_search
    (get_local $string)
    (get_local $substr)
    (call $-integer_u (get_local $start))
  )
)
(func $string_lower (param $string i32) (result i32)
  (local $out i32)
  (local $len i32)
  (local $byte i32)
  (set_local $len (call $-len (get_local $string)))
  (set_local $out (call $-new_value (i32.const 3) (get_local $len)))
  (block(loop (br_if 1 (i32.eqz (get_local $len)))
    (set_local $len (i32.sub (get_local $len) (i32.const 1)))
    (set_local $byte (call $-read8 (get_local $string) (get_local $len)))
    (if (i32.and
      (i32.gt_u
        (get_local $byte)
        (i32.const 0x40)
      )
      (i32.lt_u
        (get_local $byte)
        (i32.const 0x5B)
      )
    )(then
      (call $-write8
        (get_local $out)
        (get_local $len)
        (i32.add
          (get_local $byte)
          (i32.const 0x20)
        )
      )
    )(else
      (call $-write8
        (get_local $out)
        (get_local $len)
        (get_local $byte)
      )
    ))
  (br 0)))
  (get_local $out)
)
(func $string_upper (param $string i32) (result i32)
  (local $out i32)
  (local $len i32)
  (local $byte i32)
  (set_local $len (call $-len (get_local $string)))
  (set_local $out (call $-new_value (i32.const 3) (get_local $len)))
  (block(loop (br_if 1 (i32.eqz (get_local $len)))
    (set_local $len (i32.sub (get_local $len) (i32.const 1)))
    (set_local $byte (call $-read8 (get_local $string) (get_local $len)))
    (if (i32.and
      (i32.gt_u
        (get_local $byte)
        (i32.const 0x60)
      )
      (i32.lt_u
        (get_local $byte)
        (i32.const 0x7B)
      )
    )(then
      (call $-write8
        (get_local $out)
        (get_local $len)
        (i32.sub
          (get_local $byte)
          (i32.const 0x20)
        )
      )
    )(else
      (call $-write8
        (get_local $out)
        (get_local $len)
        (get_local $byte)
      )
    ))
  (br 0)))
  (get_local $out)
)

;; array functions
(func $array_length (param $array i32) (result i32)
  (call $-integer_u (i32.div_u (call $-len (get_local $array)) (i32.const 4)))
)
(func $array_insert (param $array i32) (param $index i32) (param $value i32) (result i32)
  (local $rest i32)
  (set_local $index (i32.mul (call $-i32_u (get_local $index)) (i32.const 4)))
  (if (i32.lt_u (call $-len (get_local $array)) (get_local $index))(then
    (set_local $index (call $-len (get_local $array)))
  ))
  (set_local $rest (i32.sub (call $-len (get_local $array)) (get_local $index)))
  (call $-resize
    (get_local $array)
    (i32.add (i32.add (get_local $index) (get_local $rest)) (i32.const 4))
  )
  (call $-memcopy
    (i32.add (call $-offset (get_local $array)) (get_local $index))
    (i32.add (i32.add (call $-offset (get_local $array)) (get_local $index)) (i32.const 4))
    (get_local $rest)
  )
  (call $-write32 (get_local $array) (get_local $index) (get_local $value))
  (get_local $value)
)
(func $array_remove (param $array i32) (param $index i32) (result i32)
  (local $value i32)
  (local $rest i32)
  (set_local $index (i32.mul (call $-i32_u (get_local $index)) (i32.const 4)))
  (if (i32.le_u (call $-len (get_local $array)) (get_local $index))(then
    (return (i32.const 0))
  ))
  (set_local $rest (i32.sub (i32.sub (call $-len (get_local $array)) (get_local $index)) (i32.const 4)))
  (set_local $value (call $-read32 (get_local $array) (get_local $index)))
  (call $-memcopy
    (i32.add (i32.add (call $-offset (get_local $array)) (get_local $index)) (i32.const 4))
    (i32.add (call $-offset (get_local $array)) (get_local $index))
    (get_local $rest)
  )
  (call $-resize
    (get_local $array)
    (i32.add (get_local $index) (get_local $rest))
  )
  (get_local $value)
)
(func $array_push (param $array i32) (param $value i32) (result i32)
  (call $array_insert (get_local $array) (call $array_length (get_local $array)) (get_local $value))
)
(func $array_pop (param $array i32) (result i32)
  (call $array_remove
    (get_local $array)
    (call $-sub
      (call $array_length (get_local $array))
      (call $-integer_u (i32.const 1))
    )
  )
)
(func $array_unshift (param $array i32) (param $value i32) (result i32)
  (call $array_insert (get_local $array) (i32.const 2) (get_local $value))
)
(func $array_shift (param $array i32) (result i32)
  (call $array_remove
    (get_local $array)
    (i32.const 2)
  )
)
(func $array_search (param $array i32) (param $value i32) (param $start i32) (result i32)
  (local $index i32)
  (local $len i32)
  (local $pos i32)
  (set_local $start (i32.mul (call $-i32_u (get_local $start)) (i32.const 4)))
  (if (i32.lt_u (call $-len (get_local $array)) (get_local $start))(then
    (return (i32.const 0))
  ))
  (set_local $len (i32.sub (call $-len    (get_local $array)) (get_local $start)))
  (set_local $pos (i32.add (call $-offset (get_local $array)) (get_local $start)))
  (block(loop (br_if 1 (i32.eqz (get_local $len)))
    (if (call $-truthy (call $-equal (get_local $value) (i32.load (get_local $pos))))(then
      (set_local $index (call $-integer_u (i32.div_u
        (i32.sub
          (get_local $pos )
          (call $-offset
            (get_local $array ) 
          ) 
        )
        (i32.const 4 ) 
      )))
      (br 1)
    ))
    (set_local $pos (i32.add (get_local $pos) (i32.const 4)))
    (set_local $len (i32.sub (get_local $len) (i32.const 4)))
  (br 0)))

  (get_local $index)
)
(func $array_slice (param $array i32) (param $start i32) (param $len i32) (result i32)
  (local $out i32)
  (set_local $start (i32.mul (call $-i32_u (get_local $start)) (i32.const 4)))
  (set_local $len  (i32.mul (call $-i32_u (get_local $len))  (i32.const 4)))
  (if (i32.lt_u (call $-len (get_local $array)) (get_local $start))(then
    (set_local $start (call $-len (get_local $array)))
  ))
  (if (i32.lt_u (i32.sub (call $-len (get_local $array)) (get_local $start)) (get_local $len))(then
    (set_local $len (i32.sub (call $-len (get_local $array)) (get_local $start)))
  ))
  (set_local $out (call $-new_value (i32.const 4) (call $-i32_u (get_local $len))))
  (call $-memcopy (i32.add (call $-offset (get_local $array)) (get_local $start)) (call $-offset (get_local $out)) (get_local $len))
  (get_local $out)
)
(func $array_splice (param $array i32) (param $start i32) (param $delete i32) (param $replace i32) (result i32)
  (local $rest i32)
  (set_local $start (i32.mul (call $-i32_u (get_local $start)) (i32.const 4)))
  (set_local $delete  (i32.mul (call $-i32_u (get_local $delete))  (i32.const 4)))
  (if (i32.lt_u (call $-len (get_local $array)) (get_local $start))(then
    (set_local $start (call $-len (get_local $array)))
  ))
  (if (i32.lt_u (i32.sub (call $-len (get_local $array)) (get_local $start)) (get_local $delete))(then
    (set_local $delete (i32.sub (call $-len (get_local $array)) (get_local $start)))
  ))
  (set_local $rest (i32.sub (i32.sub (call $-len (get_local $array)) (get_local $start)) (get_local $delete)))
  (call $-memcopy
    (i32.add (i32.add (call $-offset (get_local $array)) (get_local $start)) (get_local $delete))
    (i32.add (call $-offset (get_local $array)) (get_local $start))
    (get_local $rest)
  )
  (call $-resize
    (get_local $array)
    (i32.add (i32.add (get_local $start) (get_local $rest)) (call $-len (get_local $replace)))
  )
  (call $-memcopy
    (i32.add (call $-offset (get_local $array)) (get_local $start))
    (i32.add (i32.add (call $-offset (get_local $array)) (get_local $start)) (call $-len (get_local $replace)))
    (get_local $rest)
  )
  (call $-memcopy
    (call $-offset (get_local $replace))
    (i32.add (call $-offset (get_local $array)) (get_local $start))
    (call $-len (get_local $replace))
  )
  (i32.const 0)
)
(func $array_sort (param $array i32) (result i32)
  (local $out i32)
  (local $len i32)
  (local $pos i32)
  (local $ins i32)
  (local $val i32)
  (set_local $out (call $-new_value (i32.const 4) (call $-len (get_local $array))))
  (set_local $len (i32.div_u (call $-len (get_local $array)) (i32.const 4)))
  (block(loop (br_if 1 (i32.eqz (get_local $len)))
    (set_local $val
      (call $-read32
        (get_local $array)
        (i32.mul (get_local $pos) (i32.const 4))
      )
    )
    (set_local $ins (get_local $pos))
    (block(loop (br_if 1 (i32.eqz (get_local $ins)))
      (br_if 1 (call $-ge
        (get_local $val)
        (call $-read32
          (get_local $out)
          (i32.mul (i32.sub (get_local $ins) (i32.const 1)) (i32.const 4))
        )
      ))
      (call $-write32
        (get_local $out)
        (i32.mul (get_local $ins) (i32.const 4))
        (call $-read32
          (get_local $out)
          (i32.mul (i32.sub (get_local $ins) (i32.const 1)) (i32.const 4))
        )
      )
      (set_local $ins (i32.sub (get_local $ins) (i32.const 1)))
    (br 0)))
    (call $-write32
      (get_local $out)
      (i32.mul (get_local $ins) (i32.const 4))
      (get_local $val)
    )
    (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
    (set_local $len (i32.sub (get_local $len) (i32.const 1)))
  (br 0)))
  (get_local $out)
)
(func $range (param $start i32) (param $end i32) (param $step i32) (result i32)
  (local $_start f64)
  (local $_end f64)
  (local $_step f64)
  (local $out i32)
  (local $offset i32)
  (local $len i32)
  (set_local $_start (call $-f64 (get_local $start)))
  (set_local $_end (call $-f64 (get_local $end)))
  (set_local $_step (call $-f64 (get_local $step)))
  (if (f64.eq (get_local $_step) (f64.const 0))(then
    (if (f64.gt (get_local $_start) (get_local $_end))(then
      (set_local $_step (f64.const -1))
    )(else
      (set_local $_step (f64.const 1))
    ))
  ))
  (set_local $out (call $-new_value (i32.const 4) (i32.trunc_u/f64 
     (f64.mul
      (f64.floor (f64.div
        (f64.sub
          (get_local $_end)
          (get_local $_start)
        )
        (get_local $_step)
      ))
      (f64.const 4)
    )
  )))
  (set_local $offset (call $-offset (get_local $out)))
  (set_local $len (call $-len (get_local $out)))
  (block(loop (br_if 1 (i32.eqz (get_local $len)))
    (i32.store (get_local $offset) (call $-number (get_local $_start)))
    (set_local $_start  (f64.add (get_local $_start)  (get_local $_step)))
    (set_local $offset  (i32.add (get_local $offset)  (i32.const 4)))
    (set_local $len     (i32.sub (get_local $len)     (i32.const 4)))
  (br 0)))
  (get_local $out)
)

;; object functions
(func $object_keys (param $object i32) (result i32)
  (local $out i32)
  (local $len i32)
  (set_local $out (call $-new_value (i32.const 4) (i32.div_u (call $-len (get_local $object)) (i32.const 2))))
  (set_local $len (i32.div_u (call $-len (get_local $out)) (i32.const 4)))
  (block(loop (br_if 1 (i32.eqz (get_local $len)))
    (set_local $len (i32.sub (get_local $len) (i32.const 1)))
    (call $-write32
      (get_local $out)
      (i32.mul (get_local $len) (i32.const 4))
      (call $-read32
        (get_local $object)
        (i32.mul (get_local $len) (i32.const 8))
      )
    )
  (br 0)))
  (get_local $out)
)
(func $object_values (param $object i32) (result i32)
  (local $out i32)
  (local $len i32)
  (set_local $out (call $-new_value (i32.const 4) (i32.div_u (call $-len (get_local $object)) (i32.const 2))))
  (set_local $len (i32.div_u (call $-len (get_local $out)) (i32.const 4)))
  (block(loop (br_if 1 (i32.eqz (get_local $len)))
    (set_local $len (i32.sub (get_local $len) (i32.const 1)))
    (call $-write32
      (get_local $out)
      (i32.mul (get_local $len) (i32.const 4))
      (call $-read32
        (get_local $object)
        (i32.add (i32.mul (get_local $len) (i32.const 8)) (i32.const 4))
      )
    )
  (br 0)))
  (get_local $out)
)

;; math functions
(func $abs (param $number i32) (result i32)
  (call $-number (f64.abs (call $-f64 (get_local $number))))
)
(func $ceil (param $number i32) (result i32)
  (call $-number (f64.ceil (call $-f64 (get_local $number))))
)
(func $floor (param $number i32) (result i32)
  (call $-number (f64.floor (call $-f64 (get_local $number))))
)
(func $nearest (param $number i32) (result i32)
  (call $-number (f64.nearest (call $-f64 (get_local $number))))
)
(func $sqrt (param $number i32) (result i32)
  (call $-number (f64.sqrt (call $-f64 (get_local $number))))
)
(func $min (param $number1 i32) (param $number2 i32) (result i32)
  (call $-number (f64.min
    (call $-f64 (get_local $number1))
    (call $-f64 (get_local $number2))
  ))
)
(func $max (param $number1 i32) (param $number2 i32) (result i32)
  (call $-number (f64.max
    (call $-f64 (get_local $number1))
    (call $-f64 (get_local $number2))
  ))
)
