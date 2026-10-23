import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/verification_api.dart';
import '../../../../core/verification/chip/chip_reader.dart';
import '../../../../core/verification/mrz/mrz_data.dart';
import 'identity_flow_state.dart';
import 'identity_messages.dart';

/// Drives the level 2 verification: MRZ, chip, selfie, submission.
///
/// Everything sensitive (MRZ data, raw chip files) lives in this object only
/// and is dropped when the flow ends or is closed. Nothing is logged.
class IdentityFlowController extends StateNotifier<IdentityFlowState> {
  IdentityFlowController({
    required ChipReader chipReader,
    required VerificationApi? api,
    required LivenessCapture? liveness,
    DateTime Function()? clock,
  })  : _chipReader = chipReader,
        _api = api,
        _liveness = liveness,
        _clock = clock ?? DateTime.now,
        super(const IdentityChecking());

  final ChipReader _chipReader;
  final VerificationApi? _api;
  final LivenessCapture? _liveness;
  final DateTime Function() _clock;

  MrzData? _mrz;
  ChipReadResult? _chip;
  bool _busy = false;

  /// Decides the first screen from what this phone and this build can do.
  Future<void> initialize() async {
    if (_api == null || _liveness == null) {
      state = const IdentityUnavailable(IdentityUnavailableReason.comingSoon);
      return;
    }
    final nfc = await _chipReader.availability();
    if (!mounted) return;
    state = nfc == NfcAvailability.unsupported
        ? const IdentityUnavailable(IdentityUnavailableReason.noNfc)
        : const IdentityIntro();
  }

  void begin() {
    if (state is IdentityIntro) state = const IdentityMrz();
  }

  void useManualEntry() {
    if (state is IdentityMrz) state = const IdentityMrz(manual: true);
  }

  void useCamera() {
    if (state is IdentityMrz) state = const IdentityMrz();
  }

  /// The MRZ was scanned or typed. A document that is expired, or whose
  /// holder is under 18, can never pass: say so before touching the chip.
  void submitMrz(MrzData mrz) {
    if (state is! IdentityMrz) return;
    final now = _clock();
    if (mrz.expiryDate().isBefore(DateTime(now.year, now.month, now.day))) {
      state = IdentityFailed(describeIdentityRejection('document_expired'));
      return;
    }
    if (_isUnderage(mrz.birthDate(now: now), now)) {
      state = IdentityFailed(describeIdentityRejection('underage'));
      return;
    }
    _mrz = mrz;
    state = IdentityNfc(mrz);
  }

  /// Reads the chip once the user has put the document against the phone.
  Future<void> readChip() async {
    final mrz = _mrz;
    final current = state;
    if (_busy || mrz == null || current is! IdentityNfc) return;
    _busy = true;
    state = IdentityNfc(mrz, reading: true);
    try {
      final chip = await _chipReader.read(mrz, onProgress: (p) {
        if (mounted) state = IdentityNfc(mrz, reading: true, progress: p);
      });
      if (!mounted) return;
      _chip = chip;
      state = const IdentityFace();
    } on ChipReadException catch (e) {
      if (!mounted) return;
      state = IdentityNfc(mrz, failure: describeChipFailure(e.kind));
    } finally {
      _busy = false;
    }
  }

  /// Selfie session, live capture, then submission together with the chip files.
  Future<void> captureFace(BuildContext context) async {
    final chip = _chip;
    final api = _api;
    final liveness = _liveness;
    if (_busy || api == null || liveness == null) return;
    if (chip == null) {
      state = const IdentityMrz();
      return;
    }
    _busy = true;
    try {
      state = const IdentitySubmitting(IdentitySubmitStage.starting);
      final session = await api.startFaceSession(FacePurpose.identity);
      if (!mounted) return;
      final data = session.data;
      if (!session.success || data == null) {
        state = IdentityFailed(describeApiFailure(session.error));
        return;
      }

      if (!context.mounted) return;
      state = const IdentitySubmitting(IdentitySubmitStage.capturing);
      final frames = await liveness.capture(context, data.challenges);
      if (!mounted) return;
      if (frames == null) {
        state = const IdentityFace(); // cancelled by the user
        return;
      }

      state = const IdentitySubmitting(IdentitySubmitStage.sending);
      final result = await api.submitIdentity(data.sessionId, frames, chip);
      if (!mounted) return;
      final outcome = result.data;
      if (!result.success || outcome == null) {
        state = IdentityFailed(describeApiFailure(result.error));
      } else if (outcome.verified) {
        _forget();
        state = const IdentityDone();
      } else {
        state = IdentityFailed(describeIdentityRejection(outcome.reason));
      }
    } on Exception {
      if (mounted) {
        state = const IdentityFailed(IdentityFailureInfo(faceUnavailableMessage, IdentityRecovery.retryFace, 'Réessayer'));
      }
    } finally {
      _busy = false;
    }
  }

  /// The button of a failure screen. [context] is only needed to relaunch the camera.
  Future<void> recover(BuildContext context) async {
    final current = state;
    final recovery = switch (current) {
      IdentityFailed(:final info) => info.recovery,
      IdentityNfc(:final failure?) => failure.recovery,
      _ => null,
    };
    switch (recovery) {
      case IdentityRecovery.retryFace:
        if (_chip == null) {
          state = const IdentityMrz();
        } else {
          await captureFace(context);
        }
      case IdentityRecovery.retryChip:
        final mrz = _mrz;
        if (mrz == null) {
          state = const IdentityMrz();
        } else {
          state = IdentityNfc(mrz);
          await readChip();
        }
      case IdentityRecovery.rescanMrz:
        _forget();
        state = const IdentityMrz();
      case IdentityRecovery.close:
      case null:
        break;
    }
  }

  static bool _isUnderage(DateTime birth, DateTime now) {
    final eighteen = DateTime(birth.year + 18, birth.month, birth.day);
    return eighteen.isAfter(DateTime(now.year, now.month, now.day));
  }

  /// Zeroes the raw chip files and drops the MRZ data.
  void _forget() {
    final chip = _chip;
    if (chip != null) {
      for (final file in [chip.dg1, chip.dg2, chip.sod]) {
        file.fillRange(0, file.length, 0);
      }
    }
    _chip = null;
    _mrz = null;
  }

  @override
  void dispose() {
    _forget();
    super.dispose();
  }
}
