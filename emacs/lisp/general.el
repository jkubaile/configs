;; ido mode - better files choosing
(require 'ido)
(ido-mode t)

;; change fontsize with C-+/C--
(load-library "fontsize")

(require 'lsp-mode)

;; language server
(require 'eglot)
(add-hook 'python-mode-hook 'eglot-ensure)
(add-hook 'python-mode-hook (lambda () (add-hook 'before-save-hook 'eglot-format-buffer)))
(add-hook 'js-mode-hook 'eglot-ensure)

;; enable auto completion for all
(add-hook 'after-init-hook 'global-company-mode)
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; disable autosave
(setq auto-save-default nil)
(setq create-lockfiles nil)
(setq make-backup-files nil)


(add-to-list 'auto-mode-alist '("\\.hbs\\'" . handlebars-mode))
(add-to-list 'auto-mode-alist '("\\.json\\'" . prettier-js-mode))
(add-to-list 'auto-mode-alist '("\\.mjs\\'" . js-mode))
(add-to-list 'auto-mode-alist '("\\.cjs\\'" . js-mode))
(add-to-list 'auto-mode-alist '("\\.gjs\\'" . glint-ts-mode))

(add-hook 'js-mode-hook 'prettier-mode)
(add-hook 'js-mode-hook 'ember-mode)
(add-hook 'web-mode-hook 'prettier-mode)
(add-hook 'handlebars-mode-hook 'prettier-mode)
(add-hook 'handlebars-mode-hook 'ember-mode)
(add-hook 'html-mode-hook 'prettier-mode)
(add-hook 'markdown-mode-hook 'prettier-mode)
(add-hook 'css-mode-hook 'prettier-mode)
(add-hook 'glint-ts-mode-hook 'prettier-mode)
(add-hook 'glint-ts-mode-hook 'ember-mode)

;; configure prettier to use the project prettier, we have no global one
(setq prettier-js-use-modules-bin t)

(require 'yasnippet)
(yas-global-mode 1)

(use-package diff-hl
  :config
  (setq diff-hl-draw-borders t)
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  (diff-hl-margin-mode)
  (global-diff-hl-mode))


(setq treesit-language-source-alist
      '((tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (glimmer "https://github.com/alexlafroscia/tree-sitter-glimmer")))

;; Nächster Buffer mit Strg + Shift + Rechts
(global-set-key (kbd "C-M-<right>") 'next-buffer)

;; Vorheriger Buffer mit Strg + Shift + Links
(global-set-key (kbd "C-M-<left>") 'previous-buffer)
