(func $get_mindex (result i32)
  (get_global $-mindex)
)
(export "get_mindex" (func $get_mindex))

(func $load_f64 (param $offset i32) (result f64)
  (f64.load (get_local $offset))
)
(export "load_f64" (func $load_f64))
(export "garbagecollect" (func $-garbagecollect))
;; (export "traceGC" (func $-traceGC))
