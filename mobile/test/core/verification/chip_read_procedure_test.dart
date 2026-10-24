import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/verification/chip/chip_read_procedure.dart';
import 'package:mazl/core/verification/chip/chip_reader.dart';
import 'package:mazl/core/verification/mrz/mrz_data.dart';

const _mrz = MrzData(format: MrzFormat.td3, documentNumber: 'L898902C3', birthYymmdd: '740812', expiryYymmdd: '120415');

/// Distinct sentences, so a test sees which one reached the iOS sheet. The core
/// never writes them: the presentation layer hands them in, translated.
const _alerts = ChipAlertTexts(
  approach: 'approach',
  authenticating: 'authenticating',
  readingPhoto: 'reading photo',
  readingSignature: 'reading signature',
  done: 'done',
  failure: 'failure',
);

/// Scripted eMRTD: each protocol either works or throws the given kind.
class _FakeLink implements EmrtdLink {
  _FakeLink({this.paceAdvertised = true, this.paceFailure, this.bacFailure, this.readFailure});

  final bool paceAdvertised;
  final ChipFailureKind? paceFailure;
  final ChipFailureKind? bacFailure;
  final ChipFailureKind? readFailure;

  final calls = <String>[];
  final alerts = <String>[];
  String? disconnectSuccess;
  String? disconnectFailure;

  @override
  Future<void> connect(String alertMessage) async {
    calls.add('connect');
    alerts.add(alertMessage);
  }

  @override
  Future<void> setAlertMessage(String message) async => alerts.add(message);

  @override
  Future<bool> readCardAccess() async {
    calls.add('cardAccess');
    return paceAdvertised;
  }

  @override
  Future<void> startPace(MrzData mrz) async {
    calls.add('pace');
    if (paceFailure != null) throw ChipReadException(paceFailure!);
  }

  @override
  Future<void> startBac(MrzData mrz) async {
    calls.add('bac');
    if (bacFailure != null) throw ChipReadException(bacFailure!);
  }

  @override
  Future<Uint8List> readDg1() async => _read('dg1', 1);

  @override
  Future<Uint8List> readDg2() async => _read('dg2', 2);

  @override
  Future<Uint8List> readSod() async => _read('sod', 3);

  Uint8List _read(String name, int fill) {
    calls.add(name);
    if (readFailure != null) throw ChipReadException(readFailure!);
    return Uint8List.fromList([fill, fill]);
  }

  @override
  Future<void> disconnect({String? success, String? failure}) async {
    calls.add('disconnect');
    disconnectSuccess = success;
    disconnectFailure = failure;
  }
}

void main() {
  test('PACE works: no BAC, files read in order, success sheet', () async {
    final link = _FakeLink();
    final result = await readChipFiles(link, _mrz, alerts: _alerts);
    expect(link.calls, ['connect', 'cardAccess', 'pace', 'dg1', 'dg2', 'sod', 'disconnect']);
    expect(result.dg1, [1, 1]);
    expect(result.dg2, [2, 2]);
    expect(result.sod, [3, 3]);
    expect(link.disconnectSuccess, _alerts.done);
  });

  test('chip without EF.CardAccess goes straight to BAC', () async {
    final link = _FakeLink(paceAdvertised: false);
    await readChipFiles(link, _mrz, alerts: _alerts);
    expect(link.calls, ['connect', 'cardAccess', 'bac', 'dg1', 'dg2', 'sod', 'disconnect']);
  });

  test('PACE refused for an unsupported algorithm falls back to BAC', () async {
    final link = _FakeLink(paceFailure: ChipFailureKind.unsupportedDocument);
    await readChipFiles(link, _mrz, alerts: _alerts);
    expect(link.calls, ['connect', 'cardAccess', 'pace', 'bac', 'dg1', 'dg2', 'sod', 'disconnect']);
  });

  test('PACE refused with the key then BAC works: still succeeds', () async {
    final link = _FakeLink(paceFailure: ChipFailureKind.accessDenied);
    await readChipFiles(link, _mrz, alerts: _alerts);
    expect(link.calls, contains('bac'));
    expect(link.calls.last, 'disconnect');
  });

  test('wrong key on both protocols is access denied', () async {
    final link = _FakeLink(paceFailure: ChipFailureKind.accessDenied, bacFailure: ChipFailureKind.accessDenied);
    await expectLater(
      readChipFiles(link, _mrz, alerts: _alerts),
      throwsA(isA<ChipReadException>().having((e) => e.kind, 'kind', ChipFailureKind.accessDenied)),
    );
    expect(link.calls.where((c) => c.startsWith('dg')), isEmpty);
    expect(link.disconnectFailure, _alerts.failure);
  });

  test('PACE-only chip: wrong key reported as access denied, not "BAC unsupported"', () async {
    final link = _FakeLink(paceFailure: ChipFailureKind.accessDenied, bacFailure: ChipFailureKind.unsupportedDocument);
    await expectLater(
      readChipFiles(link, _mrz, alerts: _alerts),
      throwsA(isA<ChipReadException>().having((e) => e.kind, 'kind', ChipFailureKind.accessDenied)),
    );
  });

  test('BAC unsupported without a wrong-key signal stays unsupported', () async {
    final link = _FakeLink(paceAdvertised: false, bacFailure: ChipFailureKind.unsupportedDocument);
    await expectLater(
      readChipFiles(link, _mrz, alerts: _alerts),
      throwsA(isA<ChipReadException>().having((e) => e.kind, 'kind', ChipFailureKind.unsupportedDocument)),
    );
  });

  for (final kind in [ChipFailureKind.tagLost, ChipFailureKind.timeout, ChipFailureKind.cancelled]) {
    test('$kind during PACE is final: BAC is not attempted', () async {
      final link = _FakeLink(paceFailure: kind);
      await expectLater(
        readChipFiles(link, _mrz, alerts: _alerts),
        throwsA(isA<ChipReadException>().having((e) => e.kind, 'kind', kind)),
      );
      expect(link.calls, isNot(contains('bac')));
    });
  }

  test('tag lost while reading the photo closes the session and reports it', () async {
    final link = _FakeLink(readFailure: ChipFailureKind.tagLost);
    await expectLater(
      readChipFiles(link, _mrz, alerts: _alerts),
      throwsA(isA<ChipReadException>().having((e) => e.kind, 'kind', ChipFailureKind.tagLost)),
    );
    expect(link.calls.last, 'disconnect');
    expect(link.disconnectFailure, isNotNull);
  });

  test('progress goes up and ends at 100', () async {
    final seen = <ChipReadProgress>[];
    await readChipFiles(_FakeLink(), _mrz, alerts: _alerts, onProgress: seen.add);
    expect(seen.first.step, ChipReadStep.waitingForDocument);
    expect(seen.map((p) => p.percent), orderedEquals([...seen.map((p) => p.percent)]..sort()));
    expect(seen.last.percent, 100);
  });

  test('the iOS sheet says what it was told, in order, whatever the language', () async {
    final link = _FakeLink();
    await readChipFiles(link, _mrz, alerts: _alerts);
    expect(link.alerts, ['approach', 'authenticating', 'reading photo', 'reading signature']);
    expect(link.disconnectSuccess, 'done');
  });

  test('a failed read closes the sheet with the failure sentence', () async {
    final link = _FakeLink(readFailure: ChipFailureKind.tagLost);
    await expectLater(readChipFiles(link, _mrz, alerts: _alerts), throwsA(isA<ChipReadException>()));
    expect(link.disconnectFailure, 'failure');
    expect(link.disconnectSuccess, isNull);
  });
}
