(def rpc (op args)
  (let r (http-get
          nil
          (string "http://localhost:8080/" op)
          args)
    (when (~caris r 'content) (err (tostring (write r))))
    (read (cadr r))))

(def api-getobj (id)
  (rpc 'getobj (al id id)))

(def api-lookup-nickname (userid nickname)
  (rpc 'lookup-nickname (al userid userid nickname nickname)))

(def api-lookup-recipe (recipe-id)
  (rpc 'lookup-recipe (al recipe recipe-id)))
