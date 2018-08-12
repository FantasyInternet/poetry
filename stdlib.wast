(func $address_of (param $id i32) (result i32)
  (call $-number (f64.convert_u/i32 (call $-offset (get_local $id))))
)
(func $size_of (param $id i32) (result i32)
  (call $-number (f64.convert_u/i32 (call $-len (get_local $id))))
)

