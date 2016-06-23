;; see:
;; https://realpython.com/blog/python/emacs-the-best-python-editor/

(setq inhibit-startup-message t) ;; hide the startup message
(load-theme 'material t) ;; load material theme
(global-linum-mode t) ;; enable line numbers globally

;; enable flycheck, cause elpy uses flyamke, which only checks at save time
(when (require 'flycheck nil t)
  (setq elpy-modules (delq 'elpy-module-flymake elpy-modules))
  (add-hook 'elpy-mode-hook 'flycheck-mode))

;; breaks autocomplete?
;; (add-hook 'elpy-mode-hook 'fci-mode)
;; (setq fci-rule-width 1)
;; (setq fci-rule-color "red")
;; (setq fci-rule-column 120)
