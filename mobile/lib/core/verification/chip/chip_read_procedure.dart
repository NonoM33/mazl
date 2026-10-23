import 'dart:typed_data';

import '../../models/verification.dart';
import '../mrz/mrz_data.dart';
import 'chip_reader.dart';

/// The few operations of an eMRTD session the read procedure needs.
/// Implementations translate their library errors into [ChipReadException].
abstract class EmrtdLink {
  /// Opens the NFC session and waits for a document.
  Future<void> connect(String alertMessage);

  Future<void> setAlertMessage(String message);

  /// Reads EF.CardAccess. True when the chip advertises PACE, false when the
  /// file is absent (BAC-only chip).
  Future<bool> readCardAccess();

  /// PACE with the MRZ-derived key.
  Future<void> startPace(MrzData mrz);

  /// Basic Access Control with the MRZ-derived key.
  Future<void> startBac(MrzData mrz);

  Future<Uint8List> readDg1();
  Future<Uint8List> readDg2();
  Future<Uint8List> readSod();

  /// Closes the session. [success] / [failure] are shown by the iOS sheet.
  Future<void> disconnect({String? success, String? failure});
}

/// French texts of the iOS NFC sheet.
abstract final class ChipAlerts {
  static const approach = 'Approchez votre document du haut du téléphone.';
  static const authenticating = 'Ne bouge pas. Connexion sécurisée…';
  static const readingPhoto = 'Lecture de la photo… 40 %';
  static const readingSignature = 'Lecture de la signature… 85 %';
  static const done = 'Terminé.';
  static const failure = 'La lecture a échoué.';
}

/// PACE first, BAC as fallback, then DG1, DG2 and EF.SOD.
///
/// Kept apart from the plugin so the fallback rules are unit-tested.
Future<ChipReadResult> readChipFiles(
  EmrtdLink link,
  MrzData mrz, {
  void Function(ChipReadProgress progress)? onProgress,
}) async {
  void report(ChipReadStep step, int percent) => onProgress?.call(ChipReadProgress(step, percent));

  report(ChipReadStep.waitingForDocument, 0);
  await link.connect(ChipAlerts.approach);
  try {
    report(ChipReadStep.authenticating, 10);
    await link.setAlertMessage(ChipAlerts.authenticating);
    await _openSecureChannel(link, mrz);

    report(ChipReadStep.readingPhoto, 30);
    await link.setAlertMessage(ChipAlerts.readingPhoto);
    final dg1 = await link.readDg1();
    final dg2 = await link.readDg2();

    report(ChipReadStep.readingSignature, 85);
    await link.setAlertMessage(ChipAlerts.readingSignature);
    final sod = await link.readSod();

    report(ChipReadStep.readingSignature, 100);
    await link.disconnect(success: ChipAlerts.done);
    return ChipReadResult(dg1: dg1, dg2: dg2, sod: sod);
  } on ChipReadException {
    await _closeQuietly(link);
    rethrow;
  }
}

/// Failures that retrying with the other protocol cannot fix.
const _fatal = {
  ChipFailureKind.tagLost,
  ChipFailureKind.timeout,
  ChipFailureKind.cancelled,
  ChipFailureKind.nfcUnavailable,
  ChipFailureKind.nfcDisabled,
};

Future<void> _openSecureChannel(EmrtdLink link, MrzData mrz) async {
  ChipReadException? paceFailure;
  if (await link.readCardAccess()) {
    try {
      await link.startPace(mrz);
      return;
    } on ChipReadException catch (e) {
      if (_fatal.contains(e.kind)) rethrow;
      paceFailure = e;
    }
  }
  try {
    await link.startBac(mrz);
  } on ChipReadException catch (e) {
    if (_fatal.contains(e.kind)) rethrow;
    // A chip that answered "wrong key" to either protocol means the MRZ is
    // wrong; a BAC "not supported" after that is just the chip being PACE-only.
    if (paceFailure?.kind == ChipFailureKind.accessDenied) {
      throw const ChipReadException(ChipFailureKind.accessDenied);
    }
    rethrow;
  }
}

Future<void> _closeQuietly(EmrtdLink link) async {
  try {
    await link.disconnect(failure: ChipAlerts.failure);
  } on Object {
    // The session is already gone (tag lost, user cancelled): nothing to close.
  }
}
