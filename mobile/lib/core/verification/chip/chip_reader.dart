import '../../models/verification.dart';
import '../mrz/mrz_data.dart';

/// State of the phone's NFC hardware.
enum NfcAvailability { available, disabled, unsupported }

/// Why a chip read failed. Turned into a sentence by the presentation layer,
/// in the member's language.
enum ChipFailureKind {
  /// The phone has no NFC reader.
  nfcUnavailable,

  /// NFC exists but is switched off in the system settings.
  nfcDisabled,

  /// The document moved away during the read.
  tagLost,

  /// The chip refused the access key: the MRZ data does not match the document.
  accessDenied,

  /// Not an eMRTD, or a chip variant we cannot read.
  unsupportedDocument,

  /// No document was presented in time.
  timeout,

  /// The user closed the system NFC sheet.
  cancelled,

  unknown,
}

/// Thrown by a [ChipReader]. Carries no document data, only the failure kind.
class ChipReadException implements Exception {
  const ChipReadException(this.kind);

  final ChipFailureKind kind;

  @override
  String toString() => '$runtimeType(${kind.name})';
}

/// Coarse steps reported while reading, for the progress display.
enum ChipReadStep { waitingForDocument, authenticating, readingPhoto, readingSignature }

class ChipReadProgress {
  const ChipReadProgress(this.step, this.percent);

  final ChipReadStep step;
  final int percent;
}

/// What the iOS NFC sheet says during a read. The sheet is drawn by the
/// system, outside any widget, so the presentation layer hands the sentences
/// in (already translated) and the core never knows the language.
class ChipAlertTexts {
  const ChipAlertTexts({
    required this.approach,
    required this.authenticating,
    required this.readingPhoto,
    required this.readingSignature,
    required this.done,
    required this.failure,
  });

  /// Shown while waiting for the document.
  final String approach;
  final String authenticating;
  final String readingPhoto;
  final String readingSignature;

  /// Closing message of a successful read.
  final String done;

  /// Closing message of a failed read.
  final String failure;
}

/// Reads the identity files of an eMRTD (passport or ID card) over NFC.
///
/// The returned bytes are the raw files exactly as stored on the chip. They
/// must never be logged or written to disk.
abstract class ChipReader {
  Future<NfcAvailability> availability();

  /// Reads DG1, DG2 and EF.SOD using the access key derived from [mrz].
  /// [alerts] are the sentences of the iOS NFC sheet.
  /// Throws [ChipReadException].
  Future<ChipReadResult> read(
    MrzData mrz, {
    required ChipAlertTexts alerts,
    void Function(ChipReadProgress progress)? onProgress,
  });
}
