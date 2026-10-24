import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../../../core/chat/voice.dart';

/// Outcome of the press: recording, microphone refused, or the recorder failed
/// (threw, or did not answer within [VoiceCapture.startTimeout]).
enum VoiceStartResult { started, denied, failed }

/// State of one voice recording gesture, between the press and the release.
/// Wraps a [VoiceRecorder] and turns its streams into what the recording strip
/// draws. Written against the interface only, so tests drive it with a fake.
class VoiceCapture extends ChangeNotifier {
  VoiceCapture(this.recorder, {this.onLimit});

  /// Slide left by this much to cancel, up by this much to lock.
  static const cancelDistance = 80.0;
  static const lockDistance = 64.0;
  static const visibleLevels = 12;

  /// A recorder that has not started after this is given up on: the press must
  /// never stay silent (seen on the simulator, 2026-10-24).
  static const startTimeout = Duration(seconds: 4);

  final VoiceRecorder recorder;

  /// Called when [maxVoiceDuration] is reached: the owner finishes the note.
  final VoidCallback? onLimit;

  bool recording = false;

  /// The finger is down and the recorder has not answered yet: the strip is
  /// already shown, so the press is never without feedback.
  bool pending = false;
  bool locked = false;
  bool willCancel = false;
  Duration elapsed = Duration.zero;
  final List<int> levels = [];

  Future<VoiceStartResult>? _starting;
  StreamSubscription<int>? _levelSub;
  StreamSubscription<Duration>? _elapsedSub;

  /// A press began and has not been released yet (even while the permission
  /// prompt is up).
  bool get active => _starting != null;

  /// What the strip shows: as soon as the finger is down.
  bool get visible => pending || recording;

  Future<VoiceStartResult> start() => _starting ??= _start();

  Future<VoiceStartResult> _start() async {
    pending = true;
    notifyListeners();
    final VoiceStartResult result = await _askRecorder();
    pending = false;
    if (result != VoiceStartResult.started) {
      // Never cache a failed start: the next press must try again.
      _starting = null;
      notifyListeners();
      return result;
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
    return VoiceStartResult.started;
  }

  Future<VoiceStartResult> _askRecorder() async {
    final starting = recorder.start();
    try {
      final ok = await starting.timeout(startTimeout);
      return ok ? VoiceStartResult.started : VoiceStartResult.denied;
    } on TimeoutException {
      // If it starts after all, stop it: nobody is holding the mic any more.
      unawaited(starting.then((ok) => ok ? recorder.cancel() : null, onError: (_) {}));
      debugPrint('VoiceCapture: recorder did not start within $startTimeout');
      return VoiceStartResult.failed;
    } catch (error) {
      debugPrint('VoiceCapture: recorder failed to start (${error.runtimeType})');
      return VoiceStartResult.failed;
    }
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
    if (await (_starting ?? Future.value(VoiceStartResult.failed)) != VoiceStartResult.started) return null;
    _release();
    return recorder.stop();
  }

  Future<void> cancel() async {
    final starting = _starting;
    if (starting == null || await starting != VoiceStartResult.started) return;
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
