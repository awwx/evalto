(defvar x (fn () 3) (fn (v)))
(testis x 3)

(let p 5
  (defvar x (fn () p) (fn (v) (= p v)))
  (testis x 5)
  (= x 7)
  (testis p 7)
  (testis x 7))
