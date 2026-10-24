import '../../../../l10n/l10n.dart';
import '../identity/manual_mrz_input.dart';

/// The error under a field of the manual entry, in the member's language.
extension ManualMrzErrorText on ManualMrzError {
  String text(AppLocalizations l10n) => switch (this) {
    ManualMrzError.documentNumberFormat => l10n.verificationErrorDocumentNumber,
    ManualMrzError.invalidDate => l10n.verificationErrorInvalidDate,
  };
}
