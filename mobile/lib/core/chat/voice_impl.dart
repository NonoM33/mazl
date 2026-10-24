import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'bytes_audio_source.dart';
import 'voice.dart';
import 'waveform.dart';

export 'waveform.dart';

// Voice messages on `record` and `just_audio`. CONTRACT: docs/chat/CONTRAT.md §4.
// The recorder works through a [RecorderBackend] so its rules (1 s minimum,
// 120 s cap, temp file deleted at once) are tested without a microphone.

/// AAC-LC, 64 kbit/s, mono, 44.1 kHz.
const voiceRecordConfig = RecordConfig(
  encoder: AudioEncoder.aacLc,
  bitRate: 64000,
  sampleRate: 44100,
  numChannels: 1,
);

const minVoiceDuration = Duration(seconds: 1);
const _elapsedTick = Duration(milliseconds: 200);
const _amplitudeTick = Duration(milliseconds: 100);

/// The microphone side, one call per platform feature the recorder needs.
abstract class RecorderBackend {
  /// Asks for the microphone permission when needed.
  Future<bool> hasPermission();
  Future<void> start(String path);

  /// Microphone level in dBFS (-160…0).
  Stream<double> amplitudeDb(Duration interval);

  /// Stops and returns the path of the file, if any.
  Future<String?> stop();
  Future<void> cancel();
  Future<void> dispose();
}

class RecordPackageBackend implements RecorderBackend {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) => _recorder.start(voiceRecordConfig, path: path);

  @override
  Stream<double> amplitudeDb(Duration interval) => _recorder.onAmplitudeChanged(interval).map((a) => a.current);

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Future<void> dispose() => _recorder.dispose();
}

Future<String> _defaultTempPath() async => (await getTemporaryDirectory()).path;

/// Reads the whole file into memory and deletes it right away: the clip only
/// lives in memory from then on.
Future<Uint8List> readAndDelete(String path) async {
  final file = File(path);
  try {
    return await file.readAsBytes();
  } finally {
    await deleteQuietly(path);
  }
}

Future<void> deleteQuietly(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // Nothing more can be done for a temp file; the OS clears the folder.
  }
}

class RecordVoiceRecorder implements VoiceRecorder {
  RecordVoiceRecorder({
    RecorderBackend? backend,
    Future<String> Function()? tempPath,
    Future<Uint8List> Function(String path)? readFile,
    Future<void> Function(String path)? deleteFile,
  })  : _backend = backend ?? RecordPackageBackend(),
        _tempPath = tempPath ?? _defaultTempPath,
        _readFile = readFile ?? readAndDelete,
        _deleteFile = deleteFile ?? deleteQuietly;

  final RecorderBackend _backend;
  final Future<String> Function() _tempPath;
  final Future<Uint8List> Function(String path) _readFile;
  final Future<void> Function(String path) _deleteFile;

  final _levels = StreamController<int>.broadcast();
  final _elapsed = StreamController<Duration>.broadcast();

  Stopwatch? _stopwatch;
  Timer? _tick;
  StreamSubscription<double>? _amplitude;
  String? _path;
  final List<int> _samples = [];
  Future<VoiceRecording?>? _stopping;
  bool _hasAutoStopped = false;

  @override
  Stream<int> get levels => _levels.stream;

  @override
  Stream<Duration> get elapsed => _elapsed.stream;

  bool get isRecording => _path != null;

  @override
  Future<bool> start() async {
    if (isRecording) return true;
    if (!await _backend.hasPermission()) return false;
    final directory = await _tempPath();
    final path = '$directory/mazl_voice_${clock.now().microsecondsSinceEpoch}.m4a';
    _samples.clear();
    _stopping = null;
    _hasAutoStopped = false;
    await _backend.start(path);
    _path = path;
    _stopwatch = clock.stopwatch()..start();
    _amplitude = _backend.amplitudeDb(_amplitudeTick).listen((db) {
      final level = amplitudeToLevel(db);
      _samples.add(level);
      if (!_levels.isClosed) _levels.add(level);
    });
    _tick = Timer.periodic(_elapsedTick, (_) => _onTick());
    return true;
  }

  void _onTick() {
    final elapsed = _stopwatch?.elapsed ?? Duration.zero;
    if (elapsed >= maxVoiceDuration) {
      _hasAutoStopped = true;
      _stopping ??= _finish(capAt: maxVoiceDuration);
      if (!_elapsed.isClosed) _elapsed.add(maxVoiceDuration);
      return;
    }
    if (!_elapsed.isClosed) _elapsed.add(elapsed);
  }

  /// Returns the recording, or null if it lasted less than a second. After the
  /// 120 s cap the recorder has already stopped itself: this returns that clip.
  @override
  Future<VoiceRecording?> stop() async {
    if (_hasAutoStopped) return _stopping;
    if (!isRecording) return null;
    return _stopping ??= _finish();
  }

  Future<VoiceRecording?> _finish({Duration? capAt}) async {
    final path = _path;
    final stopwatch = _stopwatch;
    _release();
    if (path == null || stopwatch == null) return null;
    var duration = stopwatch.elapsed;
    if (capAt != null && duration > capAt) duration = capAt;
    stopwatch.stop();
    final written = await _backend.stop();
    final file = written ?? path;
    if (duration < minVoiceDuration) {
      await _deleteFile(file);
      return null;
    }
    final aac = await _readFile(file);
    return VoiceRecording(aac: aac, duration: duration, waveform: downsampleWaveform(_samples));
  }

  void _release() {
    _tick?.cancel();
    _tick = null;
    unawaited(_amplitude?.cancel());
    _amplitude = null;
    _path = null;
    _stopwatch = null;
  }

  @override
  Future<void> cancel() async {
    final path = _path;
    _release();
    _stopping = null;
    _hasAutoStopped = false;
    if (path == null) return;
    await _backend.cancel();
    await _deleteFile(path);
  }

  @override
  Future<void> dispose() async {
    await cancel();
    await _backend.dispose();
    await _levels.close();
    await _elapsed.close();
  }
}

/// True for the two kinds of address the player accepts (CONTRAT §4bis).
bool isPlayableVoiceUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  return uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'data';
}

class JustAudioVoicePlayer implements VoicePlayer {
  JustAudioVoicePlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _subscriptions
      ..add(_player.positionStream.listen((p) {
        if (_currentUrl != null) _position.add(p);
      }))
      ..add(_player.playingStream.listen((p) => _playing.add(p && _currentUrl != null)))
      ..add(_player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) unawaited(_finished());
      }));
  }

  final AudioPlayer _player;
  final _position = StreamController<Duration?>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  String? _currentUrl;

  @override
  Stream<Duration?> get position => _position.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  String? get currentUrl => _currentUrl;

  /// One clip at a time: playing another URL replaces the current one.
  @override
  Future<void> play(String url, {double speed = 1}) async {
    if (!isPlayableVoiceUrl(url)) {
      throw ArgumentError.value(url, 'url', 'only http(s) and data: addresses can be played');
    }
    if (url == _currentUrl) {
      await _player.setSpeed(speed);
      unawaited(_player.play());
      return;
    }
    // Recording leaves the session on the earpiece; playback wants the speaker.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await _player.stop();
    _currentUrl = url;
    try {
      await _player.setAudioSource(_sourceFor(url));
      await _player.setSpeed(speed);
    } on Object {
      _currentUrl = null;
      _position.add(null);
      rethrow;
    }
    unawaited(_player.play());
  }

  AudioSource _sourceFor(String url) {
    final uri = Uri.parse(url);
    final data = uri.data;
    if (data == null) return AudioSource.uri(uri);
    return BytesAudioSource(data.contentAsBytes(), data.mimeType);
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> _finished() async {
    _currentUrl = null;
    _position.add(null);
    _playing.add(false);
    await _player.pause();
    await _player.seek(Duration.zero);
  }

  @override
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _player.dispose();
    await _position.close();
    await _playing.close();
  }
}

/// A recorder per recording screen; the microphone is released with it.
final voiceRecorderProvider = Provider.autoDispose<VoiceRecorder>((ref) {
  final recorder = RecordVoiceRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

/// One player for the whole app, so two clips never play at once.
final voicePlayerProvider = Provider<VoicePlayer>((ref) {
  final player = JustAudioVoicePlayer();
  ref.onDispose(player.dispose);
  return player;
});
