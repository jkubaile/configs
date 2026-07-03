(add-to-list 'load-path "~/.config/emacs/lisp")

(load-library "packageinstaller")
(load-library "general")
(load-library "javascript-modern")
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(background black)
 '(column-number-mode t)
 '(custom-enabled-themes '(modus-vivendi))
 '(font-use-system-font t)
 '(menu-bar-mode t)
 '(package-selected-packages nil)
 '(package-vc-selected-packages
   '((glnt-ts-mode :vc-backend Git :url
		   "https://github.com/overcast-software/glnt-ts-mode")))
 '(show-paren-mode t)
 '(tool-bar-mode nil)
 '(uniquify-buffer-name-style 'forward nil (uniquify))
 '(use-file-dialog nil))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
