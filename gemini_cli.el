;;; gemini --- Emacs interface for Gemini CLI

;;; Commentary:
;; This file provides functions and a minor mode to interact with the Gemini CLI
;; from within Emacs.  It allows starting the Gemini CLI in a term buffer,
;; switching to that buffer, and sending regions of text to the Gemini process.

;;; Code:
(require 'use-package)

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown")
  :bind (:map markdown-mode-map
              ("C-c C-e" . markdown-do)))

(use-package vterm
  :ensure t)

(defvar gemini-cli/buffer nil
  "Buffer for the Gemini CLI process.")

(defun gemini-cli/rebind-cli ()
  (interactive)
  (setq gemini-cli/buffer (switch-to-buffer "*gemini-cli*")))

(defun gemini-cli/start ()
  "Open a term process and call gemini, and display the buffer."
  (interactive)
  (if (buffer-live-p gemini-cli/buffer)
      (message "Gemini process already running")
    (progn
      (split-window-horizontally)
      (setq gemini-cli/buffer (vterm "*gemini-cli*"))
      (switch-to-buffer-other-window gemini-cli/buffer)
      (vterm-send-string "gemini")
      (vterm-send-return))))

(defun gemini-cli/switch-buffer ()
  "Switch buffer to *gemini-cli*."
  (interactive)
  (if (buffer-live-p gemini-cli/buffer)
      (switch-to-buffer-other-window "*gemini-cli*")
    (gemini-cli/start)))

(defun gemini-cli/send-region (start end)
  "Send the region from START to END to the gemini process.
This is done without switching the current buffer.
The region content is sent as input to the Gemini CLI process."
  (interactive "r")
  (let ((current-buffer (current-buffer))
        (region-text (buffer-substring-no-properties start end)))
    (if (buffer-live-p gemini-cli/buffer)
        (progn
          (with-current-buffer gemini-cli/buffer
            (vterm-send-string region-text)
            (sleep-for 0.5)
            (vterm-send-escape)
            (vterm-send-return)
            (vterm-send-return)))
      (message "Gemini process not running. Run M-x gemini-cli first."))))

(defun gemini-cli/send-section ()
  "In a file with markdown format, send the current smallest section to Gemini."
  (interactive)
  (save-excursion
    (outline-back-to-heading t)
    (let ((start (point)))
      (outline-end-of-subtree)
      (gemini-cli/send-region start (point)))))


(defvar gemini-cli/mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-p") 'gemini-cli/start)
    (define-key map (kbd "C-c C-z") 'gemini-cli/switch-buffer)
    (define-key map (kbd "C-c C-r") 'gemini-cli/send-region)
    (define-key map (kbd "C-M-x") 'gemini-cli/send-section)
    map)
  "Keymap for gemini-mode.")

(define-minor-mode gemini-cli/mode
  "A minor mode for interacting with the Gemini CLI."
  :init-value nil
  :lighter " Gemini"
  :keymap gemini-cli/mode-map)

;; Activate gemini mode for .gemini files
(define-derived-mode gemini-cli/major-mode prog-mode "Gemini"
  "Major mode for editing .gemini files."
  (gemini-cli/mode 1))

(add-to-list 'auto-mode-alist '("\\.gemini\\'" . gemini-cli/major-mode))

;; Activate markdown-mode when gemini is active
(add-hook 'gemini-cli/major-mode-hook (lambda () (markdown-mode 1)))

(provide 'gemini-cli)
;;; gemini.el ends here
