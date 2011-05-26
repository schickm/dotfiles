;;;
;;; interface/general emacs stuff
;;;

(tool-bar-mode -1)
(menu-bar-mode 0)
(scroll-bar-mode nil)

(add-to-list 'load-path "~/.emacs.d/site-lisp/")

(require 'windmove)
;(windmove-default-keybindings 'shift)
(global-set-key "\M-e" 'windmove-left)
(global-set-key "\M-u" 'windmove-right)
(global-set-key "\M-k" 'windmove-up)
(global-set-key "\M-j" 'windmove-down)

;; ido for extra madness
(require 'ido)

;; browse docs in w3m in emacs
(require 'w3m-load)
(setq browse-url-browser-function 'w3m)

;; enable tramp for root editing
(require 'tramp)
(setq tramp-default-method "scp")

;; ignore svn dirs when grepping
(setq grep-find-command 
  "find . -type f '!' -wholename '*/.svn/*' -print0 | xargs -0 -e grep -nH -e ")

;; sweet buffer swapping action http://www.emacswiki.org/cgi-bin/wiki/buffer-move.el
(require 'buffer-move)
(global-set-key (kbd "<C-S-up>")     'buf-move-up)
(global-set-key (kbd "<C-S-down>")   'buf-move-down)
(global-set-key (kbd "<C-S-left>")   'buf-move-left)
(global-set-key (kbd "<C-S-right>")  'buf-move-right)

;;; make stuff pretty
(require 'color-theme)
(require 'color-theme-tango)
(color-theme-tango)

;; defaults for windows
(setq default-frame-alist
      '((scroll-bar-width . 5)))

;; startup edit server for interacting with other apps
(if (locate-library "edit-server")
    (progn
      (require 'edit-server)
      (setq edit-server-new-frame nil)
      (edit-server-start)))


;;;
;;; flymake
;;;

(load-library "flymake-cursor")


;;;
;;; lua
;;;

(setq auto-mode-alist (cons '("\.lua$" . lua-mode) auto-mode-alist))
(autoload 'lua-mode "lua-mode" "Lua editing mode." t)

;;;
;;; lisp
;;;

;; paredit always for lisp code
(autoload 'paredit-mode "paredit"
  "Minor mode for pseudo-structurally editing Lisp code." t)
(add-hook 'lisp-mode-hook (lambda () (paredit-mode +1)))

;; autoindent always for lisp code
(add-hook 'lisp-mode-hook '(lambda ()
      (local-set-key (kbd "RET") 'newline-and-indent)))

;; slime
(global-set-key "\C-cs" 'slime-selector)
(setq inferior-lisp-program "/usr/bin/sbcl")

; try to get specified location of webcheckout
(setq webco-dir (getenv "WEBCO_DIR"))
; default to the symlink
(unless webco-dir
  (setf webco-dir "~/web-co"))  

(add-to-list 'load-path (format "%s/production/third-party-source/slime" webco-dir))
(setq inferior-lisp-program (format "%s/production/bin/devel.sh" webco-dir))

(eval-after-load "slime"
'(progn
  (setq common-lisp-hyperspec-root "file:/usr/share/doc/HyperSpec/")
  (slime-setup '(slime-asdf
		 slime-banner
		 slime-fancy
		 slime-indentation
		 slime-package-fu
		 slime-sbcl-exts
		 slime-xref-browser))
  (slime-autodoc-mode)
  (setq slime-startup-animation nil)
  (setq slime-complete-symbol*-fancy t)
  (setq slime-complete-symbol-function 'slime-fuzzy-complete-symbol
   lisp-indent-function 'common-lisp-indent-function)
  (add-hook 'lisp-mode-hook (lambda () (slime-mode t)))))

(require 'slime)

;;; 
;;; python
;;;

(setq
 python-shell-interpreter "ipython"
 python-shell-interpreter-args ""
 python-shell-prompt-regexp "In \\[[0-9]+\\]: "
 python-shell-prompt-output-regexp "Out\\[[0-9]+\\]: "
 python-shell-completion-setup-code ""
 python-shell-completion-string-code
 "';'.join(__IP.complete('''%s'''))\n")

(require 'python)

;; autoindent always for python code
;; and bind flymake next/prev to sane defaults
(add-hook 'python-mode-hook '(lambda ()
			      (local-set-key (kbd "RET") 'newline-and-indent)
			      (local-set-key (kbd "M-n") 'flymake-goto-next-error)
			      (local-set-key (kbd "M-p") 'flymake-goto-prev-error)))

(when (load "flymake" t)
  (defun flymake-pylint-init ()
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           (local-file (file-relative-name
                        temp-file
                        (file-name-directory buffer-file-name))))
      (list "~/.emacs.d/pyflymake.py" (list local-file))))

  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.py\\'" flymake-pylint-init)))

(add-hook 'python-mode-hook 'flymake-mode)
(add-hook 'find-file-hook 'flymake-find-file-hook)

;;;
;;; javascript stuff
;;;

(require 'flymake-jslint)
(add-hook 'js-mode-hook
	  (lambda () 
	    (flymake-mode t)
	    (local-set-key (kbd "RET") 'newline-and-indent)
	    (local-set-key (kbd "M-n") 'flymake-goto-next-error)
	    (local-set-key (kbd "M-p") 'flymake-goto-prev-error)))

;;;
;;; and custom stuff
;;;

(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(ido-enable-flex-matching t)
 '(ido-mode (quote both) nil (ido))
 '(lintnode-location "/home/matt/.emacs.d/lintnode")
 '(safe-local-variable-values (quote ((Package . HUNCHENTOOT) (Syntax . COMMON-LISP) (Encoding . utf-8) (Package . CL-USER) (Syntax . Common-Lisp) (Package . net\.html\.generator) (Package . imho) (Package . wco) (package . asdf) (Package . wco-framework) (Package . wco-framework-utils) (Package . odcl) (Package . wco-system) (Package . wcof) (Syntax . Ansi-Common-Lisp) (Package . cl-user) (Base . 10) (Syntax . ANSI-Common-Lisp)))))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )
(put 'upcase-region 'disabled nil)
