(= running-inside-evalto* t)

(= str string)

(= data* "/home/evalto/data/")
(= objdir* (str data* "objs/"))
(= pages*  (str data* "pages/"))

(ensure-dir objdir*)
(ensure-dir pages*)

(= objs* (table))

(def alset1 (al key val)
  (cons (list key val) (rem [is car._ key] al)))

(def alset (al . args)
  (each (key val) (pair args)
    (= al (alset1 al key val)))
  al)

(= usernum-user* (table))
(= arclang-account* (table))
(= apikeys* (table))
(= user-arclang-accounts* (table))
(= user-pagename-page* (table))
(= nickname* (table))

;; todo unindexing things 

(def user-index (m)
  (when (and (is m!kind 'user) m!usernum)
    (= (usernum-user* m!usernum) m)))

(def arclang-index (m)
  (when (is m!kind 'arclang-account)
    (= (arclang-account* m!account) m)
    (pushnew m!id (user-arclang-accounts* m!user))))

(def apikey-index (m)
  (when (is m!kind 'user)
    (each apikey m!apikeys
      (= apikeys*.apikey m))))

(def page-index (m)
  (when (is m!kind 'page)
    (= (user-pagename-page* (list m!owner m!name)) m)))

(def nickname-index (m)
  (when (is m!kind 'nickname)
    (= (nickname* (list m!user m!nickname)) m)))

(def index (m)
  (user-index m)
  (arclang-index m)
  (apikey-index m)
  (page-index m)
  (nickname-index m))

(each id (dir objdir*)
  (let d (readfile1 (str objdir* id))
    (let m (cons `(id ,id) d)
      (= objs*.id m)
      (index m))))

(def wr (m)
  (withs (id (or (okid m!id) (err "invalid id"))
          filename (str objdir* id)
          d (rem [is car._ 'id] m))
    (= (objs* id) m)
    (index m)
    (if d
         (writefile d filename)
         (rmfile filename))
    m))

(def ob (m)
  (if (isa m 'string)
       (or (objs* m) (err "no object found with id" m))
       m))

(def newusernum ()
  (let usernum (rand 1000000)
    (if (usernum-user* usernum)
         (newusernum)
         usernum)))

(def deepcopy-list (x)
  (if (no x)
       nil
      (acons x)
       (cons (deepcopy-list (car x))
             (deepcopy-list (cdr x)))
       x))

(fromdisk pagenames* (str data* "pagenames")
  (table)
  ;; blarg
  (fn (file)
    (w/infile i file (listtab (deepcopy-list (read i)))))
  save-table)
