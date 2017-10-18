(auto-complete-mode t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(font-use-system-font t)
 '(show-paren-mode t)
 '(tool-bar-mode nil)
 '(menu-bar-mode t)
 '(uniquify-buffer-name-style (quote forward) nil (uniquify))
 '(background brightwhite)
 '(use-file-dialog nil))

;; ido mode - better files choosing
(require 'ido)
(ido-mode t
)
;; change fontsize with C-+/C--
(load-library "fontsize")

;; parenthesis stuff / Klammern
(setq show-paren-delay 0)           ; how long to wait?
(show-paren-mode t)                 ; turn paren-mode on
(setq show-paren-style 'expression) ; alternatives are 'parenthesis' and 'mixed'
(set-face-background 'show-paren-match-face "#dddddd")
(set-face-attribute 'show-paren-match-face nil
        :weight 'normal :underline nil :overline nil :slant 'normal)
(set-face-foreground 'show-paren-mismatch-face "red")
(set-face-attribute 'show-paren-mismatch-face nil
                    :weight 'normal :underline t :overline nil :slant 'normal)

(add-hook 'before-save-hook 'delete-trailing-whitespace)


(add-hook 'html-mode-hook
      (lambda()
        (setq c-basic-offset 2)
        (setq indent-tabs-mode nil)))

(setq browse-url-browser-function 'w3m-browse-url)
(autoload 'w3m-browse-url "w3m" "Ask a WWW browser to show a URL." t)
;; optional keyboard short-cut
(global-set-key "\C-xm" 'browse-url-at-point)

(add-to-list 'auto-mode-alist '("\\.robot\\'" . robot-mode))

;(require 'flymake-puppet)
;(add-hook puppet-mode-hook 'flymake-puppet-load)

;; disable autosave
(setq auto-save-default nil)
(setq create-lockfiles nil)

(global-auto-revert-mode t)

;; disable vc-git
(setq vc-handled-backends ())
