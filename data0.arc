(def newid ()
  (rand-string 12))

(def okid (id)
  (and (isa id 'string) (in (len id) 12 16) (all alphadig id) id))
