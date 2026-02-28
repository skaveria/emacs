;;; slabos-monokai-theme.el --- SlabOS Doom-Monokai (semantic-rich) -*- lexical-binding: t; -*-

(deftheme slabos-monokai
  "SlabOS Doom-Monokai palette (semantic-rich editor faces).")

(custom-theme-set-faces
 'slabos-monokai

 '(default ((t (:background "#1c1e1f" :foreground "#e8e3d6"))))
 '(cursor  ((t (:background "#fd971f"))))
 '(fringe  ((t (:background "#1c1e1f" :foreground "#6c675b"))))
 '(shadow  ((t (:foreground "#6c675b"))))
 '(region  ((t (:background "#2a342a"))))
 '(hl-line ((t (:background "#191c1d"))))
 '(minibuffer-prompt ((t (:foreground "#fd971f" :weight bold))))

 '(vertical-border ((t (:foreground "#2d2e2e"))))

 '(show-paren-match ((t (:background "#202020" :foreground "#a6e22e" :weight bold))))
 '(show-paren-mismatch ((t (:background "#f92672" :foreground "#1c1e1f" :weight bold))))

 ;; Main font-lock
 '(font-lock-comment-face ((t (:foreground "#6c675b" :slant italic))))
 '(font-lock-comment-delimiter-face ((t (:foreground "#6c675b" :slant italic))))
 '(font-lock-doc-face ((t (:foreground "#b7b1a1"))))
 '(font-lock-string-face ((t (:foreground "#e6db74"))))
 '(font-lock-keyword-face ((t (:foreground "#ff2f7d" :weight bold))))
 '(font-lock-builtin-face ((t (:foreground "#66d9ef"))))
 '(font-lock-function-name-face ((t (:foreground "#b6f35a" :weight bold))))
 '(font-lock-type-face ((t (:foreground "#66d9ef" :weight bold))))
 '(font-lock-constant-face ((t (:foreground "#fd971f" :weight bold))))
 '(font-lock-variable-name-face ((t (:foreground "#e8e3d6"))))
 '(font-lock-warning-face ((t (:foreground "#fd971f" :weight bold))))

 ;; Emacs 29+ extra semantic faces (these are what make init.el “wake up”)
 '(font-lock-property-name-face ((t (:foreground "#66d9ef"))))
 '(font-lock-variable-use-face ((t (:foreground "#e8e3d6"))))
 '(font-lock-operator-face ((t (:foreground "#b7b1a1"))))
 '(font-lock-number-face ((t (:foreground "#e6b450" :weight bold))))

 ;; Completion UI baselines
 '(corfu-default ((t (:background "#202020" :foreground "#e8e3d6"))))
 '(corfu-border  ((t (:background "#2d2e2e" :foreground "#2d2e2e"))))
 '(corfu-current ((t (:background "#181a1c" :foreground "#ffffff" :weight bold))))
 '(vertico-current ((t (:background "#202020" :foreground "#e8e3d6" :weight bold))))

 '(mode-line ((t (:background "#181a1c" :foreground "#e8e3d6" :box nil))))
 '(mode-line-inactive ((t (:background "#181a1c" :foreground "#6c675b" :box nil))))
 '(header-line ((t (:background "#181a1c" :foreground "#b7b1a1" :box nil)))))

(custom-theme-set-variables
 'slabos-monokai
 '(ansi-color-names-vector
   ["#1c1e1f" "#f92672" "#a6e22e" "#e6b450" "#66d9ef" "#fd971f" "#66d9ef" "#e8e3d6"]))

(provide-theme 'slabos-monokai)
;;; slabos-monokai-theme.el ends here
