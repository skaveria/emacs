;;; slabos-lisp-fontify.el --- SlabOS Lisp call-head highlighting -*- lexical-binding: t; -*-

;; Goal:
;; - Vanilla Emacs, but “Doom-grade” Lisp readability.
;; - Make the FIRST symbol in a list pop (the call head).
;; - For Emacs Lisp: classify (special form / macro / function / variable).
;; - For Clojure: pattern-based heads + keywords.

(require 'cl-lib)

;; -------------------------
;; Faces (tuned to your SlabOS palette)
;; -------------------------

(defface slabos/lisp-head-special
  '((t :foreground "#ff2f7d" :weight bold))
  "Head of list for special forms.")

(defface slabos/lisp-head-macro
  '((t :foreground "#fd971f" :weight bold))
  "Head of list for macros.")

(defface slabos/lisp-head-fn
  '((t :foreground "#b6f35a" :weight bold))
  "Head of list for function calls.")

(defface slabos/lisp-head-var
  '((t :foreground "#66d9ef" :weight bold))
  "Head of list for variables/symbols that aren’t fns/macros/special.")

(defface slabos/lisp-clj-keyword
  '((t :foreground "#fd971f" :weight bold))
  "Clojure :keywords.")

(defface slabos/lisp-clj-head-1
  '((t :foreground "#f92672" :weight bold))
  "Clojure structural head 1.")

(defface slabos/lisp-clj-head-2
  '((t :foreground "#fd971f" :weight bold))
  "Clojure structural head 2.")

(defface slabos/lisp-clj-head-3
  '((t :foreground "#a6e22e" :weight bold))
  "Clojure structural head 3.")

;; -------------------------
;; Helpers
;; -------------------------

(defun slabos--in-string-or-comment-p ()
  "Non-nil if point is inside a string or comment."
  (let ((ppss (syntax-ppss)))
    (or (nth 3 ppss) (nth 4 ppss))))

(defun slabos--elisp-head-face (sym)
  "Pick the right face for Emacs Lisp list head SYM (a symbol)."
  (cond
   ((special-form-p sym) 'slabos/lisp-head-special)
   ((macrop sym)         'slabos/lisp-head-macro)
   ((fboundp sym)        'slabos/lisp-head-fn)
   ((boundp sym)         'slabos/lisp-head-var)
   (t                    'slabos/lisp-head-var)))

;; -------------------------
;; Emacs Lisp: classify list head
;; -------------------------

(defun slabos--elisp-match-head (limit)
  "Font-lock matcher: find next (HEAD ...) and set match 1 to HEAD."
  (catch 'found
    (while (re-search-forward "(\\s-*\\(\\(?:\\sw\\|\\s_\\|\\s.\\)+\\)" limit t)
      (unless (slabos--in-string-or-comment-p)
        (throw 'found t)))
    nil))

(defun slabos--elisp-apply-head-face ()
  "Compute face for match 1 based on symbol classification."
  (let* ((txt (match-string-no-properties 1))
         (sym (intern-soft txt)))
    (when sym
      (slabos--elisp-head-face sym))))

(defun slabos-enable-elisp-call-heads ()
  "Enable SlabOS call-head highlighting in Emacs Lisp buffers."
  (font-lock-add-keywords
   nil
   `((slabos--elisp-match-head
      1 (slabos--elisp-apply-head-face) prepend)))
  (font-lock-flush)
  (font-lock-ensure))

;; -------------------------
;; Clojure: pattern-based (fast + effective)
;; -------------------------

(defconst slabos--clj-heads-1
  '("def" "defn" "defn-" "defmacro" "defonce" "defmulti" "defmethod"
    "ns" "comment" "testing" "deftest"
    "let" "let*" "when" "when-not" "if" "if-not" "cond" "case"
    "doseq" "dotimes" "loop" "recur"
    "->" "->>" "some->" "some->>" "cond->" "cond->>"
    "try" "catch" "finally"
    "fn" "fn*" "do" "doto" "with-open" "binding" "locking")
  "Strong structural heads (pink).")

(defconst slabos--clj-heads-2
  '("assoc" "dissoc" "update" "update-in" "get" "get-in"
    "merge" "select-keys"
    "map" "mapv" "filter" "remove" "reduce" "into" "comp" "juxt"
    "->map" "hash-map" "sorted-map"
    "str" "keyword" "name" "pr-str")
  "Common ops (orange).")

(defconst slabos--clj-heads-3
  '("println" "prn" "pprint" "tap>" "spy" "dbg"
    "swap!" "reset!" "deref" "@")
  "Runtime/IO-ish heads (green).")

(defun slabos--clj-head-face (head)
  (cond
   ((member head slabos--clj-heads-1) 'slabos/lisp-clj-head-1)
   ((member head slabos--clj-heads-2) 'slabos/lisp-clj-head-2)
   ((member head slabos--clj-heads-3) 'slabos/lisp-clj-head-3)
   (t nil)))

(defun slabos--clj-match-head (limit)
  "Find next (HEAD ...) and set match 1 to HEAD."
  (catch 'found
    (while (re-search-forward "(\\s-*\$begin:math:text$\[\[\:alnum\:\]\*\+\!\_\?\<\>\.\/\-\]\+\\$end:math:text$" limit t)
      (unless (slabos--in-string-or-comment-p)
        (throw 'found t)))
    nil))

(defun slabos--clj-apply-head-face ()
  (slabos--clj-head-face (match-string-no-properties 1)))

(defun slabos-enable-clj-call-heads ()
  "Enable SlabOS call-head highlighting in clojure-mode buffers."
  ;; :keywords
  (font-lock-add-keywords
   nil
   '(("\\_<:\$begin:math:text$\[\[\:alnum\:\]\_\?\!\*\/\+\<\>\=\.\-\]\+\\$end:math:text$\\_>"
      0 'slabos/lisp-clj-keyword prepend)))

  ;; list heads
  (font-lock-add-keywords
   nil
   `((slabos--clj-match-head
      1 (slabos--clj-apply-head-face) prepend)))
  (font-lock-flush)
  (font-lock-ensure))

(provide 'slabos-lisp-fontify)
;;; slabos-lisp-fontify.el ends here
