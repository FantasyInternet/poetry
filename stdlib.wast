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
  (set_local $sub (call $-new_value (call $-datatype (get_local $subbin)) (call $-len (get_local $subbin))))
  (block(loop
    (br_if 1 (i32.gt_u (get_local $start) (i32.sub (call $-len (get_local $binary)) (call $-len (get_local $subbin)))))
    (call $-memcopy
      (i32.add (call $-offset (get_local $binary)) (get_local $start))
      (call $-offset (get_local $sub))
      (call $-len (get_local $sub))
    )
    (if (i32.eqz (call $-compare (get_local $sub) (get_local $subbin))) (then
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
  (call $-integer_u (call $-bytes_to_chars (call $-offset (get_local $str)) (call $-len (get_local $str))))
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
  (local $res i32)
  (set_local $start (call $-chars_to_bytes
    (call $-offset (get_local $string))
    (call $-i32_u (get_local $start))
  ))
  (set_local $res (call $binary_search
    (get_local $string)
    (get_local $substr)
    (call $-integer_u (get_local $start))
  ))
  (if (get_local $res)(then
    (set_local $res (call $-integer_u (call $-bytes_to_chars
      (call $-offset (get_local $string))
      (call $-i32_u (get_local $res))
    )))
  ))
  (get_local $res)
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
(func $string_split (param $string i32) (param $seperator i32) (result i32)
  (local $parts i32)
  (local $sub i32)
  (local $start i32)
  (local $pos i32)
  (if (i32.lt_u (call $-len (get_local $string)) (call $-len (get_local $seperator))) (then
    (return (i32.const 0))
  ))
  (set_local $parts (call $-new_value (i32.const 4) (i32.const 0)))
  (set_local $sub (call $-new_value (call $-datatype (get_local $seperator)) (call $-len (get_local $seperator))))
  (block(loop
    (br_if 1 (i32.gt_u (get_local $pos) (i32.sub (call $-len (get_local $string)) (call $-len (get_local $seperator)))))
    (call $-memcopy
      (i32.add (call $-offset (get_local $string)) (get_local $pos))
      (call $-offset (get_local $sub))
      (call $-len (get_local $sub))
    )
    (if (i32.eqz (call $-compare (get_local $sub) (get_local $seperator))) (then
      (call $-write32
        (get_local $parts)
        (call $-len (get_local $parts))
        (call $-string 
          (i32.add
            (call $-offset (get_local $string))
            (get_local $start)
          )
          (i32.sub
            (get_local $pos)
            (get_local $start)
          )
        )
      )
      (set_local $start (i32.add
        (get_local $pos)
        (call $-len (get_local $seperator))
      ))
      (set_local $pos (get_local $start))
    )(else
      (set_local $pos (i32.add (get_local $pos) (i32.const 1)))
    ))
    (br 0)
  ))
  (call $-write32
    (get_local $parts)
    (call $-len (get_local $parts))
    (call $-string 
      (i32.add
        (call $-offset (get_local $string))
        (get_local $start)
      )
      (i32.sub
        (call $-len (get_local $string))
        (get_local $start)
      )
    )
  )
  (get_local $parts)
)
(func $char (param $code i32) (result i32)
  (set_local $code (call $-i32_u (get_local $code)))
  (call $-char (get_local $code))
)
(func $char_code (param $string i32) (param $pos i32) (result i32)
  (set_local $pos (i32.add
    (call $-offset (get_local $string))
    (call $-chars_to_bytes
      (call $-offset (get_local $string))
      (call $-i32_u (get_local $pos))
    )
  ))
  (call $-integer_u (call $-char_code (get_local $pos)))
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
      (br 2)
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
(func $array_join (param $array i32) (param $glue i32) (result i32)
  (local $string i32)
  (local $strlen i32)
  (local $part i32)
  (local $pos i32)
  (local $len i32)
  (set_local $string (call $-new_value (i32.const 3) (get_local $strlen)))
  (set_local $len (call $-len (get_local $array)))
  (if (get_local $len)(then
    (set_local $part (call $-to_string (call $-read32 (get_local $array) (get_local $pos))))
    (call $-resize (get_local $string) (i32.add
      (get_local $strlen)
      (call $-len (get_local $part))
    ))
    (call $-memcopy
      (call $-offset (get_local $part))
      (i32.add
        (call $-offset (get_local $string))
        (get_local $strlen)
      )
      (call $-len (get_local $part))
    )
    (set_local $strlen (i32.add (get_local $strlen) (call $-len (get_local $part))))
    (set_local $pos (i32.add (get_local $pos) (i32.const 4)))
    (set_local $len (i32.sub (get_local $len) (i32.const 4)))
  ))
  (block(loop (br_if 1 (i32.eqz (get_local $len)))
    (set_local $part (call $-to_string (call $-read32 (get_local $array) (get_local $pos))))
    (call $-resize (get_local $string) (i32.add
      (get_local $strlen)
      (i32.add
        (call $-len (get_local $glue))
        (call $-len (get_local $part))
      )
    ))
    (call $-memcopy
      (call $-offset (get_local $glue))
      (i32.add
        (call $-offset (get_local $string))
        (get_local $strlen)
      )
      (call $-len (get_local $glue))
    )
    (set_local $strlen (i32.add (get_local $strlen) (call $-len (get_local $glue))))
    (call $-memcopy
      (call $-offset (get_local $part))
      (i32.add
        (call $-offset (get_local $string))
        (get_local $strlen)
      )
      (call $-len (get_local $part))
    )
    (set_local $strlen (i32.add (get_local $strlen) (call $-len (get_local $part))))
    (set_local $pos (i32.add (get_local $pos) (i32.const 4)))
    (set_local $len (i32.sub (get_local $len) (i32.const 4)))
  (br 0)))
  (get_local $string)
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

;; JSON
(func $json_encode (param $value i32) (result i32)
  (local $datatype i32)
  (local $len i32)
  (local $json_string i32)
  (local $char i32)
  (local $done i32)
  (local $ipos i32)
  (local $opos i32)
  (set_local $datatype (call $-datatype (get_local $value)))
  (set_local $len (call $-len (get_local $value)))
  (if (i32.lt_u (get_local $datatype) (i32.const 3))(then
    (set_local $json_string (call $-to_string (get_local $value)))
  ))
  (if (i32.eq (get_local $datatype) (i32.const 3))(then ;; string
    (set_local $json_string (call $-new_value (i32.const 3) (call $-len (get_local $value))))
    (call $-write8 (get_local $json_string) (get_local $opos) (i32.const 0x22)) ;; "
    (set_local $opos (i32.add (get_local $opos) (i32.const 1)))
    (block(loop (br_if 1 (i32.ge_u (get_local $ipos) (get_local $len)))
      (set_local $done (i32.const 0))
      (set_local $char (call $-read8 (get_local $value) (get_local $ipos)))
      (if (i32.eq (get_local $char) (i32.const 0x08))(then
        (call $-write16 (get_local $json_string) (get_local $opos) (i32.const 0x625c)) ;; \b
        (set_local $opos (i32.add (get_local $opos) (i32.const 2)))
        (set_local $done (i32.const 1))
      ))
      (if (i32.eq (get_local $char) (i32.const 0x09))(then
        (call $-write16 (get_local $json_string) (get_local $opos) (i32.const 0x745c)) ;; \t
        (set_local $opos (i32.add (get_local $opos) (i32.const 2)))
        (set_local $done (i32.const 1))
      ))
      (if (i32.eq (get_local $char) (i32.const 0x0a))(then
        (call $-write16 (get_local $json_string) (get_local $opos) (i32.const 0x6e5c)) ;; \n
        (set_local $opos (i32.add (get_local $opos) (i32.const 2)))
        (set_local $done (i32.const 1))
      ))
      (if (i32.eq (get_local $char) (i32.const 0x0c))(then
        (call $-write16 (get_local $json_string) (get_local $opos) (i32.const 0x665c)) ;; \f
        (set_local $opos (i32.add (get_local $opos) (i32.const 2)))
        (set_local $done (i32.const 1))
      ))
      (if (i32.eq (get_local $char) (i32.const 0x0d))(then
        (call $-write16 (get_local $json_string) (get_local $opos) (i32.const 0x725c)) ;; \r
        (set_local $opos (i32.add (get_local $opos) (i32.const 2)))
        (set_local $done (i32.const 1))
      ))
      (if (i32.eq (get_local $char) (i32.const 0x22))(then
        (call $-write16 (get_local $json_string) (get_local $opos) (i32.const 0x225c)) ;; \"
        (set_local $opos (i32.add (get_local $opos) (i32.const 2)))
        (set_local $done (i32.const 1))
      ))
      (if (i32.eq (get_local $char) (i32.const 0x5c))(then
        (call $-write16 (get_local $json_string) (get_local $opos) (i32.const 0x5c5c)) ;; \\
        (set_local $opos (i32.add (get_local $opos) (i32.const 2)))
        (set_local $done (i32.const 1))
      ))
      (if (i32.eq (get_local $char) (i32.const 0x7f))(then
        (call $-write16 (get_local $json_string) (get_local $opos) (i32.const 0x755c)) ;; \u
        (set_local $opos (i32.add (get_local $opos) (i32.const 2)))
        (call $-write32 (get_local $json_string) (get_local $opos) (i32.const 0x66373030)) ;; 007f
        (set_local $opos (i32.add (get_local $opos) (i32.const 4)))
        (set_local $done (i32.const 1))
      ))
      (if (i32.eqz (get_local $done))(then
        (if (i32.lt_u (get_local $char) (i32.const 0x20))(then
          (call $-write16 (get_local $json_string) (get_local $opos) (i32.const 0x755c)) ;; \u
          (set_local $opos (i32.add (get_local $opos) (i32.const 2)))
          (set_local $done (call $-to_hex (get_local $char) (i32.const 4)))
          (call $-write32 (get_local $json_string) (get_local $opos) (call $-read32 (get_local $done) (i32.const 0)))
          (set_local $opos (i32.add (get_local $opos) (i32.const 4)))
        )(else
          (call $-write8 (get_local $json_string) (get_local $opos) (get_local $char))
          (set_local $opos (i32.add (get_local $opos) (i32.const 1)))
        ))
      ))
      (set_local $ipos (i32.add (get_local $ipos) (i32.const 1)))
    (br 0)))
    (call $-write8 (get_local $json_string) (get_local $opos) (i32.const 0x22)) ;; "
  ))
  (if (i32.eq (get_local $datatype) (i32.const 4))(then ;; array
    (set_local $json_string (call $-new_value (i32.const 3) (i32.const 0)))
    (call $-write8 (get_local $json_string) (get_local $opos) (i32.const 0x5b)) ;; [
    (set_local $opos (i32.add (get_local $opos) (i32.const 1)))
    (block(loop (br_if 1 (i32.ge_u (get_local $ipos) (get_local $len)))
      (set_local $char (call $-read32 (get_local $value) (get_local $ipos)))
      (set_local $ipos (i32.add (get_local $ipos) (i32.const 4)))
      (set_local $opos (call $-len (get_local $json_string)))
      (call $-write_to (get_local $json_string) (get_local $opos) (call $json_encode (get_local $char)))
      (set_local $opos (call $-len (get_local $json_string)))
      (call $-write8 (get_local $json_string) (get_local $opos) (i32.const 0x2c)) ;; ,
    (br 0)))
    (call $-write8 (get_local $json_string) (get_local $opos) (i32.const 0x5d)) ;; ]
  ))
  (if (i32.eq (get_local $datatype) (i32.const 5))(then ;; object
    (set_local $json_string (call $-new_value (i32.const 3) (i32.const 0)))
    (call $-write8 (get_local $json_string) (get_local $opos) (i32.const 0x7b)) ;; {
    (set_local $opos (i32.add (get_local $opos) (i32.const 1)))
    (block(loop (br_if 1 (i32.ge_u (get_local $ipos) (get_local $len)))
      (set_local $char (call $-read32 (get_local $value) (get_local $ipos)))
      (set_local $ipos (i32.add (get_local $ipos) (i32.const 4)))
      (set_local $opos (call $-len (get_local $json_string)))
      (call $-write_to (get_local $json_string) (get_local $opos) (call $json_encode (call $-to_string (get_local $char))))
      (set_local $opos (call $-len (get_local $json_string)))
      (call $-write8 (get_local $json_string) (get_local $opos) (i32.const 0x3a)) ;; :
      (set_local $char (call $-read32 (get_local $value) (get_local $ipos)))
      (set_local $ipos (i32.add (get_local $ipos) (i32.const 4)))
      (set_local $opos (call $-len (get_local $json_string)))
      (call $-write_to (get_local $json_string) (get_local $opos) (call $json_encode (get_local $char)))
      (set_local $opos (call $-len (get_local $json_string)))
      (call $-write8 (get_local $json_string) (get_local $opos) (i32.const 0x2c)) ;; ,
    (br 0)))
    (call $-write8 (get_local $json_string) (get_local $opos) (i32.const 0x7d)) ;; }
  ))
  (get_local $json_string)
)
(func $json_decode (param $json_string i32) (result i32)
  (local $datatype i32)
  (local $value i32)
  (set_local $datatype (call $-datatype (get_local $json_string)))
  (set_local $value (get_local $json_string))
  (set_global $~pos (call $-offset (get_local $json_string)))
  (if (i32.eq (get_local $datatype) (i32.const 3))(then
    (set_local $value (call $~json_decode))
  ))
  (if (i32.eq (get_local $datatype) (i32.const 6))(then
    (set_local $value (call $~json_decode))
  ))
  (get_local $value)
)
(global $~pos (mut i32) (i32.const 0))
(func $~json_decode (result i32)
  (local $value i32)
  (local $err i32)
  (local $char i32)
  (local $pos i32)
  (local $hex i32)
  (local $num f64)
  (local $neg f64)
  (local $exp f64)
  (local $eneg f64)
  (set_local $err (i32.eqz (call $~skip_whitespace)))
  (set_local $char (i32.load8_u (get_global $~pos)))
  (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
  (if (i32.eq (get_local $char) (i32.const 0x6e))(then ;; n
    (set_global $~pos (i32.sub (get_global $~pos) (i32.const 1)))
    (set_local $char (i32.load (get_global $~pos)))
    (set_global $~pos (i32.add (get_global $~pos) (i32.const 4)))
    (if (i32.eq (get_local $char) (i32.const 0x6c6c756e))(then ;; null
      (set_local $value (i32.const 0))
    )(else
      (set_local $char (i32.const 0))
      (set_local $err (i32.const 1))
    ))
  ))
  (if (i32.eq (get_local $char) (i32.const 0x66))(then ;; f
    (set_local $char (i32.load (get_global $~pos)))
    (set_global $~pos (i32.add (get_global $~pos) (i32.const 4)))
    (if (i32.eq (get_local $char) (i32.const 0x65736c61))(then ;; alse
      (set_local $value (i32.const 1))
    )(else
      (set_local $char (i32.const 0))
      (set_local $err (i32.const 1))
    ))
  ))
  (if (i32.eq (get_local $char) (i32.const 0x74))(then ;; t
    (set_global $~pos (i32.sub (get_global $~pos) (i32.const 1)))
    (set_local $char (i32.load (get_global $~pos)))
    (set_global $~pos (i32.add (get_global $~pos) (i32.const 4)))
    (if (i32.eq (get_local $char) (i32.const 0x65757274))(then ;; true
      (set_local $value (i32.const 5))
    )(else
      (set_local $char (i32.const 0))
      (set_local $err (i32.const 1))
    ))
  ))
  (if (i32.or
        (i32.eq (get_local $char) (i32.const 0x2d)) ;; -
        (i32.and
          (i32.ge_u (get_local $char) (i32.const 0x30)) ;; 0
          (i32.le_u (get_local $char) (i32.const 0x39)) ;; 9
        )) (then
    (set_local $num (f64.const 0))
    (set_local $exp (f64.const 0))
    (if (i32.eq (get_local $char) (i32.const 0x2d))(then ;; -
      (set_local $neg (f64.const -1))
      (set_local $char (i32.load8_u (get_global $~pos)))
      (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
    )(else
      (set_local $neg (f64.const 1))
    ))
    (block(loop
      (br_if 1 
        (i32.or
          (i32.lt_u (get_local $char) (i32.const 0x30)) ;; 0
          (i32.gt_u (get_local $char) (i32.const 0x39)) ;; 9
      ))
      (set_local $num (f64.mul (get_local $num) (f64.const 10)))
      (set_local $num (f64.add (get_local $num) (f64.convert_u/i32(i32.sub
        (get_local $char)
        (i32.const 0x30)
      ))))
      (set_local $char (i32.load8_u (get_global $~pos)))
      (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
    (br 0)))
    (if (i32.eq (get_local $char) (i32.const 0x2e))(then ;; .
      (set_local $char (i32.load8_u (get_global $~pos)))
      (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
      (block(loop
        (br_if 1 
          (i32.or
            (i32.lt_u (get_local $char) (i32.const 0x30)) ;; 0
            (i32.gt_u (get_local $char) (i32.const 0x39)) ;; 9
        ))
        (set_local $num (f64.mul (get_local $num) (f64.const 10)))
        (set_local $num (f64.add (get_local $num) (f64.convert_u/i32(i32.sub
          (get_local $char)
          (i32.const 0x30)
        ))))
        (set_local $exp (f64.sub (get_local $exp) (f64.const 1)))
        (set_local $char (i32.load8_u (get_global $~pos)))
        (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
      (br 0)))
      (block(loop (br_if 1 (f64.ge (get_local $exp) (f64.const 0)))
        (set_local $num (f64.div (get_local $num) (f64.const 10)))
        (set_local $exp (f64.add (get_local $exp) (f64.const 1)))
      (br 0)))
    ))
    (if (i32.eq (get_local $char) (i32.const 0x65))(then ;; e
      (set_local $char (i32.sub (get_local $char) (i32.const 0x20)))
    ))
    (if (i32.eq (get_local $char) (i32.const 0x45))(then ;; E
      (set_local $char (i32.load8_u (get_global $~pos)))
      (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
      (if (i32.eq (get_local $char) (i32.const 0x2d))(then ;; -
        (set_local $eneg (f64.const -1))
        (set_local $char (i32.load8_u (get_global $~pos)))
        (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
      )(else
        (set_local $eneg (f64.const 1))
      ))
      (block(loop
        (br_if 1 
          (i32.or
            (i32.lt_u (get_local $char) (i32.const 0x30)) ;; 0
            (i32.gt_u (get_local $char) (i32.const 0x39)) ;; 9
        ))
        (set_local $exp (f64.mul (get_local $exp) (f64.const 10)))
        (set_local $exp (f64.add (get_local $exp) (f64.convert_u/i32(i32.sub
          (get_local $char)
          (i32.const 0x30)
        ))))
        (set_local $char (i32.load8_u (get_global $~pos)))
        (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
      (br 0)))
      (set_local $exp (f64.mul (get_local $exp) (get_local $eneg)))
      (block(loop (br_if 1 (f64.le (get_local $exp) (f64.const 0)))
        (set_local $num (f64.mul (get_local $num) (f64.const 10)))
        (set_local $exp (f64.sub (get_local $exp) (f64.const 1)))
      (br 0)))
      (block(loop (br_if 1 (f64.ge (get_local $exp) (f64.const 0)))
        (set_local $num (f64.div (get_local $num) (f64.const 10)))
        (set_local $exp (f64.add (get_local $exp) (f64.const 1)))
      (br 0)))
    ))
    (set_global $~pos (i32.sub (get_global $~pos) (i32.const 1)))
    (set_local $value (call $-number (f64.mul (get_local $num) (get_local $neg))))
  ))
  (if (i32.eq (get_local $char) (i32.const 0x22))(then ;; "
    (set_local $char (i32.load8_u (get_global $~pos)))
    (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
    (set_local $value (call $-new_value (i32.const 3) (i32.const 0)))
    (block(loop (br_if 1 (i32.eq (get_local $char) (i32.const 0x22))) ;; "
      (set_local $pos (call $-len (get_local $value)))
      (if (i32.eq (get_local $char) (i32.const 0x5c))(then ;; \
        (set_local $char (i32.load8_u (get_global $~pos)))
        (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
        (call $-write8 (get_local $value) (get_local $pos) (get_local $char))
        (if (i32.eq (get_local $char) (i32.const 0x62))(then ;; b
          (call $-write8 (get_local $value) (get_local $pos) (i32.const 0x08))
        ))
        (if (i32.eq (get_local $char) (i32.const 0x66))(then ;; f
          (call $-write8 (get_local $value) (get_local $pos) (i32.const 0x0c))
        ))
        (if (i32.eq (get_local $char) (i32.const 0x6e))(then ;; n
          (call $-write8 (get_local $value) (get_local $pos) (i32.const 0x0a))
        ))
        (if (i32.eq (get_local $char) (i32.const 0x72))(then ;; r
          (call $-write8 (get_local $value) (get_local $pos) (i32.const 0x0d))
        ))
        (if (i32.eq (get_local $char) (i32.const 0x74))(then ;; t
          (call $-write8 (get_local $value) (get_local $pos) (i32.const 0x09))
        ))
        (if (i32.eq (get_local $char) (i32.const 0x75))(then ;; u
          (if (i32.eqz (get_local $hex))(then
            (set_local $hex (call $-new_value (i32.const 3) (i32.const 4)))
          ))
          (set_local $char (i32.load (get_global $~pos)))
          (set_global $~pos (i32.add (get_global $~pos) (i32.const 4)))
          (call $-write32 (get_local $hex) (i32.const 0) (get_local $char))
          (set_local $char (call $-from_hex (get_local $hex)))
          (if (i32.eq (i32.and (get_local $char) (i32.const 0xfc00)) (i32.const 0xd800))(then ;; surrogate pair
            (set_global $~pos (i32.add (get_global $~pos) (i32.const 2)))
            (call $-write32 (get_local $hex) (i32.const 0) (i32.load (get_global $~pos)))
            (set_global $~pos (i32.add (get_global $~pos) (i32.const 4)))
            (set_local $hex (call $-from_hex (get_local $hex)))
            (set_local $char (i32.mul (i32.sub (get_local $char) (i32.const 0xd800)) (i32.const 0x400)))
            (set_local $hex (i32.sub (get_local $hex) (i32.const 0xdc00)))
            (set_local $char (i32.add (i32.add (get_local $char) (get_local $hex)) (i32.const 0x10000)))
            (set_local $char (call $-char (get_local $char)))
            (set_local $hex (i32.const 0))
          )(else
            (set_local $char (call $-char (get_local $char)))
          ))
          (call $-write_to (get_local $value) (get_local $pos) (get_local $char))
        ))
      )(else
        (call $-write8 (get_local $value) (get_local $pos) (get_local $char))
      ))

      (set_local $char (i32.load8_u (get_global $~pos)))
      (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
    (br 0)))
  ))
  (if (i32.eq (get_local $char) (i32.const 0x5b))(then ;; [
    (set_local $value (call $-new_value (i32.const 4) (i32.const 0)))
    (set_local $char (call $~skip_whitespace))
    (set_local $err (i32.eqz (call $~skip_whitespace)))
    (block(loop (br_if 1 (i32.or (get_local $err) (i32.eq (get_local $char) (i32.const 0x5d)))) ;; ]
      (if (i32.eq (get_local $char) (i32.const 0x2c))(then ;; ,
        (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
      ))
      (call $-write32 (get_local $value) (call $-len (get_local $value)) (call $~json_decode))
      (set_local $char (call $~skip_whitespace))
      (set_local $err (i32.eqz (call $~skip_whitespace)))
    (br 0)))
    (if (i32.eq (get_local $char) (i32.const 0x5d))(then ;; ]
      (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
    ))
  ))
  (if (i32.eq (get_local $char) (i32.const 0x7b))(then ;; {
    (set_local $value (call $-new_value (i32.const 5) (i32.const 0)))
    (set_local $char (call $~skip_whitespace))
    (set_local $err (i32.eqz (call $~skip_whitespace)))
    (block(loop (br_if 1 (i32.or (get_local $err) (i32.eq (get_local $char) (i32.const 0x7d)))) ;; }
      (if (i32.eq (get_local $char) (i32.const 0x2c))(then ;; ,
        (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
      ))
      (call $-write32 (get_local $value) (call $-len (get_local $value)) (call $~json_decode))
      (set_local $char (call $~skip_whitespace))
      (set_local $err (i32.eqz (call $~skip_whitespace)))
      (if (i32.eq (get_local $char) (i32.const 0x3a))(then ;; :
        (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
      ))
      (call $-write32 (get_local $value) (call $-len (get_local $value)) (call $~json_decode))
      (set_local $char (call $~skip_whitespace))
      (set_local $err (i32.eqz (call $~skip_whitespace)))
    (br 0)))
    (if (i32.eq (get_local $char) (i32.const 0x7d))(then ;; }
      (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
    ))
  ))
  (get_local $value)
)
(func $~skip_whitespace (result i32)
  (local $char i32)
  (local $err i32)
  (set_local $char (i32.load8_u (get_global $~pos)))
  (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
  (block(loop (br_if 1 (i32.or (get_local $err) (i32.gt_u (get_local $char) (i32.const 0x20))))
    (if (i32.eqz (get_local $char)) (then
      (set_local $err (i32.const 1))
    )(else
      (set_local $char (i32.load8_u (get_global $~pos)))
      (set_global $~pos (i32.add (get_global $~pos) (i32.const 1)))
    ))
  (br 0)))
  (set_global $~pos (i32.sub (get_global $~pos) (i32.const 1)))
  (get_local $char)
)
