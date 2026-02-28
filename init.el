;;; init.el --- SlabOS vanilla Emacs (goal: replicate SlabOS screenshot) -*- lexical-binding: t; -*-

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

;; Keep minibuffer/echo area as a tight 1-line HUD.
(setq resize-mini-windows nil
      max-mini-window-height 1)

;; ---------------------------------------------------------------------------
;; macOS modifiers + macOS clipboard keys
;; ---------------------------------------------------------------------------

(when (eq system-type 'darwin)
  (setq mac-command-modifier 'super)
  (setq mac-option-modifier 'meta)
  (setq ns-use-native-tab-bar nil))

;; ---------------------------------------------------------------------------
;; Kill compilation spam
;; ---------------------------------------------------------------------------

(setq native-comp-async-report-warnings-errors nil)
(setq warning-minimum-level :error)

;; Load paths
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'custom-theme-load-path (expand-file-name "themes" user-emacs-directory))

;; Packages
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

;; Fonts
(set-face-attribute 'default nil
                    :family "MonoLisa MonoLisaSkav"
                    :height 120
                    :weight 'semi-light)

;; Theme (your literal CSS-token theme)
(load-theme 'slabos-monokai t)

;; Completion
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
  :init (global-corfu-mode 1)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.0)
  (corfu-auto-prefix 1)
  (corfu-cycle t))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

;; Which-key as the minibuffer HUD (SlabOS-style)
(use-package which-key
  :init
  (setq which-key-idle-delay 0.35
        which-key-idle-secondary-delay 0.05
        which-key-sort-order 'which-key-key-order-alpha
        which-key-max-display-columns 3
        which-key-min-display-lines 1)
  :config
  (which-key-mode 1)
  (which-key-setup-minibuffer))

;; Evil
(setq evil-want-keybinding nil)

(use-package evil
  :init (setq evil-want-integration t)
  :config
  (evil-mode 1)
  (setq evil-echo-state nil))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; Leader key (SPC)
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
    "r"   '(:ignore t :which-key "repl")
    "r e" '(ielm :which-key "ielm")))

;; Helpful
(use-package helpful
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)))

;; Lisp vibes (optional)
(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)
         (emacs-lisp-mode . rainbow-delimiters-mode)
         (ielm-mode . rainbow-delimiters-mode)))

(use-package smartparens
  :hook ((prog-mode . smartparens-mode)
         (ielm-mode . smartparens-mode))
  :config (require 'smartparens-config))

(use-package eros
  :hook ((emacs-lisp-mode . eros-mode)
         (ielm-mode . eros-mode)))

(use-package eval-sexp-fu
  :hook ((emacs-lisp-mode . eval-sexp-fu-flash-mode)
         (ielm-mode . eval-sexp-fu-flash-mode)))

(with-eval-after-load 'ielm
  (setq ielm-prompt "λ "
        ielm-dynamic-return t))

;; ---------------------------------------------------------------------------
;; macOS clipboard keys (work in Evil insert too)
;; ---------------------------------------------------------------------------

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

;; Chrome
(require 'slabos-chrome)
(slabos-init-chrome)

;;; init.el ends here
