;;; diffinator.el --- Apply unified diffs to files/buffers (SlabOS vanilla) -*- lexical-binding: t; -*-

;; Design goals:
;; - Safe: never run git apply against your real working tree directly.
;; - Accurate: apply diff in a temp workspace with correct relative paths.
;; - Convenient: reads clipboard (pbpaste on macOS, GUI clipboard fallback).
;; - Multi-file: supports diffs containing multiple `diff --git` blocks.
;; - Friendly failure: shows *diffinator errors* with stdout/stderr + file list.
;;
;; SlabOS test patch: diffinator is alive and patchable.

(require 'subr-x)
(require 'cl-lib)

(defgroup diffinator nil
  "Apply unified diffs to files/buffers."
  :group 'tools)

(defcustom diffinator-git-executable "git"
  "Git executable used to apply patches."
  :type 'string
  :group 'diffinator)

(defcustom diffinator-prefer-pbpaste t
  "Prefer reading clipboard via pbpaste on macOS."
  :type 'boolean
  :group 'diffinator)

(defcustom diffinator-git-apply-args
  '("apply"
    "--unsafe-paths"
    "--recount"
    "--whitespace=nowarn"
    "--ignore-space-change"
    "--ignore-whitespace"
    "-C2")
  "Arguments passed to `git apply` (excluding the patch file path)."
  :type '(repeat string)
  :group 'diffinator)

(defun diffinator--errbuf (title body)
  "Show TITLE and BODY in *diffinator errors*."
  (let ((buf (get-buffer-create "*diffinator errors*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert title "\n\n" body)
        (goto-char (point-min))
        (special-mode)))
    (display-buffer buf)))

(defun diffinator--pbpaste ()
  "Return clipboard text using pbpaste, or nil."
  (when (and diffinator-prefer-pbpaste
             (eq system-type 'darwin)
             (executable-find "pbpaste"))
    (condition-case _
        (let ((s (shell-command-to-string "pbpaste")))
          (when (and (stringp s) (not (string-empty-p (string-trim s))))
            (if (string-suffix-p "\n" s) s (concat s "\n"))))
      (error nil))))

(defun diffinator--gui-clipboard ()
  "Return GUI clipboard text via gui-get-selection, or nil."
  (when (fboundp 'gui-get-selection)
    (condition-case _
        (let ((s (gui-get-selection 'CLIPBOARD 'STRING)))
          (when (and (stringp s) (not (string-empty-p (string-trim s))))
            (if (string-suffix-p "\n" s) s (concat s "\n"))))
      (error nil))))

(defun diffinator--read-clipboard ()
  "Read diff text from clipboard or raise a user error."
  (let ((s (or (diffinator--pbpaste)
               (diffinator--gui-clipboard))))
    (unless (stringp s)
      (user-error "diffinator: couldn't read text from system clipboard"))
    s))

(defun diffinator--looks-like-diff-p (s)
  "Cheap sanity check for a unified diff."
  (and (stringp s)
       (not (string-empty-p (string-trim s)))
       (or (string-match-p "^diff --git " s)
           (string-match-p "^--- " s)
           (string-match-p "^\\+\\+\\+ " s)
           (string-match-p "^@@ " s))))

(defun diffinator--project-root ()
  "Best-effort project root for applying diffs."
  (or (and (fboundp 'vc-root-dir) (vc-root-dir))
      (locate-dominating-file default-directory ".git")
      default-directory))

(defun diffinator--split-by-diff-git (diff-text)
  "Return a list of per-file patch chunks from DIFF-TEXT.
If no `diff --git` headers exist, returns a singleton list with DIFF-TEXT."
  (let* ((lines (split-string diff-text "\n" nil))
         (chunks '())
         (cur '()))
    (dolist (ln lines)
      (when (string-prefix-p "diff --git " ln)
        (when cur
          (push (mapconcat #'identity (nreverse cur) "\n") chunks)
          (setq cur '())))
      (push ln cur))
    (when cur
      (push (mapconcat #'identity (nreverse cur) "\n") chunks))
    (nreverse chunks)))

(defun diffinator--chunk-bpath (chunk)
  "Extract b/<path> from CHUNK's first diff header, or nil."
  (when (string-match "^diff --git a/\\(.+\\) b/\\(.+\\)$" chunk)
    (match-string 2 chunk)))

(defun diffinator--ensure-dir (path)
  (let ((dir (file-name-directory path)))
    (when (and dir (not (file-directory-p dir)))
      (make-directory dir t))))

(defun diffinator--buffer-string (buf)
  (with-current-buffer buf
    (buffer-substring-no-properties (point-min) (point-max))))

(defun diffinator--git-apply (dir patch-path)
  "Run `git apply` on PATCH-PATH in DIR. Return plist."
  (let* ((default-directory dir)
         (out (generate-new-buffer " *diffinator git out*"))
         (err (generate-new-buffer " *diffinator git err*"))
         (argv (append diffinator-git-apply-args (list patch-path)))
         exit-code stdout stderr)
    (unwind-protect
        (progn
          (setq exit-code (apply #'call-process diffinator-git-executable nil out nil argv))
          (setq stdout (with-current-buffer out (buffer-string)))
          (setq stderr (with-current-buffer err (buffer-string)))
          (list :ok (eq exit-code 0) :exit exit-code :stdout stdout :stderr stderr))
      (when (buffer-live-p out) (kill-buffer out))
      (when (buffer-live-p err) (kill-buffer err)))))

(defun diffinator--apply-multifile (root diff-text)
  "Apply DIFF-TEXT (possibly multi-file) against buffers/files under ROOT."
  (let* ((chunks (diffinator--split-by-diff-git diff-text))
         (has-diff-git (string-match-p "^diff --git " diff-text))
         (tmpdir (make-temp-file "diffinator-" t))
         (patchfile (expand-file-name "patch.diff" tmpdir))
         (files '())
         (buf-map (make-hash-table :test 'equal))
         (was-modified (make-hash-table :test 'equal)))
    (unwind-protect
        (progn
          ;; If no diff --git headers, target current buffer file only
          (unless has-diff-git
            (unless buffer-file-name
              (user-error "diffinator: diff has no diff --git header and current buffer isn't visiting a file"))
            (setq chunks (list diff-text))
            (setq files (list (file-relative-name buffer-file-name root))))

          ;; Collect files + write workspace copies
          (dolist (chunk chunks)
            (let ((bpath (or (diffinator--chunk-bpath chunk)
                             (and buffer-file-name (file-relative-name buffer-file-name root)))))
              (unless bpath
                (diffinator--errbuf
                 "diffinator: couldn't determine target path"
                 "This diff chunk had no diff --git header, and no buffer-file-name fallback was available.")
                (user-error "diffinator: could not determine patch target"))
              (when (string= bpath "/dev/null")
                (diffinator--errbuf
                 "diffinator: deletion patch not supported"
                 "This patch targets /dev/null (file deletion). Handle deletions manually for now.")
                (user-error "diffinator: deletion patch not supported"))
              (push bpath files)

              (let* ((abs (expand-file-name bpath root))
                     (buf (find-file-noselect abs))
                     (workfile (expand-file-name bpath tmpdir)))
                (puthash bpath buf buf-map)
                (puthash bpath (with-current-buffer buf (buffer-modified-p)) was-modified)
                (diffinator--ensure-dir workfile)
                (with-temp-file workfile
                  (insert (diffinator--buffer-string buf))
                  (unless (bolp) (insert "\n"))))))

          (setq files (delete-dups (nreverse files)))

          ;; Write a single patch file containing all chunks (git apply can handle it)
          (with-temp-file patchfile
            (insert diff-text)
            (unless (string-suffix-p "\n" diff-text) (insert "\n")))

          ;; Apply patch in tempdir
          (let ((res (diffinator--git-apply tmpdir patchfile)))
            (unless (plist-get res :ok)
              (diffinator--errbuf
               "diffinator: git apply failed"
               (concat
                "Project root: " root "\n"
                "Temp workspace: " tmpdir "\n"
                "Patch file: " patchfile "\n\n"
                "Targets:\n  - " (string-join files "\n  - ") "\n\n"
                "stderr:\n" (plist-get res :stderr) "\n"
                "stdout:\n" (plist-get res :stdout) "\n"))
              (user-error "diffinator: could not apply diff (see *diffinator errors*)")))

          ;; Copy results back into real buffers
          (dolist (bpath files)
            (let* ((buf (gethash bpath buf-map))
                   (workfile (expand-file-name bpath tmpdir))
                   (newtext (with-temp-buffer
                              (insert-file-contents workfile)
                              (buffer-string)))
                   (was (gethash bpath was-modified)))
              (with-current-buffer buf
                (atomic-change-group
                  (erase-buffer)
                  (insert newtext)
                  ;; Mark as modified: keep original modified state, but applying a patch is a real change.
                  (set-buffer-modified-p (or was t))))))

          files)
      (when (file-directory-p tmpdir)
        (delete-directory tmpdir t)))))

;;;###autoload
(defun diffinator-apply-clipboard ()
  "Apply unified diff from clipboard to one or more files safely."
  (interactive)
  (let ((diff (diffinator--read-clipboard)))
    (unless (diffinator--looks-like-diff-p diff)
      (diffinator--errbuf
       "diffinator: clipboard doesn't look like a unified diff"
       (substring diff 0 (min 1200 (length diff))))
      (user-error "diffinator: clipboard doesn't look like a diff (see *diffinator errors*)"))
    (let* ((root (diffinator--project-root))
           (files (diffinator--apply-multifile root diff)))
      (message "diffinator: applied diff (%d file%s): %s"
               (length files)
               (if (= (length files) 1) "" "s")
               (string-join files ", ")))))

;; Back-compat name you used previously
;;;###autoload
(defalias 'diffinator-apply-diff-from-kill #'diffinator-apply-clipboard)

(provide 'diffinator)
;;; diffinator.el ends here
