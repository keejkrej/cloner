import 'dart:io';
import 'package:path/path.dart' as p;

class TemplateScaffolder {
  /// Scaffolds a full Vite + React + Tailwind project structure on disk
  static Future<void> scaffold({
    required String projectDir,
    required String appName,
    required String appTitle,
    required String reactAppJsCode,
  }) async {
    final dir = Directory(projectDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final srcDir = Directory(p.join(projectDir, 'src'));
    if (!await srcDir.exists()) {
      await srcDir.create(recursive: true);
    }

    // 1. package.json
    final packageJson = '''{
  "name": "${appName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '-')}",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "lucide-react": "^0.395.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.3.0"
  },
  "devDependencies": {
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.1",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38",
    "tailwindcss": "^3.4.4",
    "typescript": "^5.2.2",
    "vite": "^5.3.1"
  }
}''';
    await File(p.join(projectDir, 'package.json')).writeAsString(packageJson);

    // 2. index.html (Self-contained, production-ready React 18 + Tailwind CDN + Lucide Icons)
    final indexHtml = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$appTitle</title>
  <!-- Tailwind CSS -->
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      darkMode: 'class',
      theme: {
        extend: {
          colors: {
            brand: {
              50: '#eff6ff',
              100: '#dbeafe',
              500: '#3b82f6',
              600: '#2563eb',
              700: '#1d4ed8',
            }
          }
        }
      }
    }
  </script>
  <!-- React 18 & ReactDOM -->
  <script src="https://unpkg.com/react@18/umd/react.production.min.js" crossorigin></script>
  <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js" crossorigin></script>
  <!-- Babel Standalone for JSX -->
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  <!-- Lucide Icons -->
  <script src="https://unpkg.com/lucide@latest"></script>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
    body {
      font-family: 'Inter', sans-serif;
    }
  </style>
</head>
<body class="bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-slate-100 min-h-screen transition-colors duration-200">
  <div id="root"></div>

  <script type="text/babel">
$reactAppJsCode

    const rootElement = document.getElementById('root');
    const root = ReactDOM.createRoot(rootElement);
    root.render(<App />);

    // Initialize Lucide icons on load and updates
    setTimeout(() => {
      if (window.lucide) window.lucide.createIcons();
    }, 100);
  </script>
</body>
</html>''';
    await File(p.join(projectDir, 'index.html')).writeAsString(indexHtml);

    // 3. src/App.tsx
    await File(p.join(projectDir, 'src', 'App.tsx')).writeAsString(reactAppJsCode);

    // 4. src/main.tsx
    const mainTsx = '''import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
''';
    await File(p.join(projectDir, 'src', 'main.tsx')).writeAsString(mainTsx);

    // 5. README.md
    final readme = '''# $appTitle

Generated autonomously with Lovable Clone.

## Features
- React 18 + Tailwind CSS
- Responsive layout & modern design system
- Local persistence via browser localStorage

## Local Dev Server
```bash
npm install
npm run dev
```
''';
    await File(p.join(projectDir, 'README.md')).writeAsString(readme);
  }
}
