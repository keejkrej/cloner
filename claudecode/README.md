# Claude Code Clone

> Hub: [../README.md](../README.md)

Desktop clone of Claude Code focusing strictly on the signature features.

## Signature features
- **Agent loop**: Autonomous LLM ↔ tools loop until the task is complete
- **File tools**: `list_dir`, `read_file`, `grep`, `write_file`, `edit_file` (with diff match patch)
- **Terminal sandbox**: Shell commands jailed to the project directory, with approval prompts and streaming output

## Tech Stack
- **Flutter Desktop** (Windows)
- **Process execution**: `dart:io Process` with timeout and output truncation
- **Diff Engine**: `diff_match_patch`
- **Jail Security**: Strict canonical path validation refusing access outside working directory

## Signature-Complete Checklist
- [x] "Add a test for X and make it pass" completes over multiple tool calls on its own
- [x] Edits are shown as diffs and applied
- [x] Commands stream output and require approval
- [x] Paths outside the project are refused

## Running the App

```bash
cd claudecode
flutter run -d windows
```
