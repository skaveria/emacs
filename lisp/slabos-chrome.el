;;; slabos-chrome.el --- SlabOS powerline chrome -*- lexical-binding: t; -*-

(defgroup slabos-chrome nil
  "SlabOS UI chrome."
  :group 'convenience)

(defcustom slabos-pl-left ""
  "Powerline left separator glyph."
  :type 'string
  :group 'slabos-chrome)

(defcustom slabos-pl-right ""
  "Powerline right separator glyph."
  :type 'string
  :group 'slabos-chrome)

;; CSS token ports (keep these in sync with your theme)
(defconst slabos/bg             "#1c1e1f")
(defconst slabos/block          "#202020")
(defconst slabos/line           "#2d2e2e")
(defconst slabos/fg             "#bdbdbd")
(defconst slabos/muted          "#b7b1a1")
(defconst slabos/dim            "#807a6a")
(defconst slabos/orange         "#fd971f")
(defconst slabos/yellow         "#ffbe00")
(defconst slabos/titlebar-field "#141517")
(defconst slabos/titlebar-right "#181a1c")

(defun slabos--pad (s) (concat " " s " "))

(defun slabos--face (bg fg &optional weight)
  (list :background bg :foreground fg :weight (or weight 'normal) :box nil))

(defun slabos--seg (text face)
  (propertize (slabos--pad text) 'face face))

(defun slabos--sep-left (from-bg to-bg)
  ;;  : background = from, foreground = to
  (propertize slabos-pl-left 'face (slabos--face from-bg to-bg)))

(defun slabos--sep-right (from-bg to-bg)
  ;;  : background = from, foreground = to
  (propertize slabos-pl-right 'face (slabos--face from-bg to-bg)))

(defun slabos--project-name ()
  (when (fboundp 'project-current)
    (when-let ((p (project-current nil)))
      (file-name-nondirectory (directory-file-name (project-root p))))))

(defun slabos--clock ()
  (format-time-string "%H:%M"))

;; -------------------------
;; Header-line (top strip) — now true powerline chips
;; -------------------------

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

(defun slabos--header-line ()
  "SlabOS header-line: chips on the left, time on the right."
  (let* ((title (or (slabos--project-name) "emacs"))
         (time  (slabos--clock))

         ;; chip backgrounds (top bar)
         (bg-field slabos/titlebar-field)  ;; darkest (full bar)
         (bg-title slabos/titlebar-right)  ;; dark chip
         (bg-chev  "#2a2c2e")              ;; mid chip (adds separation)
         (bg-time  slabos/titlebar-right)  ;; dark chip

         (right (concat
                 (slabos--seg time (slabos--face bg-time slabos/orange 'bold)))))
    (concat
     ;; LEFT chips: [title][chevron]
     (slabos--seg title (slabos--face bg-title slabos/orange 'bold))
     (slabos--sep-left bg-title bg-chev)
     (slabos--seg (slabos--chevron) (slabos--face bg-chev slabos/orange 'bold))
     (slabos--sep-left bg-chev bg-field)

     ;; FILL
     (propertize " " 'face (slabos--face bg-field slabos/fg)
                 'display `((space :align-to (- right ,(length right)))))

     ;; RIGHT chip: [time]
     (slabos--sep-right bg-field bg-time)
     right)))

(defun slabos-enable-top-strip ()
  (setq-default header-line-format '(:eval (slabos--header-line))))

;; -------------------------
;; Modeline (bottom strip): state + buffer | right-aligned mode + pos
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

(defun slabos--modeline ()
  "SlabOS modeline with distinct powerline chips."
  (let* ((state (or (slabos--evil-state) ""))
         (buf   (slabos--buffer-id))
         (mode  (format-mode-line mode-name))
         (pos   (slabos--pos))

         ;; High contrast segment backgrounds
         (bg-state slabos/titlebar-field)  ;; #141517
         (bg-buf   "#2a2c2e")              ;; mid
         ;; Whole bar dark like titlebar-field
         (bg-fill  slabos/titlebar-field)  ;; #141517
         (bg-mode  "#3a3d40")              ;; lighter
         (bg-pos   "#232527")              ;; dark-mid

         (right (concat
                 (slabos--seg mode (slabos--face bg-mode slabos/yellow 'bold))
                 (slabos--sep-right bg-mode bg-pos)
                 (slabos--seg pos (slabos--face bg-pos slabos/orange 'bold)))))
    (concat
     ;; STATE CHIP
     (slabos--seg state (slabos--face bg-state slabos/orange 'bold))
     (slabos--sep-left bg-state bg-buf)

     ;; BUFFER CHIP (distinct tag)
     (slabos--seg buf (slabos--face bg-buf slabos/fg 'bold))
     (slabos--sep-left bg-buf bg-fill)

     ;; FILL (dark like titlebar-field)
     (propertize " "
                 'face (slabos--face bg-fill slabos/muted)
                 'display `((space :align-to (- right ,(length right)))))

     ;; RIGHT CLUSTER
     right)))

(defun slabos-enable-mode-line ()
  (setq-default mode-line-format '((:eval (slabos--modeline)))))

(defun slabos-minimize-mode-line-noise ()
  (setq-default mode-line-modes '("" mode-name))
  (setq-default mode-line-process nil))

;; -------------------------
;; Init
;; -------------------------

(defun slabos-init-chrome ()
  "Enable SlabOS header and modeline."
  (slabos--ensure-chevron-timer)

  ;; Faces: make the bar field dark like the titlebar-field
  (set-face-attribute 'header-line nil :box nil :background slabos/titlebar-field :foreground slabos/fg)
  (set-face-attribute 'mode-line nil :box nil :background slabos/titlebar-field :foreground slabos/fg)
  (set-face-attribute 'mode-line-inactive nil :box nil :background slabos/bg :foreground slabos/dim)
  (set-face-attribute 'vertical-border nil :foreground slabos/line)

  (slabos-enable-top-strip)
  (slabos-minimize-mode-line-noise)
  (slabos-enable-mode-line))

(provide 'slabos-chrome)
;;; slabos-chrome.el ends here
