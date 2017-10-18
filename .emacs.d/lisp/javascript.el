;; js stuff - http://truongtx.me/2014/02/23/set-up-javascript-development-environment-in-emacs/
(add-to-list 'auto-mode-alist '("\\.json$" . js-mode))
(add-to-list 'auto-mode-alist '("\\.hbs$" . web-mode))
(add-hook 'js-mode-hook 'js2-minor-mode)
(add-hook 'js2-mode-hook 'ac-js2-mode)
(setq js2-highlight-level 3)


(add-hook 'js-mode-hook
      (lambda()
        (setq c-basic-offset 4)
        (setq indent-tabs-mode nil)))


;; integrate ember mode and enable it on js and web mode
(add-to-list 'load-path "~/.emacs.d/ember-mode/")
(require 'ember-mode)

(add-hook 'js-mode-hook (lambda () (ember-mode t)))
(add-hook 'web-mode-hook (lambda () (ember-mode t)))


(setq web-mode-markup-indent-offset 2
      web-mode-css-indent-offset 2
      web-mode-code-indent-offset 2)
(setq js-indent-level 2)


;; eslint
;; http://www.flycheck.org/manual/latest/index.html
(require 'flycheck)

;; turn on flychecking globally
(add-hook 'after-init-hook #'global-flycheck-mode)

;; disable jshint since we prefer eslint checking
(setq-default flycheck-disabled-checkers
  (append flycheck-disabled-checkers
    '(javascript-jshint)))

;; use local eslint from node_modules before global
;; http://emacs.stackexchange.com/questions/21205/flycheck-with-file-relative-eslint-executable
(defun my/use-eslint-from-node-modules ()
  (let* ((root (locate-dominating-file
                (or (buffer-file-name) default-directory)
                "node_modules"))
         (eslint (and root
                      (expand-file-name "node_modules/eslint/bin/eslint.js"
                                        root))))
    (when (and eslint (file-executable-p eslint))
      (setq-local flycheck-javascript-eslint-executable eslint))))
(add-hook 'flycheck-mode-hook #'my/use-eslint-from-node-modules)

;; use eslint with web-mode for jsx files
(flycheck-add-mode 'javascript-eslint 'web-mode)

;; customize flycheck temp file prefix
(setq-default flycheck-temp-prefix ".flycheck")

;; disable json-jsonlist checking for json files
(setq-default flycheck-disabled-checkers
  (append flycheck-disabled-checkers
    '(json-jsonlist)))

(add-hook 'js-mode-hook (lambda () (flycheck-mode t)))
