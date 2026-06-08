# Changelog

## [Unreleased] - 2025-11-23

### Added
- Feature to record regions with file and line context
  (`gemini-cli-record-region` bound to `C-c M-w`).
- Feature to send all recorded regions together
  (`gemini-cli-send-recorded-regions` bound to `C-c C-y`).
- Feature to send a region immediately with its file path and lines
  (`gemini-cli-send-region-with-reference` bound to `C-c C-l`).

### Fixed
- Byte-compilation warnings with Emacs 30.1.
- Removed deprecated `gemini-cli-buffer` and unused variables.
- Explicitly require `outline` and `vterm` dependencies.
- Docstrings and style improvements (Checkdoc, Melpazoid).
- CI workflow now tests against Emacs 30.1.

## [b7cf30c](https://github.com/google-gemini/gemini-cli/commit/b7cf30cf666647b2c3e78162bf597f0e4605124d) - 2025-11-16

### Features

- **Initialize project:** This commit introduces the initial version of the
  `gemini-cli` Emacs extension.  This commit adds three files:
  - `README.md`: This file provides a comprehensive introduction to the
    `gemini_cli.el` library, including its motivation, features, installation
    instructions for the `gemini-cli` tool, and Emacs setup guidelines. It also
    includes a table of keyboard shortcuts for easy reference.
  - `gemini_cli.el`: This is the core Emacs Lisp file that provides the
    functionality for interacting with the Gemini CLI. It includes functions
    for starting and managing the Gemini CLI process, sending code regions for
    evaluation, and a minor mode with keybindings to streamline the workflow.
  - `instruction.gemini`: This file contains a set of instructions or tasks for
    the Gemini model, which is used for the development and testing of this
    project.
