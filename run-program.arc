;; todo Will deadlock if stderr pipe buffer fills before all stdout
;; content is read.

;; todo Assumes output is valid UTF-8 and crashes if it isn't.

;; todo Since we wait for the consume thread to terminate, this could
;; be more simply expressed as a promise instead of returning the raw
;; thread.  But will need to ensure that we can sync on the result to
;; fix the deadlock.

(def consume (s)
  (let result (list nil)
    (list (thread (let chars (allchars s)
                    (= (car result) chars)))
          result)))

(def run-program (max-output-length args)
  (let (outport inport process-id errport control)
       (apply scheme.process* args)
    (after
     (let (errthread errout) (consume errport)
       (let aborted nil
         (let content
              (tostring:catch
               (let size 0
                 (whilet c (readc outport)
                   (when (and max-output-length
                              (> (++ size) max-output-length))
                     (control 'kill)
                     (set aborted)
                     (throw nil))
                   (pr c))))
           (scheme.thread-wait errthread)
           (control 'wait)
           (if (or aborted)
                'max-output-length-exceeded
               (isnt (control 'exit-code) 0)
                (list 'exit-code (control 'exit-code)
                      'stderr (car errout))
                (list 'content content)))))
     (close outport)
     (close inport)
     (close errport))))
