import '../../../l10n/l10n.dart';

/// Sentence for every refusal / error code of the verification endpoints
/// (docs/verification/CONTRAT.md: `FaceRejection`, `IdentityRejection`) and
/// for the client side failures of `HttpVerificationApi`, in the member's
/// language. The codes stay the server's; only the sentences are translated.
String verificationReasonText(AppLocalizations l10n, String? code) => switch (code) {
      'no_face' => l10n.verificationReasonNoFace,
      'multiple_faces' => l10n.verificationReasonMultipleFaces,
      'face_too_small' => l10n.verificationReasonFaceTooSmall,
      'pose_mismatch' => l10n.verificationReasonPoseMismatch,
      'duplicate_frames' => l10n.verificationReasonDuplicateFrames,
      'inconsistent_identity' => l10n.verificationReasonInconsistentIdentity,
      'no_profile_photo' => l10n.verificationReasonNoProfilePhoto,
      'profile_mismatch' => l10n.verificationReasonProfileMismatch,
      'daily_limit_reached' => l10n.verificationReasonDailyLimit,
      'session_expired' => l10n.verificationReasonSessionExpired,
      'session_not_found' || 'session_used' => l10n.verificationReasonSessionInvalid,
      'wrong_frame_count' || 'invalid_image' => l10n.verificationReasonImagesUnreadable,
      'app_update_required' => l10n.verificationReasonAppUpdate,
      'chip_data_invalid' || 'chip_signature_invalid' || 'csca_unknown' => l10n.verificationReasonChipAuth,
      'document_expired' => l10n.verificationDocumentExpired,
      'underage' => l10n.verificationReasonUnderage,
      'document_already_used' => l10n.verificationDocumentAlreadyUsed,
      'document_banned' => l10n.verificationDocumentBanned,
      'document_face_mismatch' => l10n.verificationDocumentFaceMismatch,
      'timeout' || 'network' => l10n.verificationReasonNetwork,
      _ => l10n.verificationReasonGeneric,
    };
