(= sample-example-spec*
   `((recipe "EtnyaWdfeCaZCZtV")
     (exprs (#<<Z
(scheme (let ((a 3))
          (+ a 20)))
Z
))))

(= example-jobid* nil)

(def example-jobid (example-spec)
  (alref-iso example-jobid* example-spec))

(def register-example (example-spec jobid)
  (= example-jobid*
     (cons (list example-spec jobid)
           (rem [iso _ example-spec] example-jobid*))))

(def chomp-left (s)
  (if (begins s "\n")
       (cut s 1)
       s))

(def chomp-right (s)
  (if (endmatch "\n" s)
       (cut s 0 (- (len s) 1))
       s))

(def chomp-both (s)
  (chomp-right (chomp-left s)))

(def display-expr (expr)
  (pr "arc> ")
  (each c (chomp-both expr)
    (if (is c #\newline)
         (do (prn)
             (pr "     "))
         (pr c)))
  (prn))

(def render-example-input-output (eval)
  erp.eval
  (tag pre
    (pr-escaped:tostring
     (display-expr eval!input)
     (only.disp eval!output!stdout)
     (only.disp eval!output!value))))
  
(def render-example-eval (eval)
  (erp eval)
  (render-example-input-output eval)
  (aif (alref eval!output 'error)
        (tag i (pr-escaped it))))

(def display-example (expr result)
  (tag blockquote (render-example-ioe expr result)))

(def capture-recipe (recipe exprs)
  (join (lookup-recipe recipe)
        (list 'evalto/output.arc%hvbVQKQwi1gPcDto
              'evalto/capture.arc%oDAdLy1Yawmj09ik
              `((apply load)
                (name "run.arc")
                (contents ,(tostring
                            (each expr exprs
                              (write `(output ,expr))
                              (prn))
                            (write '(quit))
                            (prn)))))))

(def create-example (recipe exprs)
  (let recipe (capture-recipe recipe exprs)
    (run-recipe "/tmp/example" recipe)
    nil))

(= job-status* (table))
(= job-for* (table))
(= jobs-need-doing* nil) ;; todo remove

(def launch-example-job (example)
  (let id example!id
    (= job-status*.id 'queued)
    (let job
        `((jobid ,id)
          ;; (eval (evalrecipe ',(capture-recipe example!recipe example!exprs))))
          (exprs ,example!exprs)
          (callback "https://localhost/result"))
      (givework job))
    id))

(def launch-example-job-if-needed (spec)
  (atomic
   (or (example-jobid spec)
       (launch-example-job spec))))

;; todo garbage collection of old jobs

(= job-result* (table))
(= job-result-channel* (table))
(= job-process-id* (table))

(def record-job-result (jobid results)
  (ero "recording job result" jobid results)
  (erp job-process-id*.jobid)
  (atomic
   (= job-status*.jobid 'done)
   ;; todo accumulate results
   ;(wr (alset (objs* jobid) 'results results))))
   (= job-result*.jobid results)
   (send-channel job-result-channel*.jobid
     (obj kind "job_result"
          jobid jobid
          for   job-for*.jobid
          results (map listtab results)))))

(def display-job-progress (spec status)
  (tag blockquote
    (tag pre
      (pr-escaped:string (display-expr (car spec!exprs))))
    (when (cdr spec!exprs)
      (pr "...")
      (br))
    (tag (span style "color: green")
      (pr "job status: ")
      (pr-escaped (string status)))))

(def display-job-conclusion (example)
  (let evals example!evals
    (if (is evals 'killed)
         (tag (blockquote style "color: red")
           (pr "Process killed (failed to run, or out of memory or CPU time...)"))
         (do (tag (div style "margin-bottom: 1em") (pr-escaped example!desc))
             (map render-example-eval evals)))))

(def render-example-block (example)
  (erp example)
  ;;(aif example!result
  (display-job-conclusion example))

;;        (let status (job-status* example!id)
;;          (if (no status)
;;               (tag (blockquote style "color: red")
;;                 (pr "job lost for this example"))
;;              (in status 'queued 'running)
;;               (display-job-progress example status)
;;               (tag (pre style "color: red")
;;                 (pr-escaped (tostring (write status))))))))

;; (def go ()
;;   (example "EtnyaWdfeCaZCZtV"
;;            (list #<<Z
;; (scheme (let ((a 3))
;;           (+ a 20)))
;; Z
;; ))
;;  nil)
