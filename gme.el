;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;To use this, 
;;1. First install the stock go-mode
;;   (available in your $GOROOT/misc/emacs directory).
;;
;;2. Then copy the gme.el file to the same directory
;;   where the stock go-mode.el and go-mode-load.el files are
;;   kept.
;;
;;3. Add the following lines to your ~/.emacs file:
;;  (load "gme")
;;  (add-hook 'go-mode-hook 'gme)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gme ()
  ;; Define some shortcuts
  (define-key go-mode-map "\C-c\C-t" #'gme-help-type)
  (define-key go-mode-map "\C-c\C-f" #'gme-help-function)
  (define-key go-mode-map "\C-c\C-m" #'gme-help-method)
  (define-key go-mode-map "\C-c\C-g" #'gme-help-generic)
  (define-key go-mode-map "\C-c\C-d" #'gme-help-doc)
  (define-key go-mode-map "\C-c\C-xf" #'gofmt)
  
  ;; List of Go packages installed (at the moment looks only 
  ;; for packages installed under $GOROOT/src/pkg)
  (setq 
   go-packages-installed
   (split-string 
    (shell-command-to-string
     "echo $(cd $GOROOT/src/pkg && find . -iname *.go | sed -e 's|^\./||g; s|/[^/]*\.go||g' | sort | uniq)")))
  
  (defun gme-help (pkg &optional search exact)
    "Search the go documentation in package 'pkg' for regexp 'search'

The 'search' term is optional. If not provided, then the whole
'pkg' documentation is provided.  

'exact' determines what kind of search to perform.
If it is 0, searches for a go type matching regexp 'search', 
if it is 1, searches for a go function matching regexp 'search', 
if it is 2, searches for a go method matching regexp 'search'. 
For any other non-nil value, a generic search is made using the 
'search' regexp.

If 'exact' is nil, then an exact 'search' term is fed to
godoc, and the result obtained is the same as if the following
command is issued: godoc pkg search
"
    ;;This function no longer needs to be called interactively
    ;;(interactive "Mpkg: \nMsearch term: \nP")
    (with-help-window "gme-help"
      ;;(set-variable 'help-window-select t t)
      (if exact
          (case exact
            (0 ;find in 'type's godoc $1 | grep "$2"
             (shell-command (concat "godoc " pkg " | grep '^ *type *" search "'") "gme-help"))
            (1 ;find in 'func's
             (shell-command (concat "godoc " pkg " | grep '^ *func *" search "'") "gme-help"))
            (2 ;find in 'method's
             (shell-command (concat "godoc " pkg " | grep '^ *func *(.*) *" search "'") "gme-help"))
            (t
             (shell-command (concat "godoc " pkg " | grep '" search "'") "gme-help")))
        (shell-command (concat "godoc " pkg " " search) "gme-help"))))

  (defun gme-string-unquote (str)
    "Remove quotes from the given string"
    (replace-regexp-in-string "\"*\\([^\"]*\\)\"" "\\1" str))

  (defun gme-strings-unquote (str-list)
    "Unquote all strings in list"
    (mapcar #'string-unquote str-list))

  (defun gme-list-to-hash (l h)
    "Converts a list with even number of items to a hash table"
    (let ((k (car l))
	  (v (cadr l)))
      (if (null k)
	  h
	(progn
	  (puthash k v h)
	  (list-to-hash (cddr l) h)))))

  (defun gme-list-imports ()
    "Make a list of all go packages imported in current go file in buffer
using shell command 'goimports'"
    (strings-unquote
     (split-string
      (shell-command-to-string
       (concat "goimports " (expand-file-name (buffer-name)))))))

  (defun gme-hash-imports ()
    "Make a hash table out of the output from shell command 'goimports'
on the current go file in buffer"
    (let ((l (strings-unquote 
	      (split-string 
	       (shell-command-to-string 
		(concat "goimports -h " (expand-file-name (buffer-name)))))))
	  (h (make-hash-table)))
      (list-to-hash l h)))

  (defun gme-help-type (pkg type)
    "Call gme-help with 0 for the argument 'exact'"
    (interactive
     (list 
      (completing-read "pkg: " (gme-list-imports))
      (read-string "function: " (current-word 1 1) (current-word 1 1))))
    (gme-help pkg type 0))

  (defun gme-help-function (pkg func)
    "Call gme-help with 1 for the argument 'exact'"
    (interactive
     (list 
      (completing-read "pkg: " (gme-list-imports))
      (read-string "function: " (current-word 1 1) (current-word 1 1))))
    (gme-help pkg func 1))

  (defun gme-help-method (pkg method)
    "Call gme-help with 2 for the argument 'exact'"
    (interactive
     (list 
      (completing-read "pkg: " (gme-list-imports))
      (read-string "method: " (current-word 1 1) (current-word 1 1))))
    (gme-help pkg method 2))

  (defun gme-help-generic (pkg search)
    "Call gme-help with '(4) for the argument 'exact'"
    (interactive
     (list 
      (completing-read "pkg: " (gme-list-imports))
      (read-string "search: " (current-word 1 1) (current-word 1 1))))
    (gme-help pkg search '(4)))

  (defun gme-help-doc (pkg name)
    "Call gme-help with nil for the argument 'exact'"
    (interactive
     (list 
      (completing-read "pkg: " (gme-list-imports))
      (read-string "search: " (current-word 1 1) (current-word 1 1))))
    (gme-help pkg name)))

(provide 'gme)
