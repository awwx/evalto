(def command-line-args ()
  (ac-niltree (scheme (vector->list (current-command-line-arguments)))))

(= targetdir (string "/tmp/" (rand-string 16)))

(let (recipefile) (command-line-args)
  (run-recipe targetdir (readfile recipefile)))

(w/cwd targetdir
  (system "/home/andrew/racket-5.0.2/bin/racket -f as.scm"))

(quit)
