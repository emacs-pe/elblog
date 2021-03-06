;; -*- lexical-binding: t -*-

;;; Code:

(require 'cl-lib)
(require 'rx)
(require 'htmlize)
(require 'elnode)

(defgroup elblog nil
  "Turn Emacs into a blog plataform, literally."
  :group 'comm)


;; Configuration

(defvar elblog-host "*")

(defvar elblog-port 8080
  "The port for published buffers to be served on.")

(defvar elblog-post-directory nil
  "The directory where to look for posts.")

(defvar elblog-posts nil
  "A collection elblog-posts")

(defvar elblog-post-regexp
  (rx (and bol
           (1+ anything)
           ".org"))
  "Is file a post? By default it matches org files.")

(defvar elblog-routes
  '(("^/posts/.*/$" . elblog-post-handler)
    ("^/$" . elblog-index)))

 ;; TODO: Should it be title instead?
(defvar elblog--memoized-posts nil
  "An plist containing the buffers already HTMLized. In the form
  of '((buffer-name . buffer)).")


;; Utilities

(defun elblog--get-post-language (buffer)
  "Get the language keyword option from the org buffer."
  (with-current-buffer (get-buffer buffer)
    (save-excursion
      (goto-char (point-min))
      (cl-loop
       with result = nil
       for current-element = (prog1 (org-element-context)
                               (forward-line))
       until (eql (car current-element) 'headline)
       when (and (eql 'keyword (car current-element))
                     ;; TODO: Use string-match for case-insensitive comparison
                     (string= "LANGUAGE"
                              (plist-get (cadr current-element) :key)))
       do (setq result (plist-get (cadr current-element) :value))
       finally return result))))

(defun elblog--get-post-date (buffer)
  "Get the language keyword option from the org buffer."
  (with-current-buffer (get-buffer buffer)
    (save-excursion
      (goto-char (point-min))
      (cl-loop
       with result = nil
       for current-element = (prog1 (org-element-context)
                               (forward-line))
       until (eql (car current-element) 'headline)
       when (and (eql 'keyword (car current-element))
                     ;; TODO: Use string-match for case-insensitive comparison
                     (string= "DATE"
                              (plist-get (cadr current-element) :key)))
       do (setq result (plist-get (cadr current-element) :value))
       finally return result))))


;; The meat

(cl-defstruct elblog-post
  "A blog post."
  name
  date
  language
  html-buffer)

(defun elblog-build-posts ()
  "Scan the ELBLOG-POST-DIRECTORY and collect them in
ELBLOG-POSTS."
  (setq elblog-posts nil)
  (dolist (file (directory-files elblog-post-directory t elblog-post-regexp))
    (let ((filename (file-name-base file))
          (buffer (find-file file)))
      (push (make-elblog-post :name filename
                              :date (elblog--get-post-date buffer)
                              :language (elblog--get-post-language buffer)
                              :html-buffer (htmlize-buffer buffer))
            elblog-posts)))
  elblog-posts)

(defun elblog-index (httpcon)
  "List all the published buffers.
Argument HTTPCON http connection."
  (elnode-send-html httpcon
                    (with-output-to-string
                      (princ "<!DOCTYPE html><html><head><title>Elblog index</title></head><body><ul>")
                      (dolist (post elblog-posts)
                        (princ (format "<li><a href='/posts/%s/'>%s on %s | %s </a></li>\n"
                                       (elblog-post-name post) (elblog-post-name post) (elblog-post-date post) (elblog-post-language post))))
                      (princ "</ul></body></html>"))))

(defun elblog-post-handler (httpcon)
  "Render the HTMLized buffer."
  (let* ((path (elnode-http-pathinfo httpcon))
         (buffer-name (caddr (split-string path "/"))))
    (elnode-send-html httpcon
                      (with-current-buffer
                          (htmlize-buffer (get-buffer (format "%s.org" buffer-name)))
                        (buffer-string)))))

(defun elblog-root (httpcon)
  (elnode-dispatcher httpcon elblog-routes))

(defun elblog-start ()
  "Start listening for requests for published buffers."
  (interactive)
  (when (y-or-n-p "Start publishing buffers? ")
    (elnode-start 'elblog-root :port elblog-port :host elblog-host)))

(defun elblog-stop ()
  "Stop listening for requests for published buffers."
  (interactive)
  (when (y-or-n-p "Stop publishing buffers? ")
    (elnode-stop elblog-port)))

(provide 'elblog)
;;; elblog.el ends here
