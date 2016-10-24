(add-to-list 'load-path "~/.emacs.d/lisp")

(package-initialize)

(load-library "packageinstaller.el")
;(load "~/.emacs.d/lisp/packageinstaller.el")

;; ELPY
(elpy-enable)

;; Fixing a key binding bug in elpy
(define-key yas-minor-mode-map (kbd "C-c k") 'yas-expand)
;; Fixing another key binding bug in iedit mode
(define-key global-map (kbd "C-c o") 'iedit-mode)

; (load-library "python")

(load-library "general")
(load-library "javascript")

(load-library "testing")
(load-library "robot-mode")
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(background brightwhite)
 '(column-number-mode t)
 '(flycheck-eslintrc "eslint")
 '(font-use-system-font t)
 '(menu-bar-mode t)
 '(show-paren-mode t)
 '(tool-bar-mode nil)
 '(uniquify-buffer-name-style (quote forward) nil (uniquify))
 '(use-file-dialog nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
