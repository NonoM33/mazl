import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/core/verification/chip/chip_reader.dart';
import 'package:mazl/core/verification/mrz/mrz_data.dart';

/// Specimen data of ICAO 9303 (fictional state UTO), expiring far in the future.
const futureDoc = MrzData(documentNumber: 'L898902C3', birthYymmdd: '740812', expiryYymmdd: '450415');

/// Sentences of the iOS NFC sheet for tests that do not look at them.
const testAlerts = ChipAlertTexts(
  approach: 'approach',
  authenticating: 'authenticating',
  readingPhoto: 'reading photo',
  readingSignature: 'reading signature',
  done: 'done',
  failure: 'failure',
);

class FakeContext extends Fake implements BuildContext {
  @override
  bool get mounted => true;
}

class FakeChipReader implements ChipReader {
  FakeChipReader({this.nfc = NfcAvailability.available, this.failure, Uint8List? dg1}) : dg1 = dg1 ?? Uint8List.fromList([1, 2, 3]);

  NfcAvailability nfc;
  ChipFailureKind? failure;
  final Uint8List dg1;
  int reads = 0;
  MrzData? lastMrz;
  ChipAlertTexts? lastAlerts;
  ChipReadResult? lastResult;

  @override
  Future<NfcAvailability> availability() async => nfc;

  @override
  Future<ChipReadResult> read(
    MrzData mrz, {
    required ChipAlertTexts alerts,
    void Function(ChipReadProgress progress)? onProgress,
  }) async {
    reads++;
    lastMrz = mrz;
    lastAlerts = alerts;
    onProgress?.call(const ChipReadProgress(ChipReadStep.readingPhoto, 40));
    final kind = failure;
    if (kind != null) throw ChipReadException(kind);
    return lastResult = ChipReadResult(dg1: dg1, dg2: Uint8List.fromList([4, 5]), sod: Uint8List.fromList([6, 7]));
  }
}

class FakeVerificationApi implements VerificationApi {
  ApiResponse<FaceSession>? sessionResponse;
  ApiResponse<VerificationOutcome> identityResponse = ApiResponse.success(const VerificationOutcome(verified: true));
  int sessions = 0;
  final submitted = <ChipReadResult>[];

  @override
  Future<ApiResponse<FaceSession>> startFaceSession(FacePurpose purpose) async {
    sessions++;
    expect(purpose, FacePurpose.identity);
    return sessionResponse ??
        ApiResponse.success(FaceSession(
          sessionId: 's$sessions',
          challenges: const [FaceChallenge.front, FaceChallenge.left, FaceChallenge.right],
          expiresAt: DateTime(2100),
        ));
  }

  @override
  Future<ApiResponse<VerificationOutcome>> submitIdentity(String sessionId, List<Uint8List> frames, ChipReadResult chip) async {
    submitted.add(ChipReadResult(dg1: Uint8List.fromList(chip.dg1), dg2: Uint8List.fromList(chip.dg2), sod: Uint8List.fromList(chip.sod)));
    return identityResponse;
  }

  @override
  Future<ApiResponse<VerificationOutcome>> submitFace(String sessionId, List<Uint8List> frames) => throw UnimplementedError();

  @override
  Future<ApiResponse<VerificationStatus>> getStatus() => throw UnimplementedError();

  @override
  Future<ApiResponse<void>> deleteFaceReference() => throw UnimplementedError();
}

class FakeLiveness implements LivenessCapture {
  FakeLiveness({this.error, bool cancel = false}) : frames = cancel ? null : [Uint8List.fromList([9])];

  final List<Uint8List>? frames;
  Object? error;
  int captures = 0;
  List<FaceChallenge>? lastChallenges;

  @override
  Future<List<Uint8List>?> capture(BuildContext context, List<FaceChallenge> challenges) async {
    captures++;
    lastChallenges = challenges;
    final e = error;
    if (e != null) throw e;
    return frames;
  }
}
