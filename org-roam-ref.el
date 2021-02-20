;;; org-roam-node.el --- Org-roam references -*- lexical-binding: t -*-
;; Copyright © 2020 Jethro Kuan <jethrokuan95@gmail.com>

;; Author: Jethro Kuan <jethrokuan95@gmail.com>
;; URL: https://github.com/org-roam/org-roam
;; Keywords: org-mode, roam, convenience
;; Version: 2.0.0
;; Package-Requires: ((emacs "26.1") (dash "2.13") (f "0.17.2") (s "1.12.0") (org "9.4") (emacsql "3.0.0") (emacsql-sqlite3 "1.0.2") (magit-section "2.90.1"))


;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This library provides functionality dealing with references.
;;
;; An org-roam node can contain references: these are typically sources: URLs, or cite links.
;;
;;; Code:
;;;; Library Requires
(defun org-roam-ref--completions (&optional arg filter)
  "Return an alist of refs to absolute path of Org-roam files.

When called interactively (i.e. when ARG is 1), formats the car
of the completion-candidates with extra information: title, tags,
and type \(when `org-roam-include-type-in-ref-path-completions'
is non-nil).

When called with a `C-u' prefix (i.e. when ARG is 4), forces the
default format without the formatting.

FILTER can either be a string or a function:

- If it is a string, it should be the type of refs to include as
  candidates \(e.g. \"cite\", \"website\", etc.)

- If it is a function, it should be the name of a function that
  takes three arguments: the type, the ref, and the file of the
  current candidate. It should return t if that candidate is to
  be included as a candidate."
  nil
  (let ((rows (org-roam-db-query
               [:select [refs:node-id refs:ref nodes:title nodes:file nodes:pos]
                :from refs
                :left :join nodes
                :on (= refs:node-id nodes:id)])))
    (mapcar (lambda (row)
              (pcase-let ((`(,id ,ref ,title ,file, pos) row))
                (let ((s (propertize ref 'meta (list :id id :ref ref :title title :file file :pos pos))))
                  (cons s s))))
            rows)))

(defun org-roam-ref-read (&optional initial-input filter-fn)
  "Read an Org-roam ref.
Return a string, is propertized in `meta' with additional properties.
INITIAL-INPUT is the initial prompt value.
FILTER-FN is a function applied to the completion list."
  (let* ((refs (org-roam-ref--completions))
         (refs (funcall (or filter-fn #'identity) refs))
         (ref (completing-read "Ref: "
                               (lambda (string pred action)
                                 (if (eq action 'metadata)
                                     '(metadata
                                       (annotation-function . org-roam-ref--annotation)
                                       (category . org-roam-ref))
                                   (complete-with-action action refs string pred)))
                               nil t initial-input)))
    (cdr (assoc ref refs))))

(defun org-roam-ref--annotation (ref)
  "Return the annotation for REF.
REF is assumed to be a propertized string."
  (let* ((meta (get-text-property 0 'meta ref))
         (title (plist-get meta :title)))
    (when title
      (concat " " title))))

(defun org-roam-ref-find (&optional initial-input filter-fn)
  "Find and open and Org-roam file from REF if it exists.
REF should be the value of '#+roam_key:' without any
type-information (e.g. 'cite:').
INITIAL-INPUT is the initial input to the prompt.
FILTER-FN is applied to the ref list to filter out candidates."
  (interactive)
  (let* ((ref (org-roam-ref-read initial-input filter-fn))
         (meta (get-text-property 0 'meta ref)))
    (find-file (plist-get meta :file))
    (goto-char (plist-get meta :pos))))

(provide 'org-roam-ref)
;;; org-roam-ref.el ends here
