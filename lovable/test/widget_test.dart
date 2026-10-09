import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:lovable/core/settings/settings_service.dart';
import 'package:lovable/features/agent/coding_agent_service.dart';
import 'package:lovable/features/projects/models/chat_message.dart';
import 'package:lovable/features/projects/models/project.dart';
import 'package:lovable/features/scaffold/template_scaffolder.dart';
import 'package:lovable/features/server/project_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TemplateScaffolder & CodingAgent Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lovable_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Scaffolds complete multi-file Vite+React+Tailwind project on disk', () async {
      await TemplateScaffolder.scaffold(
        projectDir: tempDir.path,
        appName: 'TestApp',
        appTitle: 'Test App',
        reactAppJsCode: 'function App() { return <h1>Hello</h1>; }',
      );

      expect(await File('${tempDir.path}/package.json').exists(), isTrue);
      expect(await File('${tempDir.path}/index.html').exists(), isTrue);
      expect(await File('${tempDir.path}/src/App.tsx').exists(), isTrue);
      expect(await File('${tempDir.path}/src/main.tsx').exists(), isTrue);
      expect(await File('${tempDir.path}/README.md').exists(), isTrue);

      final indexContent = await File('${tempDir.path}/index.html').readAsString();
      expect(indexContent, contains('<!DOCTYPE html>'));
      expect(indexContent, contains('React 18'));
      expect(indexContent, contains('function App()'));
    });

    test('"Build a todo app with categories" scaffolds working React todo app', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final agent = CodingAgentService(settings);

      final result = await agent.createNewApp(
        projectDir: tempDir.path,
        appName: 'TodoCategories',
        prompt: 'Build a todo app with categories',
      );

      expect(result.filesChanged, containsAll(['package.json', 'index.html', 'src/App.tsx']));

      final appCode = await File('${tempDir.path}/src/App.tsx').readAsString();
      expect(appCode, contains('todos'));
      expect(appCode, contains('categories'));
    });

    test('"Make it dark mode" updates existing project with dark mode toggle and classes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final agent = CodingAgentService(settings);

      // 1. Initial app
      await agent.createNewApp(
        projectDir: tempDir.path,
        appName: 'TodoApp',
        prompt: 'Build a todo app with categories',
      );

      // 2. Follow-up modification
      final result = await agent.modifyApp(
        projectDir: tempDir.path,
        prompt: 'Make it dark mode',
      );

      expect(result.filesChanged, contains('src/App.tsx'));
      final updatedApp = await File('${tempDir.path}/src/App.tsx').readAsString();
      expect(updatedApp, contains('isDark'));
      expect(updatedApp, contains('Switch to'));
    });
  });

  group('ProjectServer Tests', () {
    late Directory tempDir;
    late ProjectServer server;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('lovable_server_test_');
      await File('${tempDir.path}/index.html').writeAsString('<html><body><h1>Hello Lovable</h1></body></html>');
      server = ProjectServer();
    });

    tearDown(() async {
      await server.stop();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Binds to loopback port and manages lifecycle', () async {
      final url = await server.start(tempDir.path);
      expect(url, startsWith('http://localhost:'));
      expect(server.isRunning, isTrue);
      expect(server.port, isNotNull);
      expect(server.port, greaterThan(0));

      await server.stop();
      expect(server.isRunning, isFalse);
      expect(server.url, isNull);
    });
  });

  group('Models Serialization Tests', () {
    test('Project and ChatMessage models serialization', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final project = Project(
        id: 'p1',
        name: 'TodoApp',
        initialPrompt: 'Build a todo app with categories',
        dirPath: '/path/to/project',
        createdAt: now,
        updatedAt: now,
      );

      final pMap = project.toMap();
      final restoredP = Project.fromMap(pMap);
      expect(restoredP.id, equals('p1'));
      expect(restoredP.name, equals('TodoApp'));

      final msg = ChatMessage(
        id: 'm1',
        projectId: 'p1',
        role: 'assistant',
        content: 'Created files',
        filesChanged: ['src/App.tsx'],
        createdAt: now,
      );

      final mMap = msg.toMap();
      final restoredM = ChatMessage.fromMap(mMap);
      expect(restoredM.content, equals('Created files'));
      expect(restoredM.filesChanged, equals(['src/App.tsx']));
    });
  });
}
