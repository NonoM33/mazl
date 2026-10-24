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
  String get safetyBlock => 'Bloquer';

  @override
  String get safetyBlockSubtitle =>
      'Cette personne ne pourra plus vous voir ni vous contacter';

  @override
  String get safetyReportSubtitle => 'Signaler un comportement inapproprié';

  @override
  String get safetyBlockConfirmTitle => 'Bloquer cet utilisateur ?';

  @override
  String safetyBlockConfirmIntro(String name) {
    return 'En bloquant $name :';
  }

  @override
  String get safetyBlockEffectHidden =>
      'Cette personne ne pourra plus voir votre profil';

  @override
  String get safetyBlockEffectNotSeen => 'Vous ne verrez plus son profil';

  @override
  String get safetyBlockEffectChats => 'Vos conversations seront supprimées';

  @override
  String get safetyBlockEffectNotNotified =>
      'Cette personne ne sera pas notifiée';

  @override
  String safetyBlocked(String name) {
    return '$name a été bloqué';
  }

  @override
  String get safetyBlockFailed => 'Erreur lors du blocage';

  @override
  String get safetyReportTitle => 'Signaler un problème';

  @override
  String safetyReportWhy(String name) {
    return 'Pourquoi signalez-vous $name ?';
  }

  @override
  String get safetyReportDetailsHint => 'Détails supplémentaires (optionnel)';

  @override
  String get safetyReportAlsoBlock => 'Bloquer également cet utilisateur';

  @override
  String get safetyReportAlsoBlockHint => 'Vous ne verrez plus ce profil';

  @override
  String get safetyReportSend => 'Envoyer le signalement';

  @override
  String get safetyReportThanks =>
      'Merci pour votre signalement. Notre équipe va l\'examiner.';

  @override
  String get safetyReportFailed => 'Erreur lors du signalement';

  @override
  String get safetyCategoryFakeProfile => 'Faux profil';

  @override
  String get safetyCategoryFakeProfileHint => 'Photos volées, identité fausse';

  @override
  String get safetyCategoryInappropriatePhotos => 'Photos inappropriées';

  @override
  String get safetyCategoryInappropriatePhotosHint =>
      'Contenu sexuel, violent ou choquant';

  @override
  String get safetyCategoryHarassment => 'Harcèlement';

  @override
  String get safetyCategoryHarassmentHint =>
      'Messages insistants, menaces, insultes';

  @override
  String get safetyCategorySpam => 'Spam / Arnaque';

  @override
  String get safetyCategorySpamHint =>
      'Publicité, demande d\'argent, liens suspects';

  @override
  String get safetyCategoryUnderage => 'Mineur';

  @override
  String get safetyCategoryUnderageHint =>
      'La personne semble avoir moins de 18 ans';

  @override
  String get safetyCategoryOfflineBehavior => 'Comportement hors app';

  @override
  String get safetyCategoryOfflineBehaviorHint =>
      'Comportement inapproprié lors d\'une rencontre';

  @override
  String get safetyCategoryOther => 'Autre';

  @override
  String get safetyCategoryOtherHint => 'Autre raison (précisez)';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du téléphone';
}
