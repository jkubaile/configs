;; ido mode - better files choosing
(require 'ido)
(ido-mode t)

;; change fontsize with C-+/C--
(load-library "fontsize")

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
(add-to-list 'auto-mode-alist '("\\.html\\'" . web-mode))
(setq web-mode-engines-alist '(("django" . "\\.html\\'")))

(add-hook 'js-mode-hook 'prettier-mode)
(add-hook 'js-mode-hook 'ember-mode)
(add-hook 'web-mode-hook 'prettier-mode)
(add-hook 'handlebars-mode-hook 'prettier-mode)
(add-hook 'handlebars-mode-hook 'ember-mode)
(add-hook 'html-mode-hook 'prettier-mode)
(add-hook 'markdown-mode-hook 'prettier-mode)
(add-hook 'css-mode-hook 'prettier-mode)
(require 'glint-ts-mode)
(require 'glint-ts-mode-lsp)

(defun jku/glint-ts-mode-disable-lsp-completion ()
  "Use Glint LSP without completion."
  (setq-local lsp-completion-provider 'none))

(defun jku/glint-ts-mode-ensure-lsp ()
  "Start Glint LSP when glint-language-server is available."
  (condition-case nil
      (progn (glint-ts-mode-lsp--server-command)
             (unless (bound-and-true-p lsp-mode)
               (lsp)))
    (error nil)))

(add-hook 'glint-ts-mode-hook #'jku/glint-ts-mode-disable-lsp-completion)
(add-hook 'glint-ts-mode-hook #'glint-ts-mode-lsp--disable-ts-ls)
(add-hook 'glint-ts-mode-hook #'jku/glint-ts-mode-ensure-lsp)
(add-to-list 'lsp-disabled-clients 'semgrep-ls t)

(add-hook 'glint-ts-mode-hook 'prettier-mode)
(add-hook 'glint-ts-mode-hook 'ember-mode)

;; ESLint language server for Jinja/HTML (project flat config)
(require 'lsp-eslint)
(setq lsp-eslint-validate '("html" "svelte")
      lsp-eslint-format nil
      lsp-eslint-quiet t
      lsp-eslint-options (ht ("overrideConfigFile" "frontend/eslint.config.mjs")))

(defun jku/html-disable-lsp-completion ()
  "Use ESLint LSP without completion."
  (setq-local lsp-completion-provider 'none))

(defun jku/html-ensure-eslint-lsp ()
  "Start lsp-mode so the ESLint add-on client can attach."
  (unless (bound-and-true-p lsp-mode)
    (lsp)))

(add-hook 'html-mode-hook #'jku/html-disable-lsp-completion)
(add-hook 'html-mode-hook #'jku/html-ensure-eslint-lsp)
(add-hook 'web-mode-hook #'jku/html-disable-lsp-completion)
(add-hook 'web-mode-hook #'jku/html-ensure-eslint-lsp)

;; Jump to Jinja include/extends/import targets with M-.
(require 'cl-lib)
(require 'subr-x)
(require 'xref)

(defun jku/jinja--find-named-ancestor (dir name)
  "Return DIR or an ancestor directory whose basename is NAME, or nil."
  (let ((d (expand-file-name dir))
        (target (concat "/" name)))
    (while (and d
                (not (string-suffix-p target (directory-file-name d)))
                (not (member d '("" "/"))))
      (let ((parent (file-name-directory (directory-file-name d))))
        (setq d (if (or (null parent) (string-equal parent d))
                    nil
                  parent))))
    (when (and d (string-suffix-p target (directory-file-name d)))
      (file-name-as-directory d))))

(defun jku/jinja-template-roots ()
  "Return Jinja template search roots for the current buffer."
  (let* ((file (or buffer-file-name default-directory))
         (dir (file-name-directory (expand-file-name file)))
         roots)
    (dolist (name '("templates" "components"))
      (when-let* ((root (jku/jinja--find-named-ancestor dir name)))
        (push root roots)
        (let* ((sibling-name (if (string= name "templates")
                                 "components"
                               "templates"))
               (sibling (expand-file-name
                         sibling-name
                         (file-name-directory (directory-file-name root)))))
          (when (file-directory-p sibling)
            (push (file-name-as-directory sibling) roots)))))
    (unless roots
      (when-let* ((found (locate-dominating-file dir "templates")))
        (push (file-name-as-directory (expand-file-name "templates" found))
              roots)
        (let ((comp (expand-file-name "components" found)))
          (when (file-directory-p comp)
            (push (file-name-as-directory comp) roots)))))
    (delete-dups (nreverse roots))))

(defun jku/jinja-template-at-point ()
  "Return template path from include/extends/import at point, or nil."
  (save-excursion
    (let ((pt (point))
          (bound (line-end-position))
          path)
      (goto-char (line-beginning-position))
      (while (and (not path)
                  (re-search-forward
                   "{%-?\\s-*\\(?:include\\|extends\\|import\\)\\s-+[\"']\\([^\"']+\\)[\"']"
                   bound t))
        (let ((beg (match-beginning 1))
              (end (match-end 1)))
          (when (and (<= beg pt) (<= pt end))
            (setq path (match-string-no-properties 1)))))
      path)))

(defun jku/jinja-resolve-template (path)
  "Resolve Jinja template PATH to an absolute filename, or nil."
  (let ((rel (string-remove-prefix "/" path)))
    (cl-loop for root in (jku/jinja-template-roots)
             for candidate = (expand-file-name rel root)
             when (file-regular-p candidate)
             return candidate)))

(defun jku/jinja-xref-backend ()
  "Xref backend for Jinja template includes.
Only claim the backend when point is on an include/extends/import path,
so other backends (e.g. LSP) still handle everything else."
  (when (jku/jinja-template-at-point)
    'jku/jinja))

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql jku/jinja)))
  (jku/jinja-template-at-point))

(cl-defmethod xref-backend-definitions ((_backend (eql jku/jinja)) identifier)
  (when-let* ((file (jku/jinja-resolve-template identifier)))
    (list (xref-make identifier (xref-make-file-location file 1 0)))))

(cl-defmethod xref-backend-identifier-completion-table ((_backend (eql jku/jinja)))
  nil)

(defun jku/jinja--prefer-xref-backend ()
  "Keep the Jinja xref backend ahead of lsp--xref-backend.
lsp-managed-mode prepends lsp--xref-backend when the server attaches,
which would otherwise steal M-. for quoted template paths."
  (setq-local xref-backend-functions
              (cons #'jku/jinja-xref-backend
                    (delq #'jku/jinja-xref-backend
                          (copy-sequence xref-backend-functions)))))

(defun jku/jinja-goto-template-or-xref ()
  "Jump to Jinja template at point; otherwise use normal xref."
  (interactive)
  (if-let* ((path (jku/jinja-template-at-point))
            (file (jku/jinja-resolve-template path)))
      (progn
        (xref-push-marker-stack)
        (find-file file))
    (call-interactively #'xref-find-definitions)))

(defun jku/jinja-enable-xref ()
  "Prefer Jinja template xref before other backends in this buffer."
  (jku/jinja--prefer-xref-backend)
  ;; lsp-managed-mode (not lsp-mode) is what prepends lsp--xref-backend,
  ;; and it runs asynchronously after the ESLint server attaches.
  (add-hook 'lsp-managed-mode-hook #'jku/jinja--prefer-xref-backend nil t)
  ;; Direct binding: bypasses xref backend order entirely for M-.
  (local-set-key (kbd "M-.") #'jku/jinja-goto-template-or-xref))

(add-hook 'web-mode-hook #'jku/jinja-enable-xref)
(add-hook 'html-mode-hook #'jku/jinja-enable-xref)

;; Show LSP diagnostic text in the sideline; list all with C-c e
(require 'lsp-ui)
(setq lsp-ui-sideline-enable t
      lsp-ui-sideline-show-diagnostics t
      lsp-ui-sideline-show-hover nil
      lsp-ui-sideline-show-code-actions t
      lsp-ui-doc-enable t
      lsp-ui-doc-show-with-cursor nil
      lsp-ui-doc-show-with-mouse t)
(add-hook 'lsp-mode-hook #'lsp-ui-mode)
(with-eval-after-load 'lsp-mode
  (define-key lsp-mode-map (kbd "C-c e") #'flymake-show-buffer-diagnostics))

(defun jku/lsp-maybe-show-diagnostics-list ()
  "Open the Flymake diagnostics list when this buffer has issues.
Close it again when the buffer is clean."
  (when (and (bound-and-true-p flymake-mode)
             (get-buffer-window (current-buffer) 'visible))
    (if (flymake-diagnostics)
        (flymake-show-buffer-diagnostics)
      (when-let* ((diag-buf (get-buffer (flymake--diagnostics-buffer-name)))
                  (diag-win (get-buffer-window diag-buf)))
        (quit-window nil diag-win)))))

(defun jku/lsp-enable-auto-diagnostics-list ()
  "Auto-toggle the diagnostics list for the current LSP buffer."
  (add-hook 'lsp-diagnostics-updated-hook
            #'jku/lsp-maybe-show-diagnostics-list
            nil t))

(add-hook 'lsp-mode-hook #'jku/lsp-enable-auto-diagnostics-list)

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
