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

/// A failure as shown to the user: one sentence and one way forward.
class IdentityFailureInfo {
  const IdentityFailureInfo(
    this.message,
    this.recovery,
    this.actionLabel, {
    this.offerManualReview = false,
  });

  final String message;
  final IdentityRecovery recovery;
  final String actionLabel;

  /// Also show the link to the web manual review.
  final bool offerManualReview;
}

/// The web page where a document can be sent for manual review.
final Uri identityManualReviewUri = Uri.parse('${Env.apiBaseUrl}/verify');

const _retry = 'Réessayer';

/// Translates the `reason` of a refused identity submission (contract §4,
/// `IdentityRejection`, which includes the `FaceRejection` codes).
IdentityFailureInfo describeIdentityRejection(String? code) => switch (code) {
      'chip_data_invalid' => const IdentityFailureInfo('Les données de la puce sont illisibles.', IdentityRecovery.retryChip, 'Relire le document'),
      'chip_signature_invalid' => const IdentityFailureInfo(
          'La signature du document n\'a pas pu être vérifiée.', IdentityRecovery.retryChip, 'Relire le document',
          offerManualReview: true),
      'csca_unknown' => const IdentityFailureInfo('Document non reconnu.', IdentityRecovery.close, 'Fermer', offerManualReview: true),
      'document_expired' => const IdentityFailureInfo('Ce document est expiré.', IdentityRecovery.rescanMrz, 'Autre document'),
      'underage' => const IdentityFailureInfo('Il faut avoir 18 ans pour vérifier son identité.', IdentityRecovery.close, 'Fermer'),
      'document_already_used' =>
        const IdentityFailureInfo('Ce document est déjà associé à un autre compte.', IdentityRecovery.close, 'Fermer'),
      'document_banned' => const IdentityFailureInfo('Ce document ne peut pas être utilisé.', IdentityRecovery.close, 'Fermer'),
      'document_face_mismatch' => const IdentityFailureInfo(
          'Votre visage ne correspond pas à la photo du document.', IdentityRecovery.retryFace, _retry),
      'session_not_found' || 'session_expired' || 'session_used' =>
        const IdentityFailureInfo('La session a expiré.', IdentityRecovery.retryFace, _retry),
      'wrong_frame_count' || 'invalid_image' =>
        const IdentityFailureInfo('Les images n\'ont pas pu être lues.', IdentityRecovery.retryFace, _retry),
      'no_face' => const IdentityFailureInfo('Aucun visage détecté.', IdentityRecovery.retryFace, _retry),
      'multiple_faces' => const IdentityFailureInfo('Un seul visage doit apparaître.', IdentityRecovery.retryFace, _retry),
      'face_too_small' => const IdentityFailureInfo('Rapprochez-vous de la caméra.', IdentityRecovery.retryFace, _retry),
      'pose_mismatch' => const IdentityFailureInfo('Les mouvements demandés n\'ont pas été reconnus.', IdentityRecovery.retryFace, _retry),
      'duplicate_frames' => const IdentityFailureInfo('Bougez la tête comme demandé.', IdentityRecovery.retryFace, _retry),
      'inconsistent_identity' => const IdentityFailureInfo('Le visage a changé pendant la capture.', IdentityRecovery.retryFace, _retry),
      'no_profile_photo' => const IdentityFailureInfo('Ajoutez d\'abord une photo à votre profil.', IdentityRecovery.close, 'Fermer'),
      'profile_mismatch' =>
        const IdentityFailureInfo('Votre visage ne correspond pas à votre photo de profil.', IdentityRecovery.retryFace, _retry),
      'daily_limit_reached' =>
        const IdentityFailureInfo('Vous avez atteint la limite d\'essais du jour. Revenez demain.', IdentityRecovery.close, 'Fermer'),
      _ => const IdentityFailureInfo('La vérification a échoué.', IdentityRecovery.retryFace, _retry),
    };

/// Translates a typed chip failure. [ChipFailureKind.cancelled] has no
/// message: the user closed the sheet on purpose.
IdentityFailureInfo? describeChipFailure(ChipFailureKind kind) => switch (kind) {
      ChipFailureKind.cancelled => null,
      ChipFailureKind.nfcUnavailable => const IdentityFailureInfo(
          'Ce téléphone n\'a pas de lecteur NFC.', IdentityRecovery.close, 'Fermer', offerManualReview: true),
      ChipFailureKind.nfcDisabled =>
        const IdentityFailureInfo('Activez le NFC dans les réglages du téléphone.', IdentityRecovery.retryChip, _retry),
      ChipFailureKind.tagLost =>
        const IdentityFailureInfo('Le document a bougé. Gardez-le immobile contre le téléphone.', IdentityRecovery.retryChip, _retry),
      ChipFailureKind.accessDenied => const IdentityFailureInfo(
          'Les informations saisies ne correspondent pas à la puce.', IdentityRecovery.rescanMrz, 'Scanner à nouveau'),
      ChipFailureKind.unsupportedDocument => const IdentityFailureInfo(
          'Ce document ne peut pas être lu.', IdentityRecovery.close, 'Fermer', offerManualReview: true),
      ChipFailureKind.timeout => const IdentityFailureInfo('La puce n\'a pas répondu.', IdentityRecovery.retryChip, _retry),
      ChipFailureKind.unknown => const IdentityFailureInfo('La lecture a échoué.', IdentityRecovery.retryChip, _retry),
    };

/// When the server could not be reached or answered with an error.
IdentityFailureInfo describeApiFailure(String? error) => switch (error) {
      'daily_limit_reached' => describeIdentityRejection('daily_limit_reached'),
      _ => const IdentityFailureInfo('Connexion impossible. Vérifiez votre connexion.', IdentityRecovery.retryFace, _retry),
    };

const faceUnavailableMessage = 'La caméra n\'est pas disponible.';
