import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/diff/diff_service.dart';
import '../../core/settings/settings_service.dart';
import '../tools/tool_definition.dart';
import '../tools/tool_executor.dart';

enum AgentStepType {
  userMessage,
  agentMessage,
  toolCall,
  toolResult,
  error,
}

class AgentStep {
  final AgentStepType type;
  final String content;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final List<DiffLine>? diffLines;
  final DateTime timestamp;

  AgentStep({
    required this.type,
    required this.content,
    this.toolName,
    this.toolArgs,
    this.diffLines,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AgentService extends ChangeNotifier {
  final SettingsService settingsService;
  String _workingDir = '';

  final List<AgentStep> _transcript = [];
  bool _isRunning = false;
  bool _isCancelled = false;
  ApprovalCallback? approvalHandler;

  AgentService({required this.settingsService});

  String get workingDir => _workingDir;
  List<AgentStep> get transcript => List.unmodifiable(_transcript);
  bool get isRunning => _isRunning;

  void setWorkingDir(String path) {
    _workingDir = path;
    _transcript.clear();
    _transcript.add(AgentStep(
      type: AgentStepType.agentMessage,
      content: 'Working directory set to: `$path`\nReady to work on tasks.',
    ));
    notifyListeners();
  }

  void cancel() {
    _isCancelled = true;
    _isRunning = false;
    _transcript.add(AgentStep(
      type: AgentStepType.agentMessage,
      content: '⏹ **Task stopped by user.**',
    ));
    notifyListeners();
  }

  void clearTranscript() {
    _transcript.clear();
    notifyListeners();
  }

  Future<void> runTask(String userPrompt) async {
    final cleanPrompt = userPrompt.trim();
    if (cleanPrompt.isEmpty || _isRunning) return;

    if (_workingDir.isEmpty) {
      _transcript.add(AgentStep(
        type: AgentStepType.error,
        content: 'Please select a working directory first.',
      ));
      notifyListeners();
      return;
    }

    _isRunning = true;
    _isCancelled = false;

    _transcript.add(AgentStep(
      type: AgentStepType.userMessage,
      content: cleanPrompt,
    ));
    notifyListeners();

    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': '''You are Claude Code, an autonomous AI software engineer.
You are running in a project workspace located at: $_workingDir

Your capabilities:
1. `list_dir`: explore folder structures
2. `read_file`: view file content
3. `grep`: search code for symbols or strings
4. `write_file`: create new files
5. `edit_file`: modify existing code using exact string replacement
6. `run_command`: run terminal commands (e.g. "dart test", "flutter test", "git status")

Guidelines:
- Solve the user's task step-by-step.
- Inspect and read existing code before making edits.
- When asked to add a feature or test, create or edit the files and run tests until they pass.
- When done, summarize what you achieved.
''',
      },
      {'role': 'user', 'content': cleanPrompt},
    ];

    final executor = ToolExecutor(
      workingDir: _workingDir,
      autoApprove: settingsService.autoApprove,
      requestApproval: approvalHandler ?? ({required toolName, required target, required details, diffLines}) async => true,
    );

    int iterations = 0;
    const maxIterations = 20;

    try {
      while (_isRunning && !_isCancelled && iterations < maxIterations) {
        iterations++;

        final response = await _callLlmWithTools(messages);
        if (_isCancelled) break;

        final choice = response['choices']?[0];
        final message = choice?['message'];
        if (message == null) break;

        final toolCalls = message['tool_calls'] as List<dynamic>?;
        final textContent = message['content'] as String?;

        if (textContent != null && textContent.trim().isNotEmpty) {
          _transcript.add(AgentStep(
            type: AgentStepType.agentMessage,
            content: textContent,
          ));
          notifyListeners();
        }

        // Add assistant turn to context
        messages.add(message);

        // If no tool calls, task is finished!
        if (toolCalls == null || toolCalls.isEmpty) {
          break;
        }

        // Execute each tool call
        for (final tc in toolCalls) {
          if (_isCancelled) break;

          final id = tc['id'] as String;
          final function = tc['function'] as Map<String, dynamic>;
          final toolName = function['name'] as String;
          Map<String, dynamic> args = {};
          try {
            args = jsonDecode(function['arguments'] as String);
          } catch (_) {}

          _transcript.add(AgentStep(
            type: AgentStepType.toolCall,
            content: 'Executing `$toolName`',
            toolName: toolName,
            toolArgs: args,
          ));
          notifyListeners();

          final result = await executor.execute(toolName, args);
          if (_isCancelled) break;

          _transcript.add(AgentStep(
            type: AgentStepType.toolResult,
            content: result.output,
            toolName: toolName,
            diffLines: result.diffLines,
          ));
          notifyListeners();

          // Append tool response for LLM
          messages.add({
            'role': 'tool',
            'tool_call_id': id,
            'name': toolName,
            'content': result.output,
          });
        }
      }

      if (iterations >= maxIterations) {
        _transcript.add(AgentStep(
          type: AgentStepType.agentMessage,
          content: '⚠️ Reached maximum iteration limit (20 steps).',
        ));
      }
    } catch (e) {
      if (!_isCancelled) {
        _transcript.add(AgentStep(
          type: AgentStepType.error,
          content: 'Error in agent loop: $e',
        ));
      }
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _callLlmWithTools(List<Map<String, dynamic>> messages) async {
    final client = http.Client();
    try {
      var baseUrl = settingsService.baseUrl.trim();
      if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);

      final response = await client.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          if (settingsService.apiKey.isNotEmpty) 'Authorization': 'Bearer ${settingsService.apiKey}',
        },
        body: jsonEncode({
          'model': settingsService.model,
          'messages': messages,
          'tools': ToolDefinition.allTools,
          'tool_choice': 'auto',
          'temperature': 0.2,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API error (${response.statusCode}): ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }
}
