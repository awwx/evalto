(require "ac.scm") 
(require "brackets.scm")
(use-bracket-readtable)

(define (after a b)
  (dynamic-wind (lambda () #f) a b))

(define (capture-stdout box f)
  (let ((o (open-output-string)))
    (after
     (lambda ()
       (parameterize ((current-output-port o)) (f)))
     (lambda ()
       (close-output-port o)
       (set-box! box (get-output-string o))))))

(define (capture-error box f)
  (with-handlers ((exn:fail? (lambda (c)
                               (set-box! box (exn-message c))
                               #f)))
    (f)))

(define (check-exit-code f ok)
  (if (eqv? (f) 0)
       (ok)
       'failed))

(define (http-get url)
  (let ((stdout (box #f)))
    (check-exit-code
     (lambda ()
       (capture-stdout stdout
         (lambda ()
           (system*/exit-code "/usr/bin/curl" "-v" "-k" "-f" "-s" "-S" url))))
     (lambda ()
       (unbox stdout)))))

(define (http-post url content-type data)
  (let ((tmpfile (make-temporary-file)))
    (after
     (lambda ()
       (let ((o (open-output-file tmpfile #:exists 'truncate)))
         (display data o)
         (close-output-port o))
       (let ((stdout (box #f)))
         (check-exit-code
          (lambda ()
            (capture-stdout stdout
              (lambda ()
                (system*/exit-code
                 "/usr/bin/curl" "-v" "-k" "-f" "-s" "-S"
                 "--header" (string-append "Content-Type: " content-type)
                 "--data-binary" (string-append "@" (path->string tmpfile))
                 url))))
          (lambda ()
            (unbox stdout)))))
     (lambda ()
       (delete-file tmpfile)))))

(define (read-from-string str)
  (let ((port (open-input-string str)))
    (let ((val (read port)))
      (close-input-port port)
      val)))

(define (fetch-job url)
  (let ((s (http-get url)))
    (cond ((eqv? s 'failed)
           (sleep 5)
           (fetch-job url))
          (else
           (let ((v (read-from-string s)))
             (cond ((eqv? v 'nil)
                    (fetch-job url))
                   (else
                    v)))))))

(define (write-to-string v)
  (let ((p (open-output-string)))
    (write v p)
    (get-output-string p)))

(define (disp-to-string x)
  (let ((o (open-output-string)))
    (display x o)
    (close-output-port o)
    (get-output-string o)))

(define (capture f)
  (let ((value #f) (err (box #f)) (stdout (box #f)))
    (capture-stdout stdout
      (lambda ()
        (capture-error err
          (lambda ()
            (set! value (f))))))
    (append
     (if (> (string-length (unbox stdout)) 0)
          `((stdout ,(unbox stdout)))
          '())
     (if (unbox err)
          `((error ,(unbox err)))
          `((value  ,(write-to-string value)))))))

(define (alref alist key)
  (cadr (assoc key alist)))

(define (execute arc-eval job)
  (let ((exprs (alref job 'exprs)))
    (let ((results
           (map (lambda (expr-string)
                  (capture
                   (lambda ()
                     (arc-eval (read-from-string expr-string)))))
                exprs)))
      (display "results: ") (write results) (newline)
      (http-post (alref job 'callback)
                 "x-application/arc"
                 (write-to-string `((jobid  ,(alref job 'jobid))
                                    (results ,results)))))))
(define (repl-server arc-eval process-id)
  (let loop ()
    (let ((job (fetch-job (string-append
                           evalto-url*
                           "getjob?process=" process-id))))
      (display "job: ") (write job) (newline)
      (execute arc-eval job))
    (loop)))

(aload "arc.arc")

(repl-server arc-eval process-id*)
