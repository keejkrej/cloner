import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/settings/settings_service.dart';
import '../stt/stt_service.dart';
import '../tools/siri_tool.dart';
import '../tools/tools_registry.dart';
import '../tts/tts_service.dart';

enum SiriState { idle, listening, thinking, speaking }

class SiriInteractionResult {
  final String query;
  final String speechReply;
  final String displayText;
  final String? toolType;
  final Map<String, dynamic> toolData;

  SiriInteractionResult({
    required this.query,
    required this.speechReply,
    required this.displayText,
    this.toolType,
    this.toolData = const {},
  });
}

class SiriAgentService {
  final SettingsService _settingsService;
  final SttService _sttService;
  final TtsService _ttsService;
  final http.Client? client;
  final Map<String, SiriTool> _tools = {};

  final _stateController = StreamController<SiriState>.broadcast();
  Stream<SiriState> get onStateChanged => _stateController.stream;
  SiriState _state = SiriState.idle;
  SiriState get state => _state;

  final _resultController = StreamController<SiriInteractionResult>.broadcast();
  Stream<SiriInteractionResult> get onResult => _resultController.stream;

  SiriAgentService({
    SettingsService? settingsService,
    SttService? sttService,
    TtsService? ttsService,
    this.client,
  })  : _settingsService = settingsService ?? SettingsService(),
        _sttService = sttService ?? SttService(),
        _ttsService = ttsService ?? TtsService() {
    registerTool(OpenAppTool());
    registerTool(OpenUrlTool());
    registerTool(GetWeatherTool(client: client));
    registerTool(SetTimerTool());
    registerTool(SystemInfoTool());
  }

  void registerTool(SiriTool tool) {
    _tools[tool.name] = tool;
  }

  void _setState(SiriState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  Future<SiriInteractionResult> handleQuery(String rawQuery) async {
    final query = await _sttService.processSpeechText(rawQuery);
    if (query.isEmpty) {
      return SiriInteractionResult(
        query: '',
        speechReply: "I'm listening.",
        displayText: "I'm listening...",
      );
    }

    _setState(SiriState.thinking);

    SiriInteractionResult result;
    final apiKey = await _settingsService.getOpenAiKey();

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      result = await _handleWithOpenAi(query, apiKey);
    } else {
      result = await _handleWithIntentParser(query);
    }

    _setState(SiriState.speaking);
    _resultController.add(result);

    // Speak reply aloud
    await _ttsService.speak(result.speechReply);

    _setState(SiriState.idle);
    return result;
  }

  Future<SiriInteractionResult> _handleWithIntentParser(String query) async {
    final lower = query.toLowerCase().trim();

    // 1. Weather
    if (lower.contains('weather') || lower.contains('temperature') || lower.contains('forecast')) {
      String city = 'Berlin';
      final inMatch = RegExp(r'(?:in|for|at)\s+([a-zA-Z\s]+)', caseSensitive: false).firstMatch(query);
      if (inMatch != null) {
        city = inMatch.group(1)!.replaceAll('?', '').trim();
      }
      final tool = _tools['get_weather']!;
      final res = await tool.execute({'city': city});
      return SiriInteractionResult(
        query: query,
        speechReply: res.speechResponse,
        displayText: res.displayText,
        toolType: res.toolType,
        toolData: res.data,
      );
    }

    // 2. Open App
    if (lower.startsWith('open ') || lower.startsWith('launch ') || lower.startsWith('start ')) {
      final appName = query.replaceFirst(RegExp(r'^(open|launch|start)\s+', caseSensitive: false), '').replaceAll('!', '').trim();
      if (appName.startsWith('http://') || appName.startsWith('https://') || appName.contains('.com') || appName.contains('.org')) {
        final tool = _tools['open_url']!;
        final res = await tool.execute({'url': appName});
        return SiriInteractionResult(
          query: query,
          speechReply: res.speechResponse,
          displayText: res.displayText,
          toolType: res.toolType,
          toolData: res.data,
        );
      }
      final tool = _tools['open_app']!;
      final res = await tool.execute({'app_name': appName});
      return SiriInteractionResult(
        query: query,
        speechReply: res.speechResponse,
        displayText: res.displayText,
        toolType: res.toolType,
        toolData: res.data,
      );
    }

    // 3. Timer
    if (lower.contains('timer') || lower.contains('countdown')) {
      int seconds = 300;
      final minMatch = RegExp(r'(\d+)\s*(?:minutes?|mins?)', caseSensitive: false).firstMatch(query);
      final secMatch = RegExp(r'(\d+)\s*(?:seconds?|secs?)', caseSensitive: false).firstMatch(query);

      if (minMatch != null) {
        seconds = int.parse(minMatch.group(1)!) * 60;
      } else if (secMatch != null) {
        seconds = int.parse(secMatch.group(1)!);
      }

      final tool = _tools['set_timer']!;
      final res = await tool.execute({'seconds': seconds, 'label': 'Timer'});
      return SiriInteractionResult(
        query: query,
        speechReply: res.speechResponse,
        displayText: res.displayText,
        toolType: res.toolType,
        toolData: res.data,
      );
    }

    // 4. System info
    if (lower.contains('system') || lower.contains('computer') || lower.contains('cpu') || lower.contains('health')) {
      final tool = _tools['system_info']!;
      final res = await tool.execute({});
      return SiriInteractionResult(
        query: query,
        speechReply: res.speechResponse,
        displayText: res.displayText,
        toolType: res.toolType,
        toolData: res.data,
      );
    }

    // 5. Conversational fallback
    final conversationalReply = _generateConversationalAnswer(query);
    return SiriInteractionResult(
      query: query,
      speechReply: conversationalReply,
      displayText: conversationalReply,
    );
  }

  Future<SiriInteractionResult> _handleWithOpenAi(String query, String apiKey) async {
    final httpClient = client ?? http.Client();

    final toolsPayload = _tools.values.map((t) => {
          'type': 'function',
          'function': {
            'name': t.name,
            'description': t.description,
            'parameters': t.parametersSchema,
          }
        }).toList();

    try {
      final res = await httpClient.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are Siri, an intelligent voice assistant on desktop. Speak in a helpful, concise, natural tone. Use the provided tools whenever appropriate.',
            },
            {'role': 'user', 'content': query},
          ],
          'tools': toolsPayload,
          'tool_choice': 'auto',
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final message = data['choices'][0]['message'];

        if (message['tool_calls'] != null && (message['tool_calls'] as List).isNotEmpty) {
          final toolCall = message['tool_calls'][0];
          final funcName = toolCall['function']['name'] as String;
          final funcArgs = jsonDecode(toolCall['function']['arguments']) as Map<String, dynamic>;

          final tool = _tools[funcName];
          if (tool != null) {
            final execRes = await tool.execute(funcArgs);
            return SiriInteractionResult(
              query: query,
              speechReply: execRes.speechResponse,
              displayText: execRes.displayText,
              toolType: execRes.toolType,
              toolData: execRes.data,
            );
          }
        }

        final content = (message['content'] as String? ?? '').trim();
        if (content.isNotEmpty) {
          return SiriInteractionResult(
            query: query,
            speechReply: content,
            displayText: content,
          );
        }
      }
    } catch (_) {}

    return _handleWithIntentParser(query);
  }

  String _generateConversationalAnswer(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('who are you') || lower.contains('what are you')) {
      return "I'm Siri, your intelligent personal voice assistant on Windows.";
    }
    if (lower.contains('how are you')) {
      return "I'm doing well, thank you! Ready to help with apps, weather, timers, and searches.";
    }
    if (lower.contains('capital of france')) {
      return "The capital of France is Paris.";
    }
    if (lower.contains('time')) {
      final now = DateTime.now();
      return "It is currently ${now.hour}:${now.minute.toString().padLeft(2, '0')}.";
    }
    return "Here is what I found for '$query'. How else can I assist you?";
  }

  void dispose() {
    _stateController.close();
    _resultController.close();
    _ttsService.dispose();
  }
}
