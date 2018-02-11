;; -*- lexical-binding: t -*-

;; declarations
(defconst services--dashboard-buffer-name "*services*")
(defconst services--output-buffer-name "*services-output*")
(defconst services--error-buffer-name "*services-error*")

(defvar services-commands-alist nil "Services commands alist")
(defvar services--commands-alist-systemd nil "Services commands alist for systemd")

(defvar services-mode-map nil "Keymap for services mode")

(defvar services-list nil "List of current system services")

;; assignments
(setq services-mode-map
      (let ((map (make-sparse-keymap)))
        (define-key map [tab] 'services-next-line)
        (define-key map [backtab] 'services-prev-line)
        (define-key map (kbd "n") 'services-next-line)
        (define-key map (kbd "p") 'services-prev-line)
        (define-key map (kbd "RET") 'services-show-current)
        (define-key map (kbd "s") 'services-status-current)
        (define-key map (kbd "S") 'services-start-current)
        (define-key map (kbd "k") 'services-stop-current)
        map))

(setq services--commands-alist-systemd
      '((list . "systemctl list-unit-files --type=service --no-legend")
        (show . (lambda (name) (format "systemctl show %s" name)))
        (status . (lambda (name) (format "systemctl status %s" name)))
        (start . (lambda (name) (format "systemctl start %s" name)))
        (stop . (lambda (name) (format "systemctl stop %s" name)))
        (restart . (lambda (name) (format "systemctl restart %s" name)))))

(setq services-commands-alist services--commands-alist-systemd)

;; defuns
(defun services--list-all ()
  "Return a list of services on the system"
  (split-string (shell-command-to-string (alist-get 'list services-commands-alist)) "[\n\r]+"))

(defun services-next-line ()
  "Move the cursor the next line"
  (interactive)
  (beginning-of-line 2))

(defun services-prev-line ()
  "Move the cursor the prev line"
  (interactive)
  (beginning-of-line 0))

(defun services--current ()
  (interactive)
  (let ((index (- (line-number-at-pos) (services--header-lines) 1)))
    (nth index services-list)))

(defun services-show-current ()
  (interactive)
  (services-run
   (apply (alist-get 'show services-commands-alist) (services--current))))

(defun services-status-current ())
(defun services-start-current ())
(defun services-stop-current ())

(defun services-run (command)
  (async-shell-command command
                       (get-buffer-create services--output-buffer-name)
                       (get-buffer-create services--error-buffer-name)))

;; mode definition
(define-derived-mode services-mode special-mode
  "Services"
  "Dashboard for viewing and controlling system services"
  (linum-mode -1)
  (page-break-lines-mode 1)
  (whitespace-mode -1)
  (setq buffer-read-only t
        truncate-lines t))

(defun services--header ()
  (list
   (format "Services on %s (%s)" system-name (current-time-string))
   ""))

(defun services--header-lines ()
  (length (services--header)))

(defun services ()
  (interactive)
  (let ((dashboard-buffer (get-buffer-create services--dashboard-buffer-name)))
    (with-current-buffer dashboard-buffer
      (display-buffer-pop-up-window dashboard-buffer nil)
      (switch-to-buffer-other-window dashboard-buffer)
      (save-excursion
        (delete-region (point-min) (point-max))
        (dolist (header-line (services--header)) (insert header-line))
        (setq services-list (services--list-all))
        (dolist (service-line (services-list)) (insert service-line))
      (services-mode)))))

;; evil
(when (and (boundp 'evil-emacs-state-modes)
           (not (memq 'services-mode evil-emacs-state-modes))) 
  (add-to-list 'evil-emacs-state-modes 'services-mode))
