;; activate installed packages

(require 'package)

(add-to-list 'package-archives
             '("melpa" . "http://melpa.org/packages/") t)

(defun ensure-package-installed (&rest packages)
  "Assure every package is installed, ask for installation if it’s not.

Return a list of installed packages or nil for every skipped package."
  (mapcar
   (lambda (package)
     ;; (package-installed-p 'evil)
     (if (package-installed-p package)
         nil
       (if (y-or-n-p (format "Package %s is missing. Install it? " package))
           (package-install package)
         package)))
   packages))

;; make sure to have downloaded archive description.
;; Or use package-archive-contents as suggested by Nicolas Dudebout
(or (file-exists-p package-user-dir)
    (package-refresh-contents))

;; define our packages
;; (ensure-package-installed 'elpy 'js2-mode 'ac-js2 'auto-complete 'iedit 'w3m 'better-defaults 'material-theme 'flycheck 'json-reformat 'magit 'web-mode 'rjsx-mode 'add-node-modules-path 'prettier 'lsp-mode 'company-lsp 'lsp-ui 'eglot)
(ensure-package-installed 'ido 'eglot 'pyvenv-auto 'company 'prettier-js 'git-timemachine 'handlebars-mode 'ember-mode 'magit 'yasnippet 'yasnippet-snippets 'diff-hl 'tree-sitter 'lsp-mode 'add-node-modules-path 'prettier 'corfu 'rjsx-mode 'web-mode)
