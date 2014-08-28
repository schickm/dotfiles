;;; symlink emacs directory to ~/.emacs.d
;;; eg.  ln -s ~/Projects/dotemacs/emacs/ ~/.emacs.d

;;;
;;; interface/general emacs stuff
;;;

(tool-bar-mode -1)
(menu-bar-mode 0)
(scroll-bar-mode nil)
(setq-default indent-tabs-mode nil) ; spaces over tabs


(setq font-lock-verbose nil) ; prevent emacs from waiting to fontify things

(set-face-font 'default "Consolas-13.0")

(add-to-list 'load-path "~/.emacs.d/site-lisp/")

(setq-default line-spacing 2)



(require 'windmove)
;(windmove-default-keybindings 'shift)
(global-set-key "\M-e" 'windmove-left)
(global-set-key "\M-u" 'windmove-right)
(global-set-key "\M-k" 'windmove-up)
(global-set-key "\M-j" 'windmove-down)

;; ido for extra madness
(require 'ido)
(ido-mode t)

;; place backup files in temp directory
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))



;; ignore svn dirs when grepping
(setq grep-find-command
  "find . -type f '!' -wholename '*/.svn/*' -print0 | xargs -0 -e grep -nH -e ")

;; sweet buffer swapping action http://www.emacswiki.org/cgi-bin/wiki/buffer-move.el
(require 'buffer-move)
(global-set-key (kbd "<C-S-up>")     'buf-move-up)
(global-set-key (kbd "<C-S-down>")   'buf-move-down)
(global-set-key (kbd "<C-S-left>")   'buf-move-left)
(global-set-key (kbd "<C-S-right>")  'buf-move-right)

;; defaults for windows
(setq default-frame-alist
      '((scroll-bar-width . 5)))


;;;
;;; lisp/paredit
;;;

;; paredit always for lisp code
(autoload 'paredit-mode "paredit"
  "Minor mode for pseudo-structurally editing Lisp code." t)
(add-hook 'lisp-mode-hook
          (lambda ()
            (paredit-mode +1)
            (setq autopair-dont-activate t)
            (local-set-key (kbd "RET") 'newline-and-indent)
            (slime-mode t)))

(add-hook 'lisp-interaction-mode-hook
          (lambda ()
            (paredit-mode +1)))
(add-hook 'emacs-lisp-mode-hook
          (lambda () 
            (paredit-mode +1)
            (local-set-key (kbd "RET") 'newline-and-indent)))

(put 'if-bind 'common-lisp-indent-function '3)





;;;
;;; elisp
;;;

(global-set-key (kbd "C-h C-f") 'find-function)

(require 'trace)

(defun trace-function-background-with-default (function)
  "Call trace-function-background but grab default value from cursor position."
  (interactive
   (list
    (intern
     (completing-read "Trace function in background: " obarray 'fboundp t
                      (symbol-name (variable-at-point t))))))
  (trace-function-background function))

(global-set-key (kbd "C-h C-t") 'trace-function-background-with-default)


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ido-everywhere t)
 '(safe-local-variable-values (quote ((Package . wco) (Package . imho) (Package . wcof) (Base . 10) (Syntax . Ansi-Common-Lisp)))))
