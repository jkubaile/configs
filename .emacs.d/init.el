(add-to-list 'load-path "~/.emacs.d/lisp")

;; (package-initialize)

(load-library "packageinstaller.el")
;(load "~/.emacs.d/lisp/packageinstaller.el")

;; ELPY
(elpy-enable)

;; Fixing a key binding bug in elpy
(define-key yas-minor-mode-map (kbd "C-c k") 'yas-expand)
;; Fixing another key binding bug in iedit mode
(define-key global-map (kbd "C-c o") 'iedit-mode)

; (load-library "python")
(load-library "blacken.el")


(load-library "general")
(load-library "javascript")

(load-library "testing")
(load-library "robot-mode")
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(ansi-color-names-vector
   ["black" "#d55e00" "#009e73" "#f8ec59" "#0072b2" "#cc79a7" "#56b4e9" "white"])
 '(background brightwhite)
 '(blacken-executable "/home/jku/local/Python-3.6.5/bin/black")
 '(blacken-line-length 79)
 '(column-number-mode t)
 '(custom-enabled-themes '(material))
 '(custom-safe-themes
   '("870a63a25a2756074e53e5ee28f3f890332ddc21f9e87d583c5387285e882099" "0aa12caf6127772c1a38f7966de8258e7a0651fb6f7220d0bbb3a0232fba967f" default))
 '(elpy-test-compilation-function 'compile)
 '(elpy-test-runner 'elpy-test-pytest-runner)
 '(fci-rule-color "#ECEFF1")
 '(flycheck-eslintrc "eslint")
 '(font-use-system-font t)
 '(hl-sexp-background-color "#efebe9")
 '(menu-bar-mode t)
 '(package-selected-packages
   '(csv-mode expand-region magit yaml-mode websocket web-mode w3m vlf request puppet-mode oauth2 material-theme markdown-mode lorem-ipsum json-reformat iedit git-timemachine flymake-puppet flycheck fill-column-indicator emojify elpy crontab-mode circe better-defaults auto-complete async apache-mode alert ac-js2))
 '(show-paren-mode t)
 '(tool-bar-mode nil)
 '(uniquify-buffer-name-style 'forward nil (uniquify))
 '(use-file-dialog nil)
 '(vc-annotate-background nil)
 '(vc-annotate-color-map
   '((20 . "#B71C1C")
     (40 . "#FF5722")
     (60 . "#FFA000")
     (80 . "#558b2f")
     (100 . "#00796b")
     (120 . "#2196f3")
     (140 . "#4527A0")
     (160 . "#B71C1C")
     (180 . "#FF5722")
     (200 . "#FFA000")
     (220 . "#558b2f")
     (240 . "#00796b")
     (260 . "#2196f3")
     (280 . "#4527A0")
     (300 . "#B71C1C")
     (320 . "#FF5722")
     (340 . "#FFA000")
     (360 . "#558b2f")))
 '(vc-annotate-very-old-color nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
