(= p (parameter 36))
(make-dynamic foo p)
(testis foo 36)
(parameterize p 77 (testis foo 77))

(make-dynamic foo (parameter 36))
(testis (type (paramfor foo)) 'parameter)

(make-dynamic foo (parameter 36))
(testis (dlet foo 77 foo) 77)

(dynamic bar 33)
(testis (dlet bar 77 bar) 77)
