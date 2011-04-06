(scheme (require racket/async-channel))

;; todo gc of old processes

(= process-desc* (table))
(= process-job-queue* (table))
(= process-job-list* (table))

(def new-process (desc)
  (let id (newid)
    (= process-desc*.id desc)
    (= process-job-queue*.id (new-channel))
    (= process-job-list*.id (queue))
    id))

(def givework (process-id job)
  (ero 'givework process-id job)
  (whenlet job-queue process-job-queue*.process-id
    (= (job-process-id* job!jobid) process-id)
    (send-channel job-queue job)
    (enq job process-job-list*.process-id)))

(def bad-request (message)
  (pr "HTTP/1.0 400 Bad Request
Content-Type: text/plain; charset=utf-8
Connection: close

")
  (pr message))

(defop-base getjob
  (let process-id (arg "process")
    (iflet job-queue process-job-queue*.process-id
      (do (text-content)
          (let r (longpoll-channel job-queue)
            (write r)))
      (do (bad-request "Unknown or expired process id")))))

(defop-base result
  (catch
   (withs (post    (read req!post)
           jobid   post!jobid
           results post!results)
     (unless (okid jobid)
       (bad-request "invalid jobid")
       (throw nil))
     (record-job-result jobid results)
     (text-content)
     (pr "thanks"))))

(defop-base foo
  (erp req)
  (text-content))
