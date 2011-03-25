(def http-get (options url query)
  (let result
       (run-program
        options!max-content-length
        `("/usr/bin/curl" "-s" "-S"
          "--include"
          ,@(aif options!max-content-length `("--max-filesize" ,(string it)))
          ,@(aif options!max-download-time `("--max-time" ,(string it)))
          ,@(if options!allow-invalid-ssl-certificate `("-k"))
          ,@(accum a (each (k v) query
                       (a "--data-urlencode")
                       (a (string k "=" v))))
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
