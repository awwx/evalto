;; todo non UTF-8 content, if we care
;; todo refetching url's that have changed or were temporarily
;; unavailable

(= cachedir* (str data* "cache"))
(disktable cache* (str data* "cachetab"))

(def relpathfor (url)
  (or (begins-rest "http://" url)
      (begins-rest "https://" url)
      (err "looking for http or https" url)))

(def lastpos (s c (o i (- (len s) 1)))
  (if (< i 0)
       nil
      (is (s i) c)
       i
       (lastpos s c (- i 1))))

(def dirpart (path)
  (aand (lastpos path #\/)
        (cut path 0 it)))

(def filepart (path)
  (aif (lastpos path #\/)
        (cut path (+ it 1))
        path))

(def file-extension (path)
  (let n (filepart path)
    (aif (lastpos n #\.)
          (cut n (+ it 1)))))
          
(= maxsize* (* 128 1024))

(def consume (s)
  (let result (list nil)
    (list (thread (= (car result) (allchars s)))
          result)))

;; todo error on invalid UTF-8

;; todo use run-program

(def cache-download (url)
  (let (outport inport process-id errport control)
       (scheme.process*
        "/usr/bin/curl" "-s" "-S"
        "--include"
        "--max-filesize" (str maxsize*)
        "--max-time" "60"
        url)
    (let (errthread errout) (consume errport)
      (let aborted nil
        ;; todo possible deadlock here if stderr pipe buffer
        ;; fills before all stdout content is read
        (let content
             (tostring:catch
              (let size 0
                (whilet c (readc outport)
                  (when (> (++ size) maxsize*)
                    (control 'kill)
                    (set aborted)
                    (throw nil))
                  (pr c))))
          (scheme.thread-wait errthread)
          (control 'wait)
          (if (or aborted (is (control 'exit-code) 63))
               'too-large
              (isnt (control 'exit-code) 0)
               (list 'exit-code (control 'exit-code)
                     'stderr (car errout))
              (fromstring content
                (let response-code (cadr (tokens (readline)))
                  (if (isnt (cut response-code 0 1) "2")
                       (list 'failed response-code)
                       (do (until (in (readline) "" nil) nil)
                           (list 'content (allchars (stdin)))))))))))))

(def cache-download (url)
  (let result
       (run-program
        maxsize*
        `("/usr/bin/curl" "-s" "-S"
          "--include"
          "--max-filesize" ,(str maxsize*)
          "--max-time" "60"
          ,url))
    (if (is result 'max-output-length-exceeded)
         result
        (caris result 'exit-code)
         result
        (caris result 'content)
         (fromstring (cadr result)
           (let response-code (cadr (tokens (readline)))
             (if (isnt (cut response-code 0 1) "2")
                  (list 'failed response-code)
                  (do (until (in (readline) "" nil) nil)
                      (list 'content (allchars (stdin))))))))))

(def cache-download (url)
  (http-get (al max-content-length maxsize*
                max-download-time 60)
            url nil))

(def request-download1 (url)
  (atomic
   (aif (cache* url)
         it
         (do (thread (let result (cache-download url)
                       (atomic
                        (= (cache* url) result)
                        (todisk cache*))))
             (= (cache* url) 'downloading)))))

(def request-download (url (o timeout-msec 1000))
  (let now (msec)
    (xloop ()
      (let r (request-download1 url)
        (if (is r 'downloading)
             (when (< (msec) (+ (msec) timeout-msec))
               (sleep 0.05)
               (next))
             r)))))

(def bad-host (host)
  (let host (downcase host)
    (let parts (tokens host #\.)
      (or (< (len parts) 2)
          (all digit (last parts))
          (some "localhost" parts)))))

(def validate-url (url)
  (let u (parse-url url)
    (if (no (in u!scheme 'http 'https))
         (err "only http and https url schemes are supported"))
    (if u!port
         (err "the port may not be specified"))
    (if (bad-host u!host)
         (err "invalid host"))
    (if (or u!query u!frag)
         (err "url query and fragment components are not supported"))
    (if (> (len url) 80)
         (err "url too long"))
    ))

(def fetch-url (url)
  (or (on-err (fn (c) (list 'invalid-url (details c))) (fn () nil))
      (request-download url)))
