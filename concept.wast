(module
      ;; imports
      
      ;; runtime
      
      ;; globals
      (global $meaning_of_life (mut i32) (i32.const 0))
(global $pi (mut i32) (i32.const 0))
(global $name (mut i32) (i32.const 0))
(global $married (mut i32) (i32.const 0))
(global $friends (mut i32) (i32.const 0))

      ;; functions
      (func $double (param $n i32) (result i32)
(return (call $-mul (get_local $n) (call $-number (f32.const 2))))

)


      ;; exports
      
    )