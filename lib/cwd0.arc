(sref dynamic-parameter* scheme.current-directory 'cwd)
(defvar cwd
  (fn () (scheme (path->string (current-directory))))
  (fn (v) (scheme (current-directory v))))
(make-w/ cwd)
