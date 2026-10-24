import 'package:flutter/foundation.dart';

// Voice messages. CONTRACT: docs/chat/CONTRAT.md §4 (AAC 64 kbit/s mono,
// 120 s max, 48-bar waveform). Implemented with `record` and `just_audio`;
// widget tests use fakes of these interfaces.

const maxVoiceDuration = Duration(seconds: 120);
const waveformBars = 48;

@immutable
class VoiceRecording {
  const VoiceRecording({required this.aac, required this.duration, required this.waveform});

  final Uint8List aac;
  final Duration duration;

  /// [waveformBars] values, 0–100.
  final List<int> waveform;
}

abstract class VoiceRecorder {
  /// False when the microphone permission is refused.
  Future<bool> start();

  /// Live level 0–100 while recording, for the recording UI.
  Stream<int> get levels;

  /// Elapsed time while recording.
  Stream<Duration> get elapsed;

  /// Stops and returns the recording, or null if it was too short (< 1 s).
  Future<VoiceRecording?> stop();

  Future<void> cancel();
  Future<void> dispose();
}

abstract class VoicePlayer {
  /// [url] is an http(s) URL or a `data:` URI (demo mode).
  Future<void> play(String url, {double speed = 1});
  Future<void> pause();
  Future<void> setSpeed(double speed);

  /// Position of the clip being played; null when stopped.
  Stream<Duration?> get position;
  Stream<bool> get playing;

  /// The URL currently loaded, so a list of bubbles knows which one plays.
  String? get currentUrl;

  Future<void> dispose();
}
