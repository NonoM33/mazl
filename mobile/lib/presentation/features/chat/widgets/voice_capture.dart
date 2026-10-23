import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../../../core/chat/voice.dart';

/// State of one voice recording gesture, between the press and the release.
/// Wraps a [VoiceRecorder] and turns its streams into what the recording strip
/// draws. Written against the interface only, so tests drive it with a fake.
class VoiceCapture extends ChangeNotifier {
  VoiceCapture(this.recorder, {this.onLimit});

  /// Slide left by this much to cancel, up by this much to lock.
  static const cancelDistance = 80.0;
  static const lockDistance = 64.0;
  static const visibleLevels = 12;

  final VoiceRecorder recorder;

  /// Called when [maxVoiceDuration] is reached: the owner finishes the note.
  final VoidCallback? onLimit;

  bool recording = false;
  bool locked = false;
  bool willCancel = false;
  Duration elapsed = Duration.zero;
  final List<int> levels = [];

  Future<bool>? _starting;
  StreamSubscription<int>? _levelSub;
  StreamSubscription<Duration>? _elapsedSub;

  /// A press began and has not been released yet (even while the permission
  /// prompt is up).
  bool get active => _starting != null;

  /// True when the microphone is available and recording began.
  Future<bool> start() => _starting ??= _start();

  Future<bool> _start() async {
    final ok = await recorder.start();
    if (!ok) {
      _starting = null;
      return false;
    }
    recording = true;
    _levelSub = recorder.levels.listen((level) {
      levels.add(level);
      if (levels.length > visibleLevels) levels.removeAt(0);
      notifyListeners();
    });
    _elapsedSub = recorder.elapsed.listen((time) {
      elapsed = time;
      notifyListeners();
      if (time >= maxVoiceDuration) onLimit?.call();
    });
    notifyListeners();
    return true;
  }

  /// Follows the finger: [offset] is its distance from where it went down.
  void slide(Offset offset) {
    final cancel = offset.dx < -cancelDistance;
    final lock = locked || offset.dy < -lockDistance;
    if (cancel == willCancel && lock == locked) return;
    willCancel = cancel;
    locked = lock;
    notifyListeners();
  }

  /// Stops and returns the note, or null when it was too short or never began.
  Future<VoiceRecording?> finish() async {
    if (!await (_starting ?? Future.value(false))) return null;
    _release();
    return recorder.stop();
  }

  Future<void> cancel() async {
    final starting = _starting;
    if (starting == null || !await starting) return;
    _release();
    await recorder.cancel();
  }

  void _release() {
    unawaited(_levelSub?.cancel());
    unawaited(_elapsedSub?.cancel());
    _levelSub = _elapsedSub = null;
    _starting = null;
    recording = false;
    locked = false;
    willCancel = false;
    elapsed = Duration.zero;
    levels.clear();
    notifyListeners();
  }
}
