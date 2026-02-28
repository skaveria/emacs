;;; slabos-monokai-theme.el --- SlabOS Doom-Monokai CSS port (literal + Corfu) -*- lexical-binding: t; -*-

(deftheme slabos-monokai
  "SlabOS Doom-Monokai palette ported from doom-monokai.css tokens (literal values).")

(custom-theme-set-faces
 'slabos-monokai

 ;; Core
 '(default ((t (:background "#1c1e1f" :foreground "#e8e3d6"))))
 '(cursor  ((t (:background "#fd971f"))))
 '(fringe  ((t (:background "#1c1e1f" :foreground "#b7b1a1"))))
 '(shadow  ((t (:foreground "#807a6a"))))
 '(link    ((t (:foreground "#66d9ef" :underline t))))
 '(region  ((t (:background "#273126"))))
 '(hl-line ((t (:background "#202020"))))
 '(minibuffer-prompt ((t (:foreground "#fd971f" :weight bold))))
 '(trailing-whitespace ((t (:background "#f92672"))))

 ;; Lines / borders
 '(vertical-border ((t (:foreground "#2d2e2e"))))
 '(window-divider ((t (:foreground "#2d2e2e"))))
 '(window-divider-first-pixel ((t (:foreground "#2d2e2e"))))
 '(window-divider-last-pixel ((t (:foreground "#2d2e2e"))))

 ;; Line numbers
 '(line-number ((t (:background "#1c1e1f" :foreground "#807a6a"))))
 '(line-number-current-line ((t (:background "#1c1e1f" :foreground "#e8e3d6" :weight bold))))

 ;; Search
 '(isearch ((t (:background "#e6b450" :foreground "#1c1e1f" :weight bold))))
 '(lazy-highlight ((t (:background "#202020" :foreground "#e6b450"))))
 '(match ((t (:background "#202020" :foreground "#a6e22e" :weight bold))))

 ;; Parens
 '(show-paren-match ((t (:background "#202020" :foreground "#a6e22e" :weight bold))))
 '(show-paren-mismatch ((t (:background "#f92672" :foreground "#1c1e1f" :weight bold))))

 ;; Font-lock
 '(font-lock-builtin-face ((t (:foreground "#66d9ef"))))
 '(font-lock-comment-face ((t (:foreground "#807a6a"))))
 '(font-lock-comment-delimiter-face ((t (:foreground "#807a6a"))))
 '(font-lock-constant-face ((t (:foreground "#fd971f"))))
 '(font-lock-doc-face ((t (:foreground "#b7b1a1"))))
 '(font-lock-function-name-face ((t (:foreground "#a6e22e"))))
 '(font-lock-keyword-face ((t (:foreground "#f92672" :weight bold))))
 '(font-lock-string-face ((t (:foreground "#e6b450"))))
 '(font-lock-type-face ((t (:foreground "#66d9ef"))))
 '(font-lock-variable-name-face ((t (:foreground "#e8e3d6"))))
 '(font-lock-warning-face ((t (:foreground "#fd971f" :weight bold))))

 ;; Errors
 '(error ((t (:foreground "#f92672" :weight bold))))
 '(warning ((t (:foreground "#fd971f" :weight bold))))
 '(success ((t (:foreground "#a6e22e" :weight bold))))

 ;; Header / mode line (chrome file owns most of this)
 '(mode-line ((t (:background "#181a1c" :foreground "#e8e3d6" :box nil))))
 '(mode-line-inactive ((t (:background "#181a1c" :foreground "#807a6a" :box nil))))
 '(header-line ((t (:background "#181a1c" :foreground "#b7b1a1" :box nil))))

 ;; Vertico (minibuffer completion)
 '(vertico-current ((t (:background "#202020" :foreground "#e8e3d6" :weight bold))))

 ;; Corfu (popup completion)
 '(corfu-default ((t (:background "#202020" :foreground "#e8e3d6"))))
 '(corfu-border  ((t (:background "#2d2e2e"))))
 '(corfu-current ((t (:background "#181a1c" :foreground "#e8e3d6" :weight bold))))
 '(corfu-annotations ((t (:foreground "#807a6a"))))
 '(corfu-deprecated ((t (:foreground "#807a6a" :strike-through t))))
 '(corfu-scroll-bar ((t (:background "#2d2e2e"))))
 '(corfu-scroll-thumb ((t (:background "#807a6a"))))

 ;; Which-key
 '(which-key-key-face ((t (:foreground "#66d9ef" :weight bold))))
 '(which-key-command-description-face ((t (:foreground "#e8e3d6"))))
 '(which-key-group-description-face ((t (:foreground "#fd971f"))))
 '(which-key-local-map-description-face ((t (:foreground "#e6b450"))))

 ;; Org (light)
 '(org-level-1 ((t (:foreground "#fd971f" :weight bold))))
 '(org-level-2 ((t (:foreground "#66d9ef" :weight bold))))
 '(org-level-3 ((t (:foreground "#a6e22e" :weight bold))))
 '(org-code ((t (:foreground "#f2efe6"))))
 '(org-verbatim ((t (:foreground "#f2efe6"))))
 '(org-block ((t (:background "#202020" :foreground "#f2efe6"))))
 '(org-block-begin-line ((t (:background "#202020" :foreground "#807a6a"))))
 '(org-block-end-line ((t (:background "#202020" :foreground "#807a6a")))))

(custom-theme-set-variables
 'slabos-monokai
 '(ansi-color-names-vector
   ["#1c1e1f" "#f92672" "#a6e22e" "#e6b450" "#66d9ef" "#fd971f" "#66d9ef" "#e8e3d6"]))

(provide-theme 'slabos-monokai)
;;; slabos-monokai-theme.el ends here
