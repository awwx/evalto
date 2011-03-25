(testis (type (parameter 3)) 'parameter)

(testis (let foo (parameter 33)
          (parameterize foo 77 (foo)))
        77)
