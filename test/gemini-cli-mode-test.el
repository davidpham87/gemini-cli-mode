;;; gemini-cli-mode-test.el --- Tests for gemini-cli-mode

(require 'ert)
(require 'cl-lib)

;; Mock vterm functions
;; We define these globally for the test environment because gemini-cli-mode
;; expects vterm functions to be available, and we are running in -batch mode
;; where vterm is not installed.
(defvar gemini-cli-test-vterm-output nil)

(defun vterm-send-string (str)
  (push str gemini-cli-test-vterm-output))

(defun vterm-send-return ()
  (push "\n" gemini-cli-test-vterm-output))

(defun vterm-send-escape ()
  (push "ESC" gemini-cli-test-vterm-output))

(defun vterm-send-key (key &optional shift meta ctrl accept-proc-output)
  (push (format "KEY:%s" key) gemini-cli-test-vterm-output))

(defun vterm (buffer)
  "Mock vterm function."
  buffer)

;; Emulate vterm being provided so that if gemini-cli-mode (or its future versions)
;; attempts to require it, it won't fail in the batch environment where vterm is missing.
(provide 'vterm)

;; Require the package under test AFTER defining mocks
(require 'gemini-cli-mode)

;; Tests

(ert-deftest gemini-cli-test-resolve-agent-name-string ()
  "Test resolving agent name when a string is provided."
  (should (equal (gemini-cli--resolve-agent-name "test-agent") "test-agent")))

(ert-deftest gemini-cli-test-resolve-agent-name-plist ()
  "Test resolving agent name when a plist is provided."
  (should (equal (gemini-cli--resolve-agent-name '(:name "plist-agent")) "plist-agent")))

(ert-deftest gemini-cli-test-resolve-agent-name-single-default ()
  "Test resolving agent name defaults to 'gemini' when only one agent exists."
  (let ((gemini-cli-agents '((:name "gemini"))))
    (should (equal (gemini-cli--resolve-agent-name nil) "gemini"))))

(ert-deftest gemini-cli-test-resolve-agent-name-multiple ()
  "Test resolving agent name prompts when multiple agents exist."
  (let ((gemini-cli-agents '((:name "agent1") (:name "agent2"))))
    (cl-letf (((symbol-function 'completing-read)
               (lambda (prompt collection &rest args) "agent2")))
      (should (equal (gemini-cli--resolve-agent-name nil) "agent2")))))

(ert-deftest gemini-cli-test-resolve-config-from-plist ()
  "Test resolving config when plist is provided."
  (let ((config '(:name "custom" :command "cmd")))
    (should (equal (gemini-cli--resolve-config config "custom") config))))

(ert-deftest gemini-cli-test-resolve-config-from-name ()
  "Test resolving config when name is provided."
  (let ((gemini-cli-agents '((:name "stored" :command "stored-cmd"))))
    (should (equal (gemini-cli--resolve-config nil "stored")
                   '(:name "stored" :command "stored-cmd")))))

(ert-deftest gemini-cli-test-resolve-config-fallback ()
  "Test resolving config fallback."
  (let ((gemini-cli-agents '((:name "other"))))
    (should (equal (gemini-cli--resolve-config nil "non-existent")
                   '(:name "gemini" :command "gemini")))))

(ert-deftest gemini-cli-test-get-active-agent-names ()
  "Test retrieving active agent names."
  (let ((gemini-cli-active-buffers (make-hash-table :test 'equal)))
    (with-temp-buffer
      (puthash "agent1" (current-buffer) gemini-cli-active-buffers)
      (puthash "agent2" (current-buffer) gemini-cli-active-buffers)
      ;; Insert a dead buffer
      (let ((dead (get-buffer-create "dead-buffer")))
        (puthash "dead" dead gemini-cli-active-buffers)
        (kill-buffer dead))

      (should (equal (gemini-cli--get-active-agent-names)
                     '("agent1" "agent2"))))))

(ert-deftest gemini-cli-test-select-active-agent ()
  "Test selecting an active agent."
  (let ((gemini-cli-active-buffers (make-hash-table :test 'equal)))
    (with-temp-buffer
      (puthash "agent1" (current-buffer) gemini-cli-active-buffers)
      (cl-letf (((symbol-function 'completing-read)
                 (lambda (prompt collection &rest args) "agent1")))
        (should (equal (gemini-cli--select-active-agent "Prompt") "agent1"))))))

(ert-deftest gemini-cli-test-get-target-buffer-prefix ()
  "Test getting target buffer with prefix arg."
  (let ((gemini-cli-active-buffers (make-hash-table :test 'equal)))
    (with-temp-buffer
      (rename-buffer "*agent1*")
      (puthash "agent1" (current-buffer) gemini-cli-active-buffers)
      (cl-letf (((symbol-function 'completing-read)
                 (lambda (prompt collection &rest args) "agent1")))
        (should (equal (gemini-cli--get-target-buffer t) (current-buffer)))))))

(ert-deftest gemini-cli-test-get-target-buffer-last ()
  "Test getting target buffer returns last buffer if live."
  (with-temp-buffer
    (let ((gemini-cli-last-buffer (current-buffer)))
      (should (equal (gemini-cli--get-target-buffer nil) (current-buffer))))))

(ert-deftest gemini-cli-test-get-target-buffer-fallback ()
  "Test getting target buffer falls back to first active."
  (let ((gemini-cli-last-buffer nil)
        (gemini-cli-active-buffers (make-hash-table :test 'equal)))
    (with-temp-buffer
      (puthash "agent1" (current-buffer) gemini-cli-active-buffers)
      (should (equal (gemini-cli--get-target-buffer nil) (current-buffer))))))

(ert-deftest gemini-cli-test-initialize-session ()
  "Test session initialization sends correct commands."
  (let ((gemini-cli-test-vterm-output nil)
        (config '(:command "test-cmd" :initial-prompt "hello")))
    ;; Mock logging and execute prompt
    (cl-letf (((symbol-function 'gemini-cli-execute-prompt) #'ignore)
              ((symbol-function 'gemini-cli--log-conversation) #'ignore))
      (with-temp-buffer
        (gemini-cli--initialize-session (current-buffer) config t)
        ;; Output is pushed in reverse order
        (should (equal (reverse gemini-cli-test-vterm-output)
                       '("test-cmd" "\n" "hello" "\n")))))))
