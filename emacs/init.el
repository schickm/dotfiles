;;; symlink emacs directory to ~/.emacs.d
;;; eg.  ln -s ~/Projects/dotemacs/emacs/ ~/.emacs.d

;; override package loading setup and do things manually
(require 'package)
(setq package-enable-at-startup nil)
(package-initialize)



;;;
;;; interface/general emacs stuff
;;;

(tool-bar-mode -1)
(menu-bar-mode 0)
(scroll-bar-mode nil)
(setq-default indent-tabs-mode nil) ; spaces over tabs


(setq font-lock-verbose nil) ; prevent emacs from waiting to fontify things

;; Font stuff
(when (eq system-type 'darwin)  
  ;; default Latin font (e.g. Consolas)
  (set-face-attribute 'default nil :family "Consolas")
  
  ;; default font size (point * 10)
  ;;
  ;; WARNING!  Depending on the default font,
  ;; if the size is not supported very well, the frame will be clipped
  ;; so that the beginning of the buffer may not be visible correctly. 
  (set-face-attribute 'default nil :height 165))

(add-to-list 'load-path "~/.emacs.d/site-lisp/")

(setq-default line-spacing 2)

(global-auto-revert-mode t)

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

;; global key bindings, make command be meta and option be control
(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'ctrl)


(define-key global-map (kbd "C-x f") 'find-file-in-project)
(define-key global-map (kbd "RET") 'newline-and-indent)

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
;;; auto-complete
;;;
(require 'auto-complete)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/dict")
(require 'auto-complete-config)
(ac-config-default)

;;;
;;; autopair
;;;

(require 'autopair)



;;;
;;; web-mode
;;;

(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
(add-to-list 'ac-modes 'web-mode)
(defun my-web-mode-hook ()
  "Hooks for Web mode."
  (emmet-mode)
  (setq web-mode-markup-indent-offset 4)
  (setq web-mode-css-indent-offset 4)
  (setq web-mode-code-indent-offset 4)
  (setq web-mode-enable-current-element-highlight t))

(add-hook 'web-mode-hook  'my-web-mode-hook)

;;;
;;; emmet
;;;

(add-hook 'sgml-mode-hook 'emmet-mode) ;; Auto-start on any markup modes
(add-hook 'css-mode-hook  'emmet-mode)


;;;
;;; javascript
;;;

(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
(add-hook 'js2-mode-hook #'(lambda ()
                             (define-key js2-mode-map (kbd "M-j") 'windmove-down)
                             (autopair-mode)))
(setq-default js2-concat-multiline-strings 'eol)

;; taken from https://github.com/mangalam-research/software-standards/tree/master/emacs
(defun find-file-recursively-up (regexp)
  "Searches for regexp in the current directory and recursively in parents
   until it finds the file or fails to find it."
  (let* ((find-file-r (lambda (path)
                        (or
                         ;; search here
                         (directory-files path t regexp)
                         ;; not found, so move up
                         (let* ((parent (file-name-directory
                                         (directory-file-name path))))
                           (and parent
                                ;; Eventually path is "/", at which
                                ;; point getting its parent is also
                                ;; "/". So w/o this test, we'd recurse
                                ;; forever.
                                (not (string= parent path))
                                (funcall find-file-r parent))))))
         (start (if (or (null buffer-file-name)
                        (file-directory-p buffer-file-name))
                    buffer-file-name
                  (file-name-directory buffer-file-name))))
    (when start
      (funcall find-file-r start))))

(defun ldd-js2-parse-jshintrc ()
  "This looks recursively up for a .jshintrc and extracts the
globals from it to add them to js2-additional-externs."
  (let* ((jshintrc (find-file-recursively-up "^\\.jshintrc$"))
         (json (and jshintrc
                    (json-read-file (car jshintrc))))
         (globals (and json
                       (cdr (assq 'globals json)))))
    (when globals
      (setq js2-additional-externs
            (append
             (mapcar (lambda (pair)
                         (symbol-name (car pair)))
                     globals)
             js2-additional-externs))
      (js2-reparse t))))

(add-hook 'js2-init-hook 'ldd-js2-parse-jshintrc)



;;;
;;; JSON
;;;

(add-hook 'json-mode-hook #'(lambda ()
                              (autopair-mode)))


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
 '(create-lockfiles nil)
 '(ido-everywhere t)
 '(package-archives (quote (("gnu" . "http://elpa.gnu.org/packages/") ("marmalade" . "http://marmalade-repo.org/packages/"))))
 '(safe-local-variable-values (quote ((Package . wco) (Package . imho) (Package . wcof) (Base . 10) (Syntax . Ansi-Common-Lisp)))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(web-mode-current-element-highlight-face ((t (:background "controlHighlightColor")))))
