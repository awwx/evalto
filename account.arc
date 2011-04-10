(def cook (k v (o persistent) (o secure))
  (push `((key ,k) (value ,v) (persistent ,persistent) (secure ,secure))
        req!cookies-to-set))

(def rmcook (k)
  (push `((key ,k) (remove t)) req!cookies-to-set))

(def pr-cookies ()
  (each cook req!cookies-to-set
    (when cook
      (if (!remove cook)
           (prn "Set-Cookie: " (!key cook) "=; expires=Thu, 01 Jan 1970 00:00:00 GMT")
           (do (pr "Set-Cookie: " (!key cook) "=" (!value cook))
               (when (!persistent cook)
                 (pr "; expires=Sun, 17-Jan-2038 19:14:07 GMT"))
               (when (!secure cook)
                 (pr "; secure"))
               (prn))))))

(def system* args
  (or (scheme.tnil (apply scheme.system* args))
      (err "system* failed" args)))

(def curl-http-get (url)
  (tostring:system* "/usr/bin/curl" "-s" "-S" url))

(def fetch-arclanguage-about (userid secret-code)
  (if real*
       (curl-http-get (string "http://arclanguage.org/user?id=" userid))
       secret-code))

(def add (lst item)
  (join lst (list item)))

(def link-arclang-account (userid arclang-account)
  (wr (alset (or (arclang-account* arclang-account)
                 (al id (newid)
                     kind 'arclang-account
                     account arclang-account
                     public t))
             'user userid)))

(def create-user ()
  (ret userid (newid)
    (wr (al id userid
            kind 'user
            usernum (newusernum)
            apikeys (list (newid))))))

(def user-from-arclang (arclang-account)
  (aif (arclang-account* arclang-account)
        it!user
        (ret userid (create-user)
          (link-arclang-account userid arclang-account))))

(def users-primary-apikey (userid)
  (car ((ob userid) 'apikeys)))
  
(attribute a target opstring)
(attribute script src opstring)
(attribute table id opstring)

(def apikey-user (apikey)
  (aand (okid apikey) (apikeys* it)))

(def logged-in-user ()
  (aif (alref req!cooks "apikey") (apikey-user it)))

(def login-user (userid)
  (cook 'apikey (users-primary-apikey userid) t nil))

(def claim-step3 (arclang-userid)
  (let user
       (atomic
        (iflet user (logged-in-user)
          (do (link-arclang-account user!id arclang-userid)
              (redirect "/account"))
          (let userid (user-from-arclang arclang-userid)
            (login-user userid)
            (redirect (if ((objs* userid) 'name)
                           "/"
                           "/edit-account-name")))))))
         
(def claim-step3-check (userid code)
  (let about (fetch-arclanguage-about userid code)
    (if (posmatch code about)
         (claim-step3 userid)
         (do (html-content)
             (pr "Please ensure that the code is present in the \"about\" section of your arclanguage.org profile.")))))

(def claim-step2 (userid)
  (let code (newid)
    (html-page (al css (list css*))
     (tag h1 (pr "Claim your arclanguage.org user id"))
     (tag h2 (pr "Step two"))
     (tag p (pr "Copy and paste this code:"))
     (tag (blockquote style "font-family: monospace;") (pr-escaped code))
     (tag p
       (pr "into the \"about\" box of your arglanguage.org ")
       (tag (a href (string "http://arclanguage.org/user?id=" userid) target '_blank)
         (pr "account"))
       (pr "."))
     (tag p
       (pr "Note that it doesn't matter if someone else sees the code, since it will only work from this browser. Also, you'll be able to remove the code from your profile after this next step."))
     (baform (fn () (claim-step3-check userid code))
       (submit "next")))))


(def claim-step2-check ()
  (let userid (trim (arg req "userid") 'both)
    (if (blank userid)
         (do (text-content)
             (pr "Please enter a user id."))
         (claim-step2 userid))))

(def link-arclanguage-account ()
  (baform claim-step2-check
    (pr "Your user id on arclanguage.org:")
    (br)
    (input "userid")
    (br)
    (submit)))

(def login-using-apikey ()
  (iflet user (aand (okid (trim (arg "apikey") 'both))
                    (apikeys* it))
    (do (login-user user!id)
        (redirect "/"))
    (do (html-content)
        (pr "invalid api key"))))

(defop-base login
  (html-page (al title "login" css (list css*))
   (tag h1 (pr "login via api key"))
   (baform login-using-apikey
     (pr "Your api key:")
     (br)
     (input "apikey" "" 18)
     (br)
     (submit))
   (br)
   (tag h1 (pr "login via arclanguage.org account"))
   (link-arclanguage-account)))

(def display-name (user)
  user!name)

(def account-header-links ()
  (aif (logged-in-user)
        (list (tostring (link "account" "/account"))
              (tostring (link "logout" "/logout")))
        (list (tostring (link "login" "/login")))))

(= apikey-js #<<Z
function show_apikey(i) {
  $('.truncated-apikey:eq(' + i + ')').hide();
  $('.full-apikey:eq(' + i + ')').show();
  $('.show-apikey:eq(' + i + ')').hide();
  $('.hide-apikey:eq(' + i + ')').show();
}

function hide_apikey(i) {
  $('.full-apikey:eq(' + i + ')').hide();
  $('.truncated-apikey:eq(' + i + ')').show();
  $('.hide-apikey:eq(' + i + ')').hide();
  $('.show-apikey:eq(' + i + ')').show();
}
Z
)

(mac form-button (title . action)
  `(baform (fn () ,@action) (but ,title)))

(mac must-be-logged-in body
  `(iflet user (logged-in-user)
     (do ,@body)
     ;; todo ref to original page
     (redirect "/login")))

(def add-apikey ()
  (must-be-logged-in
   (let new-apikey (newid)
     (atomic
      (wr (alset user 'apikeys (add user!apikeys new-apikey)))))
   (redirect "/account")))

(def move-to-front (lst index)
  (if (and (> index 0) (< index (len lst)))
       (join (list (lst index))
             (cut lst 0 index)
             (cut lst (+ index 1)))
       lst))

(def make-apikey-primary (index)
  (must-be-logged-in
   (atomic
    (wr (alset user 'apikeys (move-to-front user!apikeys index)))
    (login-user user!id))
   (redirect "/account")))

(def delete-apikey (index)
  (must-be-logged-in
   (atomic
    (let keys user!apikeys
      (if (and (> index 0) (< index (len keys)))
           (let key-to-delete (keys index)
             (wr (alset user 'apikeys
                        (join (cut keys 0 index)
                              (cut keys (+ index 1)))))
             ;; todo
             (wipe apikeys*.key-to-delete)))))
   (redirect "/account")))

(def apikeys-table (user)
  (on key user!apikeys
    ; ouch
    (let i index
      (tag tr
        (if (is index 0)
             (do (tag (td class "pad") (pr "api keys"))
                 (tag (td class "pad") (pr "(secret)")))
             (do (tag td)
                 (tag td)))
        (tag (td class "pad")
          (tag (span class "truncated-apikey")
            (tag code
              (pr-escaped (cut key 0 4))
              (pr "...")))
          (tag (span class "full-apikey" style "display: none")
            (tag code
              (pr-escaped key))))
        (tag (td class "pad")
          (tag (span class "show-apikey")
            (pr "(")
            (link "show" (str "javascript:show_apikey(" index ")"))
            (pr ")"))
          (tag (span class "hide-apikey" style "display: none")
            (pr "(")
            (link "hide" (str "javascript:hide_apikey(" index ")"))
            (pr ")")))
        (when (> index 0)
          (tag (td class "pad")
            (form-button "make primary" (make-apikey-primary i)))
          (tag (td class "pad")
            (form-button "delete" (delete-apikey i)))))))
  (tag tr
    (tag td)
    (tag td)
    (tag (td class "pad")
      (form-button "add api key" (add-apikey)))))

(def account-table (user)
  (tag h1 (pr "your account"))
  (tag table
   (tag tr
     (tag (td class "pad" style "padding-bottom: 1em")
       (pr "account id"))
     (tag (td class "pad")
       (pr "(public)"))
     (tag (td class "pad")
       (pr-escaped user!id)))
   (tag tr
     (tag (td class "pad" style "padding-bottom: 1em")
       (pr "name"))
     (tag (td class "pad")
       (pr "(public)"))
     (tag (td class "pad")
       (pr-escaped user!name))
     (tag (td class "pad")
       (pr " (")
       (link "edit" "/edit-account-name")
       (pr ")")))
   (apikeys-table user)))

(def linked-accounts-table (user)
  (tag h2 (pr "linked accounts"))
  (tag table
    (aif (user-arclang-accounts* user!id)
          (each arclangid it
            (let arclang (objs* arclangid)
              (tag tr
                (tag (td class "pad")
                  (pr "("
                      (if arclang!public "public" "secret")
                      ")"))
                (tag (td class "pad")
                  (pr "arclanguage.org: ")
                  (pr-escaped arclang!account)))))
          (tag tr
            (tag td)
            (tag (td class "pad") (pr "no linked accounts"))))))


(def account-page (user)
  (html-page (al title "your account"
                 css   (list css*)
                 jsref '("https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js")
                 js    (list apikey-js))
    (header)
    (account-table user)
    (linked-accounts-table user)))

(defop-base account
  (must-be-logged-in (account-page user)))

(defop-base logout
  (rmcook "apikey")
  (redirect "/"))

(def process-edit-account-name (user)
  (let name (nonblank (trim (arg "name")))
    (wr (alset user 'name name))
    (redirect "/")))

(defop-base edit-account-name
  (must-be-logged-in
    (html-content)
    (tag h1 (pr "Your name"))
    (baform (fn () (process-edit-account-name user))
      (pr "Your name (as you'd like other people to see it):")
      (br)
      (input "name" (or user!name
                        (aif (car (user-arclang-accounts* user!id))
                              ((objs* it) 'account)))
             20)
      (br2)
      (submit "next"))))
