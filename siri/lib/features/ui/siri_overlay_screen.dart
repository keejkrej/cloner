import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';
import '../agent/siri_agent_service.dart';
import '../wakeword/wake_word_service.dart';
import 'dialogs/settings_dialog.dart';
import 'widgets/siri_orb_widget.dart';
import 'widgets/timer_card_widget.dart';
import 'widgets/weather_card_widget.dart';

class SiriOverlayScreen extends StatefulWidget {
  final SiriAgentService agentService;
  final WakeWordService wakeWordService;
  final SettingsService settingsService;

  const SiriOverlayScreen({
    super.key,
    required this.agentService,
    required this.wakeWordService,
    required this.settingsService,
  });

  @override
  State<SiriOverlayScreen> createState() => _SiriOverlayScreenState();
}

class _SiriOverlayScreenState extends State<SiriOverlayScreen> {
  final _inputController = TextEditingController();
  SiriState _state = SiriState.idle;
  String _userTranscript = '';
  String _siriResponse = 'Hey, I’m Siri. How can I help you today?';
  String? _activeToolType;
  Map<String, dynamic> _activeToolData = {};

  StreamSubscription<SiriState>? _stateSub;
  StreamSubscription<SiriInteractionResult>? _resultSub;
  StreamSubscription<void>? _wakeSub;

  final List<String> _quickQueries = [
    'Open Spotify',
    'Weather in Berlin?',
    'Timer for 5 minutes',
    'System health',
    'Who are you?',
  ];

  @override
  void initState() {
    super.initState();
    _stateSub = widget.agentService.onStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });

    _resultSub = widget.agentService.onResult.listen((res) {
      if (mounted) {
        setState(() {
          _userTranscript = res.query;
          _siriResponse = res.displayText;
          _activeToolType = res.toolType;
          _activeToolData = res.toolData;
        });
      }
    });

    _wakeSub = widget.wakeWordService.onWakeWordDetected.listen((_) {
      if (mounted) {
        setState(() {
          _userTranscript = '';
          _siriResponse = "I'm listening...";
          _activeToolType = null;
        });
      }
    });

    widget.wakeWordService.startListening();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _resultSub?.cancel();
    _wakeSub?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _submitQuery(String query) {
    final text = query.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() {
      _userTranscript = text;
      _siriResponse = 'Thinking...';
      _activeToolType = null;
    });

    widget.agentService.handleQuery(text);
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(settingsService: widget.settingsService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F15),
      body: Center(
        child: Container(
          width: 580,
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161622).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                blurRadius: 32,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Siri Desktop',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: Colors.greenAccent, size: 12),
                          SizedBox(width: 2),
                          Text('Idle CPU <1%', style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.mic, size: 18, color: Color(0xFF00E5FF)),
                      tooltip: 'Simulate "Hey Siri" Wake Word',
                      onPressed: () => widget.wakeWordService.triggerWake(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 18, color: Colors.white70),
                      tooltip: 'Preferences',
                      onPressed: _openSettings,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),

              // Dynamic Siri Content Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  children: [
                    // Siri Animated Orb
                    SiriOrbWidget(state: _state, size: 110),
                    const SizedBox(height: 20),

                    // User Transcript
                    if (_userTranscript.isNotEmpty)
                      Text(
                        '"$_userTranscript"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Siri Response Text
                    Text(
                      _siriResponse,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tool Result Widgets
                    if (_activeToolType == 'weather')
                      WeatherCardWidget(data: _activeToolData)
                    else if (_activeToolType == 'timer')
                      TimerCardWidget(data: _activeToolData)
                    else if (_activeToolType == 'app')
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.launch, color: Color(0xFF00E5FF), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Launched ${_activeToolData['app_name'] ?? 'Application'} on Windows',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    else if (_activeToolType == 'system')
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.computer, color: Colors.amberAccent, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              '${_activeToolData['os']} • ${_activeToolData['cores']} Cores Active',
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Quick query chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: _quickQueries.map((q) {
                    return ActionChip(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      label: Text(q, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      onPressed: () => _submitQuery(q),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Input Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type or say: "Weather in Berlin", "Open Spotify"...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onSubmitted: _submitQuery,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF7000FF)],
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                        onPressed: () => _submitQuery(_inputController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
