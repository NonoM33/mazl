import '../../models/verification.dart';
import '../mrz/mrz_data.dart';

/// State of the phone's NFC hardware.
enum NfcAvailability { available, disabled, unsupported }

/// Why a chip read failed. Mapped to French messages in the presentation layer.
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
  String toString() => 'ChipReadException(${kind.name})';
}

/// Coarse steps reported while reading, for the progress display.
enum ChipReadStep { waitingForDocument, authenticating, readingPhoto, readingSignature }

class ChipReadProgress {
  const ChipReadProgress(this.step, this.percent);

  final ChipReadStep step;
  final int percent;
}

/// Reads the identity files of an eMRTD (passport or ID card) over NFC.
///
/// The returned bytes are the raw files exactly as stored on the chip. They
/// must never be logged or written to disk.
abstract class ChipReader {
  Future<NfcAvailability> availability();

  /// Reads DG1, DG2 and EF.SOD using the access key derived from [mrz].
  /// Throws [ChipReadException].
  Future<ChipReadResult> read(MrzData mrz, {void Function(ChipReadProgress progress)? onProgress});
}
