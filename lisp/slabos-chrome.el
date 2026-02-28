;;; slabos-chrome.el --- SlabOS powerline chrome (stable) -*- lexical-binding: t; -*-

(defgroup slabos-chrome nil
  "SlabOS UI chrome."
  :group 'convenience)

;; If powerline glyphs show as tofu, change to "▶" and "◀".
(defcustom slabos-pl-left ""
  "Powerline left separator glyph."
  :type 'string
  :group 'slabos-chrome)

(defcustom slabos-pl-right ""
  "Powerline right separator glyph."
  :type 'string
  :group 'slabos-chrome)

;; CSS token ports (doom-monokai.css)
(defconst slabos/bg             "#1c1e1f")  ;; --bg
(defconst slabos/block          "#202020")  ;; --block
(defconst slabos/line           "#2d2e2e")  ;; --line
(defconst slabos/fg             "#e8e3d6")  ;; --fg
(defconst slabos/muted          "#b7b1a1")  ;; --muted
(defconst slabos/dim            "#807a6a")  ;; --dim
(defconst slabos/orange         "#fd971f")  ;; --orange
(defconst slabos/yellow         "#e6b450")  ;; --yellow
(defconst slabos/titlebar-field "#141517")  ;; --titlebar-field
(defconst slabos/titlebar-right "#181a1c")  ;; --titlebar-seg-right

(defun slabos--pad (s) (concat " " s " "))

(defun slabos--face (bg fg &optional weight)
  (list :background bg :foreground fg :weight (or weight 'normal) :box nil))

(defun slabos--seg (text face)
  (propertize (slabos--pad text) 'face face))

(defun slabos--sep-left (from-bg to-bg)
  (propertize slabos-pl-left 'face (slabos--face from-bg to-bg)))

(defun slabos--sep-right (from-bg to-bg)
  (propertize slabos-pl-right 'face (slabos--face from-bg to-bg)))

(defun slabos--project-name ()
  (when (fboundp 'project-current)
    (when-let ((p (project-current nil)))
      (file-name-nondirectory (directory-file-name (project-root p))))))

(defun slabos--clock ()
  (format-time-string "%H:%M"))

;; -------------------------
;; Tabs / workspace list
;; -------------------------

(defun slabos--tab-names ()
  (when (bound-and-true-p tab-bar-mode)
    (mapcar (lambda (tab) (alist-get 'name tab))
            (funcall tab-bar-tabs-function))))

(defun slabos--active-tab ()
  (when (bound-and-true-p tab-bar-mode)
    (alist-get 'name (tab-bar--current-tab))))

(defun slabos--render-tabs ()
  (let* ((tabs (slabos--tab-names))
         (active (slabos--active-tab)))
    (when tabs
      (mapconcat
       (lambda (nm)
         (if (and active (string= nm active))
             (propertize (slabos--pad nm)
                         'face (slabos--face slabos/titlebar-right slabos/fg 'bold))
           (propertize (slabos--pad nm)
                       'face (slabos--face slabos/titlebar-right slabos/muted))))
       tabs
       ""))))

;; -------------------------
;; Header-line (top strip)
;; -------------------------

(defun slabos--header-left ()
  (let* ((title (or (slabos--project-name) "emacs")))
    (concat
     (slabos--seg title (slabos--face slabos/titlebar-field slabos/orange 'bold))
     (slabos--sep-left slabos/titlebar-field slabos/titlebar-right)
     (slabos--seg "" (slabos--face slabos/titlebar-right slabos/fg)))))

(defun slabos--header-right ()
  (let ((time (slabos--clock)))
    (concat
     (slabos--seg "" (slabos--face slabos/titlebar-right slabos/fg))
     (slabos--sep-right slabos/titlebar-right slabos/titlebar-right)
     (slabos--seg time (slabos--face slabos/titlebar-right slabos/orange 'bold)))))

(defun slabos--header-line ()
  (let ((left (slabos--header-left))
        (tabs (or (slabos--render-tabs) ""))
        (right (slabos--header-right)))
    (concat
     left
     tabs
     (propertize " " 'face (slabos--face slabos/titlebar-right slabos/fg)
                 'display `((space :align-to (- right ,(length right)))))
     right)))

(defun slabos-enable-top-strip ()
  (setq-default header-line-format '(:eval (slabos--header-line))))

;; -------------------------
;; Mode-line (bottom strip)
;; -------------------------

(defun slabos--evil-state ()
  (when (bound-and-true-p evil-local-mode)
    (pcase evil-state
      ('normal "N")
      ('insert "I")
      ('visual "V")
      ('replace "R")
      ('emacs "E")
      (_ "?"))))

(defun slabos--buffer-id ()
  (let ((name (buffer-name)))
    (if (buffer-modified-p) (concat name " *") name)))

(defun slabos--pos ()
  (format "L%s C%s" (format-mode-line "%l") (format-mode-line "%c")))

(defun slabos--mode-line ()
  (let* ((state (or (slabos--evil-state) ""))
         (buf (slabos--buffer-id))
         (pos (slabos--pos)))
    (concat
     (slabos--seg (if (string-empty-p state) " " state)
                  (slabos--face slabos/titlebar-field slabos/orange 'bold))
     (slabos--sep-left slabos/titlebar-field slabos/bg)
     (slabos--seg buf (slabos--face slabos/bg slabos/fg 'bold))
     ;; NOTE: this was the broken paren site. Now it is correct.
     (propertize " " 'face (slabos--face slabos/bg slabos/fg)
                 'display `((space :align-to (- right ,(+ 2 (length pos))))))

     (slabos--sep-right slabos/bg slabos/titlebar-right)
     (slabos--seg pos (slabos--face slabos/titlebar-right slabos/orange 'bold)))))

(defun slabos-enable-mode-line ()
  (setq-default mode-line-format '((:eval (slabos--mode-line)))))

(defun slabos-minimize-mode-line-noise ()
  (setq-default mode-line-modes '("" mode-name))
  (setq-default mode-line-process nil))

;; -------------------------
;; Init
;; -------------------------

(defun slabos-enable-tabs ()
  (tab-bar-mode 1)
  (setq tab-bar-show nil
        tab-bar-close-button-show nil
        tab-bar-new-button-show nil))

(defun slabos-init-chrome ()
  "Enable SlabOS header and modeline."
  (set-face-attribute 'header-line nil :box nil :background slabos/titlebar-right :foreground slabos/fg)
  (set-face-attribute 'mode-line nil :box nil :background slabos/titlebar-right :foreground slabos/fg)
  (set-face-attribute 'mode-line-inactive nil :box nil :background slabos/bg :foreground slabos/dim)
  (slabos-enable-tabs)
  (slabos-enable-top-strip)
  (slabos-minimize-mode-line-noise)
  (slabos-enable-mode-line))

(provide 'slabos-chrome)
;;; slabos-chrome.el ends here
