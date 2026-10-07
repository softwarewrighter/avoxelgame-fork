;; Batch export of literate.org to literate.html.
;;   emacs -Q --batch -l tangle/export.el
;; htmlize gives the C and GLSL blocks syntax colour; gnu-apl-mode does the
;; same for the APL blocks, which Org does not know about by default.
(require 'package)
;; An extra package directory can be added without touching ~/.emacs.d:
;;   LITERATE_ELPA=/path/to/elpa emacs -Q --batch -l tangle/export.el
(let ((extra (getenv "LITERATE_ELPA")))
  (when (and extra (file-directory-p extra))
    (add-to-list 'package-directory-list extra)))
(package-initialize)
(require 'org)
(require 'ox-html)
(when (require 'htmlize nil t)
  (setq org-html-htmlize-output-type 'css))
(when (require 'gnu-apl-mode nil t)
  (add-to-list 'org-src-lang-modes '("apl" . gnu-apl)))
(setq org-html-doctype "html5"
      org-html-html5-fancy t
      org-html-head-include-default-style nil
      org-html-head-include-scripts nil
      org-html-validation-link nil
      org-export-with-smart-quotes t
      org-confirm-babel-evaluate nil
      org-export-use-babel nil)
(find-file "literate.org")
(org-html-export-to-html)
