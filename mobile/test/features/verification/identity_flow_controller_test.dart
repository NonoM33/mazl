import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/core/verification/chip/chip_reader.dart';
import 'package:mazl/core/verification/mrz/mrz_data.dart';
import 'package:mazl/presentation/features/verification/identity/identity_flow_controller.dart';
import 'package:mazl/presentation/features/verification/identity/identity_flow_state.dart';
import 'package:mazl/presentation/features/verification/identity/identity_messages.dart';

import 'identity_fakes.dart';

final _now = DateTime(2026, 10, 23);

({IdentityFlowController flow, FakeChipReader chip, FakeVerificationApi api, FakeLiveness liveness}) _make({
  FakeChipReader? chip,
  FakeVerificationApi? api,
  FakeLiveness? liveness,
  bool withApi = true,
  bool withLiveness = true,
}) {
  final c = chip ?? FakeChipReader();
  final a = api ?? FakeVerificationApi();
  final l = liveness ?? FakeLiveness();
  final flow = IdentityFlowController(
    chipReader: c,
    api: withApi ? a : null,
    liveness: withLiveness ? l : null,
    clock: () => _now,
  );
  return (flow: flow, chip: c, api: a, liveness: l);
}

/// Intro -> MRZ -> review -> NFC, ready to read. Stops early when the MRZ is refused.
Future<void> _toNfc(IdentityFlowController flow, [MrzData mrz = futureDoc]) async {
  await flow.initialize();
  flow.begin();
  flow.submitMrz(mrz);
  if (flow.state is IdentityMrzReview) flow.confirmMrz();
}

void main() {
  group('first screen', () {
    test('goes to the intro when NFC exists and the services are bound', () async {
      final t = _make();
      expect(t.flow.state, isA<IdentityChecking>());
      await t.flow.initialize();
      expect(t.flow.state, isA<IdentityIntro>());
    });

    test('phone without NFC', () async {
      final t = _make(chip: FakeChipReader(nfc: NfcAvailability.unsupported));
      await t.flow.initialize();
      expect((t.flow.state as IdentityUnavailable).reason, IdentityUnavailableReason.noNfc);
    });

    test('NFC switched off still reaches the intro (the read reports it)', () async {
      final t = _make(chip: FakeChipReader(nfc: NfcAvailability.disabled));
      await t.flow.initialize();
      expect(t.flow.state, isA<IdentityIntro>());
    });

    test('no API bound: "coming soon", never an exception', () async {
      final t = _make(withApi: false);
      await t.flow.initialize();
      expect((t.flow.state as IdentityUnavailable).reason, IdentityUnavailableReason.comingSoon);
    });

    test('no selfie capture bound: "coming soon"', () async {
      final t = _make(withLiveness: false);
      await t.flow.initialize();
      expect((t.flow.state as IdentityUnavailable).reason, IdentityUnavailableReason.comingSoon);
    });

    test('steps cannot be skipped', () async {
      final t = _make();
      await t.flow.initialize();
      t.flow.submitMrz(futureDoc);
      expect(t.flow.state, isA<IdentityIntro>());
      await t.flow.readChip(testAlerts);
      expect(t.flow.state, isA<IdentityIntro>());
      t.flow.begin();
      expect((t.flow.state as IdentityMrz).manual, isFalse);
      t.flow.useManualEntry();
      expect((t.flow.state as IdentityMrz).manual, isTrue);
      t.flow.useCamera();
      expect((t.flow.state as IdentityMrz).manual, isFalse);
    });
  });

  group('MRZ', () {
    test('valid data is shown for confirmation before the chip is touched', () async {
      final t = _make();
      await t.flow.initialize();
      t.flow.begin();
      t.flow.submitMrz(futureDoc);
      expect((t.flow.state as IdentityMrzReview).mrz, futureDoc);
      expect(t.chip.reads, 0);
    });

    test('"C\'est bien moi" moves to the NFC step with the reviewed data', () async {
      final t = _make();
      await _toNfc(t.flow);
      expect((t.flow.state as IdentityNfc).mrz, futureDoc);
    });

    test('rejecting the review goes back to the same entry mode', () async {
      final t = _make();
      await t.flow.initialize();
      t.flow.begin();
      t.flow.useManualEntry();
      t.flow.submitMrz(futureDoc);
      t.flow.rejectMrz();
      expect((t.flow.state as IdentityMrz).manual, isTrue);
      t.flow.confirmMrz(); // no longer under review: ignored
      expect(t.flow.state, isA<IdentityMrz>());
    });

    test('the review cannot be confirmed from another step', () async {
      final t = _make();
      await t.flow.initialize();
      t.flow.confirmMrz();
      expect(t.flow.state, isA<IdentityIntro>());
    });

    test('expired document is refused before any NFC read', () async {
      final t = _make();
      await _toNfc(t.flow, const MrzData(documentNumber: 'X1234567', birthYymmdd: '740812', expiryYymmdd: '120415'));
      final failed = t.flow.state as IdentityFailed;
      expect(failed.info.message, IdentityMessage.documentExpired);
      expect(failed.info.recovery, IdentityRecovery.rescanMrz);
      expect(t.chip.reads, 0);
    });

    test('document expiring today is still valid', () async {
      final t = _make();
      await _toNfc(t.flow, const MrzData(documentNumber: 'X1234567', birthYymmdd: '740812', expiryYymmdd: '261023'));
      expect(t.flow.state, isA<IdentityNfc>());
    });

    test('holder under 18 is refused before any NFC read', () async {
      final t = _make();
      await _toNfc(t.flow, const MrzData(documentNumber: 'X1234567', birthYymmdd: '100101', expiryYymmdd: '450101'));
      expect((t.flow.state as IdentityFailed).info.message, IdentityMessage.underage);
      expect(t.chip.reads, 0);
    });

    test('holder turning 18 today is accepted', () async {
      final t = _make();
      await _toNfc(t.flow, const MrzData(documentNumber: 'X1234567', birthYymmdd: '081023', expiryYymmdd: '450101'));
      expect(t.flow.state, isA<IdentityNfc>());
    });
  });

  group('chip', () {
    test('success moves to the selfie step and passes the MRZ to the reader', () async {
      final t = _make();
      await _toNfc(t.flow);
      await t.flow.readChip(testAlerts);
      expect(t.flow.state, isA<IdentityFace>());
      expect(t.chip.lastMrz, futureDoc);
    });

    test('the sentences of the iPhone NFC sheet reach the reader, on the first read and on a retry', () async {
      final t = _make(chip: FakeChipReader(failure: ChipFailureKind.tagLost));
      await _toNfc(t.flow);
      await t.flow.readChip(testAlerts);
      expect(t.chip.lastAlerts, same(testAlerts));

      const another = ChipAlertTexts(
        approach: 'a',
        authenticating: 'b',
        readingPhoto: 'c',
        readingSignature: 'd',
        done: 'e',
        failure: 'f',
      );
      t.chip.failure = null;
      await t.flow.recover(FakeContext(), another);
      expect(t.chip.lastAlerts, same(another));
    });

    test('progress is exposed while reading', () async {
      final t = _make();
      await _toNfc(t.flow);
      final seen = <IdentityFlowState>[];
      t.flow.addListener(seen.add);
      await t.flow.readChip(testAlerts);
      final reading = seen.whereType<IdentityNfc>().where((s) => s.reading).toList();
      expect(reading, isNotEmpty);
      expect(reading.last.progress?.percent, 40);
    });

    test('a second tap while reading does not start a second read', () async {
      final t = _make();
      await _toNfc(t.flow);
      await Future.wait([t.flow.readChip(testAlerts), t.flow.readChip(testAlerts)]);
      expect(t.chip.reads, 1);
    });

    final cases = {
      ChipFailureKind.tagLost: IdentityRecovery.retryChip,
      ChipFailureKind.timeout: IdentityRecovery.retryChip,
      ChipFailureKind.nfcDisabled: IdentityRecovery.retryChip,
      ChipFailureKind.accessDenied: IdentityRecovery.rescanMrz,
      ChipFailureKind.unsupportedDocument: IdentityRecovery.close,
      ChipFailureKind.nfcUnavailable: IdentityRecovery.close,
      ChipFailureKind.unknown: IdentityRecovery.retryChip,
    };
    cases.forEach((kind, recovery) {
      test('$kind stays on the NFC step with a message and ${recovery.name}', () async {
        final t = _make(chip: FakeChipReader(failure: kind));
        await _toNfc(t.flow);
        await t.flow.readChip(testAlerts);
        final nfc = t.flow.state as IdentityNfc;
        expect(nfc.reading, isFalse);
        expect(nfc.failure!.recovery, recovery);
      });
    });

    test('"Relire la page photo" after a chip failure forgets the MRZ and goes back to the scan', () async {
      final t = _make(chip: FakeChipReader(failure: ChipFailureKind.timeout));
      await _toNfc(t.flow);
      await t.flow.readChip(testAlerts);
      t.flow.rereadPhotoPage();
      expect((t.flow.state as IdentityMrz).manual, isFalse);
      await t.flow.readChip(testAlerts); // the old MRZ is gone: nothing to read with
      expect(t.chip.reads, 1);
    });

    test('"Relire la page photo" is ignored while the chip is being read', () async {
      final t = _make();
      await _toNfc(t.flow);
      final reading = t.flow.readChip(testAlerts);
      t.flow.rereadPhotoPage();
      await reading;
      expect(t.flow.state, isA<IdentityFace>());
    });

    test('closing the system sheet leaves the step quiet, without an error', () async {
      final t = _make(chip: FakeChipReader(failure: ChipFailureKind.cancelled));
      await _toNfc(t.flow);
      await t.flow.readChip(testAlerts);
      final nfc = t.flow.state as IdentityNfc;
      expect(nfc.failure, isNull);
      expect(nfc.reading, isFalse);
    });

    test('wrong MRZ (access denied) lets the user scan again', () async {
      final t = _make(chip: FakeChipReader(failure: ChipFailureKind.accessDenied));
      await _toNfc(t.flow);
      await t.flow.readChip(testAlerts);
      await t.flow.recover(FakeContext(), testAlerts);
      expect(t.flow.state, isA<IdentityMrz>());
    });

    test('tag lost: recover reads again with the same MRZ', () async {
      final t = _make(chip: FakeChipReader(failure: ChipFailureKind.tagLost));
      await _toNfc(t.flow);
      await t.flow.readChip(testAlerts);
      t.chip.failure = null;
      await t.flow.recover(FakeContext(), testAlerts);
      expect(t.chip.reads, 2);
      expect(t.chip.lastMrz, futureDoc);
      expect(t.flow.state, isA<IdentityFace>());
    });
  });

  group('selfie and submission', () {
    Future<({IdentityFlowController flow, FakeChipReader chip, FakeVerificationApi api, FakeLiveness liveness})> atFace({
      FakeVerificationApi? api,
      FakeLiveness? liveness,
    }) async {
      final t = _make(api: api, liveness: liveness);
      await _toNfc(t.flow);
      await t.flow.readChip(testAlerts);
      return t;
    }

    test('happy path: session, capture with the server challenges, chip files sent, done', () async {
      final t = await atFace();
      await t.flow.captureFace(FakeContext());
      expect(t.api.sessions, 1);
      expect(t.liveness.lastChallenges, [FaceChallenge.front, FaceChallenge.left, FaceChallenge.right]);
      expect(t.api.submitted.single.dg1, [1, 2, 3]);
      expect(t.flow.state, isA<IdentityDone>());
    });

    test('states go through starting, capturing, sending', () async {
      final t = await atFace();
      final stages = <IdentitySubmitStage>[];
      t.flow.addListener((s) {
        if (s is IdentitySubmitting) stages.add(s.stage);
      });
      await t.flow.captureFace(FakeContext());
      expect(stages, [IdentitySubmitStage.starting, IdentitySubmitStage.capturing, IdentitySubmitStage.sending]);
    });

    test('raw chip files are zeroed once the verification is done', () async {
      final t = await atFace();
      final sent = t.chip.lastResult!;
      await t.flow.captureFace(FakeContext());
      expect(sent.dg1, everyElement(0));
      expect(sent.dg2, everyElement(0));
      expect(sent.sod, everyElement(0));
    });

    test('raw chip files are zeroed when the flow is closed halfway', () async {
      final t = await atFace();
      final read = t.chip.lastResult!;
      t.flow.dispose();
      expect(read.dg1, everyElement(0));
    });

    test('user cancels the camera: back to the selfie step, nothing submitted', () async {
      final t = await atFace(liveness: FakeLiveness(cancel: true));
      await t.flow.captureFace(FakeContext());
      expect(t.flow.state, isA<IdentityFace>());
      expect(t.api.submitted, isEmpty);
    });

    test('camera error: message, retry possible', () async {
      final t = await atFace(liveness: FakeLiveness(error: Exception('camera denied')));
      await t.flow.captureFace(FakeContext());
      final failed = t.flow.state as IdentityFailed;
      expect(failed.info.message, IdentityMessage.cameraUnavailable);
      expect(failed.info.recovery, IdentityRecovery.retryFace);
    });

    test('daily limit reached when opening the session', () async {
      final api = FakeVerificationApi()..sessionResponse = ApiResponse.failure('daily_limit_reached');
      final t = await atFace(api: api);
      await t.flow.captureFace(FakeContext());
      final failed = t.flow.state as IdentityFailed;
      expect(failed.info.message, IdentityMessage.dailyLimitReached);
      expect(failed.info.recovery, IdentityRecovery.close);
      expect(t.liveness.captures, 0);
    });

    test('network error on submission can be retried without reading the chip again', () async {
      final api = FakeVerificationApi()..identityResponse = ApiResponse.failure('Pas de connexion', ApiErrorKind.network);
      final t = await atFace(api: api);
      await t.flow.captureFace(FakeContext());
      expect((t.flow.state as IdentityFailed).info.recovery, IdentityRecovery.retryFace);

      api.identityResponse = ApiResponse.success(const VerificationOutcome(verified: true));
      await t.flow.recover(FakeContext(), testAlerts);
      expect(t.chip.reads, 1);
      expect(api.sessions, 2);
      expect(t.flow.state, isA<IdentityDone>());
    });

    test('server rejection shows its message and the recovery of that code', () async {
      final api = FakeVerificationApi()
        ..identityResponse = ApiResponse.success(const VerificationOutcome(verified: false, reason: 'document_face_mismatch'));
      final t = await atFace(api: api);
      await t.flow.captureFace(FakeContext());
      final failed = t.flow.state as IdentityFailed;
      expect(failed.info.message, IdentityMessage.documentFaceMismatch);
      expect(failed.info.recovery, IdentityRecovery.retryFace);
    });

    test('document_already_used is final', () async {
      final api = FakeVerificationApi()
        ..identityResponse = ApiResponse.success(const VerificationOutcome(verified: false, reason: 'document_already_used'));
      final t = await atFace(api: api);
      await t.flow.captureFace(FakeContext());
      expect((t.flow.state as IdentityFailed).info.recovery, IdentityRecovery.close);
      await t.flow.recover(FakeContext(), testAlerts);
      expect(t.flow.state, isA<IdentityFailed>());
    });

    test('rejection by the chip checks sends the user back to read the chip', () async {
      final api = FakeVerificationApi()
        ..identityResponse = ApiResponse.success(const VerificationOutcome(verified: false, reason: 'chip_data_invalid'));
      final t = await atFace(api: api);
      await t.flow.captureFace(FakeContext());
      api.identityResponse = ApiResponse.success(const VerificationOutcome(verified: true));
      await t.flow.recover(FakeContext(), testAlerts);
      expect(t.chip.reads, 2);
      expect(t.flow.state, isA<IdentityFace>());
    });

    test('rescanning the MRZ forgets the chip: the selfie step cannot be reached without a new read', () async {
      final api = FakeVerificationApi()
        ..identityResponse = ApiResponse.success(const VerificationOutcome(verified: false, reason: 'document_expired'));
      final t = await atFace(api: api);
      await t.flow.captureFace(FakeContext());
      await t.flow.recover(FakeContext(), testAlerts);
      expect(t.flow.state, isA<IdentityMrz>());
      await t.flow.captureFace(FakeContext());
      expect(t.flow.state, isA<IdentityMrz>());
      expect(api.sessions, 1);
    });
  });
}
