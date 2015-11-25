(add-to-list 'load-path "~/.emacs.d")

(package-initialize)
(load-library "packageinstaller")

;; ELPY
(elpy-enable)

;; Fixing a key binding bug in elpy
(define-key yas-minor-mode-map (kbd "C-c k") 'yas-expand)
;; Fixing another key binding bug in iedit mode
(define-key global-map (kbd "C-c o") 'iedit-mode)

; (load-library "python")

(load-library "general")
(load-library "javascript")

(auto-complete-mode t)
