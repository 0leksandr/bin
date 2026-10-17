# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

This repository is a personal collection of small shell scripts. There is no build, no lint configuration, and no test suite. To try a script, run it by name.

Most scripts are POSIX `sh` with `set -e` or `set -eu`. Some scripts are `bash`. Indent with four spaces. Many scripts use GNU-style long options (`head --lines`, `xargs --no-run-if-empty`, `grep --invert-match`) and `sed -r`. Keep the style of the script that you edit.

Some scripts came from a Linux (apt) machine. Examples are `install`, `update`, and `bash_completion/`. The current machine is macOS.

## Architecture

Files with a leading `_` are internal helpers that other scripts call:

- `_real "$0"`: finds the system binary that a wrapper shadows. It skips paths under `$HOME`.
- `_cmd`: runs a command from a shell-quoted string without `eval`.
- `_log`: appends a line to `$HOME/.temp/logs/<calling-script>.log`.
- `_highlander`: kills other instances of the calling script.
- `_os`: prints `mac` or `linux`.
- `_parent`, `_parents`, `_shells`, `_is_in_script`: inspect the process tree.

Some scripts shadow standard commands and call the real binary through `_real`. Examples are `git`, `rm`, and `mv`. The `rm` wrapper sends files to `/usr/bin/trash` unless you give `-f`. The `mv` wrapper uses `git mv` for a plain tracked rename. If you change a wrapper, every shell on this machine gets the change.

Other directories:

- `mac/`: macOS-only scripts.
- `root/`: scripts for `sudo` (see `root/README`).
- `bash_completion/`: completion definitions for the scripts.
- `utils/`: scripts and configuration files that are not on `PATH`.
- `trash/`: retired scripts and shell experiments (`trash/tests/`). Do not edit or reuse them unless the user asks.

## Working rules

Stay inside this directory. Do not read or run things outside it unless the user asks.
