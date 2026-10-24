// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonBack => 'Retour';

  @override
  String get errorTimeout => 'Délai dépassé. Vérifiez votre connexion.';

  @override
  String get errorNetwork =>
      'Pas de connexion. Vérifiez votre réseau et réessayez.';

  @override
  String get errorServer =>
      'Le serveur est indisponible. Réessayez dans un instant.';

  @override
  String get errorSessionExpired => 'Session expirée. Reconnectez-vous.';

  @override
  String get errorForbidden => 'Action non autorisée.';

  @override
  String get errorNotFound => 'Introuvable : cet élément n\'existe plus.';

  @override
  String get errorConflict => 'Cette action n\'est plus possible.';

  @override
  String get errorTooLarge => 'Fichier trop volumineux.';

  @override
  String get errorRateLimited => 'Trop de tentatives. Patientez un instant.';

  @override
  String get errorInvalid =>
      'Demande refusée. Vérifiez les informations saisies.';

  @override
  String get errorUnknown => 'Une erreur est survenue. Réessayez.';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get commonSkip => 'Passer';

  @override
  String get commonSee => 'Voir';

  @override
  String get commonShare => 'Partager';

  @override
  String get commonReport => 'Signaler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonLater => 'Plus tard';

  @override
  String get commonToday => 'Aujourd\'hui';

  @override
  String get commonYesterday => 'Hier';

  @override
  String get commonNotSpecified => 'Non renseigné';

  @override
  String get commonLoadError => 'Erreur de chargement';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du téléphone';

  @override
  String get verificationProfileEyebrow => 'Votre profil';

  @override
  String get verificationTitle => 'Vérification';

  @override
  String get verificationLevel1 => 'Niveau 1';

  @override
  String get verificationLevel2 => 'Niveau 2';

  @override
  String get verificationPhotoTitle => 'Photo vérifiée';

  @override
  String get verificationIdentityTitle => 'Identité vérifiée';

  @override
  String get verificationVerifiedPill => 'Vérifiée';

  @override
  String get verificationConsent =>
      'Nous comparons votre visage à vos photos. Les images ne sont pas conservées ; seule une empreinte chiffrée l\'est, supprimable à tout moment.';

  @override
  String get verificationPhotoVerifiedLine =>
      'Votre visage correspond à vos photos.';

  @override
  String verificationPhotoVerifiedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Vérifiée le $dateString.';
  }

  @override
  String get verificationRemoveAction => 'Retirer ma vérification';

  @override
  String get verificationVerifyPhotoAction => 'Vérifier ma photo';

  @override
  String get verificationVerifyIdentityAction => 'Vérifier mon identité';

  @override
  String verificationBlockedToday(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Limite atteinte, nouvel essai possible à $timeString.';
  }

  @override
  String verificationBlockedLater(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Limite atteinte, nouvel essai possible le $dateString à $timeString.';
  }

  @override
  String get verificationIdentityCheckedNoDate =>
      'Document contrôlé par sa puce.';

  @override
  String verificationIdentityCheckedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Contrôlée le $dateString.';
  }

  @override
  String get verificationIdentityPitch =>
      'Passeport ou carte d\'identité, lu par sa puce. Un selfie confirme que c\'est bien vous.';

  @override
  String get verificationRemoveDialogTitle => 'Retirer ma vérification ?';

  @override
  String get verificationRemoveDialogBody =>
      'Votre badge et l\'empreinte de votre visage seront supprimés.';

  @override
  String verificationPhotosMismatch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count de vos photos ne vous ressemblent pas : elles ne comptent pas.',
      one: 'Une de vos photos ne vous ressemble pas : elle ne compte pas.',
    );
    return '$_temp0';
  }

  @override
  String get verificationLivenessFront => 'Regardez l\'objectif';

  @override
  String get verificationLivenessLeft =>
      'Tournez doucement la tête vers la gauche';

  @override
  String get verificationLivenessRight =>
      'Tournez doucement la tête vers la droite';

  @override
  String get verificationLivenessHintNoFace =>
      'Placez votre visage dans le cercle';

  @override
  String get verificationLivenessHintMultipleFaces =>
      'Une seule personne dans le cadre';

  @override
  String get verificationLivenessHintTooSmall => 'Rapprochez-vous un peu';

  @override
  String get verificationLivenessHintOffCenter =>
      'Centrez votre visage dans le cercle';

  @override
  String get verificationLivenessHintLookStraight =>
      'Regardez droit devant vous';

  @override
  String get verificationLivenessHintTurnMore => 'Tournez encore un peu';

  @override
  String get verificationLivenessHintTurnLess => 'Pas autant, revenez un peu';

  @override
  String get verificationLivenessHintTurnOtherWay => 'Tournez de l\'autre côté';

  @override
  String verificationLivenessPoseCounter(int current, int total) {
    return 'Pose $current / $total';
  }

  @override
  String verificationLivenessPosesTaken(int done, int total) {
    return 'Poses prises : $done sur $total';
  }

  @override
  String get verificationLivenessPrivacy =>
      'Seul dans le cadre, bien éclairé. Les images ne sont pas conservées.';

  @override
  String get verificationLivenessExpiredTitle => 'Session expirée';

  @override
  String get verificationLivenessExpiredBody =>
      'Le temps imparti est écoulé. Vous pouvez recommencer.';

  @override
  String get verificationCameraNeededTitle => 'Caméra nécessaire';

  @override
  String get verificationCameraNeededBody =>
      'MAZL utilise la caméra frontale pour vérifier que vous êtes bien la personne de vos photos.';

  @override
  String get verificationCameraOpenSettings => 'Ouvrir les réglages';

  @override
  String get verificationCameraAllow => 'Autoriser la caméra';

  @override
  String get verificationCameraUnavailableTitle => 'Caméra indisponible';

  @override
  String get verificationCameraUnavailableBody =>
      'Impossible de démarrer la caméra frontale.';

  @override
  String get verificationIntroTitle => 'Vérifiez votre identité.';

  @override
  String get verificationIntroSubtitle =>
      'Le badge « Identité vérifiée » dit aux autres que vous êtes bien la personne des photos. Il faut un passeport ou une carte d\'identité biométrique, deux minutes et un peu de lumière.';

  @override
  String get verificationIntroStep1 => 'Photographier la page photo';

  @override
  String get verificationIntroStep1Detail =>
      'Pour lire les deux lignes du bas.';

  @override
  String get verificationIntroStep2 => 'Poser le téléphone sur la puce';

  @override
  String get verificationIntroStep2Detail =>
      'La puce signée par l\'État fait foi.';

  @override
  String get verificationIntroStep3 => 'Un selfie en mouvement';

  @override
  String get verificationIntroStep3Detail => 'Comparé à la photo de la puce.';

  @override
  String get verificationIntroPrivacy =>
      'Rien n\'est conservé : nous ne gardons que le résultat.';

  @override
  String get verificationIntroStart => 'Commencer';

  @override
  String verificationStepLabel(int step, int total) {
    return 'Étape $step / $total';
  }

  @override
  String get verificationScanTitle => 'Cadrez la page photo.';

  @override
  String get verificationScanHint =>
      'Les deux lignes de « < » du bas suffisent. Évitez les reflets.';

  @override
  String get verificationScanManual => 'Saisir à la main';

  @override
  String get verificationScanFrameSemantics =>
      'Aperçu de la caméra : placez les deux lignes du bas du document dans le cadre mis en évidence';

  @override
  String get verificationCameraNotAvailable =>
      'La caméra n\'est pas disponible.';

  @override
  String get verificationScanUnavailableBody =>
      'Vous pouvez saisir les informations de la page photo à la main.';

  @override
  String get verificationScanEnterDetails => 'Saisir les informations';

  @override
  String get verificationManualTitle => 'Saisissez les informations.';

  @override
  String get verificationManualSubtitle =>
      'Recopiez-les depuis la page photo de votre document.';

  @override
  String get verificationFieldDocumentNumber => 'Numéro du document';

  @override
  String get verificationFieldBirthDate => 'Date de naissance';

  @override
  String get verificationFieldExpiryDate => 'Date d\'expiration';

  @override
  String get verificationDateHint => 'JJ/MM/AAAA';

  @override
  String get verificationManualUseCamera => 'Scanner avec la caméra';

  @override
  String get verificationErrorDocumentNumber =>
      'Entre 5 et 12 lettres ou chiffres.';

  @override
  String get verificationErrorInvalidDate => 'Date invalide.';

  @override
  String get verificationReviewTitle => 'Vérifiez ces informations.';

  @override
  String get verificationReviewConfirm => 'C\'est bien moi';

  @override
  String get verificationRescan => 'Scanner à nouveau';

  @override
  String get verificationNfcWaitingTitle =>
      'Posez votre document sur le téléphone.';

  @override
  String get verificationNfcPlacement =>
      'Le haut du téléphone contre la couverture fermée du passeport, ou contre le dos de la carte d\'identité. Retirez la coque si besoin.';

  @override
  String get verificationNfcRead => 'Lire le document';

  @override
  String get verificationNfcIllustration =>
      'Le haut du téléphone posé contre la couverture fermée du passeport';

  @override
  String get verificationNfcReadingTitle => 'Ne bougez plus.';

  @override
  String get verificationNfcReadingSubtitle =>
      'Gardez le document contre le haut du téléphone jusqu\'à la fin de la lecture.';

  @override
  String get verificationNfcProgressLabel => 'Lecture de la puce';

  @override
  String verificationNfcProgressValue(int percent) {
    return '$percent %';
  }

  @override
  String get verificationNfcStepDetect => 'Détection du document';

  @override
  String get verificationNfcStepConnect => 'Connexion sécurisée';

  @override
  String get verificationNfcStepPhoto => 'Lecture de la photo';

  @override
  String get verificationNfcStepSignature => 'Lecture de la signature';

  @override
  String verificationNfcStepSemantics(String label, String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'done': '$label, terminé',
      'active': '$label, en cours',
      'waiting': '$label, en attente',
      'other': '$label',
    });
    return '$_temp0';
  }

  @override
  String get verificationNfcSilentBody =>
      'Cela arrive souvent au premier essai. Rien n\'a été envoyé.';

  @override
  String get verificationNfcRescanBody =>
      'Rien n\'a été envoyé. Relisez la page photo pour repartir sur de bonnes données.';

  @override
  String get verificationNfcTip1 => 'Retirez la coque du téléphone.';

  @override
  String get verificationNfcTip2 =>
      'Posez le haut du téléphone au centre de la couverture, passeport fermé.';

  @override
  String get verificationNfcTip3 => 'Restez immobile une dizaine de secondes.';

  @override
  String get verificationNfcRereadPhotoPage => 'Relire la page photo';

  @override
  String get verificationManualReviewLink =>
      'Envoyer mon document pour relecture';

  @override
  String get verificationFaceTitle => 'Puce lue.';

  @override
  String get verificationFaceSubtitle =>
      'Il reste un selfie en mouvement, comparé à la photo de la puce.';

  @override
  String get verificationFaceAction => 'Prendre le selfie';

  @override
  String get verificationSubmitSending => 'Vérification en cours…';

  @override
  String get verificationSubmitPreparing => 'Préparation…';

  @override
  String get verificationDoneTitle => 'Identité vérifiée.';

  @override
  String get verificationDoneSubtitle =>
      'La puce de votre document et votre selfie correspondent. Votre profil porte maintenant le badge.';

  @override
  String get verificationDoneAction => 'Terminer';

  @override
  String get verificationBadgeLabel => 'Identité vérifiée';

  @override
  String get verificationDoneBadgeCaption =>
      'Ce que les autres voient sur votre profil.';

  @override
  String get verificationDoneStoredLabel => 'Photos et puce';

  @override
  String get verificationDoneStoredValue => 'Jamais enregistrées';

  @override
  String get verificationDoneKeptLabel => 'Conservé';

  @override
  String get verificationDoneKeptValue => 'Pays, expiration, empreinte anonyme';

  @override
  String get verificationDoneProfileLabel => 'Profil';

  @override
  String get verificationDoneProfileValue => 'Date de naissance du document';

  @override
  String get verificationComingSoon => 'Bientôt disponible';

  @override
  String get verificationFailureChipDataInvalid =>
      'Les données de la puce sont illisibles.';

  @override
  String get verificationFailureChipSignatureInvalid =>
      'La signature du document n\'a pas pu être vérifiée.';

  @override
  String get verificationFailureNotRecognized => 'Document non reconnu.';

  @override
  String get verificationDocumentExpired => 'Ce document est expiré.';

  @override
  String get verificationFailureUnderage =>
      'Il faut avoir 18 ans pour vérifier son identité.';

  @override
  String get verificationDocumentAlreadyUsed =>
      'Ce document est déjà associé à un autre compte.';

  @override
  String get verificationDocumentBanned =>
      'Ce document ne peut pas être utilisé.';

  @override
  String get verificationDocumentFaceMismatch =>
      'Votre visage ne correspond pas à la photo du document.';

  @override
  String get verificationFailureSessionExpired => 'La session a expiré.';

  @override
  String get verificationFailureImagesUnreadable =>
      'Les images n\'ont pas pu être lues.';

  @override
  String get verificationFailureNoFace => 'Aucun visage détecté.';

  @override
  String get verificationFailureMultipleFaces =>
      'Un seul visage doit apparaître.';

  @override
  String get verificationFailureFaceTooSmall => 'Rapprochez-vous de la caméra.';

  @override
  String get verificationFailurePoseMismatch =>
      'Les mouvements demandés n\'ont pas été reconnus.';

  @override
  String get verificationFailureDuplicateFrames =>
      'Bougez la tête comme demandé.';

  @override
  String get verificationFailureInconsistentIdentity =>
      'Le visage a changé pendant la capture.';

  @override
  String get verificationFailureNoProfilePhoto =>
      'Ajoutez d\'abord une photo à votre profil.';

  @override
  String get verificationFailureProfileMismatch =>
      'Votre visage ne correspond pas à votre photo de profil.';

  @override
  String get verificationFailureDailyLimit =>
      'Vous avez atteint la limite d\'essais du jour. Revenez demain.';

  @override
  String get verificationFailureGeneric => 'La vérification a échoué.';

  @override
  String get verificationFailureNoNfc =>
      'Ce téléphone n\'a pas de lecteur NFC.';

  @override
  String get verificationFailureNfcDisabled =>
      'Activez le NFC dans les réglages du téléphone.';

  @override
  String get verificationFailureTagLost =>
      'Le document a bougé. Gardez-le immobile contre le téléphone.';

  @override
  String get verificationFailureChipMismatch =>
      'Les informations saisies ne correspondent pas à la puce.';

  @override
  String get verificationFailureUnreadableDocument =>
      'Ce document ne peut pas être lu.';

  @override
  String get verificationFailureChipSilent => 'La puce n\'a pas répondu.';

  @override
  String get verificationFailureReadFailed => 'La lecture a échoué.';

  @override
  String get verificationFailureConnection =>
      'Connexion impossible. Vérifiez votre connexion.';

  @override
  String get verificationActionRereadDocument => 'Relire le document';

  @override
  String get verificationActionOtherDocument => 'Autre document';

  @override
  String get verificationReasonNoFace =>
      'Aucun visage détecté. Mettez-vous face à la caméra, dans un endroit bien éclairé.';

  @override
  String get verificationReasonMultipleFaces =>
      'Plusieurs visages détectés. Restez seul(e) dans le cadre.';

  @override
  String get verificationReasonFaceTooSmall =>
      'Votre visage est trop loin. Rapprochez-vous de la caméra.';

  @override
  String get verificationReasonPoseMismatch =>
      'Les poses demandées n\'ont pas été reconnues. Suivez bien les consignes.';

  @override
  String get verificationReasonDuplicateFrames =>
      'Les images sont trop semblables. Bougez la tête comme demandé.';

  @override
  String get verificationReasonInconsistentIdentity =>
      'Les images ne montrent pas la même personne. Recommencez seul(e).';

  @override
  String get verificationReasonNoProfilePhoto =>
      'Ajoutez d\'abord à votre profil une photo où votre visage est bien visible.';

  @override
  String get verificationReasonProfileMismatch =>
      'Votre visage ne correspond pas à votre photo principale. Choisissez une photo récente où vous êtes bien visible.';

  @override
  String get verificationReasonDailyLimit =>
      'Vous avez atteint la limite d\'essais pour aujourd\'hui. Revenez demain.';

  @override
  String get verificationReasonSessionExpired =>
      'La session a expiré. Recommencez.';

  @override
  String get verificationReasonSessionInvalid =>
      'La session n\'est plus valide. Recommencez.';

  @override
  String get verificationReasonImagesUnreadable =>
      'Les images n\'ont pas pu être lues. Recommencez.';

  @override
  String get verificationReasonAppUpdate =>
      'Mettez à jour l\'application pour vérifier votre profil.';

  @override
  String get verificationReasonChipAuth =>
      'La puce du document n\'a pas pu être authentifiée.';

  @override
  String get verificationReasonUnderage => 'Vous devez avoir au moins 18 ans.';

  @override
  String get verificationReasonNetwork =>
      'Connexion impossible. Vérifiez votre réseau et réessayez.';

  @override
  String get verificationReasonGeneric =>
      'Une erreur est survenue. Réessayez dans un instant.';

  @override
  String get verificationNfcAlertApproach =>
      'Approchez votre document du haut du téléphone.';

  @override
  String get verificationNfcAlertAuthenticating =>
      'Ne bouge pas. Connexion sécurisée…';

  @override
  String get verificationNfcAlertReadingPhoto => 'Lecture de la photo… 40 %';

  @override
  String get verificationNfcAlertReadingSignature =>
      'Lecture de la signature… 85 %';

  @override
  String get verificationNfcAlertDone => 'Terminé.';
}
