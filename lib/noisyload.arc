(let orig-load load
  (def load (file)
    (prn file)
    (orig-load file)))
