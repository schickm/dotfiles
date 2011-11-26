;;;
;;; interface/general emacs stuff
;;;

(tool-bar-mode -1)
(menu-bar-mode 0)
(scroll-bar-mode nil)
(setq-default indent-tabs-mode nil) ; spaces over tabs

(setq mac-option-key-is-meta nil)
(setq mac-command-key-is-meta t)
(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'control)

(setq font-lock-verbose nil) ; prevent emacs from waiting to fontify things

(add-to-list 'load-path "~/.emacs.d/site-lisp/")

(set-default-font "-apple-Monaco-medium-normal-normal-*-13-*-*-*-m-0-iso10646-1")
(setq-default line-spacing 2)

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
;;(setq browse-url-browser-function 'w3m)

(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "chromium")

;; enable tramp for root editing
(require 'tramp)
(setq tramp-default-method "scp")

;; setup rudel for group editing
;(add-to-list 'load-path "~/.emacs.d/rudel-0.2-4/")
;(add-to-list 'load-path "~/.emacs.d/rudel-0.2-4/")
;(add-to-list 'load-path "~/.emacs.d/rudel-0.2-4/")
(load-file "~/.emacs.d/rudel-0.2-4/rudel-loaddefs.el")
(global-rudel-minor-mode 1)

;; ack

(add-to-list 'load-path "/path/to/ack-and-a-half")
(autoload 'ack-and-a-half-same "ack-and-a-half" nil t)
(autoload 'ack-and-a-half "ack-and-a-half" nil t)
(autoload 'ack-and-a-half-find-file-samee "ack-and-a-half" nil t)
(autoload 'ack-and-a-half-find-file "ack-and-a-half" nil t)
;; Create shorter aliases
(defalias 'ack 'ack-and-a-half)
(defalias 'ack-same 'ack-and-a-half-same)
(defalias 'ack-find-file 'ack-and-a-half-find-file)
(defalias 'ack-find-file-same 'ack-and-a-half-find-file-same)

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
(require 'color-theme-railscasts)
(color-theme-railscasts)

;; defaults for windows
(setq default-frame-alist
      '((scroll-bar-width . 5)))

;; irc for emacs (erc)
(require 'erc)
;; Interpret mIRC-style color commands in IRC chats
(setq erc-interpret-mirc-color t)

(require 'erc-match)
(setq erc-keywords '("matt"))
(setq erc-autojoin-channels-alist
          '(("irc.onshored.com" "#dev" "#playground" "#webco")))

(add-hook 'erc-mode-hook '(lambda ()
                           (setq browse-url-browser-function 'browse-url-generic
                                 browse-url-generic-program "chromium")
                           ;(set (make-local-variable 'browse-url-browser-function 'browse-url-generic
                           ;      browse-url-generic-program "google-chrome"))
                            ))

;;
;; Edit in Emacs google chrome plugin
;;

(if (locate-library "edit-server")
    (progn
      (require 'edit-server)
      (setq edit-server-new-frame nil)
      (edit-server-start)))


;;;
;;; yasnippet
;;;

(add-to-list 'load-path
	     "~/.emacs.d/plugins/yasnippet-0.6.1c")
(require 'yasnippet) ;; not yasnippet-bundle
(yas/initialize)
(yas/load-directory "~/.emacs.d/plugins/yasnippet-0.6.1c/snippets")


;;;
;;; autopair
;;;

(require 'autopair)
(defvar autopair-modes '(js-mode python-mode css-mode))
(defun turn-on-autopair-mode () (autopair-mode 1))
(dolist (mode autopair-modes)
  (add-hook (intern (concat (symbol-name mode) "-hook")) 'turn-on-autopair-mode))


;;;
;;; auto-complete
;;;
;(add-to-list 'load-path "~/.emacs.d/lib/auto-complete")
;(require 'auto-complete-config)
;(ac-config-default)

;(require 'ac-slime)


;; (defun jsn-slime-source ()
;;   (let* ((end (move-marker (make-marker) (slime-symbol-end-pos)))
;;   (beg (move-marker (make-marker) (slime-symbol-start-pos)))
;;   (prefix (buffer-substring-no-properties beg end))
;;   (completion-result (slime-contextual-completions beg end))
;;   (completion-set (first completion-result)))
;;     completion-set))

;; (defvar ac-source-slime '((candidates . jsn-slime-source)))


;;;
;;; flymake
;;;

(load-library "flymake-cursor")

(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(erc-input-face ((t nil)))
 '(erc-prompt-face ((t (:background "#aaa" :foreground "Black" :weight bold))))
 '(erc-timestamp-face ((t (:foreground "#555555" :weight bold))))
 '(flymake-errline ((((class color)) (:underline "OrangeRed"))))
 '(flymake-infoline ((((class color) (background dark)) (:underline "DarkGreen"))))
 '(flymake-warnline ((((class color)) (:underline "Yellow")))))


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
(add-hook 'lisp-mode-hook (lambda ()
                            (paredit-mode +1)
                            (setq autopair-dont-activate t)
                            (local-set-key (kbd "RET") 'newline-and-indent)
                            (slime-mode t)
                            (auto-complete-mode t)))

(put 'if-bind 'common-lisp-indent-function '3)

;;;
;;; slime
;;;

(global-set-key "\C-cs" 'slime-selector)
(set-language-environment "UTF-8")
(setf slime-net-coding-system 'utf-8-unix)

; try to get specified location of webcheckout
(setq webco-dir (getenv "WEBCO_DIR"))
; default to the symlink
(unless webco-dir
  (setf webco-dir "~/web-co"))

(add-to-list 'load-path (format "%s/lib/lisp/slime" webco-dir))
(setq inferior-lisp-program (format "%s/bin/devel.sh" webco-dir))

(make-directory "/tmp/slime-fasls/" t)

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
  (setq slime-compile-file-options '(:fasl-directory "/tmp/slime-fasls/"))
  (setq slime-complete-symbol*-fancy t)
  (setq slime-complete-symbol-function 'slime-fuzzy-complete-symbol
   lisp-indent-function 'common-lisp-indent-function)))

(add-hook 'slime-mode-hook
          '(lambda ()
            (define-key slime-mode-map (kbd "<f2>") 'find-tag)
            (define-key slime-mode-map (kbd "<f3>") 'tags-search)
            (define-key slime-mode-map (kbd "M-<f3>") 'tags-loop-continue)
            (define-key slime-mode-map (kbd "<f4>") 'tags-query-replace)))

(add-hook 'slime-mode-hook 'set-up-slime-ac)

(require 'slime)


;;;
;;; python
;;;

(setq
 python-shell-interpreter "ipython"
 python-shell-virtualenv-path "/home/matt/vc/env_emulsion/"
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
			      (add-hook 'before-save-hook 'delete-trailing-whitespace)
			      (local-set-key (kbd "M-n") 'flymake-goto-next-error)
			      (local-set-key (kbd "M-p") 'flymake-goto-prev-error)))

;; (defun flymake-create-temp-in-system-tempdir (filename prefix)
;;     (make-temp-file (or prefix "flymake")))

;; (when (load "flymake" t)
;;   (defun flymake-pylint-init ()
;;     (let* ((temp-file (flymake-init-create-temp-buffer-copy
;;                        'flymake-create-temp-in-system-tempdir))
;;            (local-file (file-relative-name
;;                         temp-file
;;                         (file-name-directory buffer-file-name))))
;;       (message temp-file)
;;       (list "~/.emacs.d/pyflymake.py" (list temp-file))))

;;    (add-to-list 'flymake-allowed-file-name-masks
;;                 '("\\.py\\'" flymake-pylint-init)))

;; (add-hook 'python-mode-hook 'flymake-mode)

(add-hook 'find-file-hook 'flymake-find-file-hook)


;;;
;;; django-mode
;;;

;; (require 'django-html-mode)
;; (require 'django-mode)
;; (yas/load-directory "~/.emacs.d/django-mode/snippets")

;; (add-hook 'django-mode-hook '(lambda ()
;; 			      (add-to-list 'auto-mode-alist '("\.html$" . django-html-mode))))


;;;
;;; pony-mode
;;;
(add-to-list 'load-path "~/.emacs.d/lib/pony-mode")
(require 'pony-mode)


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
 '(erc-modules (quote (autojoin button completion fill irccontrols list match menu move-to-prompt netsplit networks noncommands readonly ring scrolltobottom stamp track)))
 '(erc-prompt "===>")
 '(erc-track-exclude-types (quote ("JOIN" "NICK" "PART" "QUIT" "MODE" "333" "353")))
 '(eshell-aliases-file "/home/matt/.emacs.d/eshell/alias")
 '(ido-enable-flex-matching t)
 '(ido-mode (quote both) nil (ido))
 '(lintnode-location "/home/matt/.emacs.d/lintnode")
 '(safe-local-variable-values (quote ((Package . HUNCHENTOOT) (Syntax . COMMON-LISP) (Encoding . utf-8) (Package . CL-USER) (Syntax . Common-Lisp) (Package . net\.html\.generator) (Package . imho) (Package . wco) (package . asdf) (Package . wco-framework) (Package . wco-framework-utils) (Package . odcl) (Package . wco-system) (Package . wcof) (Syntax . Ansi-Common-Lisp) (Package . cl-user) (Base . 10) (Syntax . ANSI-Common-Lisp)))))

(put 'upcase-region 'disabled nil)
(put 'erase-buffer 'disabled nil)
