(attribute div id opstring)

(def connector-instructions (process-id)
  (tag (div id "connector_instructions" style "margin-left: 2em")
    (pr "To start the process, download ")
    (link "connector.ss" (url "/connector.ss" process process-id))
    (pr " to your Arc 3.1 directory and run:")
    (br)
    (tag (pre style "margin: 1em 0 0.5em 2em")
      (pr "racket -f connector.ss"))
    (tag p
      (pr "Note the connector allows this website to execute arbitrary code on the computer running the connector.  If you'd rather not do this on your own personal computer, you may wish to use a virtual machine or an Amazon EC2 instance, etc."))))

(def render-repl (process-id job-queue)
   (let channelid (new-channel)
     (add-channel-listener job-queue
       (fn (job-channel-id status)
         (send-channel channelid
           (obj kind "process_status"
                process_name process-desc*.process-id
                status (subst " " "-" (str status))))))
     (html-content)
     (html-page
      (al title "repl"
          jsref '("https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"
                  "/static/codemirror-0.93/codemirror.js"
                  "/static/codemirror-0.93/mirrorframe.js")
          cssref '("/static/codemirror-0.93/line-numbers.css")
          css (list css*)
          js (list (filechars (string source* "/repl.js"))
                   (str "evalto_url = " (tostring (tojson evalto-url*)) ";\n")
                   (str "process_id = " (tostring (tojson process-id)) ";\n")
                   (str "channel_id = " (tostring (tojson channelid)) ";\n")))
       (header)
       (br)
       (tag (textarea id "one-line-height" cols 10 rows 1 style "width: 100px; position: absolute; left: -200px; ")
         (pr "\n"))
       (connector-instructions process-id))))

(defop-base repl
  ;; (must-be-logged-in
  (let process-id (arg "process")
    (iflet job-queue (process-job-queue* process-id)
      (render-repl process-id job-queue)
      (do (html-content)
          (pr "Unknown or expired process id")))))

(def submit-job (process-id channelid forref exprs)
  (let jobid (newid)
    (let job `((jobid ,jobid)
               (exprs ,exprs)
               (callback ,(str evalto-url* "result")))
      (= job-for*.jobid forref)
      (= job-status*.jobid 'queued)
      (= job-result-channel*.jobid channelid)
      (givework process-id job))
    jobid))

(defop-base eval
  (with (processid (arg "process")
         channelid (arg "channel")
         forref    (arg "for")
         code      (arg "code"))
    (let jobid (submit-job processid channelid forref (list code))
      (text-content)
      (tojson jobid))))

(defop-base polljob
  (json-content)
  (let jobid (arg "jobid")
    (if (is job-status*.jobid 'done)
         (tojson (map listtab job-result*.jobid))
         (tojson 'false))))

(def launch-new-repl ()
  ;; (must-be-logged-in
  (let process-id (new-process "Arc 3.1 with only arc.arc loaded")
    (redirect (url "/repl" process process-id))))

(def process-evals (process-id)
  (accum a
    (each job (qlist (process-job-list* process-id))
      (map (fn (input output)
             (a (al input input output output)))
           job!exprs
           (job-result* job!jobid)))))

(defop-base save-example
  ;; (must-be-logged-in
  (let process-id (arg "process")
    (let example (wr (al id (newid)
                         kind 'example
                         desc process-desc*.process-id
                         evals (process-evals process-id)))
      (redirect (str "/" example!id)))))

(defop-base ||
  (html-content)
  (html-page (al title "eval.to")
    (header)
    (br)
    ;;(when (logged-in-user)
    (form-button "start new repl" (launch-new-repl))))


(def connector_ss ()
  (text-content)
  (write `(define evalto-url* ,evalto-url*)) (prn)
  (write `(define process-id* ,(arg "process"))) (prn)
  (pr (filechars (string source* "/connector.ss"))))

(defop-base connector.ss
  (connector_ss))
