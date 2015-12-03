;; js stuff - http://truongtx.me/2014/02/23/set-up-javascript-development-environment-in-emacs/
(add-to-list 'auto-mode-alist '("\\.json$" . js-mode))
(add-hook 'js-mode-hook 'js2-minor-mode)
(add-hook 'js2-mode-hook 'ac-js2-mode)
(setq js2-highlight-level 3)


(add-hook 'js-mode-hook
      (lambda()
        (setq c-basic-offset 4)
        (setq indent-tabs-mode nil)))
