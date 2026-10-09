# Lovable Clone (Full-Stack Studio)

A signature-complete Lovable clone built for Windows desktop with Flutter.

## Signature Features
- **Prompt → Working Multi-File Full-Stack App on Disk**:
  - Scaffolds a complete Vite + React 18 + Tailwind CSS project on local disk (`package.json`, `index.html`, `src/App.tsx`, `src/main.tsx`, `README.md`).
  - Supports data persistence via browser `localStorage` and structured modern UI components.
  - "Build a todo app with categories" scaffolds a working Todo application with category filters, priority tags, and completion tracking.
- **Live Preview Updating Live as You Chat**:
  - Automatically spins up an internal loopback HTTP server serving the project files.
  - Embedded Windows webview with device viewport controls (Desktop 100%, Tablet 768px, Mobile 375px), reload button, and direct "Open in Browser" button.
  - Asking "Make it dark mode" updates the codebase on disk and reloads the preview in real-time.
- **Autonomous Coding Agent Loop**:
  - Inspects existing application files.
  - Synthesizes incremental updates and re-renders the web application.
  - Displays changed files pills (`src/App.tsx`, `index.html`).
- **Persistent Project Library**:
  - Projects and chat conversation history persist locally in SQLite (`projects` and `chat_messages` tables).

## Architecture
- `lib/core/settings/settings_service.dart`: LLM API key and model selection.
- `lib/core/db/database_service.dart`: SQLite tables for projects and chat messages.
- `lib/features/scaffold/template_scaffolder.dart`: Generates multi-file Vite+React+Tailwind apps on disk.
- `lib/features/agent/coding_agent_service.dart`: Coding agent for initial app synthesis and incremental modification.
- `lib/features/server/project_server.dart`: Embedded Dart HTTP server for serving the generated app.
- `lib/features/preview/live_preview_pane.dart`: Responsive live preview pane wrapping `webview_windows` and browser launcher.
- `lib/features/ui/project_workspace_screen.dart`: Two-pane workspace (chat left, preview right).
- `lib/features/ui/project_list_screen.dart`: Saved project manager.

## Running
```bash
flutter pub get
flutter run -d windows
```
