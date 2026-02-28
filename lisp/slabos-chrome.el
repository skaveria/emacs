;;; slabos-chrome.el --- SlabOS chrome: powerline wedges everywhere -*- lexical-binding: t; -*-

(defgroup slabos-chrome nil
  "SlabOS UI chrome."
  :group 'convenience)

;; If powerline glyphs show as tofu, change to "▶" and "◀".
(defcustom slabos-pl-left ""  "Powerline left separator glyph."  :type 'string :group 'slabos-chrome)
(defcustom slabos-pl-right "" "Powerline right separator glyph." :type 'string :group 'slabos-chrome)

;; CSS token ports
(defconst slabos/bg             "#1c1e1f")  ;; content bg
(defconst slabos/line           "#2d2e2e")
(defconst slabos/fg             "#e8e3d6")
(defconst slabos/muted          "#b7b1a1")
(defconst slabos/dim            "#807a6a")
(defconst slabos/orange         "#fd971f")
(defconst slabos/titlebar-field "#141517")  ;; dark segment base
(defconst slabos/bar            "#181a1c")  ;; ALL bars base

;; “color-mix(hdr-color 18%, #000)” vibe: makes segment fill distinct vs the bar.
(defconst slabos/seg-fill "#22160b")

(defun slabos--pad (s) (concat " " s " "))
(defun slabos--face (bg fg &optional weight)
  (list :background bg :foreground fg :weight (or weight 'normal) :box nil))

(defun slabos--seg (text bg fg &optional weight)
  (propertize (slabos--pad text) 'face (slabos--face bg fg weight)))

(defun slabos--sep (glyph from-bg to-bg)
  (propertize glyph 'face (slabos--face from-bg to-bg)))

(defun slabos--sep-left (from-bg to-bg)
  (slabos--sep slabos-pl-left from-bg to-bg))

(defun slabos--sep-right (from-bg to-bg)
  (slabos--sep slabos-pl-right from-bg to-bg))

(defun slabos--clock () (format-time-string "%H:%M"))

(defun slabos--project-name ()
  (when (fboundp 'project-current)
    (when-let ((p (project-current nil)))
      (file-name-nondirectory (directory-file-name (project-root p))))))

(defun slabos--label ()
  (or (slabos--project-name) "emacs"))

;; Blinking chevron (titlebar only, like your CSS)
(defvar slabos--chev-on t)
(defvar slabos--chev-timer nil)

(defun slabos--ensure-chevron-timer ()
  (unless slabos--chev-timer
    (setq slabos--chev-timer
          (run-with-timer
           0 1.1
           (lambda ()
             (setq slabos--chev-on (not slabos--chev-on))
             (force-mode-line-update t))))))

(defun slabos--chevron ()
  (if slabos--chev-on "›" " "))

;; -------------------------
;; TITLEBAR (header-line)
;; -------------------------

(defun slabos--titlebar-left ()
  (let ((label (slabos--label)))
    (concat
     (slabos--seg label slabos/seg-fill slabos/orange 'bold)
     (slabos--seg (slabos--chevron) slabos/seg-fill slabos/orange 'bold)
     (slabos--sep-left slabos/seg-fill slabos/bar))))

(defun slabos--titlebar-right ()
  (let ((time (slabos--clock)))
    (concat
     (slabos--sep-right slabos/bar slabos/bar)
     (slabos--seg time slabos/bar slabos/orange 'bold))))

(defun slabos--titlebar ()
  (let ((left (slabos--titlebar-left))
        (right (slabos--titlebar-right)))
    (concat
     left
     (propertize " " 'face (slabos--face slabos/bar slabos/fg)
                 'display `((space :align-to (- right ,(length right)))))
     right)))

(defun slabos-enable-titlebar ()
  (setq-default header-line-format '(:eval (slabos--titlebar))))

;; -------------------------
;; MODELINE (powerline segments)
;; -------------------------

(defun slabos--evil-state ()
  (when (bound-and-true-p evil-local-mode)
    (pcase evil-state
      ('normal "N")
      ('insert "I")
      ('visual "V")
      ('replace "R")
      ('emacs "E")
      (_ ""))))

(defun slabos--buffer-id ()
  (let ((name (buffer-name)))
    (if (buffer-modified-p) (concat name " *") name)))

(defun slabos--pos ()
  (format "L%s C%s" (format-mode-line "%l") (format-mode-line "%c")))

(defun slabos--modeline ()
  (let* ((state (or (slabos--evil-state) ""))
         (buf   (slabos--buffer-id))
         (pos   (slabos--pos))

         ;; Segment backgrounds
         (bg-a slabos/seg-fill)      ;; left segment
         (bg-b slabos/bar)           ;; middle segment
         (bg-c slabos/titlebar-field) ;; right segment (darker than bar, like screenshot wedges)

         (fg-a slabos/orange)
         (fg-b slabos/fg)
         (fg-c slabos/orange)

         ;; Pre-render right to compute align-to width
         (right (concat
                 (slabos--sep-right bg-b bg-c)
                 (slabos--seg pos bg-c fg-c 'bold))))
    (concat
     ;; Left: state on warm fill
     (slabos--seg (if (string-empty-p state) " " state) bg-a fg-a 'bold)
     (slabos--sep-left bg-a bg-b)

     ;; Middle: buffer on bar base
     (slabos--seg buf bg-b fg-b 'bold)

     ;; Align to right segment
     (propertize " " 'face (slabos--face bg-b fg-b)
                 'display `((space :align-to (- right ,(length right)))))

     right)))

(defun slabos-enable-modeline ()
  ;; Ensure the built-in faces don't fight us.
  (set-face-attribute 'mode-line nil :box nil :background slabos/bar :foreground slabos/fg)
  (set-face-attribute 'mode-line-inactive nil :box nil :background slabos/bar :foreground slabos/dim)

  ;; Remove minor-mode spam
  (setq-default mode-line-modes '("" mode-name))
  (setq-default mode-line-process nil)

  (setq-default mode-line-format '((:eval (slabos--modeline)))))

;; -------------------------
;; Minibuffer / echo area: always slabos/bar (so the "dead strip" disappears)
;; -------------------------

(defvar slabos--minibuffer-cookie nil)

(defun slabos--minibuffer-style ()
  (when slabos--minibuffer-cookie
    (face-remap-remove-relative slabos--minibuffer-cookie)
    (setq slabos--minibuffer-cookie nil))
  (setq slabos--minibuffer-cookie
        (face-remap-add-relative 'default `(:background ,slabos/bar :foreground ,slabos/fg)))
  (set-face-attribute 'minibuffer-prompt nil :foreground slabos/orange :weight 'bold))

(add-hook 'minibuffer-setup-hook #'slabos--minibuffer-style)

;; Borders
(defun slabos-apply-lines ()
  (set-face-attribute 'vertical-border nil :foreground slabos/line))

;; Public
(defun slabos-init-chrome ()
  (slabos--ensure-chevron-timer)
  (set-face-attribute 'header-line nil :box nil :background slabos/bar :foreground slabos/fg)
  (slabos-apply-lines)
  (slabos-enable-titlebar)
  (slabos-enable-modeline))

(provide 'slabos-chrome)
;;; slabos-chrome.el ends her
