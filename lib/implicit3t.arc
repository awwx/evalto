(dynamic foo3 33)
(make-w/ foo3)
(testis (w/foo3 77 foo3) 77)

(make-implicit foo4 (parameter 3))
(testis foo4 3)
(testis (w/foo4 4 foo4) 4)

(implicit foo5 3)
(testis foo5 3)
(assign foo5 4)
(testis foo5 4)
(testis (w/foo5 99 foo5) 99)
