;; (def delete-name (pagename)
;;   (must-be-logged-in
;;     (wipe (pagenames* (list user!id pagename)))
;;     (todisk pagenames*)
;;     (redirect "/pagelist")))

;; (def render-wikipage (page users-pagename)
;;   (html-page `((title ,page!title)
;;                (css (,css*)))
;;     (header)
;;     (aif users-pagename (tag h1 (pr-escaped it)))
;;     (aif page!title (tag h2 (pr-escaped it)))
;;     (on-err
;;      (fn (e)
;;        (br)
;;        (tag (div style "color: red")
;;          (pr-escaped (details e))))
;;      (fn ()
;;        (renders (readall page!content))))
;;     (br)
;;     (tag table (tag tr
;;       (tag td
;;         (form-button (if users-pagename "edit" "clone")
;;           (redirect (url "/edit-wiki-page" from page!id name users-pagename))))
;;       (when users-pagename
;;         (tag td
;;           (form-button "delete" (delete-name users-pagename))))))))

;; (def user-pages (userid)
;;   (sort (fn (a b) (< a.0 b.0))
;;         (map [list _.0.1 _.1]
;;              (keep [is caar._ userid]
;;                    (tablist pagenames*)))))

;; (def pagelist (foruser)
;;   (html-page (al title foruser!name
;;                  css (list css*))
;;     (header)
;;     (tag h2 (pr-escaped foruser!name))
;;     (tag table
;;       (each (name id) (user-pages foruser!id)
;;         (let page (objs* id)
;;           (tag tr
;;             (tag td (link name (str "/u/" foruser!usernum "/" name)))
;;             (tag td (pr-escaped page!title))))))
;;     (when (is ((logged-in-user) 'id) foruser!id)
;;       (br)
;;       (link "create new page" "/edit-wiki-page"))))

(def bailf (code msg)
  (prn (case code 404 nfheader* (err "code" code)))
  (prn)
  (prn msg))

(mac bail (code msg)
  `(do (bailf ,code ,msg)
       (throw nil)))

;; (def wikipage (usernum pagename)
;;   (catch
;;    (let user (usernum-user* (int usernum))
;;      (unless user (bail 404 "unknown user"))
;;      (if (is pagename "")
;;           (pagelist user)
;;           (let page (aand (pagenames* (list user!id pagename)) (objs* it))
;;             (unless page (bail 404 "no page by that name"))
;;             (render-wikipage page
;;                              (aand (logged-in-user) (is it!id user!id)
;;                                    pagename)))))))

(attribute textarea id opstring)

;; (def preprocess-wiki-page (page)
;;   (errsafe (render-wikipage nil)))

;; (def save-wiki-page (frompageid)
;;   (must-be-logged-in
;;    (catch
;;     ;; todo validate fields are non empty etc
;;     (let page (wr (al id (newid)
;;                       kind 'page
;;                       title (nonblank (trim (arg "title") 'both))
;;                       content (rem #\return (arg "code"))
;;                       edited-from frompageid))
;;       (let name (nonblank (trim (arg "name") 'both))
;;         (when name
;;           (= (pagenames* (list user!id name)) page!id)
;;           (todisk pagenames*))
;;         (preprocess-wiki-page page)
;;         (redirect (if name
;;                        (str "/u/" user!usernum "/" name)
;;                        (str "/" page!id))))))))

;; (defop-base edit-wiki-page
;;   (must-be-logged-in
;;    (catch
;;     (let page (check (aand (okid (arg "from")) (objs* it))
;;                      [is _!kind 'page])
;;       (html-page (al title "Edit Page"
;;                      jsref '("https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"
;;                              "/static/codemirror-0.93/codemirror.js"
;;                              "/static/codemirror-0.93/mirrorframe.js"
;;                              "/static/codemirror-0.93/edit.js")
;;                      cssref '("/static/codemirror-0.93/line-numbers.css")
;;                      css (list css*)
;;                      js '("
;; $(function () {
;;   initialize_editor();
;; });
;;     ")
;;                      )
;;         (header)
;;         (baform (fn () (save-wiki-page page!id))
;;           (br)
;;           (pr "name:")
;;           (br)
;;           (input "name" (or (nonblank (arg "name")) (rand-string 10)) 20)
;;           (br2)
;;           (pr "title:")
;;           (br)
;;           (input "title" page!title 40)
;;           (br2)
;;           (tag (div style "border-top: 1px solid black; border-bottom: 1px solid black")
;;             (tag (textarea id "code" name "code")
;;               (pr-escaped page!content)))
;;           (submit "save")))))))

(def argid (name)
  (okid (nonblank (trim (arg name) 'both))))

;; (def codeindex (name)
;;   (int (begins-rest "code" name)))

;; (def codekeys ()
;;   (sort (fn (a b) (< (codeindex a) (codeindex b)))
;;         (keep [begins _ "code"] (keys req!args))))

;; (def codeexprs ()
;;   (rem nil (map (fn (key)
;;                   (aand (arg key)
;;                         (nonblank it)
;;                         (rem #\return it)))
;;                 (codekeys))))
       
;; (def run-input (inp)
;;   (let example (wr (al id     (newid)
;;                        kind   'example
;;                        recipe inp!recipe
;;                        exprs  inp!exprs))
;;     (launch-example-job example)
;;     (redirect (str "/" example!id))))

;; (def render-input (inp)
;;   (html-page `((title "input")
;;                (css (,css*)))
;;     (header)
;;     (tag h1 (pr "input"))
;;     (tag p (pr "recipe: " inp!recipe))
;;     (tag table
;;       (each expr inp!exprs
;;         (tag tr
;;           (tag td
;;             (tag pre
;;               (pr-escaped expr))))))
;;     (form-button "run" (run-input inp))
;;     ))

(def render-example (example)
  (html-page `((title "example")
               (css (,css*)))
    (header)
    (tag (div style "margin: 1em 0 0.5em 0")
      (tag (span style "font-size: larger; font-weight: bold")
        (pr "example"))
      (pr " ")
      (tag (span style "font-size: smaller") (pr example!id)))
    (render-example-block example)))

(def json-content ()
  (pr "HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Connection: close

"))

;; (defop-base example-data
;;   (catch
;;    (let example (aif (erp (okid (arg "id"))) objs*.it)
;;      erp.example
;;      (unless (and example (is example!kind 'example))
;;        (bail 404 "not found"))
;;      (json-content)
;;      (tojson (obj id example!id
;;                   kind "example"
;;                   recipe example!recipe
;;                   exprs (map (fn (inp result)
;;                                (list inp (listtab (map (fn ((k v))
;;                                                          (list (if (is k 'result) 'value (is k 'out) 'stdout k) v))
;;                                                        result))))
;;                              example!exprs
;;                              example!result)
;;                   status (job-status* example!id)
;;                   )))))

;; (def save-input (example-id)
;;   (must-be-logged-in
;;    (catch
;;     (let example (wr (al id     (newid)
;;                          kind   'input
;;                          recipe (argid "recipe")
;;                          exprs  (codeexprs)))
;;       (redirect (str "/" example!id))))))
                     
;; (defop-base edit-input
;;   (must-be-logged-in
;;    (catch
;;     (let inp (check (aand (okid (arg "from")) (objs* it))
;;                     [is _!kind 'input])
;;       (html-page (al title "Edit Input"
;;                      jsref '("https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"
;;                              "/static/codemirror-0.93/codemirror.js"
;;                              "/static/codemirror-0.93/mirrorframe.js"
;;                              "/static/codemirror-0.93/edit.js")
;;                      ;; cssref '("/static/codemirror-0.93/line-numbers.css")
;;                      ;; css (list css*)
;;                      js '("
;; $(function () {
;;   initialize_editor(document.getElementById('code1'));
;;   initialize_editor(document.getElementById('code2'));
;; });
;;     ")
;;                      )
;;         (header)
;;         (baform (fn () (save-input inp!id))
;;           (br)
;;           (pr "recipe id:")
;;           (br)
;;           (input "recipe" inp!recipe-id 20)
;;           (br2)
;;           (tag (div style "border-top: 1px solid black; border-bottom: 1px solid black")
;;             (tag (textarea id "code1" name "code1")
;;               (pr-escaped inp!code1)))
;;           (br2)
;;           (tag (div style "border-top: 1px solid black; border-bottom: 1px solid black")
;;             (tag (textarea id "code2" name "code2")
;;               (pr-escaped inp!code2)))
;;           (submit "save")))))))

;; (def auserpage (op)
;;   (match (str op)
;;     (accum a
;;       (mliteral "u/")
;;       (a (str (many1 (one digit))))
;;       (mliteral "/")
;;       (a (str pos*)))))

;; (defrule respond (auserpage req!op)
;;   (w/req req
;;     (wikipage (car it) (cadr it))))

(def display-page (id)
  (catch
   (let x (objs* id)
     (unless x (bail 404 "not found"))
     (case x!kind
       ;; page    (render-wikipage x nil)
       ;; input   (render-input x)
       example (render-example x)
             (bail 404 "hmm, don't know how to render this")))))

(defrule respond (okid (str req!op))
  (w/req req
    (display-page it)))

(def wiki-header-links ()
  (whenlet user (logged-in-user)
    (list (tostring (link user!name (str "/u/" user!usernum "/"))))))

(def scramp (x)
  (tag div (pr-escaped (tostring (write x)))))
