;;; init.el --- SlabOS vanilla Emacs (stable: lisp fontify + org src + vterm) -*- lexical-binding: t; -*-

(require 'subr-x)

;; ---------------------------------------------------------------------------
;; Core hygiene
;; ---------------------------------------------------------------------------

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
;; macOS: modifiers + PATH (Homebrew)
;; ---------------------------------------------------------------------------

(when (eq system-type 'darwin)
  (setq mac-command-modifier 'super
        mac-option-modifier 'meta
        ns-use-native-tab-bar nil)

  ;; Force /opt/homebrew/bin ahead of everything else, always.
  (let* ((brew-paths '("/opt/homebrew/bin" "/opt/homebrew/sbin"
                       "/usr/local/bin" "/usr/local/sbin"))
         (cur (split-string (or (getenv "PATH") "") ":" t))
         (merged (delete-dups (append brew-paths cur))))
    (dolist (p brew-paths)
      (when (file-directory-p p)
        (add-to-list 'exec-path p)))
    (setenv "PATH" (string-join merged ":"))))

;; Keep native-comp chatter down
(setq native-comp-async-report-warnings-errors nil)
(setq warning-minimum-level :error)

;; Load paths
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'custom-theme-load-path (expand-file-name "themes" user-emacs-directory))

;; ---------------------------------------------------------------------------
;; Packages (package.el + use-package)
;; ---------------------------------------------------------------------------

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; ---------------------------------------------------------------------------
;; Fonts + Theme
;; ---------------------------------------------------------------------------

(set-face-attribute 'default nil
                    :family "MonoLisa MonoLisaSkav"
                    :height 110
                    :weight 'semi-light)

(load-theme 'slabos-monokai t)

;; Make sure font-lock is actually on everywhere
(setq font-lock-maximum-decoration t)
(setq-default font-lock-maximum-decoration t)
(global-font-lock-mode 1)

(show-paren-mode 1)
(setq show-paren-delay 0
      show-paren-style 'mixed)

;; ---------------------------------------------------------------------------
;; Performance tuning (macOS scroll lag)
;; ---------------------------------------------------------------------------

;; Reduce GC pauses while scrolling / redisplay.
(setq gc-cons-threshold (* 100 1024 1024)  ; 100MB
      gc-cons-percentage 0.6)

;; Emacs 29+ smooth pixel scrolling (great on trackpads).
(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))

;; Avoid expensive vscroll bookkeeping (often causes micro-stutter on mac).
(setq auto-window-vscroll nil)

;; Scroll behavior: avoid recentering / jumpiness.
(setq scroll-margin 3
      scroll-step 1
      scroll-conservatively 101
      scroll-preserve-screen-position t)

;; Mouse wheel tuning.
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))
      mouse-wheel-progressive-speed nil
      mouse-wheel-follow-mouse t)

;; Optional speed-ups: prioritize responsiveness during input/scroll.
(setq fast-but-imprecise-scrolling t
      redisplay-skip-fontification-on-input t)

;; ---------------------------------------------------------------------------
;; Line numbers (everywhere, with a few sane exceptions)
;; ---------------------------------------------------------------------------

(setq display-line-numbers-type t) ;; absolute line numbers everywhere
(global-display-line-numbers-mode 1)

(dolist (hook '(org-mode-hook
                vterm-mode-hook
                ielm-mode-hook
                eshell-mode-hook
                term-mode-hook
                shell-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode -1))))

;; ---------------------------------------------------------------------------
;; Completion stack (Vertico/Orderless/Marginalia/Consult/Corfu)
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
  :config
  (setq corfu-margin-formatters nil
        corfu-left-margin-width 0
        corfu-right-margin-width 0)
  (when (boundp 'corfu-border-width)
    (setq corfu-border-width 2))
  (set-face-attribute 'corfu-default nil :background "#202020" :foreground "#bdbdbd" :box nil)
  (set-face-attribute 'corfu-border  nil :background "#2d2e2e" :foreground "#2d2e2e")
  (set-face-attribute 'corfu-current nil :background "#181a1c" :foreground "#ffffff" :weight 'bold :underline nil)
  (define-key corfu-map (kbd "C-j") #'corfu-next)
  (define-key corfu-map (kbd "C-k") #'corfu-previous)
  (define-key corfu-map (kbd "<escape>") #'corfu-quit))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(use-package which-key
  :init
  (setq which-key-idle-delay 0.35
        which-key-idle-secondary-delay 0.05
        which-key-sort-order 'which-key-key-order-alpha)
  :config
  (which-key-mode 1))

;; ---------------------------------------------------------------------------
;; Evil + leader
;; ---------------------------------------------------------------------------

(setq evil-want-keybinding nil)

(use-package evil
  :init
  (setq evil-want-integration t)
  :config
  (evil-mode 1)
  (setq evil-echo-state nil)

  ;; SINGLE-TAP ESC FIX (global)
  (setq evil-esc-delay 0.0
        evil-esc-timeout 0.0)
  (define-key evil-insert-state-map (kbd "<escape>") #'evil-force-normal-state)
  (define-key evil-visual-state-map (kbd "<escape>") #'evil-force-normal-state))

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
    :keymaps 'override))

;; Also force ESC in elisp buffers (some minor modes can swallow it)
(with-eval-after-load 'elisp-mode
  (define-key emacs-lisp-mode-map (kbd "<escape>") #'evil-force-normal-state)
  (define-key lisp-interaction-mode-map (kbd "<escape>") #'evil-force-normal-state))

;; ---------------------------------------------------------------------------
;; Window + buffer management
;; ---------------------------------------------------------------------------

(require 'windmove)

(defun slabos/window-swap-left  () (interactive) (windmove-swap-states 'left))
(defun slabos/window-swap-right () (interactive) (windmove-swap-states 'right))
(defun slabos/window-swap-up    () (interactive) (windmove-swap-states 'up))
(defun slabos/window-swap-down  () (interactive) (windmove-swap-states 'down))

(global-set-key (kbd "C-x C-b") #'ibuffer)

(defun slabos/kill-buffer-and-window ()
  (interactive)
  (kill-buffer (current-buffer))
  (when (window-parent)
    (delete-window)))

;; ---------------------------------------------------------------------------
;; macOS clipboard (restore cmd-v in Evil insert)
;; ---------------------------------------------------------------------------

(defun slabos/paste () (interactive) (yank))
(global-set-key (kbd "s-v") #'slabos/paste)
(global-set-key (kbd "s-c") #'kill-ring-save)
(global-set-key (kbd "s-x") #'kill-region)
(global-set-key (kbd "s-a") #'mark-whole-buffer)
(global-set-key (kbd "s-z") #'undo)

(with-eval-after-load 'evil
  (define-key evil-insert-state-map (kbd "s-v") #'slabos/paste)
  (define-key evil-insert-state-map (kbd "s-c") #'kill-ring-save)
  (define-key evil-insert-state-map (kbd "s-x") #'kill-region)
  (define-key evil-insert-state-map (kbd "s-a") #'mark-whole-buffer)
  (define-key evil-insert-state-map (kbd "s-z") #'undo))

;; ---------------------------------------------------------------------------
;; Lisp experience (yesterday’s work)
;; ---------------------------------------------------------------------------

(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)
         (emacs-lisp-mode . rainbow-delimiters-mode)
         (lisp-interaction-mode . rainbow-delimiters-mode)
         (ielm-mode . rainbow-delimiters-mode)
         (clojure-mode . rainbow-delimiters-mode)))

(use-package smartparens
  :hook ((prog-mode . smartparens-mode)
         (emacs-lisp-mode . smartparens-mode)
         (lisp-interaction-mode . smartparens-mode)
         (ielm-mode . smartparens-mode)
         (clojure-mode . smartparens-mode))
  :config (require 'smartparens-config))

(use-package eros
  :hook ((emacs-lisp-mode . eros-mode)
         (lisp-interaction-mode . eros-mode)
         (ielm-mode . eros-mode)))

(use-package eval-sexp-fu
  :hook ((emacs-lisp-mode . eval-sexp-fu-flash-mode)
         (lisp-interaction-mode . eval-sexp-fu-flash-mode)
         (ielm-mode . eval-sexp-fu-flash-mode)))

(when (require 'slabos-lisp-fontify nil 'noerror)
  (add-hook 'emacs-lisp-mode-hook #'slabos-enable-elisp-call-heads)
  (add-hook 'lisp-interaction-mode-hook #'slabos-enable-elisp-call-heads)
  (add-hook 'clojure-mode-hook #'slabos-enable-clj-call-heads))

;; ---------------------------------------------------------------------------
;; Org (built-in) + src highlighting
;; ---------------------------------------------------------------------------

(use-package org
  :ensure nil
  :init
  (setq org-directory (expand-file-name "~/org")
        org-agenda-files (list (expand-file-name "~/org"))
        org-startup-indented t
        org-hide-emphasis-markers t
        org-ellipsis " ▾"
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-src-preserve-indentation t
        org-edit-src-content-indentation 0)
  :config
  (require 'org-src)
  (add-hook 'org-mode-hook
            (lambda ()
              (visual-line-mode 1)
              (setq-local display-line-numbers nil)
              (font-lock-mode 1))))

(use-package clojure-mode)

(with-eval-after-load 'org
  (add-to-list 'org-src-lang-modes '("clojure" . clojure))
  (add-to-list 'org-src-lang-modes '("clj" . clojure))
  (add-to-list 'org-src-lang-modes '("cljc" . clojure))
  (add-to-list 'org-src-lang-modes '("cljs" . clojure)))

(defun slabos/org-refontify ()
  (interactive)
  (font-lock-mode -1)
  (font-lock-mode 1))

(defun slabos/org-debug-src ()
  (interactive)
  (message "org-src-get-lang-mode(clojure) => %S ; org-src-fontify-natively=%S"
           (org-src-get-lang-mode "clojure")
           org-src-fontify-natively))

;; ---------------------------------------------------------------------------
;; vterm (simple + reliable)
;; ---------------------------------------------------------------------------

(use-package vterm
  :commands vterm
  :init
  (setq vterm-shell "/bin/zsh"
        vterm-max-scrollback 20000)
  :config
  (setq vterm-environment (list (concat "PATH=" (getenv "PATH"))))
  (defun slabos/vterm-send-esc () (interactive) (vterm-send-key "<escape>"))
  (add-hook 'vterm-mode-hook
            (lambda ()
              (evil-insert-state)
              (define-key vterm-mode-map (kbd "<escape>") #'evil-normal-state)
              (define-key vterm-mode-map (kbd "C-c <escape>") #'slabos/vterm-send-esc)
              (define-key vterm-mode-map (kbd "s-v") #'vterm-yank))))

(defun slabos/vterm-here ()
  (interactive)
  (let ((buf (get-buffer "*vterm*")))
    (if (buffer-live-p buf)
        (switch-to-buffer buf)
      (vterm "*vterm*"))))

;; ---------------------------------------------------------------------------
;; Leader bindings
;; ---------------------------------------------------------------------------

(slab/leader
  "f"   '(:ignore t :which-key "files")
  "f f" '(find-file :which-key "find file")
  "f r" '(consult-recent-file :which-key "recent")

  "s"   '(:ignore t :which-key "search")
  "s s" '(consult-line :which-key "search line")
  "s g" '(consult-ripgrep :which-key "ripgrep")

  "b"   '(:ignore t :which-key "buffers")
  "b b" '(consult-buffer :which-key "switch")
  "b i" '(ibuffer :which-key "ibuffer")
  "b k" '(kill-current-buffer :which-key "kill")
  "b d" '(slabos/kill-buffer-and-window :which-key "kill+window")

  "w"   '(:ignore t :which-key "windows")
  "w h" '(windmove-left :which-key "left")
  "w j" '(windmove-down :which-key "down")
  "w k" '(windmove-up :which-key "up")
  "w l" '(windmove-right :which-key "right")
  "w H" '(slabos/window-swap-left  :which-key "swap left")
  "w J" '(slabos/window-swap-down  :which-key "swap down")
  "w K" '(slabos/window-swap-up    :which-key "swap up")
  "w L" '(slabos/window-swap-right :which-key "swap right")
  "w s" '(split-window-below :which-key "split below")
  "w v" '(split-window-right :which-key "split right")
  "w o" '(delete-other-windows :which-key "only")
  "w d" '(delete-window :which-key "delete")

  "o"   '(:ignore t :which-key "open")
  "o t" '(slabos/vterm-here :which-key "vterm")
  "o ?" '(slabos/org-debug-src :which-key "org src debug")
  "o f" '(slabos/org-refontify :which-key "org refontify"))

;; ---------------------------------------------------------------------------
;; SlabOS chrome
;; ---------------------------------------------------------------------------

(require 'slabos-chrome)
(slabos-init-chrome)

;;; init.el ends here

(with-eval-after-load 'vterm
  (defun slabos/vterm-apply-slabos-faces ()
    "Make vterm match SlabOS palette via vterm-color-* faces."
    (interactive)
    ;; Base face (what the terminal background/foreground actually uses)
    (set-face-attribute 'vterm nil
                        :background "#1c1e1f"
                        :foreground "#bdbdbd")
    (set-face-attribute 'vterm-color-default nil
                        :background "#1c1e1f"
                        :foreground "#bdbdbd")

    ;; 16-color palette (faces)
    (set-face-attribute 'vterm-color-black   nil :foreground "#1c1e1f" :background "#1c1e1f")
    (set-face-attribute 'vterm-color-red     nil :foreground "#f92672" :background "#f92672")
    (set-face-attribute 'vterm-color-green   nil :foreground "#a6e22e" :background "#a6e22e")
    (set-face-attribute 'vterm-color-yellow  nil :foreground "#ffbe00" :background "#ffbe00")
    (set-face-attribute 'vterm-color-blue    nil :foreground "#66d9ef" :background "#66d9ef")
    ;; Powerline/SlabOS uses orange a lot; map magenta → orange for vibe
    (set-face-attribute 'vterm-color-magenta nil :foreground "#fd971f" :background "#fd971f")
    (set-face-attribute 'vterm-color-cyan    nil :foreground "#00c0ff" :background "#00c0ff")
    (set-face-attribute 'vterm-color-white   nil :foreground "#bdbdbd" :background "#bdbdbd")

    ;; Bright palette (faces) — vterm uses these for “bold/bright”
    (set-face-attribute 'vterm-color-bright-black   nil :foreground "#2a2c2e" :background "#2a2c2e")
    (set-face-attribute 'vterm-color-bright-red     nil :foreground "#ff2f7d" :background "#ff2f7d")
    (set-face-attribute 'vterm-color-bright-green   nil :foreground "#b6f35a" :background "#b6f35a")
    (set-face-attribute 'vterm-color-bright-yellow  nil :foreground "#ffbe00" :background "#ffbe00")
    (set-face-attribute 'vterm-color-bright-blue    nil :foreground "#66d9ef" :background "#66d9ef")
    (set-face-attribute 'vterm-color-bright-magenta nil :foreground "#fd971f" :background "#fd971f")
    (set-face-attribute 'vterm-color-bright-cyan    nil :foreground "#00c0ff" :background "#00c0ff")
    (set-face-attribute 'vterm-color-bright-white   nil :foreground "#ffffff" :background "#ffffff")

    ;; Refresh current vterm buffer if applicable
    (when (derived-mode-p 'vterm-mode)
      (vterm--redraw)))

  (add-hook 'vterm-mode-hook #'slabos/vterm-apply-slabos-faces))

(when (file-exists-p (expand-file-name "lisp/diffinator.el" user-emacs-directory))
  (load (expand-file-name "lisp/diffinator.el" user-emacs-directory) nil t))

(with-eval-after-load 'general
  (slab/leader
    "c"   '(:ignore t :which-key "code")
    "c p" '(diffinator-apply-clipboard :which-key "apply diff")))
