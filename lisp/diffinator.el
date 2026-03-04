;;; diffinator.el --- Apply unified diffs (patch-first) OR replace whole file -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'cl-lib)

(defgroup diffinator nil
  "Apply diffs from clipboard."
  :group 'tools)

(defcustom diffinator-prefer-pbpaste t
  "Prefer reading clipboard via pbpaste on macOS."
  :type 'boolean
  :group 'diffinator)

(defcustom diffinator-patch-executable "patch"
  "Patch executable."
  :type 'string
  :group 'diffinator)

(defcustom diffinator-strip-levels '(0 1 2 3)
  "Strip levels (-pN) to try, in order."
  :type '(repeat integer)
  :group 'diffinator)

(defcustom diffinator-patch-common-args '("--batch" "--forward" "-l")
  "Common args passed to patch."
  :type '(repeat string)
  :group 'diffinator)

(defcustom diffinator-patch-fuzz 3
  "Fuzz factor for patch matching."
  :type 'integer
  :group 'diffinator)

(defun diffinator--errbuf (title body)
  (let ((buf (get-buffer-create "*diffinator errors*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert title "\n\n" body)
        (goto-char (point-min))
        (special-mode)))
    (display-buffer buf)))

(defun diffinator--pbpaste ()
  (when (and diffinator-prefer-pbpaste
             (eq system-type 'darwin)
             (executable-find "pbpaste"))
    (condition-case _
        (shell-command-to-string "pbpaste")
      (error nil))))

(defun diffinator--gui-clipboard ()
  (when (fboundp 'gui-get-selection)
    (condition-case _
        (gui-get-selection 'CLIPBOARD 'STRING)
      (error nil))))

(defun diffinator--read-clipboard ()
  (let ((s (or (diffinator--pbpaste)
               (diffinator--gui-clipboard))))
    (unless (and (stringp s) (not (string-empty-p (string-trim s))))
      (user-error "diffinator: clipboard empty"))
    (setq s (replace-regexp-in-string "\r\n" "\n" s))
    (unless (string-suffix-p "\n" s)
      (setq s (concat s "\n")))
    s))

(defun diffinator--looks-like-diff-p (s)
  (and (stringp s)
       (or (string-match-p "^diff --git " s)
           (string-match-p "^--- " s)
           (string-match-p "^\\+\\+\\+ " s)
           (string-match-p "^@@ " s))))

(defun diffinator--project-root ()
  (or (and (fboundp 'vc-root-dir) (vc-root-dir))
      (locate-dominating-file default-directory ".git")
      default-directory))

(defun diffinator--collect-target-files (diff-text)
  (let (files)
    (dolist (line (split-string diff-text "\n" t))
      (when (string-match "^diff --git a/.* b/\\(.+\\)$" line)
        (push (match-string 1 line) files)))
    (setq files (delete-dups (nreverse files)))
    (when (null files)
      (dolist (line (split-string diff-text "\n" t))
        (when (string-match "^\\+\\+\\+ \\(?:b/\\)?\\(.+\\)$" line)
          (let ((p (match-string 1 line)))
            (unless (string= p "/dev/null")
              (push p files))))))
    (delete-dups (nreverse files))))

(defun diffinator--ensure-dir (path)
  (let ((dir (file-name-directory path)))
    (when (and dir (not (file-directory-p dir)))
      (make-directory dir t))))

(defun diffinator--buffer-string (buf)
  (with-current-buffer buf
    (buffer-substring-no-properties (point-min) (point-max))))

(defun diffinator--call-process (exe dir argv)
  (let* ((default-directory dir)
         (out (generate-new-buffer " *diffinator out*"))
         (err (generate-new-buffer " *diffinator err*"))
         (standard-error err)
         exit-code stdout stderr)
    (unwind-protect
        (progn
          (setq exit-code (apply #'call-process exe nil out nil argv))
          (setq stdout (with-current-buffer out (buffer-string)))
          (setq stderr (with-current-buffer err (buffer-string)))
          (list :ok (eq exit-code 0) :exit exit-code :stdout stdout :stderr stderr))
      (when (buffer-live-p out) (kill-buffer out))
      (when (buffer-live-p err) (kill-buffer err)))))

(defun diffinator--write-workspace-files (files root tmpdir bufmap modmap)
  (dolist (rel files)
    (let* ((abs (expand-file-name rel root))
           (buf (find-file-noselect abs))
           (dst (expand-file-name rel tmpdir)))
      (puthash rel buf bufmap)
      (puthash rel (with-current-buffer buf (buffer-modified-p)) modmap)
      (diffinator--ensure-dir dst)
      (with-temp-file dst
        (insert (diffinator--buffer-string buf))
        (unless (bolp) (insert "\n"))))))

(defun diffinator--copy-results-back (files tmpdir bufmap modmap)
  (dolist (rel files)
    (let* ((buf (gethash rel bufmap))
           (file (expand-file-name rel tmpdir))
           (txt (with-temp-buffer
                  (insert-file-contents file)
                  (buffer-string)))
           (was (gethash rel modmap)))
      (with-current-buffer buf
        (atomic-change-group
          (erase-buffer)
          (insert txt)
          (set-buffer-modified-p (or was t)))))))

(defun diffinator--patch-try (tmpdir patchfile p-level)
  (let* ((fuzz (format "--fuzz=%d" (max 0 diffinator-patch-fuzz)))
         (argv (append (list (format "-p%d" p-level))
                       diffinator-patch-common-args
                       (list fuzz "-i" patchfile)))
         (res (diffinator--call-process diffinator-patch-executable tmpdir argv)))
    (list :p p-level :argv argv :res res)))

(defun diffinator--apply-with-patch (tmpdir patchfile)
  (let (attempts)
    (catch 'ok
      (dolist (p diffinator-strip-levels)
        (let* ((attempt (diffinator--patch-try tmpdir patchfile p))
               (res (plist-get attempt :res)))
          (push attempt attempts)
          (when (plist-get res :ok)
            (throw 'ok (list :ok t :winner attempt :attempts (nreverse attempts))))))
      (list :ok nil :attempts (nreverse attempts)))))

;;;###autoload
(defun diffinator-replace-buffer-from-clipboard ()
  "Replace current buffer contents with clipboard text (whole-file mode)."
  (interactive)
  (unless buffer-file-name
    (user-error "diffinator: current buffer is not visiting a file"))
  (let ((txt (diffinator--read-clipboard)))
    (atomic-change-group
      (erase-buffer)
      (insert txt)
      (set-buffer-modified-p t))
    (message "diffinator: replaced buffer from clipboard → %s"
             (abbreviate-file-name buffer-file-name))))

;;;###autoload
(defun diffinator-apply-clipboard ()
  "Apply clipboard as a diff (patch-first). If it isn't a diff, replace buffer."
  (interactive)
  (let ((clip (diffinator--read-clipboard)))
    (if (diffinator--looks-like-diff-p clip)
        (let* ((root (diffinator--project-root))
               (tmpdir (make-temp-file "diffinator-" t))
               (patchfile (expand-file-name "patch.diff" tmpdir))
               (bufmap (make-hash-table :test 'equal))
               (modmap (make-hash-table :test 'equal))
               (files (diffinator--collect-target-files clip)))
          (unwind-protect
              (progn
                (when (null files)
                  (unless buffer-file-name
                    (user-error "diffinator: diff has no file headers and current buffer isn't visiting a file"))
                  (setq files (list (file-relative-name buffer-file-name root))))
                (with-temp-file patchfile
                  (insert clip)
                  (unless (string-suffix-p "\n" clip) (insert "\n")))
                (diffinator--write-workspace-files files root tmpdir bufmap modmap)
                (let ((result (diffinator--apply-with-patch tmpdir patchfile)))
                  (unless (plist-get result :ok)
                    (let ((msg (concat
                                "Project root: " root "\n"
                                "Temp workspace: " tmpdir "\n"
                                "Patch file: " patchfile "\n\n"
                                "Targets:\n  - " (string-join files "\n  - ") "\n\n"
                                "patch attempts:\n\n")))
                      (dolist (a (plist-get result :attempts))
                        (let* ((p (plist-get a :p))
                               (argv (plist-get a :argv))
                               (r (plist-get a :res))
                               (stdout (string-trim-right (or (plist-get r :stdout) "")))
                               (stderr (string-trim-right (or (plist-get r :stderr) ""))))
                          (setq msg
                                (concat msg
                                        "  - -p" (number-to-string p)
                                        " (exit " (number-to-string (plist-get r :exit)) ")\n"
                                        "    argv: " (string-join argv " ") "\n"
                                        (when (not (string-empty-p stdout))
                                          (concat "    stdout:\n" stdout "\n"))
                                        (when (not (string-empty-p stderr))
                                          (concat "    stderr:\n" stderr "\n"))
                                        "\n"))))
                      (diffinator--errbuf "diffinator: patch failed" msg)
                      (user-error "diffinator: patch failed (see *diffinator errors*)"))))
                (diffinator--copy-results-back files tmpdir bufmap modmap)
                (message "diffinator: applied diff (%d file%s): %s"
                         (length files)
                         (if (= (length files) 1) "" "s")
                         (string-join files ", ")))
            (when (file-directory-p tmpdir)
              (delete-directory tmpdir t))))
      ;; Not a diff: whole-file replace
      (diffinator-replace-buffer-from-clipboard))))

;;;###autoload
(defalias 'diffinator-apply-diff-from-kill #'diffinator-apply-clipboard)

(provide 'diffinator)
;;; diffinator.el ends here
