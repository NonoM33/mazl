import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/verification_api.dart';
import '../../verification/chip/chip_reader.dart';
import '../../verification/chip/dmrtd_chip_reader.dart';
import '../../vision/mlkit_text_line_recognizer.dart';
import '../../vision/text_line_recognizer.dart';

/// NFC chip reader (dmrtd). Override in tests.
final chipReaderProvider = Provider<ChipReader>((ref) => const DmrtdChipReader());

/// OCR engine of the MRZ scanner. The only place that picks the engine.
final textLineRecognizerProvider = Provider.autoDispose<TextLineRecognizer>((ref) {
  final recognizer = MlKitTextLineRecognizer();
  ref.onDispose(recognizer.close);
  return recognizer;
});

/// The verification endpoints. Null until the app binds an implementation;
/// the identity flow then shows "Bientôt disponible".
final identityVerificationApiProvider = Provider<VerificationApi?>((ref) => null);

/// The guided selfie capture. Null until the app binds an implementation.
final identityLivenessCaptureProvider = Provider<LivenessCapture?>((ref) => null);
