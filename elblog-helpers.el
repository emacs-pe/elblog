
(defun elblog-publish-dir (directory)
  "Add all the files in the buffer to the `elnode-published-buffers'"
  (dolist (file (directory-files directory t))
    (message "%s" file)
    )
  )

(elblog-publish-dir "~/.emacs.d/user-lisp")


(defun assoc-delete-all (key alist)
  "Delete from ALIST all elements whose car is `equal' to KEY.
Return the modified alist.
Elements of ALIST that are not conses are ignored."
  (while (and (consp (car alist))
              (equal (car (car alist)) key))
    (setq alist (cdr alist)))
  (let ((tail alist) tail-cdr)
    (while (setq tail-cdr (cdr tail))
      (if (and (consp (car tail-cdr))
               (equal (car (car tail-cdr)) key))
          (setcdr tail (cdr tail-cdr))
        (setq tail tail-cdr))))
  alist)

(provide 'elblog-helpers)