;;; early-init.el --- fast + minimal -*- lexical-binding: t; -*-

;; Faster startup
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Keep macOS menu bar; remove clutter
(menu-bar-mode 1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode 0)

;; Retina friendliness
(setq frame-resize-pixelwise t)

;; Let init.el control package loading
(setq package-enable-at-startup nil)

;;; early-init.el ends here
