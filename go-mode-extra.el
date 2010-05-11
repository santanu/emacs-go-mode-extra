;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;To use this, 
;;1. First install the stock go-mode
;;   (available in your $GOROOT/misc/emacs directory).
;;
;;2. Then copy the go-mode-extra.el file to the same directory
;;   where the stock go-mode.el and go-mode-load.el files are
;;   kept.
;;
;;3. Add the following lines to your ~/.emacs file:
;;  (load "go-mode-extra")
;;  (add-hook 'go-mode-hook 'go-mode-extra)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun go-mode-extra ()
  ;; Define some shortcuts
  (define-key go-mode-map "\C-c\C-t" #'go-help-type)
  (define-key go-mode-map "\C-c\C-f" #'go-help-function)
  (define-key go-mode-map "\C-c\C-m" #'go-help-method)
  (define-key go-mode-map "\C-c\C-g" #'go-help-generic)
  (define-key go-mode-map "\C-c\C-d" #'go-help-doc)
  (define-key go-mode-map "\C-c\C-xf" #'gofmt)
  
  ;; List of Go packages installed (at the moment looks only 
  ;; for packages installed under $GOROOT/src/pkg)
  (setq go-package-list 
        (split-string 
         (shell-command-to-string
          "echo $(cd $GOROOT/src/pkg && find . -iname *.go | sed -e 's|^\./||g; s|/[^/]*\.go||g' | sort | uniq)")))
  
  (defun go-help (pkg &optional search exact)
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
    (with-help-window "go-help"
      ;;(set-variable 'help-window-select t t)
      (if exact
          (case exact
            (0 ;find in 'type's godoc $1 | grep "$2"
             (shell-command (concat "godoc " pkg " | grep '^ *type *" search "'") "go-help"))
            (1 ;find in 'func's
             (shell-command (concat "godoc " pkg " | grep '^ *func *" search "'") "go-help"))
            (2 ;find in 'method's
             (shell-command (concat "godoc " pkg " | grep '^ *func *(.*) *" search "'") "go-help"))
            (t
             (shell-command (concat "godoc " pkg " | grep '" search "'") "go-help")))
        (shell-command (concat "godoc " pkg " " search) "go-help"))))

  (defun go-help-type (pkg type)
    "Call go-help with 0 for the argument 'exact'"
    (interactive
     (list 
      (completing-read "pkg: " go-package-list)
      (read-string "function: " (current-word 1 1) (current-word 1 1))))
    (go-help pkg type 0))

  (defun go-help-function (pkg func)
    "Call go-help with 1 for the argument 'exact'"
    (interactive
     (list 
      (completing-read "pkg: " go-package-list)
      (read-string "function: " (current-word 1 1) (current-word 1 1))))
    (go-help pkg func 1))

  (defun go-help-method (pkg method)
    "Call go-help with 2 for the argument 'exact'"
    (interactive
     (list 
      (completing-read "pkg: " go-package-list)
      (read-string "method: " (current-word 1 1) (current-word 1 1))))
    (go-help pkg method 2))

  (defun go-help-generic (pkg search)
    "Call go-help with '(4) for the argument 'exact'"
    (interactive
     (list 
      (completing-read "pkg: " go-package-list)
      (read-string "search: " (current-word 1 1) (current-word 1 1))))
    (go-help pkg search '(4)))

  (defun go-help-doc (pkg name)
    "Call go-help with nil for the argument 'exact'"
    (interactive
     (list 
      (completing-read "pkg: " go-package-list)
      (read-string "search: " (current-word 1 1) (current-word 1 1))))
    (go-help pkg name)))

(provide 'go-mode-extra)
