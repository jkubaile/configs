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
Only claim the backend when point is on an include/extends/import path."
  (when (jku/jinja-template-at-point)
    'jku/jinja))

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql jku/jinja)))
  (jku/jinja-template-at-point))

(cl-defmethod xref-backend-definitions ((_backend (eql jku/jinja)) identifier)
  (when-let* ((file (jku/jinja-resolve-template identifier)))
    (list (xref-make identifier (xref-make-file-location file 1 0)))))

(cl-defmethod xref-backend-identifier-completion-table ((_backend (eql jku/jinja)))
  nil)

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
  "Enable Jinja template jump with M-."
  (add-hook 'xref-backend-functions #'jku/jinja-xref-backend nil t)
  (local-set-key (kbd "M-.") #'jku/jinja-goto-template-or-xref))

(add-hook 'web-mode-hook #'jku/jinja-enable-xref)
(add-hook 'html-mode-hook #'jku/jinja-enable-xref)

;; Jump to Ember Glimmer imports / <Component> usages with M-.
;; Prefer this over Glint LSP when the server is not installed in the project.
(require 'json)

(defun jku/glimmer--package-root ()
  "Return directory containing the nearest package.json, or nil."
  (when-let* ((dir (locate-dominating-file default-directory "package.json")))
    (file-name-as-directory (expand-file-name dir))))

(defun jku/glimmer--read-package-json (dir)
  "Parse package.json in DIR; return alist or nil."
  (let ((file (expand-file-name "package.json" dir)))
    (when (file-readable-p file)
      (json-parse-string
       (with-temp-buffer
         (insert-file-contents file)
         (buffer-string))
       :object-type 'alist
       :null-object nil
       :false-object nil))))

(defun jku/glimmer--find-package-dir (name)
  "Find install/root directory for package NAME."
  (let* ((root (jku/glimmer--package-root))
         (pkg (and root (jku/glimmer--read-package-json root))))
    (cond
     ((and pkg (equal (alist-get 'name pkg) name)) root)
     (root
      (let ((nm (expand-file-name (concat "node_modules/" name) root)))
        (when (file-directory-p nm)
          (file-name-as-directory (file-truename nm)))))
     (t nil))))

(defun jku/glimmer--split-spec (spec)
  "Split SPEC into (package . subpath). Subpath may be \"\"."
  (if (string-prefix-p "@" spec)
      (let ((parts (split-string spec "/")))
        (cons (concat (nth 0 parts) "/" (nth 1 parts))
              (string-join (nthcdr 2 parts) "/")))
    (let ((parts (split-string spec "/")))
      (cons (car parts) (string-join (cdr parts) "/")))))

(defun jku/glimmer--try-file (path)
  "Return PATH if it is a readable file, else nil."
  (and path (file-regular-p path) path))

(defun jku/glimmer--bare-base (path)
  "Strip a trailing .js/.ts extension from PATH."
  (if (string-match "\\.[jt]s\\'" path)
      (substring path 0 (match-beginning 0))
    path))

(defun jku/glimmer--with-exts (base)
  "Try common Ember/JS extensions for BASE."
  (let ((base (jku/glimmer--bare-base base)))
    (or (jku/glimmer--try-file base)
        (cl-loop for ext in '(".gjs" ".gts" ".js" ".ts" ".hbs" "/index.gjs"
                              "/index.gts" "/index.js" "/index.ts")
                 for candidate = (concat base ext)
                 when (jku/glimmer--try-file candidate)
                 return candidate))))

(defun jku/glimmer--export-target (val)
  "Normalize package exports entry VAL to a path string or nil."
  (cond ((stringp val) val)
        ((consp val)
         (or (alist-get 'default val)
             (alist-get 'import val)
             (let ((first (car val)))
               (and (consp first) (stringp (cdr first)) (cdr first)))))
        (t nil)))

(defun jku/glimmer--apply-exports (pkg-dir subpath)
  "Resolve SUBPATH via package exports in PKG-DIR when possible."
  (let* ((pkg (jku/glimmer--read-package-json pkg-dir))
         (exports (alist-get 'exports pkg))
         (key (if (string-empty-p subpath) "." (concat "./" subpath)))
         (exact (and exports
                     (or (alist-get (intern key) exports)
                         (alist-get key exports nil nil #'equal))))
         (star (and exports (or (alist-get './* exports)
                                (alist-get "./*" exports nil nil #'equal))))
         (star-target (jku/glimmer--export-target star)))
    (cond
     (exact
      (when-let* ((target (jku/glimmer--export-target exact)))
        (jku/glimmer--with-exts
         (expand-file-name (string-remove-prefix "./" target) pkg-dir))))
     ((and star-target (string-search "*" star-target)
           (not (string-empty-p subpath)))
      (let* ((mapped (replace-regexp-in-string "\\*" subpath star-target t t))
             (abs (expand-file-name (string-remove-prefix "./" mapped) pkg-dir))
             (src-alt (replace-regexp-in-string "/dist/" "/src/" abs t t)))
        (or (jku/glimmer--with-exts src-alt)
            (jku/glimmer--with-exts abs))))
     (t nil))))

(defun jku/glimmer-resolve-module (spec)
  "Resolve Ember/JS module SPEC to an absolute file, or nil."
  (cond
   ((string-prefix-p "." spec)
    (jku/glimmer--with-exts
     (expand-file-name spec (file-name-directory buffer-file-name))))
   ((string-match-p "/" spec)
    (pcase-let* ((`(,name . ,sub) (jku/glimmer--split-spec spec))
                 (pkg-dir (jku/glimmer--find-package-dir name)))
      (when pkg-dir
        (or (jku/glimmer--apply-exports pkg-dir sub)
            (jku/glimmer--with-exts (expand-file-name sub pkg-dir))
            (jku/glimmer--with-exts (expand-file-name (concat "app/" sub) pkg-dir))
            (jku/glimmer--with-exts (expand-file-name (concat "src/" sub) pkg-dir))
            (jku/glimmer--with-exts (expand-file-name (concat "addon/" sub) pkg-dir))))))
   (t
    (when-let* ((pkg-dir (jku/glimmer--find-package-dir spec)))
      (or (jku/glimmer--apply-exports pkg-dir "")
          (jku/glimmer--with-exts (expand-file-name "index" pkg-dir)))))))
(defun jku/glimmer-import-spec-at-point ()
  "Return module specifier string at point inside an import, or nil."
  (save-excursion
    (let ((pt (point))
          (bound (line-end-position))
          spec)
      (goto-char (line-beginning-position))
      (while (and (not spec)
                  (re-search-forward
                   "\\(?:from\\s-+\\|import\\s-+\\)[\"']\\([^\"']+\\)[\"']"
                   bound t))
        (let ((beg (match-beginning 1))
              (end (match-end 1)))
          (when (and (<= beg pt) (<= pt end))
            (setq spec (match-string-no-properties 1)))))
      spec)))

(defun jku/glimmer-component-name-at-point ()
  "Return AngleBracket component name at point, or nil."
  (save-excursion
    (skip-chars-backward "A-Za-z0-9-_")
    (when (eq (char-before) ?<)
      (when (looking-at "\\([A-Z][A-Za-z0-9]*\\)")
        (match-string-no-properties 1)))))
(defun jku/glimmer-import-spec-for-binding (name)
  "Return module specifier for imported binding NAME, or nil."
  (save-excursion
    (goto-char (point-min))
    (let (spec)
      (while (and (not spec)
                  (re-search-forward
                   (concat "import\\s-+\\(?:{\\s-*\\)?"
                           (regexp-quote name)
                           "\\(?:\\s-*}\\)?\\s-+from\\s-+[\"']\\([^\"']+\\)[\"']")
                   nil t))
        (setq spec (match-string-no-properties 1)))
      spec)))

(defun jku/glimmer-target-at-point ()
  "Return absolute file for import/component at point, or nil."
  (or (when-let* ((spec (jku/glimmer-import-spec-at-point)))
        (jku/glimmer-resolve-module spec))
      (when-let* ((name (jku/glimmer-component-name-at-point))
                  (spec (jku/glimmer-import-spec-for-binding name)))
        (jku/glimmer-resolve-module spec))))

(defun jku/glimmer-xref-backend ()
  "Xref backend for Glimmer imports/components."
  (when (jku/glimmer-target-at-point)
    'jku/glimmer))

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql jku/glimmer)))
  (or (jku/glimmer-import-spec-at-point)
      (jku/glimmer-component-name-at-point)))

(cl-defmethod xref-backend-definitions ((_backend (eql jku/glimmer)) identifier)
  (when-let* ((file (or (jku/glimmer-target-at-point)
                        (jku/glimmer-resolve-module identifier)
                        (when-let* ((spec (jku/glimmer-import-spec-for-binding identifier)))
                          (jku/glimmer-resolve-module spec)))))
    (list (xref-make identifier (xref-make-file-location file 1 0)))))

(cl-defmethod xref-backend-identifier-completion-table ((_backend (eql jku/glimmer)))
  nil)

(defun jku/glimmer-goto-or-xref ()
  "Jump to Glimmer import/component at point; otherwise normal xref/LSP."
  (interactive)
  (if-let* ((file (jku/glimmer-target-at-point)))
      (progn
        (xref-push-marker-stack)
        (find-file file))
    (call-interactively #'xref-find-definitions)))

(defun jku/glimmer-enable-xref ()
  "Enable Glimmer import/component jump with M-."
  (add-hook 'xref-backend-functions #'jku/glimmer-xref-backend nil t)
  (local-set-key (kbd "M-.") #'jku/glimmer-goto-or-xref))

(add-hook 'glint-ts-mode-hook #'jku/glimmer-enable-xref)

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
