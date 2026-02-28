;;; init.el --- SlabOS vanilla Emacs (stable, corfu vim-ish keys, magit+cider) -*- lexical-binding: t; -*-

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))

(setq inhibit-startup-screen t
      initial-scratch-message ""
      ring-bell-function #'ignore
      use-short-answers t)

(setq-default cursor-type 'bar
              indent-tabs-mode nil
              tab-width 2)

(when (eq system-type 'darwin)
  (setq mac-command-modifier 'super
        mac-option-modifier 'meta
        ns-use-native-tab-bar nil))

(setq native-comp-async-report-warnings-errors nil)
(setq warning-minimum-level :error)

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'custom-theme-load-path (expand-file-name "themes" user-emacs-directory))

(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("nongnu". "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

(set-face-attribute 'default nil
                    :family "MonoLisa MonoLisaSkav"
                    :height 120
                    :weight 'semi-light)

(load-theme 'slabos-monokai t)

(show-paren-mode 1)
(setq show-paren-delay 0
      show-paren-style 'mixed)

;; ---------------------------------------------------------------------------
;; Completion stack
;; ---------------------------------------------------------------------------

(use-package vertico
  :init (vertico-mode 1)
  :custom (vertico-cycle t))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package consult
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)
         ("C-c s" . consult-ripgrep)
         ("M-y" . consult-yank-pop)))

(use-package corfu
  :init
  (global-corfu-mode 1)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.0)
  (corfu-auto-prefix 1)
  (corfu-cycle t)
  (corfu-min-width 40)
  (corfu-max-width 90)
  (corfu-count 14)
  :config
  ;; IMPORTANT: keep any old/broken margin config dead
  (setq corfu-margin-formatters nil
        corfu-right-margin-width 0
        corfu-left-margin-width 0)

  (when (boundp 'corfu-border-width)
    (setq corfu-border-width 2))

  ;; SlabOS Corfu styling
  (set-face-attribute 'corfu-default nil
                      :background "#202020"
                      :foreground "#e8e3d6")

  (set-face-attribute 'corfu-border nil
                      :background "#2d2e2e"
                      :foreground "#2d2e2e")

  (set-face-attribute 'corfu-current nil
                      :background "#181a1c"
                      :foreground "#ffffff"
                      :weight 'bold
                      :underline nil)

  ;; Match highlights
  (dolist (f '(orderless-match-face-0 orderless-match-face-1
               orderless-match-face-2 orderless-match-face-3))
    (when (facep f)
      (set-face-attribute f nil :foreground "#66d9ef" :weight 'bold)))

  (when (facep 'completions-common-part)
    (set-face-attribute 'completions-common-part nil
                        :foreground "#66d9ef"
                        :weight 'bold))
  (when (facep 'completions-first-difference)
    (set-face-attribute 'completions-first-difference nil
                        :foreground "#fd971f"
                        :weight 'bold))

  (when (facep 'corfu-common)
    (set-face-attribute 'corfu-common nil :foreground "#66d9ef" :weight 'bold))
  (when (facep 'corfu-common-selected)
    (set-face-attribute 'corfu-common-selected nil :foreground "#66d9ef" :weight 'bold))

  (when (facep 'corfu-annotations)
    (set-face-attribute 'corfu-annotations nil :foreground "#807a6a"))

  (when (facep 'corfu-scroll-bar)
    (set-face-attribute 'corfu-scroll-bar nil :background "#2d2e2e"))
  (when (facep 'corfu-scroll-thumb)
    (set-face-attribute 'corfu-scroll-thumb nil :background "#fd971f"))

  ;; Vim-ish movement in the popup (only active while Corfu is open)
  (define-key corfu-map (kbd "C-j") #'corfu-next)
  (define-key corfu-map (kbd "C-k") #'corfu-previous)
  (define-key corfu-map (kbd "C-n") #'corfu-next)
  (define-key corfu-map (kbd "C-p") #'corfu-previous)
  (define-key corfu-map (kbd "C-l") #'corfu-insert)
  (define-key corfu-map (kbd "C-h") #'corfu-quit)
  (define-key corfu-map (kbd "<escape>") #'corfu-quit)
  (define-key corfu-map (kbd "RET") #'corfu-insert)
  (define-key corfu-map (kbd "TAB") #'corfu-insert)
  (define-key corfu-map (kbd "<tab>") #'corfu-insert))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(use-package which-key
  :init
  (setq which-key-idle-delay 0.35
        which-key-idle-secondary-delay 0.05
        which-key-sort-order 'which-key-key-order-alpha
        which-key-max-display-columns 3
        which-key-min-display-lines 3
        which-key-side-window-location 'bottom
        which-key-side-window-max-height 0.18
        which-key-side-window-slot -10)
  :config
  (which-key-mode 1))

;; ---------------------------------------------------------------------------
;; Evil + leader
;; ---------------------------------------------------------------------------

(setq evil-want-keybinding nil)

(use-package evil
  :init (setq evil-want-integration t)
  :config
  (evil-mode 1)
  (setq evil-echo-state nil))

(use-package evil-collection
  :after evil
  :config (evil-collection-init))

(use-package general
  :after evil
  :config
  (general-create-definer slab/leader
    :states '(normal visual motion)
    :prefix "SPC"
    :keymaps 'override)

  (slab/leader
    "f"   '(:ignore t :which-key "files")
    "f f" '(find-file :which-key "find")
    "f r" '(consult-recent-file :which-key "recent")

    "b"   '(:ignore t :which-key "buffers")
    "b b" '(consult-buffer :which-key "switch")
    "b k" '(kill-current-buffer :which-key "kill")

    "s"   '(:ignore t :which-key "search")
    "s s" '(consult-line :which-key "line")
    "s g" '(consult-ripgrep :which-key "ripgrep")

    "g"   '(:ignore t :which-key "git")
    "g s" '(magit-status :which-key "status")

    "c"   '(:ignore t :which-key "clojure")
    "c j" '(cider-jack-in-clj :which-key "jack-in (clj)")
    "c r" '(cider-repl :which-key "repl")

    "r"   '(:ignore t :which-key "repl")
    "r e" '(ielm :which-key "ielm")))

(use-package magit)
(use-package clojure-mode :mode ("\\.clj\\'" "\\.cljs\\'" "\\.cljc\\'" "\\.edn\\'"))
(use-package cider :after clojure-mode)

;; macOS clipboard keys
(defun slabos/paste () (interactive) (yank))
(defun slabos/copy () (interactive)
       (when (use-region-p)
         (kill-ring-save (region-beginning) (region-end))
         (deactivate-mark)))
(defun slabos/cut () (interactive)
       (when (use-region-p)
         (kill-region (region-beginning) (region-end))))
(defun slabos/select-all () (interactive)
       (goto-char (point-min))
       (push-mark (point-max) nil t))

(global-set-key (kbd "s-v") #'slabos/paste)
(global-set-key (kbd "s-c") #'slabos/copy)
(global-set-key (kbd "s-x") #'slabos/cut)
(global-set-key (kbd "s-a") #'slabos/select-all)
(global-set-key (kbd "s-z") #'undo)

(with-eval-after-load 'evil
  (define-key evil-insert-state-map (kbd "s-v") #'slabos/paste)
  (define-key evil-insert-state-map (kbd "s-c") #'slabos/copy)
  (define-key evil-insert-state-map (kbd "s-x") #'slabos/cut)
  (define-key evil-insert-state-map (kbd "s-a") #'slabos/select-all)
  (define-key evil-insert-state-map (kbd "s-z") #'undo))

(require 'slabos-chrome)
(slabos-init-chrome)

;;; init.el ends here

(with-eval-after-load 'vertico
  ;; Vim-ish movement in the minibuffer menu (Vertico)
  (define-key vertico-map (kbd "C-j") #'vertico-next)
  (define-key vertico-map (kbd "C-k") #'vertico-previous)
  (define-key vertico-map (kbd "C-l") #'vertico-exit)
  (define-key vertico-map (kbd "C-h") #'vertico-directory-delete-char)

  ;; Also keep the classic Emacs keys working
  (define-key vertico-map (kbd "C-n") #'vertico-next)
  (define-key vertico-map (kbd "C-p") #'vertico-previous))
