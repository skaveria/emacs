;;; init.el --- slabOS vanilla build -*- lexical-binding: t; -*-

;; Restore sane GC after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

(setq inhibit-startup-screen t
      initial-scratch-message ""
      ring-bell-function #'ignore
      use-short-answers t)

(setq-default cursor-type 'bar
              indent-tabs-mode nil
              tab-width 2)

;; ---------------------------------------------------------------------------
;; Package system
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
;; Fonts
;; ---------------------------------------------------------------------------

(set-face-attribute 'default nil
                    :family "MonoLisa MonoLisaSkav"
                    :height 120
                    :weight 'semi-light)

;; ---------------------------------------------------------------------------
;; SlabOS Monokai Palette
;; ---------------------------------------------------------------------------

(defconst slabos-bg        "#1c1e1f")
(defconst slabos-bg-alt    "#232526")
(defconst slabos-fg        "#f8f8f2")
(defconst slabos-gray      "#75715e")
(defconst slabos-red       "#f92672")
(defconst slabos-orange    "#fd971f")
(defconst slabos-yellow    "#e6db74")
(defconst slabos-green     "#a6e22e")
(defconst slabos-cyan      "#66d9ef")
(defconst slabos-purple    "#ae81ff")

(load-theme 'tango-dark t)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:background "#1c1e1f" :foreground "#f8f8f2"))))
 '(cursor ((t (:background "#f8f8f2"))))
 '(font-lock-builtin-face ((t (:foreground "#ae81ff"))))
 '(font-lock-comment-face ((t (:foreground "#75715e"))))
 '(font-lock-constant-face ((t (:foreground "#fd971f"))))
 '(font-lock-function-name-face ((t (:foreground "#a6e22e"))))
 '(font-lock-keyword-face ((t (:foreground "#f92672" :weight bold))))
 '(font-lock-string-face ((t (:foreground "#e6db74"))))
 '(font-lock-type-face ((t (:foreground "#66d9ef"))))
 '(mode-line ((t (:background "#232526" :foreground "#f8f8f2" :box nil))))
 '(mode-line-inactive ((t (:background "#1c1e1f" :foreground "#75715e" :box nil))))
 '(region ((t (:background "#232526")))))

;; ---------------------------------------------------------------------------
;; Completion Stack
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
         ("C-c s" . consult-ripgrep)))

(use-package corfu
  :init (global-corfu-mode 1)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.0)
  (corfu-cycle t))

;; ---------------------------------------------------------------------------
;; Evil
;; ---------------------------------------------------------------------------

(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; Simple leader key (SPC)
(use-package general
  :after evil
  :config
  (general-create-definer slab/leader
    :states '(normal visual motion)
    :prefix "SPC"))

(general-create-definer slab/leader
  :states '(normal visual motion)
  :prefix "SPC"
  :keymaps 'override)

(slab/leader
  ;; Files
  "f"  '(:ignore t :which-key "files")
  "f f" '(find-file :which-key "find")
  "f r" '(consult-recent-file :which-key "recent")

  ;; Buffers
  "b"  '(:ignore t :which-key "buffers")
  "b b" '(consult-buffer :which-key "switch")
  "b k" '(kill-current-buffer :which-key "kill")

  ;; Search
  "s"  '(:ignore t :which-key "search")
  "s s" '(consult-line :which-key "line")
  "s g" '(consult-ripgrep :which-key "ripgrep")

  ;; Git (once magit is installed)
  "g"  '(:ignore t :which-key "git")
  "g s" '(magit-status :which-key "status")

  ;; REPL
  "r"  '(:ignore t :which-key "repl")
  "r e" '(ielm :which-key "ielm"))

;; ---------------------------------------------------------------------------
;; Modeline
;; ---------------------------------------------------------------------------

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 28)
  (doom-modeline-bar-width 3)
  (doom-modeline-buffer-file-name-style 'truncate-upto-root)
  (doom-modeline-major-mode-icon t))

;; ---------------------------------------------------------------------------
;; Lisp Vibes + IELM
;; ---------------------------------------------------------------------------

(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)
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

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(which-key doom-modeline general evil-collection evil vertico smartparens rainbow-delimiters orderless marginalia helpful eval-sexp-fu eros doom-themes corfu consult cape)))

(use-package which-key
  :init
  (setq which-key-idle-delay 0.4
        which-key-idle-secondary-delay 0.05
        which-key-sort-order 'which-key-key-order-alpha
        which-key-max-display-columns 3
        which-key-min-display-lines 4
        which-key-side-window-location 'bottom
        which-key-side-window-max-height 0.25)
  :config
  (which-key-mode 1))
