# Cursor Clone

> Hub: [../README.md](../README.md)

Desktop clone of Cursor focusing strictly on the signature features.

## Signature features
- **Codebase indexing** — the AI knows the whole project with vector search and live re-indexing on file save
- **Diff edits** you accept or reject directly in the editor
- **Inline autocomplete** (ghost text, Tab inserts)

## Tech Stack
- **Flutter Desktop** (Windows)
- **Watcher**: `watcher` detecting file saves for real-time re-indexing
- **Diff Engine**: `diff_match_patch`
- **FIM Autocomplete**: Fast debounced prefix/suffix model

## Signature-Complete Checklist
- [x] "Where is X handled?" on a real repo finds the right files
- [x] A requested change shows as a diff; accept writes, reject discards
- [x] Ghost-text completions appear while typing; Tab inserts
- [x] Index updates after saving a file

## Running the App

```bash
cd cursor
flutter run -d windows
```
