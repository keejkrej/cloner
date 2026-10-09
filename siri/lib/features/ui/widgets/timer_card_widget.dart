import 'dart:async';
import 'package:flutter/material.dart';

class TimerCardWidget extends StatefulWidget {
  final Map<String, dynamic> data;

  const TimerCardWidget({super.key, required this.data});

  @override
  State<TimerCardWidget> createState() => _TimerCardWidgetState();
}

class _TimerCardWidgetState extends State<TimerCardWidget> {
  late int _totalSeconds;
  late int _remainingSeconds;
  late String _label;
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = (widget.data['total_seconds'] as num?)?.toInt() ?? 300;
    _remainingSeconds = _totalSeconds;
    _label = widget.data['label']?.toString() ?? 'Timer';
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer?.cancel();
        }
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _reset() {
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isPaused = false;
    });
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? (_remainingSeconds / _totalSeconds) : 0.0;
    final isDone = _remainingSeconds == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C3E50).withValues(alpha: 0.8),
            const Color(0xFF3498DB).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  color: isDone ? Colors.amber : Colors.cyanAccent,
                ),
              ),
              Icon(
                isDone ? Icons.alarm_on : Icons.hourglass_bottom,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
                Text(
                  isDone ? "Time's up!" : _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.amberAccent : Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
            tooltip: _isPaused ? 'Resume' : 'Pause',
            onPressed: isDone ? null : _togglePause,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Reset',
            onPressed: _reset,
          ),
        ],
      ),
    );
  }
}
