(attribute div id opstring)

(def connector-instructions (process-id)
  (tag (div id "connector_instructions" style "margin-left: 2em")
    (pr "To start the process, download ")
    (link "connector.ss" (url "/connector.ss" process process-id))
    (pr " to your Arc 3.1 directory and run:")
    (br)
    (tag (pre style "margin: 1em 0 1em 2em")
      (pr "racket -f connector.ss"))))

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

 ;;

(def autopr (args)
  (map [if (isa _ 'string) `(pr ,_) _] args))

(mac faqp body
  `(tag (p style "margin-left: 2em") ,@(autopr body)))

(mac faq (q . ps)
  `(do (tag p (pr ,q))
       ,@(map (fn (p) `(faqp ,@p)) ps)))

(def discuss ()
  (tag p (pr "Discuss"))
  (tag (p style "margin-left: 2em")
    (pr "Join the conversation about eval.to on ")
    (link "Convore" "https://convore.com/evalto/")
    (pr ".")))

(def bugs ()
  (tag p (pr "Current Bugs"))
  (tag ul
    (tag li (pr "The connector only supports Arc 3.1, and only loads arc.arc at that."))
    (tag li (pr "Due to my overly simplistic longpoll implementation the browser page loading indicator spins constantly in webkit browsers such as Chrome.  (The REPL still works though)."))
    (tag li (pr "In Firefox the text cursor is invisible unless you click outside the code box and back inside again.  (Apparently this is a known bug with Firefox and CodeMirror)."))))

(def faqs ()
  (tag p (pr "FAQ"))

  (faq "What does this site do?"
       ("It provides a browser based REPL connected to an Arc instance that you run in the computer and environment of your choice.  Since the REPL is hosted from the website, a transcript of the REPL can easily be captured and shared as a programming language example."))

  (faq "Can I have someone else open the same REPL window at the same time, if I send them the URL to the REPL page?"
       ("Yes.  The system isn't clever enough yet to copy the REPL history into the new REPL page so that both people see the same thing.  But expressions typed in either browser page will go to the same connected Arc instance."))

  (faq "Can I connect two different Arc instances to the same REPL?"
       ("No.  You can of course run two different REPL's separately connected to two different Arc instances.  But having two Arc instances connect to the same REPL will confuse the system. (For example, in the implementation there's only one queue for expressions to deliver to the Arc instance)."))
  
  (faq "What happens if the eval.to server is restarted?"
       ("The state of the REPL is kept in memory so it will be lost when the server restarts.  Saved examples are stored on disk though."))

  (faq "What are the security implications of using eval.to?"
       ("Because the expressions you type in go through the website, an attacker who subverts eval.to could substitute their own code to run in your Arc process.  (And, since Arc provides full access to the operating system, this in turn would allow arbitrary code execution in the user account that you're running Arc in)."))
  
  (faq "What about using eval.to over an insecure internet connection, such as WIFI in a coffee shop?"
       ("Both the browser REPL and the connection from the Arc instance are over SSL, so that's no problem."))
  
  (faq "How does the downloaded connector know which REPL to connect to?"
       ("The connector code contains the secret key which allows it to retrieve expressions typed in to that particular REPL."))
  
  (faq "Why embed the key in the connector code, instead of running the connector with the key as a command line argument? (It's inconvenient to have to download the connector each time)."
       ("There will need to be different kinds of connectors (for different variants of Arc, to load different libraries, or to capture what's important to get for an illustrative example), so automating downloading the connector code is the part to work on to make it more convenient."))

  (faq "Is source code to eval.to available?"
       ("Yes, on " (link "github" "https://github.com/awwx/evalto")
        ", released under the "
        (link "MIT open source license" "http://opensource.org/licenses/mit-license")
        "."))
  )  
  

(defop-base ||
  (html-content)
  (html-page (al title "eval.to" css (list css*))
    (header)
    ;;(when (logged-in-user)
    (tag p (pr "Run and share Arc code examples from your browser."))
    (form-button "start new repl" (launch-new-repl))
    (br)
    (discuss)
    (bugs)
    (faqs)
    ))


(def connector_ss ()
  (text-content)
  (write `(define evalto-url* ,evalto-url*)) (prn)
  (write `(define process-id* ,(arg "process"))) (prn)
  (pr (filechars (string source* "/connector.ss"))))

(defop-base connector.ss
  (connector_ss))
