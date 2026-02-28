;;; slabos-monokai-theme.el --- SlabOS Monokai (SlabOS-screaming edition) -*- lexical-binding: t; -*-

(deftheme slabos-monokai
  "SlabOS palette: console-dark base, amber chrome accents, high semantic pop.")

(custom-theme-set-faces
 'slabos-monokai

 ;; --------------------------------------------------------------------------
 ;; SlabOS tokens (from your CSS)
 ;; bg: #1c1e1f
 ;; block: #202020
 ;; line: #2d2e2e
 ;; chrome field: #181a1c
 ;; chrome dark: #141517
 ;; fg: #bdbdbd
 ;; muted: #b7b1a1
 ;; dim: #807a6a
 ;; orange: #fd971f
 ;; yellow: #ffbe00 / #ffbe00
 ;; cyan: #00c0ff
 ;; pink: #f92672
 ;; green: #a6e22e
 ;; --------------------------------------------------------------------------

 ;; Base surfaces
 '(default ((t (:background "#1c1e1f" :foreground "#bdbdbd"))))
 '(cursor  ((t (:background "#fd971f"))))
 '(fringe  ((t (:background "#1c1e1f" :foreground "#2d2e2e"))))
 '(shadow  ((t (:foreground "#807a6a"))))
 '(vertical-border ((t (:foreground "#2d2e2e"))))
 '(window-divider ((t (:foreground "#2d2e2e"))))
 '(window-divider-first-pixel ((t (:foreground "#2d2e2e"))))
 '(window-divider-last-pixel ((t (:foreground "#2d2e2e"))))

 ;; Selection + line focus (SlabOS = subtle, not neon)
 '(region  ((t (:background "#273126"))))
 '(hl-line ((t (:background "#181a1c"))))   ;; makes the active line feel like chrome
 '(lazy-highlight ((t (:background "#202020" :foreground "#ffbe00"))))
 '(isearch ((t (:background "#ffbe00" :foreground "#1c1e1f" :weight bold))))

 ;; Line numbers
 '(line-number ((t (:background "#1c1e1f" :foreground "#6c675b"))))
 '(line-number-current-line ((t (:background "#1c1e1f" :foreground "#bdbdbd" :weight bold))))

 ;; Minibuffer
 '(minibuffer-prompt ((t (:foreground "#fd971f" :weight bold))))

 ;; Parens
 '(show-paren-match ((t (:background "#202020" :foreground "#a6e22e" :weight bold))))
 '(show-paren-mismatch ((t (:background "#f92672" :foreground "#1c1e1f" :weight bold))))

 ;; --------------------------------------------------------------------------
 ;; Syntax: “SlabOS screaming”
 ;; - keywords: hot pink
 ;; - functions: green
 ;; - strings: warm off-yellow
 ;; - constants: amber
 ;; - builtins/types: cyan
 ;; - comments: dim + slightly cool (less monokai mush)
 ;; --------------------------------------------------------------------------

 '(font-lock-comment-face ((t (:foreground "#6c675b" :slant italic))))
 '(font-lock-comment-delimiter-face ((t (:foreground "#6c675b" :slant italic))))
 '(font-lock-doc-face ((t (:foreground "#b7b1a1"))))

 '(font-lock-string-face ((t (:foreground "#ffbe00"))))
 '(font-lock-keyword-face ((t (:foreground "#ff2f7d" :weight bold))))
 '(font-lock-function-name-face ((t (:foreground "#b6f35a" :weight bold))))
 '(font-lock-builtin-face ((t (:foreground "#00c0ff"))))
 '(font-lock-type-face ((t (:foreground "#00c0ff" :weight bold))))
 '(font-lock-constant-face ((t (:foreground "#fd971f" :weight bold))))
 '(font-lock-variable-name-face ((t (:foreground "#bdbdbd"))))
 '(font-lock-warning-face ((t (:foreground "#fd971f" :weight bold))))

 ;; Emacs 29+ semantic faces (this is the “alive” part)
 '(font-lock-function-call-face ((t (:foreground "#b6f35a" :weight bold))))
 '(font-lock-variable-use-face ((t (:foreground "#bdbdbd"))))
 '(font-lock-property-name-face ((t (:foreground "#00c0ff"))))
 '(font-lock-property-use-face ((t (:foreground "#00c0ff"))))
 '(font-lock-number-face ((t (:foreground "#ffbe00" :weight bold))))
 '(font-lock-operator-face ((t (:foreground "#b7b1a1"))))

 ;; Links / errors
 '(link ((t (:foreground "#00c0ff" :underline t))))
 '(link-visited ((t (:foreground "#ae81ff" :underline t))))
 '(error ((t (:foreground "#f92672" :weight bold))))
 '(warning ((t (:foreground "#fd971f" :weight bold))))
 '(success ((t (:foreground "#a6e22e" :weight bold))))

 ;; Mode/header line defaults (chrome overrides most of it)
 '(mode-line ((t (:background "#181a1c" :foreground "#bdbdbd" :box nil))))
 '(mode-line-inactive ((t (:background "#181a1c" :foreground "#6c675b" :box nil))))
 '(header-line ((t (:background "#181a1c" :foreground "#b7b1a1" :box nil))))

 ;; Corfu + Vertico baseline (init.el can still force)
 '(corfu-default ((t (:background "#202020" :foreground "#bdbdbd"))))
 '(corfu-border  ((t (:background "#2d2e2e" :foreground "#2d2e2e"))))
 '(corfu-current ((t (:background "#181a1c" :foreground "#ffffff" :weight bold))))
 '(vertico-current ((t (:background "#202020" :foreground "#bdbdbd" :weight bold))))

 ;; Which-key baseline
 '(which-key-key-face ((t (:foreground "#00c0ff" :weight bold))))
 '(which-key-group-description-face ((t (:foreground "#fd971f"))))
 '(which-key-command-description-face ((t (:foreground "#bdbdbd"))))
 '(which-key-local-map-description-face ((t (:foreground "#ffbe00"))))

 ;; Org panes (SlabOS look)
 '(org-block ((t (:background "#202020" :foreground "#f2efe6"))))
 '(org-block-begin-line ((t (:background "#202020" :foreground "#6c675b"))))
 '(org-block-end-line ((t (:background "#202020" :foreground "#6c675b"))))
 '(org-level-1 ((t (:foreground "#fd971f" :weight bold))))
 '(org-level-2 ((t (:foreground "#00c0ff" :weight bold))))
 '(org-level-3 ((t (:foreground "#a6e22e" :weight bold))))
 '(org-level-4 ((t (:foreground "#ffbe00" :weight bold))))

 ;; Magit / diff (keeps the vibe)
 '(diff-added ((t (:foreground "#a6e22e"))))
 '(diff-removed ((t (:foreground "#f92672"))))
 '(diff-changed ((t (:foreground "#ffbe00"))))
 '(diff-header ((t (:foreground "#00c0ff"))))
 '(diff-file-header ((t (:foreground "#bdbdbd" :weight bold)))))

(custom-theme-set-variables
 'slabos-monokai
 '(ansi-color-names-vector
   ["#1c1e1f" "#f92672" "#a6e22e" "#ffbe00" "#00c0ff" "#fd971f" "#00c0ff" "#bdbdbd"]))

(provide-theme 'slabos-monokai)
;;; slabos-monokai-theme.el ends here
