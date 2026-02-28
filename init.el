;;; init.el --- SlabOS vanilla Emacs (Doom-level Elisp pop) -*- lexical-binding: t; -*-

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

;; Ensure our config files are always Elisp mode
(add-to-list 'auto-mode-alist '("init\\.el\\'" . emacs-lisp-mode))
(add-to-list 'auto-mode-alist '("early-init\\.el\\'" . emacs-lisp-mode))

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

;; Font-lock should be maximum everywhere
(setq font-lock-maximum-decoration t)
(setq-default font-lock-maximum-decoration t)
(global-font-lock-mode 1)

;; Parens
(show-paren-mode 1)
(setq show-paren-delay 0
      show-paren-style 'mixed)

;; ---------------------------------------------------------------------------
;; “Doom sauce” for Elisp semantic pop
;; ---------------------------------------------------------------------------

(use-package highlight-quoted
  :hook ((emacs-lisp-mode . highlight-quoted-mode)
         (lisp-interaction-mode . highlight-quoted-mode)))

(use-package highlight-defined
  :hook ((emacs-lisp-mode . highlight-defined-mode)
         (lisp-interaction-mode . highlight-defined-mode)))

;; Emacs 29+ semantic faces (these are what Doom-like setups rely on)
(defun slabos/apply-elisp-semantic-faces ()
  (when (facep 'font-lock-function-call-face)
    (set-face-attribute 'font-lock-function-call-face nil
                        :foreground "#b6f35a" :weight 'bold))
  (when (facep 'font-lock-variable-use-face)
    (set-face-attribute 'font-lock-variable-use-face nil
                        :foreground "#e8e3d6" :weight 'normal))
  (when (facep 'font-lock-property-use-face)
    (set-face-attribute 'font-lock-property-use-face nil
                        :foreground "#66d9ef"))
  (when (facep 'font-lock-number-face)
    (set-face-attribute 'font-lock-number-face nil
                        :foreground "#e6b450" :weight 'bold)))

(add-hook 'emacs-lisp-mode-hook #'slabos/apply-elisp-semantic-faces)
(add-hook 'lisp-interaction-mode-hook #'slabos/apply-elisp-semantic-faces)

;; ---------------------------------------------------------------------------
;; Completion stack
;; ---------------------------------------------------------------------------

(use-package vertico
  :init (vertico-mode 1)
  :custom (vertico-cycle t)
  :config
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
  (setq corfu-margin-formatters nil
        corfu-left-margin-width 0
        corfu-right-margin-width 0)

  (when (boundp 'corfu-border-width)
    (setq corfu-border-width 2))

  (set-face-attribute 'corfu-default nil :background "#202020" :foreground "#e8e3d6" :box nil)
  (set-face-attribute 'corfu-border  nil :background "#2d2e2e" :foreground "#2d2e2e")
  (set-face-attribute 'corfu-current nil :background "#181a1c" :foreground "#ffffff" :weight 'bold :underline nil)

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
  :config (which-key-mode 1))

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
    "f f" '(find-file :which-key "find")
    "b b" '(consult-buffer :which-key "switch")
    "s s" '(consult-line :which-key "line")
    "s g" '(consult-ripgrep :which-key "ripgrep")
    "g s" '(magit-status :which-key "status")
    "c j" '(cider-jack-in-clj :which-key "jack-in (clj)")
    "c r" '(cider-repl :which-key "repl")))

(use-package magit)
(use-package clojure-mode :mode ("\\.clj\\'" "\\.cljs\\'" "\\.cljc\\'" "\\.edn\\'"))
(use-package cider :after clojure-mode)

(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)
         (emacs-lisp-mode . rainbow-delimiters-mode)
         (clojure-mode . rainbow-delimiters-mode)))

;; macOS clipboard keys
(defun slabos/paste () (interactive) (yank))
(global-set-key (kbd "s-v") #'slabos/paste)
(with-eval-after-load 'evil
  (define-key evil-insert-state-map (kbd "s-v") #'slabos/paste))

(require 'slabos-chrome)
(slabos-init-chrome)

;;; init.el ends here
