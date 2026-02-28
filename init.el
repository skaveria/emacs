;;; init.el --- SlabOS vanilla Emacs (clean) -*- lexical-binding: t; -*-

;; Keep Customize out of init
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))

;; Quiet UX
(setq inhibit-startup-screen t
      initial-scratch-message ""
      ring-bell-function #'ignore
      use-short-answers t)

(setq-default cursor-type 'bar
              indent-tabs-mode nil
              tab-width 2)

;; macOS modifiers + prevent native window tabs
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'super
        mac-option-modifier 'meta
        ns-use-native-tab-bar nil))

;; Keep native-comp chatter down
(setq native-comp-async-report-warnings-errors nil)
(setq warning-minimum-level :error)

;; Load paths
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'custom-theme-load-path (expand-file-name "themes" user-emacs-directory))

;; ---------------------------------------------------------------------------
;; Packages
;; ---------------------------------------------------------------------------

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

;; ---------------------------------------------------------------------------
;; Fonts + Theme + core visuals
;; ---------------------------------------------------------------------------

(set-face-attribute 'default nil
                    :family "MonoLisa MonoLisaSkav"
                    :height 110
                    :weight 'semi-light)

(load-theme 'slabos-monokai t)

(show-paren-mode 1)
(setq show-paren-delay 0
      show-paren-style 'mixed)

;; ---------------------------------------------------------------------------
;; Completion stack (Vertico + Corfu)
;; ---------------------------------------------------------------------------

(use-package vertico
  :init (vertico-mode 1)
  :custom (vertico-cycle t)
  :config
  ;; Vim-ish navigation in Vertico
  (define-key vertico-map (kbd "C-j") #'vertico-next)
  (define-key vertico-map (kbd "C-k") #'vertico-previous)
  (define-key vertico-map (kbd "C-l") #'vertico-exit)
  (define-key vertico-map (kbd "C-h") #'vertico-directory-delete-char))

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
  (corfu-cycle t)
  (corfu-min-width 40)
  (corfu-max-width 90)
  (corfu-count 14)
  :config
  ;; Keep margins off (stable)
  (setq corfu-margin-formatters nil
        corfu-left-margin-width 0
        corfu-right-margin-width 0)
  (when (boundp 'corfu-border-width)
    (setq corfu-border-width 2))

  ;; SlabOS Corfu styling
  (set-face-attribute 'corfu-default nil :background "#202020" :foreground "#bdbdbd" :box nil)
  (set-face-attribute 'corfu-border  nil :background "#2d2e2e" :foreground "#2d2e2e")
  (set-face-attribute 'corfu-current nil :background "#181a1c" :foreground "#ffffff" :weight 'bold :underline nil)

  ;; Vim-ish popup nav
  (define-key corfu-map (kbd "C-j") #'corfu-next)
  (define-key corfu-map (kbd "C-k") #'corfu-previous)
  (define-key corfu-map (kbd "C-l") #'corfu-insert)
  (define-key corfu-map (kbd "<escape>") #'corfu-quit))

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
  ;; SlabOS: no echo spam
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

  ;; Core
  (slab/leader
    "f f" '(find-file :which-key "find file")
    "b b" '(consult-buffer :which-key "buffers")
    "s s" '(consult-line :which-key "search line")
    "s g" '(consult-ripgrep :which-key "ripgrep")

    ;; Windows
    "w"   '(:ignore t :which-key "windows")
    "w s" '(split-window-below :which-key "split below")
    "w v" '(split-window-right :which-key "split right")
    "w d" '(delete-window :which-key "delete")
    "w o" '(delete-other-windows :which-key "only")
    "w h" '(windmove-left :which-key "left")
    "w j" '(windmove-down :which-key "down")
    "w k" '(windmove-up :which-key "up")
    "w l" '(windmove-right :which-key "right")

    ;; Git
    "g"   '(:ignore t :which-key "git")
    "g s" '(magit-status :which-key "status")

    ;; Clojure
    "c"   '(:ignore t :which-key "clojure")
    "c j" '(cider-jack-in-clj :which-key "jack-in")
    "c r" '(cider-repl :which-key "repl")

    ;; ELisp repl
    "r"   '(:ignore t :which-key "repl")
    "r e" '(ielm :which-key "ielm")))

;; ---------------------------------------------------------------------------
;; Lisp experience
;; ---------------------------------------------------------------------------

(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)
         (emacs-lisp-mode . rainbow-delimiters-mode)
         (lisp-interaction-mode . rainbow-delimiters-mode)
         (ielm-mode . rainbow-delimiters-mode)
         (clojure-mode . rainbow-delimiters-mode))
  :config
  ;; Your swapped palette (orange/pink swapped) – keep as-is
  (set-face-attribute 'rainbow-delimiters-depth-1-face nil :foreground "#f92672" :weight 'bold)
  (set-face-attribute 'rainbow-delimiters-depth-2-face nil :foreground "#fd971f" :weight 'bold)
  (set-face-attribute 'rainbow-delimiters-depth-3-face nil :foreground "#a6e22e" :weight 'bold)
  (set-face-attribute 'rainbow-delimiters-depth-4-face nil :foreground "#ffbe00" :weight 'bold)
  (set-face-attribute 'rainbow-delimiters-depth-5-face nil :foreground "#66d9ef" :weight 'bold)
  (set-face-attribute 'rainbow-delimiters-depth-6-face nil :foreground "#f92672" :weight 'bold)
  (set-face-attribute 'rainbow-delimiters-depth-7-face nil :foreground "#fd971f" :weight 'bold)
  (set-face-attribute 'rainbow-delimiters-depth-8-face nil :foreground "#a6e22e" :weight 'bold)
  (set-face-attribute 'rainbow-delimiters-depth-9-face nil :foreground "#ffbe00" :weight 'bold)
  (set-face-attribute 'rainbow-delimiters-unmatched-face nil
                      :foreground "#ffffff" :background "#f92672" :weight 'bold))

(use-package smartparens
  :hook ((prog-mode . smartparens-mode)
         (emacs-lisp-mode . smartparens-mode)
         (lisp-interaction-mode . smartparens-mode)
         (ielm-mode . smartparens-mode)
         (clojure-mode . smartparens-mode))
  :config
  (require 'smartparens-config))

(use-package eros
  :hook ((emacs-lisp-mode . eros-mode)
         (lisp-interaction-mode . eros-mode)
         (ielm-mode . eros-mode)))

(use-package eval-sexp-fu
  :hook ((emacs-lisp-mode . eval-sexp-fu-flash-mode)
         (lisp-interaction-mode . eval-sexp-fu-flash-mode)
         (ielm-mode . eval-sexp-fu-flash-mode)))

;; Our new call-head semantic fontification
(require 'slabos-lisp-fontify)
(add-hook 'emacs-lisp-mode-hook #'slabos-enable-elisp-call-heads)
(add-hook 'lisp-interaction-mode-hook #'slabos-enable-elisp-call-heads)
(add-hook 'clojure-mode-hook #'slabos-enable-clj-call-heads)

;; ---------------------------------------------------------------------------
;; Dev tools
;; ---------------------------------------------------------------------------

(use-package magit)
(use-package clojure-mode :mode ("\\.clj\\'" "\\.cljs\\'" "\\.cljc\\'" "\\.edn\\'"))
(use-package cider :after clojure-mode)

;; ---------------------------------------------------------------------------
;; macOS clipboard
;; ---------------------------------------------------------------------------

(defun slabos/paste () (interactive) (yank))
(global-set-key (kbd "s-v") #'slabos/paste)
(with-eval-after-load 'evil
  (define-key evil-insert-state-map (kbd "s-v") #'slabos/paste))

;; ---------------------------------------------------------------------------
;; SlabOS chrome
;; ---------------------------------------------------------------------------

(require 'slabos-chrome)
(slabos-init-chrome)

;;; init.el ends here
