import '../../../../core/verification/chip/chip_reader.dart';
import '../../../../l10n/l10n.dart';

/// The sentences of the iPhone's NFC sheet, in the member's language. iOS draws
/// the sheet, so they are handed to the chip reader before the read starts.
ChipAlertTexts chipAlertTexts(AppLocalizations l10n) => ChipAlertTexts(
  approach: l10n.verificationNfcAlertApproach,
  authenticating: l10n.verificationNfcAlertAuthenticating,
  readingPhoto: l10n.verificationNfcAlertReadingPhoto,
  readingSignature: l10n.verificationNfcAlertReadingSignature,
  done: l10n.verificationNfcAlertDone,
  failure: l10n.verificationFailureReadFailed,
);
