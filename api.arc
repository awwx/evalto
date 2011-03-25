;; todo access control

(def orerror (f)
  (on-err (fn (e) `(error ,(details e))) f))

;; todo distinguish error

(defop-base getobj
  (text-content)
  (write (orerror (fn () (objs* (arg "id"))))))

(defop-base lookup-nickname
  (text-content)
  (write (orerror (fn () (lookup-nickname (arg "userid") (arg "nickname"))))))

(defop-base lookup-recipe
  (text-content)
  (write (orerror (fn () (lookup-recipe (arg "recipe"))))))
