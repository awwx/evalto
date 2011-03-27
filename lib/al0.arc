(def akeys (q)
  (map car q))

(mac al args
  `(accum a
     ,@(map (fn ((k v))
              `(aif ,v (a (list ',k it))))
            (pair args))))
