import '../../../../core/config/env.dart';
import '../../../../core/verification/chip/chip_reader.dart';

/// What the user can do after a failure.
enum IdentityRecovery {
  /// New selfie session; the chip data is still in memory.
  retryFace,

  /// Read the chip again with the same MRZ data.
  retryChip,

  /// Start over from the MRZ (wrong data or another document).
  rescanMrz,

  /// Nothing more to try here.
  close,
}

/// The sentence of a failure screen. A kind, not a text: the screen says it in
/// the member's language (`l10n/identity_failure_text.dart`), so a failure kept
/// in the flow state follows a language change.
enum IdentityMessage {
  chipDataInvalid,
  chipSignatureInvalid,
  documentNotRecognized,
  documentExpired,
  underage,
  documentAlreadyUsed,
  documentBanned,
  documentFaceMismatch,
  sessionExpired,
  imagesUnreadable,
  noFace,
  multipleFaces,
  faceTooSmall,
  poseMismatch,
  duplicateFrames,
  inconsistentIdentity,
  noProfilePhoto,
  profileMismatch,
  dailyLimitReached,
  verificationFailed,
  noNfcReader,
  nfcDisabled,
  documentMoved,
  chipMismatch,
  documentUnreadable,
  chipSilent,
  readFailed,
  connectionFailed,
  cameraUnavailable,
}

/// The label of the one button of a failure screen.
enum IdentityAction { retry, close, rereadDocument, otherDocument, rescan }

/// A failure as shown to the user: one sentence and one way forward.
class IdentityFailureInfo {
  const IdentityFailureInfo(
    this.message,
    this.recovery,
    this.action, {
    this.offerManualReview = false,
  });

  final IdentityMessage message;
  final IdentityRecovery recovery;
  final IdentityAction action;

  /// Also show the link to the web manual review.
  final bool offerManualReview;

  /// A chip that stayed silent, as opposed to a phone setting or a wrong MRZ:
  /// worth tips and a fresh look at the photo page.
  bool get isSilentChip => _silentChipMessages.contains(message);
}

const _silentChipMessages = {IdentityMessage.chipSilent, IdentityMessage.documentMoved, IdentityMessage.readFailed};

/// The web page where a document can be sent for manual review.
final Uri identityManualReviewUri = Uri.parse('${Env.apiBaseUrl}/verify');

const _retry = IdentityAction.retry;

/// Classifies the `reason` of a refused identity submission (contract §4,
/// `IdentityRejection`, which includes the `FaceRejection` codes).
IdentityFailureInfo describeIdentityRejection(String? code) => switch (code) {
      'chip_data_invalid' => const IdentityFailureInfo(
          IdentityMessage.chipDataInvalid, IdentityRecovery.retryChip, IdentityAction.rereadDocument),
      'chip_signature_invalid' => const IdentityFailureInfo(
          IdentityMessage.chipSignatureInvalid, IdentityRecovery.retryChip, IdentityAction.rereadDocument,
          offerManualReview: true),
      'csca_unknown' => const IdentityFailureInfo(
          IdentityMessage.documentNotRecognized, IdentityRecovery.close, IdentityAction.close,
          offerManualReview: true),
      'document_expired' => const IdentityFailureInfo(
          IdentityMessage.documentExpired, IdentityRecovery.rescanMrz, IdentityAction.otherDocument),
      'underage' => const IdentityFailureInfo(IdentityMessage.underage, IdentityRecovery.close, IdentityAction.close),
      'document_already_used' =>
        const IdentityFailureInfo(IdentityMessage.documentAlreadyUsed, IdentityRecovery.close, IdentityAction.close),
      'document_banned' =>
        const IdentityFailureInfo(IdentityMessage.documentBanned, IdentityRecovery.close, IdentityAction.close),
      'document_face_mismatch' =>
        const IdentityFailureInfo(IdentityMessage.documentFaceMismatch, IdentityRecovery.retryFace, _retry),
      'session_not_found' || 'session_expired' || 'session_used' =>
        const IdentityFailureInfo(IdentityMessage.sessionExpired, IdentityRecovery.retryFace, _retry),
      'wrong_frame_count' || 'invalid_image' =>
        const IdentityFailureInfo(IdentityMessage.imagesUnreadable, IdentityRecovery.retryFace, _retry),
      'no_face' => const IdentityFailureInfo(IdentityMessage.noFace, IdentityRecovery.retryFace, _retry),
      'multiple_faces' => const IdentityFailureInfo(IdentityMessage.multipleFaces, IdentityRecovery.retryFace, _retry),
      'face_too_small' => const IdentityFailureInfo(IdentityMessage.faceTooSmall, IdentityRecovery.retryFace, _retry),
      'pose_mismatch' => const IdentityFailureInfo(IdentityMessage.poseMismatch, IdentityRecovery.retryFace, _retry),
      'duplicate_frames' =>
        const IdentityFailureInfo(IdentityMessage.duplicateFrames, IdentityRecovery.retryFace, _retry),
      'inconsistent_identity' =>
        const IdentityFailureInfo(IdentityMessage.inconsistentIdentity, IdentityRecovery.retryFace, _retry),
      'no_profile_photo' =>
        const IdentityFailureInfo(IdentityMessage.noProfilePhoto, IdentityRecovery.close, IdentityAction.close),
      'profile_mismatch' =>
        const IdentityFailureInfo(IdentityMessage.profileMismatch, IdentityRecovery.retryFace, _retry),
      'daily_limit_reached' =>
        const IdentityFailureInfo(IdentityMessage.dailyLimitReached, IdentityRecovery.close, IdentityAction.close),
      _ => const IdentityFailureInfo(IdentityMessage.verificationFailed, IdentityRecovery.retryFace, _retry),
    };

/// Classifies a typed chip failure. [ChipFailureKind.cancelled] has no
/// message: the user closed the sheet on purpose.
IdentityFailureInfo? describeChipFailure(ChipFailureKind kind) => switch (kind) {
      ChipFailureKind.cancelled => null,
      ChipFailureKind.nfcUnavailable => const IdentityFailureInfo(
          IdentityMessage.noNfcReader, IdentityRecovery.close, IdentityAction.close, offerManualReview: true),
      ChipFailureKind.nfcDisabled =>
        const IdentityFailureInfo(IdentityMessage.nfcDisabled, IdentityRecovery.retryChip, _retry),
      ChipFailureKind.tagLost =>
        const IdentityFailureInfo(IdentityMessage.documentMoved, IdentityRecovery.retryChip, _retry),
      ChipFailureKind.accessDenied => const IdentityFailureInfo(
          IdentityMessage.chipMismatch, IdentityRecovery.rescanMrz, IdentityAction.rescan),
      ChipFailureKind.unsupportedDocument => const IdentityFailureInfo(
          IdentityMessage.documentUnreadable, IdentityRecovery.close, IdentityAction.close, offerManualReview: true),
      ChipFailureKind.timeout =>
        const IdentityFailureInfo(IdentityMessage.chipSilent, IdentityRecovery.retryChip, _retry),
      ChipFailureKind.unknown =>
        const IdentityFailureInfo(IdentityMessage.readFailed, IdentityRecovery.retryChip, _retry),
    };

/// When the server could not be reached or answered with an error.
IdentityFailureInfo describeApiFailure(String? error) => switch (error) {
      'daily_limit_reached' => describeIdentityRejection('daily_limit_reached'),
      _ => const IdentityFailureInfo(IdentityMessage.connectionFailed, IdentityRecovery.retryFace, _retry),
    };

/// The selfie camera could not be used.
const faceUnavailableFailure = IdentityFailureInfo(
  IdentityMessage.cameraUnavailable,
  IdentityRecovery.retryFace,
  IdentityAction.retry,
);
