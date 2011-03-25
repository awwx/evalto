(= example-dir* "/tmp/example")
(= racketbin* "/home/andrew/racket-5.0.2/bin/racket")

(def system/check-exit args
  (let cmd (string args)
    (scheme (tnil (system cmd)))))

(def run-example (recipe exprs)
  (create-example recipe exprs)
  (system/check-exit
   (str "cd " example-dir* "; "
        "ulimit -d " (str (* 5 1024)) "; "
        "ulimit -t 10; "
        racketbin* " -f as.scm")))

(def run-examples (recipe exprs)
  (catch
   (readall (tostring (or (run-example recipe exprs)
                          (throw 'killed))))))

(def sample ()
  (run-examples (readfile "/code/evalto/scheme0.recipe")
                '("(scheme (let ((a 3))
          (+ a 20)))")))
