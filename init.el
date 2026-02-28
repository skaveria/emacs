;;; init.el --- SlabOS vanilla Emacs (stable) -*- lexical-binding: t; -*-

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

;; ---------------------------------------------------------------------------
;; macOS: disable native window tabbing (the white tab bar)
;; ---------------------------------------------------------------------------

(when (eq system-type 'darwin)
  ;; Don't use macOS "window tabs" (this is the ugly white strip)
  (setq ns-use-native-tab-bar nil)
  ;; If the function exists (varies by build), force it off:
  (when (fboundp 'mac-toggle-tab-bar)
    (ignore-errors (mac-toggle-tab-bar -1))))

;; ---------------------------------------------------------------------------
;; Kill compilation spam (native-comp warnings)
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

;; Theme
(condition-case err
    (load-theme 'slabos-monokai t)
  (error
   (message "Theme load failed: %s" (error-message-string err))
   (load-theme 'tango-dark t)))

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

;; Which-key
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

;; Evil
(setq evil-want-keybinding nil)

(use-package evil
  :init
  (setq evil-want-integration t)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

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

;; Lisp vibes
(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)
         (emacs-lisp-mode . rainbow-delimiters-mode)
         (ielm-mode . rainbow-delimiters-mode)))

(use-package smartparens
  :hook ((prog-mode . smartparens-mode)
         (ielm-mode . smartparens-mode))
  :config
  (require 'smartparens-config))

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
;; Tabs: we render our own; hide Emacs' tab-bar UI
;; ---------------------------------------------------------------------------

(tab-bar-mode 1)
(setq tab-bar-show nil
      tab-bar-close-button-show nil
      tab-bar-new-button-show nil)

;; SlabOS chrome (top + bottom powerline)
(when (require 'slabos-chrome nil 'noerror)
  (ignore-errors (slabos-init-chrome)))

;;; init.el ends here
