(scheme (require racket/async-channel))

(def timer (timeout f)
  (ret tm (obj)
    (thread (sleep timeout)
            (atomic (unless tm!canceled (f))))))

(def cancel-timer (tm)
  (atomic (set tm!canceled)))

(= channel* (table))

(= channel-status* (table))

(def new-channel ()
  (let id (newid)
    (= channel*.id (scheme.make-async-channel))
    (= channel-status*.id 'not-connected-yet)
    id))

(def channel (id)
  (or channel*.id (err "no channel" id)))

(= channel-listeners* (table))

;; careful, f is currently called within an atomic
;; (maybe should use an async channel instead)

(def add-channel-listener (id f)
  (atomic
   (f id channel-status*.id)
   (= channel-listeners*.id
      (cons f channel-listeners*.id))))

(= channel-timeout-timer* (table))

;; called within atomic

(def update-channel-status (id status)
  (unless (is channel-status*.id status)
    (= channel-status*.id status)
    (each listener channel-listeners*.id
      (listener id status))))

(def channel-active (id)
  (update-channel-status id 'connected))

(def channel-inactive (id)
  (update-channel-status id 'disconnected))

;; todo if the client closes their side of the TCP connection, that
;; should tell us that the channel has become inactive immediately...
;; or at least start the 5 second timeout timer

;; todo nothing prevents a buggy client from making *two* simultaneous
;; longpoll requests on the same channel id

(def longpoll-channel (id (o no-message))
  (atomic (awhen channel-timeout-timer*.id (cancel-timer it))
          (wipe channel-timeout-timer*.id)
          (channel-active id))
  (let channel channel.id
    (do1 (let r (scheme.sync/timeout 20.0 channel)
           (if (is r scheme-f) no-message r))
         (atomic
          (= channel-timeout-timer*.id
             (timer 5 (fn ()
                        (channel-inactive id)
                        (wipe channel-timeout-timer*.id))))))))

(def send-channel (id msg)
  (ero 'send-channel id msg)
  (let channel channel.id
    (scheme.async-channel-put channel msg)
    nil))

(defop-base longpoll-json
  (ero "longpoll-json")
  (catch
   (let r (on-err (fn (c)
                    (bad-request (details c))
                    (throw nil))
                  (fn ()
                    (longpoll-channel (arg "id") 'false)))
     (json-content)
     (tojson r))))
