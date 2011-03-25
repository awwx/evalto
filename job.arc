;; todo would be better not to have the key in the url?

(def jobdir (key jobid)
  (str "/home/evalto/job/" key "/" jobid "/"))

(def tarfile (key jobid)
  (str (jobdir key jobid) "job.tar"))

(def tarurl (key jobid)
  (str "https://localhost/job/" key "/" jobid "/job.tar"))

(def shurl (key jobid)
  (str "https://localhost/job/" key "/" jobid "/job.sh"))

(def recipe-tar (key jobid recipe)
  (let workdir (str "/tmp/" jobid)
    (run-recipe workdir recipe)
    (ensure-dir (jobdir key jobid))
    (system* "/bin/tar" "-c" "-C" "/tmp" "-f" (tarfile key jobid) jobid)))

(def job-script (key jobid)
  (str (map [str _ "\n"] (list
   "set -e"
   "rm -rf /tmp/work"
   "mkdir /tmp/work"
   "cd /tmp/work"
   (str "curl -k -s -S -O " (tarurl key jobid))
   "tar xf job.tar"
   (str "cd " jobid)
   "~/racket-5.0.2/bin/racket -f as.scm"
   ))))
 
(def create-job (key recipe)
  (let jobid (newid)
    (recipe-tar key jobid recipe)
    (w/outfile o (str (jobdir key jobid) "job.sh")
      (disp (job-script key jobid) o))
    jobid))

(def run-job (key jobid)
  (read:tostring:system*
   "/usr/bin/curl"
   "-s" "-S"
   "--data-urlencode" (str "jobid=" jobid)
   "--data-urlencode" (str "joburl=" (shurl key jobid))
   "--data-urlencode" (str "key=foo")
   "http://localhost:9000/job"))

;; todo I don't think caller needs to specify the key

(def create-and-run-job (key recipe)
  (let jobid (create-job key recipe)
    (let result (run-job key jobid)
      (if (caris result 'content)
           (al jobid jobid result (readall (cadr result)))
           result))))

(def foo ()
  (create-and-run-job
   "55HC348slnfewjRH"
   (capture-recipe "EtnyaWdfeCaZCZtV"
    (list "(+ 3 4)" "(* 6 7)"))))
