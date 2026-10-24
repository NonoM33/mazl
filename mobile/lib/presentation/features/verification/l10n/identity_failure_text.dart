import '../../../../l10n/l10n.dart';
import '../identity/identity_messages.dart';

/// The sentence of a failure screen, in the member's language.
extension IdentityMessageText on IdentityMessage {
  String text(AppLocalizations l10n) => switch (this) {
    IdentityMessage.chipDataInvalid => l10n.verificationFailureChipDataInvalid,
    IdentityMessage.chipSignatureInvalid =>
      l10n.verificationFailureChipSignatureInvalid,
    IdentityMessage.documentNotRecognized =>
      l10n.verificationFailureNotRecognized,
    IdentityMessage.documentExpired => l10n.verificationDocumentExpired,
    IdentityMessage.underage => l10n.verificationFailureUnderage,
    IdentityMessage.documentAlreadyUsed => l10n.verificationDocumentAlreadyUsed,
    IdentityMessage.documentBanned => l10n.verificationDocumentBanned,
    IdentityMessage.documentFaceMismatch =>
      l10n.verificationDocumentFaceMismatch,
    IdentityMessage.sessionExpired => l10n.verificationFailureSessionExpired,
    IdentityMessage.imagesUnreadable =>
      l10n.verificationFailureImagesUnreadable,
    IdentityMessage.noFace => l10n.verificationFailureNoFace,
    IdentityMessage.multipleFaces => l10n.verificationFailureMultipleFaces,
    IdentityMessage.faceTooSmall => l10n.verificationFailureFaceTooSmall,
    IdentityMessage.poseMismatch => l10n.verificationFailurePoseMismatch,
    IdentityMessage.duplicateFrames => l10n.verificationFailureDuplicateFrames,
    IdentityMessage.inconsistentIdentity =>
      l10n.verificationFailureInconsistentIdentity,
    IdentityMessage.noProfilePhoto => l10n.verificationFailureNoProfilePhoto,
    IdentityMessage.profileMismatch => l10n.verificationFailureProfileMismatch,
    IdentityMessage.dailyLimitReached => l10n.verificationFailureDailyLimit,
    IdentityMessage.verificationFailed => l10n.verificationFailureGeneric,
    IdentityMessage.noNfcReader => l10n.verificationFailureNoNfc,
    IdentityMessage.nfcDisabled => l10n.verificationFailureNfcDisabled,
    IdentityMessage.documentMoved => l10n.verificationFailureTagLost,
    IdentityMessage.chipMismatch => l10n.verificationFailureChipMismatch,
    IdentityMessage.documentUnreadable =>
      l10n.verificationFailureUnreadableDocument,
    IdentityMessage.chipSilent => l10n.verificationFailureChipSilent,
    IdentityMessage.readFailed => l10n.verificationFailureReadFailed,
    IdentityMessage.connectionFailed => l10n.verificationFailureConnection,
    IdentityMessage.cameraUnavailable => l10n.verificationCameraNotAvailable,
  };
}

/// The label of the one button of a failure screen, in the member's language.
extension IdentityActionText on IdentityAction {
  String label(AppLocalizations l10n) => switch (this) {
    IdentityAction.retry => l10n.commonRetry,
    IdentityAction.close => l10n.commonClose,
    IdentityAction.rereadDocument => l10n.verificationActionRereadDocument,
    IdentityAction.otherDocument => l10n.verificationActionOtherDocument,
    IdentityAction.rescan => l10n.verificationRescan,
  };
}

extension IdentityFailureText on IdentityFailureInfo {
  String messageText(AppLocalizations l10n) => message.text(l10n);

  String actionLabel(AppLocalizations l10n) => action.label(l10n);
}
