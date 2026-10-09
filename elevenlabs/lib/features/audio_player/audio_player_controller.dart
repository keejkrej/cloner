import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _currentAudioPath;

  AudioPlayerController() {
    _player.onPlayerStateChanged.listen((state) {
      _state = state;
      notifyListeners();
    });

    _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      _state = PlayerState.stopped;
      _position = Duration.zero;
      notifyListeners();
    });
  }

  PlayerState get state => _state;
  bool get isPlaying => _state == PlayerState.playing;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get currentAudioPath => _currentAudioPath;

  Future<void> play(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Audio file does not exist: $path');
    }

    if (_currentAudioPath == path && _state == PlayerState.paused) {
      await _player.resume();
      return;
    }

    _currentAudioPath = path;
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> toggle(String path) async {
    if (_currentAudioPath == path && isPlaying) {
      await pause();
    } else {
      await play(path);
    }
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  Future<void> stop() async {
    await _player.stop();
    _currentAudioPath = null;
    _position = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
