(def assoc-iso (key al)
  (if (atom al)
       nil
      (and (acons (car al)) (iso (caar al) key))
       (car al)
      (assoc-iso key (cdr al))))

(def alref-iso (al key) (cadr (assoc-iso key al)))
