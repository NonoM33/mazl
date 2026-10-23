import 'dart:async';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/chat/bytes_audio_source.dart';
import 'package:mazl/core/chat/voice.dart';
import 'package:mazl/core/chat/voice_impl.dart';
import 'package:record/record.dart';

class FakeBackend implements RecorderBackend {
  bool permission = true;
  final started = <String>[];
  int stops = 0;
  int cancels = 0;
  bool disposed = false;
  final amplitude = StreamController<double>.broadcast(sync: true);
  String? lastPath;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start(String path) async {
    started.add(path);
    lastPath = path;
  }

  @override
  Stream<double> amplitudeDb(Duration interval) => amplitude.stream;

  @override
  Future<String?> stop() async {
    stops++;
    return lastPath;
  }

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<void> dispose() async => disposed = true;
}

class Fixture {
  final backend = FakeBackend();
  final read = <String>[];
  final deleted = <String>[];
  late final RecordVoiceRecorder recorder = RecordVoiceRecorder(
    backend: backend,
    tempPath: () async => '/tmp/test',
    readFile: (path) async {
      read.add(path);
      deleted.add(path); // the real reader deletes right after reading
      return Uint8List.fromList([1, 2, 3]);
    },
    deleteFile: (path) async => deleted.add(path),
  );
}

void main() {
  test('record config is AAC-LC 64 kbit/s mono 44.1 kHz', () {
    expect(voiceRecordConfig.encoder, AudioEncoder.aacLc);
    expect(voiceRecordConfig.bitRate, 64000);
    expect(voiceRecordConfig.numChannels, 1);
    expect(voiceRecordConfig.sampleRate, 44100);
  });

  test('limits follow the contract', () {
    expect(maxVoiceDuration, const Duration(seconds: 120));
    expect(minVoiceDuration, const Duration(seconds: 1));
  });

  group('RecordVoiceRecorder', () {
    test('a refused microphone permission starts nothing', () {
      fakeAsync((async) {
        final f = Fixture();
        f.backend.permission = false;
        bool? started;
        f.recorder.start().then((v) => started = v);
        async.flushMicrotasks();
        expect(started, isFalse);
        expect(f.backend.started, isEmpty);
        expect(f.recorder.isRecording, isFalse);
      });
    });

    test('records into a temp .m4a and returns bytes, duration and 48 bars', () {
      fakeAsync((async) {
        final f = Fixture();
        f.recorder.start();
        async.flushMicrotasks();
        expect(f.backend.started.single, startsWith('/tmp/test/mazl_voice_'));
        expect(f.backend.started.single, endsWith('.m4a'));

        for (var i = 0; i < 30; i++) {
          f.backend.amplitude.add(i.isEven ? -10 : -40);
          async.elapse(const Duration(milliseconds: 100));
        }
        VoiceRecording? recording;
        f.recorder.stop().then((r) => recording = r);
        async.flushMicrotasks();

        expect(recording, isNotNull);
        expect(recording!.aac, [1, 2, 3]);
        expect(recording!.duration, const Duration(seconds: 3));
        expect(recording!.waveform, hasLength(waveformBars));
        expect(recording!.waveform.every((b) => b >= 0 && b <= 100), isTrue);
        expect(recording!.waveform.reduce((a, b) => a > b ? a : b), amplitudeToLevel(-10));
        expect(f.backend.stops, 1);
      });
    });

    test('the temp file is read once and deleted straight away', () {
      fakeAsync((async) {
        final f = Fixture();
        f.recorder.start();
        async.elapse(const Duration(seconds: 2));
        f.recorder.stop();
        async.flushMicrotasks();
        expect(f.read, [f.backend.lastPath]);
        expect(f.deleted, [f.backend.lastPath]);
      });
    });

    test('under one second returns null and deletes the file without reading it', () {
      fakeAsync((async) {
        final f = Fixture();
        f.recorder.start();
        async.elapse(const Duration(milliseconds: 900));
        VoiceRecording? recording = VoiceRecording(aac: Uint8List(0), duration: Duration.zero, waveform: const []);
        f.recorder.stop().then((r) => recording = r);
        async.flushMicrotasks();
        expect(recording, isNull);
        expect(f.read, isEmpty);
        expect(f.deleted, [f.backend.lastPath]);
      });
    });

    test('exactly one second is kept', () {
      fakeAsync((async) {
        final f = Fixture();
        f.recorder.start();
        async.elapse(const Duration(seconds: 1));
        VoiceRecording? recording;
        f.recorder.stop().then((r) => recording = r);
        async.flushMicrotasks();
        expect(recording, isNotNull);
      });
    });

    test('levels are 0-100 and follow the microphone', () {
      fakeAsync((async) {
        final f = Fixture();
        final levels = <int>[];
        f.recorder.levels.listen(levels.add);
        f.recorder.start();
        async.flushMicrotasks();
        f.backend.amplitude
          ..add(-160)
          ..add(-30)
          ..add(0);
        async.flushMicrotasks();
        expect(levels, [0, 50, 100]);
      });
    });

    test('elapsed time is published while recording', () {
      fakeAsync((async) {
        final f = Fixture();
        final ticks = <Duration>[];
        f.recorder.elapsed.listen(ticks.add);
        f.recorder.start();
        async.elapse(const Duration(seconds: 2));
        expect(ticks, isNotEmpty);
        expect(ticks.last, greaterThanOrEqualTo(const Duration(milliseconds: 1800)));
        expect(ticks.last, lessThanOrEqualTo(const Duration(seconds: 2)));
      });
    });

    test('stops by itself at 120 s; stop() then returns that clip, capped', () {
      fakeAsync((async) {
        final f = Fixture();
        final ticks = <Duration>[];
        f.recorder.elapsed.listen(ticks.add);
        f.recorder.start();
        async.elapse(const Duration(seconds: 125));

        expect(f.backend.stops, 1, reason: 'stopped by the cap, not by the user');
        expect(f.recorder.isRecording, isFalse);
        expect(ticks.every((d) => d <= maxVoiceDuration), isTrue);

        VoiceRecording? recording;
        f.recorder.stop().then((r) => recording = r);
        async.flushMicrotasks();
        expect(recording, isNotNull);
        expect(recording!.duration, maxVoiceDuration);
        expect(f.backend.stops, 1, reason: 'stop() does not stop twice');
      });
    });

    test('cancel stops the backend and deletes the file; nothing is returned later', () {
      fakeAsync((async) {
        final f = Fixture();
        f.recorder.start();
        async.elapse(const Duration(seconds: 3));
        f.recorder.cancel();
        async.flushMicrotasks();
        expect(f.backend.cancels, 1);
        expect(f.deleted, [f.backend.lastPath]);
        expect(f.read, isEmpty);
        VoiceRecording? recording = VoiceRecording(aac: Uint8List(0), duration: Duration.zero, waveform: const []);
        f.recorder.stop().then((r) => recording = r);
        async.flushMicrotasks();
        expect(recording, isNull);
      });
    });

    test('stop without start is null', () {
      fakeAsync((async) {
        final f = Fixture();
        VoiceRecording? recording = VoiceRecording(aac: Uint8List(0), duration: Duration.zero, waveform: const []);
        f.recorder.stop().then((r) => recording = r);
        async.flushMicrotasks();
        expect(recording, isNull);
      });
    });

    test('a new recording does not inherit the previous waveform', () {
      fakeAsync((async) {
        final f = Fixture();
        f.recorder.start();
        async.flushMicrotasks();
        f.backend.amplitude.add(0);
        async.elapse(const Duration(seconds: 2));
        f.recorder.stop();
        async.flushMicrotasks();

        f.recorder.start();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        VoiceRecording? second;
        f.recorder.stop().then((r) => second = r);
        async.flushMicrotasks();
        expect(second!.waveform, everyElement(0));
      });
    });

    test('dispose releases the backend', () {
      fakeAsync((async) {
        final f = Fixture();
        f.recorder.start();
        async.flushMicrotasks();
        f.recorder.dispose();
        async.flushMicrotasks();
        expect(f.backend.disposed, isTrue);
        expect(f.backend.cancels, 1);
      });
    });
  });

  group('isPlayableVoiceUrl', () {
    test('http, https and data are playable', () {
      expect(isPlayableVoiceUrl('https://cdn.example.com/v.m4a?sig=x'), isTrue);
      expect(isPlayableVoiceUrl('http://localhost:3000/v.m4a'), isTrue);
      expect(isPlayableVoiceUrl('data:audio/mp4;base64,AAAA'), isTrue);
    });

    test('nothing else is', () {
      expect(isPlayableVoiceUrl('file:///private/var/v.m4a'), isFalse);
      expect(isPlayableVoiceUrl('/private/var/v.m4a'), isFalse);
      expect(isPlayableVoiceUrl('ftp://example.com/v.m4a'), isFalse);
      expect(isPlayableVoiceUrl(''), isFalse);
      expect(isPlayableVoiceUrl('javascript:alert(1)'), isFalse);
    });
  });

  group('BytesAudioSource', () {
    final bytes = Uint8List.fromList(List.generate(100, (i) => i));
    final source = BytesAudioSource(bytes, 'audio/mp4');

    Future<List<int>> read(Stream<List<int>> s) async => [for (final c in await s.toList()) ...c];

    test('whole content without a range', () async {
      final response = await source.request();
      expect(response.sourceLength, 100);
      expect(response.contentLength, 100);
      expect(response.offset, 0);
      expect(response.contentType, 'audio/mp4');
      expect(await read(response.stream), bytes);
    });

    test('a byte range', () async {
      final response = await source.request(10, 20);
      expect(response.contentLength, 10);
      expect(response.offset, 10);
      expect(await read(response.stream), bytes.sublist(10, 20));
    });

    test('an open-ended range', () async {
      final response = await source.request(90);
      expect(await read(response.stream), bytes.sublist(90));
    });

    test('a range past the end does not throw', () async {
      final response = await source.request(150, 300);
      expect(response.contentLength, 0);
      expect(await read(response.stream), isEmpty);
    });
  });
}
