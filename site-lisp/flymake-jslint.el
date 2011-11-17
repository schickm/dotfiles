(require 'flymake)

(defun flymake-jslint-init ()
  (let* ((temp-file (flymake-init-create-temp-buffer-copy
		     'flymake-create-temp-inplace))
         (local-file (file-relative-name
		      temp-file
		      (file-name-directory buffer-file-name))))
    (list "jslint" (list "--config" (file-truename "../jslint_config.json") local-file))))

(setq flymake-allowed-file-name-masks
      (cons '(".+\\.js$"
	      flymake-jslint-init
	      flymake-simple-cleanup
	      flymake-get-real-file-name)
	    flymake-allowed-file-name-masks))

(setq flymake-err-line-patterns 
      (cons '("^  \\([[:digit:]]+\\) \\([[:digit:]]+\\),\\([[:digit:]]+\\): \\(.+\\)$"  
	      nil 2 3 4)
	    flymake-err-line-patterns))

(provide 'flymake-jslint)