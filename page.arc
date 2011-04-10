(def text-content ()
  (pr "HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Connection: close
")
  (pr-cookies)
  (prn))

;; todo once-only or something like it here would be nice

(mac html-page (attrs . body)
  (w/uniq a
    `(let ,a ,attrs
       (html-content)
       (prn "<!DOCTYPE html>")
       (tag html
         (tag head
           (prn "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">")
           (aif (alref ,a 'title)
                 (tag title (pr-escaped it)))
           (each cssref (alref ,a 'cssref)
             (prn "<link rel=\"stylesheet\" type=\"text/css\" href=\"" cssref "\">"))
           (each css (alref ,a 'css)
             (prn "<style>")
             (pr css)
             (prn "</style>"))
           (each jsref (alref ,a 'jsref)
             (prn "<script src=\"" jsref "\"></script>"))
           (each js (alref ,a 'js)
             (prn "<script>")
             (pr js)
             (prn "</script>")))
         (tag body
           ,@body)))))

(= css* "

body {
  font-family: verdana;
  margin: 0 2em;
}

h1 {
  font-size: large;
  font-weight: bold;
  margin-bottom: 0.3em;
}

h2 {
  font-weight: normal;
  font-size: large;
  margin-top: 1em;
}

h3 {
  font-size: medium;
  font-weight: bold;
  margin-bottom: 0;
}

h4 {
  font-style: italic;
  margin-top: 1em;
  margin-bottom: 0.5em;
}

p, ol, ul {
  max-width: 40em;
}

li {
  margin-bottom: 0.5em;
}

pre, code {
  font-family: courier, monospace;
}

.codefont {
  font-family: monospace;
  font-size: 10pt;
  white-space: pre-wrap;
}

pre {
  margin: 0;
}

blockquote {
  margin: 0 0 0 2em;
}

td {
  vertical-align: top;
}

.pad {
  padding: 0 0.5em 0 0.5em;
}

.green {
  color: #5f5;
}

.red {
  color: red;
}
")

(def header ()
  (tag (div style "background-color: #ddd; padding: 0.2em 0.5em")
    (map pr (intersperse " &nbsp;"
              (join (list (tostring (link "eval.to" evalto-url*)))
                    (wiki-header-links)
                    (account-header-links))))))
