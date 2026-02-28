;;; slabos-chrome.el --- SlabOS chrome: correct powerline fg/bg semantics + state colors -*- lexical-binding: t; -*-

(defgroup slabos-chrome nil
  "SlabOS UI chrome."
  :group 'convenience)

(defcustom slabos-pl-left ""  "Powerline left separator glyph."  :type 'string :group 'slabos-chrome)
(defcustom slabos-pl-right "" "Powerline right separator glyph." :type 'string :group 'slabos-chrome)

;; CSS token ports
(defconst slabos/bg             "#1c1e1f")  ;; content bg
(defconst slabos/line           "#2d2e2e")
(defconst slabos/fg             "#e8e3d6")
(defconst slabos/muted          "#b7b1a1")
(defconst slabos/dim            "#807a6a")

;; SlabOS accent palette
(defconst slabos/orange         "#fd971f")
(defconst slabos/green          "#a6e22e")
(defconst slabos/pink           "#f92672")
(defconst slabos/yellow         "#e6b450")
(defconst slabos/cyan           "#66d9ef")

(defconst slabos/bar            "#181a1c")  ;; bar field

;; Segment backgrounds (chosen for contrast + correct wedges)
(defconst slabos/state-bg  "#141517")  ;; darker grey (carved)
(defconst slabos/buf-bg    "#202020")  ;; lighter grey (block)
(defconst slabos/time-bg   "#141517")  ;; carved like screenshot
(defconst slabos/badge-bg  "#2b1b0c")  ;; warm badge fill (top left)

(defun slabos--face (bg fg &optional weight)
  (list :background bg :foreground fg :weight (or weight 'normal) :box nil))

(defun slabos--seg (text bg fg &optional weight lpad rpad)
  (let ((lp (or lpad " "))
        (rp (or rpad " ")))
    (propertize (concat lp text rp) 'face (slabos--face bg fg weight))))

;; POWERLINE RULE:
;; left separator : background = current bg, foreground = next bg
(defun slabos--pl-left (cur-bg next-bg)
  (propertize slabos-pl-left 'face (slabos--face cur-bg next-bg)))

;; right separator : background = current bg, foreground = next bg
(defun slabos--pl-right (cur-bg next-bg)
  (propertize slabos-pl-right 'face (slabos--face cur-bg next-bg)))

(defun slabos--clock () (format-time-string "%H:%M"))

(defun slabos--project-name ()
  (when (fboundp 'project-current)
    (when-let ((p (project-current nil)))
      (file-name-nondirectory (directory-file-name (project-root p))))))

(defun slabos--label () (or (slabos--project-name) "emacs"))

;; Blink chevron in title
(defvar slabos--chev-on t)
(defvar slabos--chev-timer nil)

(defun slabos--ensure-chevron-timer ()
  (unless slabos--chev-timer
    (setq slabos--chev-timer
          (run-with-timer 0 1.1
                          (lambda ()
                            (setq slabos--chev-on (not slabos--chev-on))
                            (force-mode-line-update t))))))

(defun slabos--chevron ()
  (if slabos--chev-on "›" " "))

;; -------------------------
;; Header-line titlebar (badge -> field -> time)
;; -------------------------

(defun slabos--titlebar ()
  (let* ((label (slabos--label))
         (time (slabos--clock))
         (left (concat
                (slabos--seg label slabos/badge-bg slabos/orange 'bold " " "")
                (slabos--seg (slabos--chevron) slabos/badge-bg slabos/orange 'bold " " "")
                (slabos--pl-left slabos/badge-bg slabos/bar)))
         (right (concat
                 (slabos--pl-right slabos/bar slabos/time-bg)
                 (slabos--seg time slabos/time-bg slabos/orange 'bold " " " "))))
    (concat
     left
     (propertize " " 'face (slabos--face slabos/bar slabos/fg)
                 'display `((space :align-to (- right ,(length right)))))
     right)))

(defun slabos-enable-titlebar ()
  (setq-default header-line-format '(:eval (slabos--titlebar))))

;; -------------------------
;; Modeline (STATE -> BUFFER -> FIELD -> POS) with state colors
;; -------------------------

(defun slabos--evil-state ()
  "Return short evil state string."
  (when (bound-and-true-p evil-local-mode)
    (pcase evil-state
      ('normal  "N")
      ('insert  "I")
      ('visual  "V")
      ('replace "R")
      ('emacs   "E")
      (_        ""))))

(defun slabos--evil-state-color ()
  "Return SlabOS color for current evil state."
  (if (not (bound-and-true-p evil-local-mode))
      slabos/orange
    (pcase evil-state
      ('normal  slabos/orange)
      ('insert  slabos/green)
      ('visual  slabos/pink)
      ('replace slabos/yellow)
      ('emacs   slabos/cyan)
      (_        slabos/orange))))

(defun slabos--buffer-id ()
  (let ((name (buffer-name)))
    (if (buffer-modified-p) (concat name " *") name)))

(defun slabos--pos ()
  (format "L%s C%s" (format-mode-line "%l") (format-mode-line "%c")))

(defun slabos--modeline ()
  (let* ((state (or (slabos--evil-state) ""))
         (state-fg (slabos--evil-state-color))
         (buf   (slabos--buffer-id))
         (pos   (slabos--pos))
         ;; left segments are flush to wedges (no trailing pad)
         (seg-state (slabos--seg (if (string-empty-p state) " " state)
                                 slabos/state-bg state-fg 'bold " " ""))
         (seg-buf   (slabos--seg buf slabos/buf-bg slabos/fg 'bold " " ""))
         ;; right segment includes padding
         (seg-pos   (slabos--seg pos slabos/state-bg slabos/orange 'bold " " " "))
         (right     (concat (slabos--pl-right slabos/bar slabos/state-bg) seg-pos)))
    (concat
     seg-state
     ;;  background = state-bg, foreground = buf-bg
     (slabos--pl-left slabos/state-bg slabos/buf-bg)
     seg-buf
     ;;  background = buf-bg, foreground = bar
     (slabos--pl-left slabos/buf-bg slabos/bar)

     (propertize " " 'face (slabos--face slabos/bar slabos/fg)
                 'display `((space :align-to (- right ,(length right)))))

     right)))

(defun slabos-enable-modeline ()
  (set-face-attribute 'mode-line nil :box nil :background slabos/bar :foreground slabos/fg)
  (set-face-attribute 'mode-line-inactive nil :box nil :background slabos/bar :foreground slabos/dim)
  (setq-default mode-line-modes '("" mode-name))
  (setq-default mode-line-process nil)
  (setq-default mode-line-format '((:eval (slabos--modeline)))))

(defun slabos-apply-lines ()
  (set-face-attribute 'vertical-border nil :foreground slabos/line))

(defun slabos-init-chrome ()
  (slabos--ensure-chevron-timer)
  (set-face-attribute 'header-line nil :box nil :background slabos/bar :foreground slabos/fg)
  (slabos-apply-lines)
  (slabos-enable-titlebar)
  (slabos-enable-modeline))

(provide 'slabos-chrome)
;;; slabos-chrome.el ends here
