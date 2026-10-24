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
  String get errorNetwork => 'Pas de connexion. Vérifiez votre réseau et réessayez.';

  @override
  String get errorServer => 'Le serveur est indisponible. Réessayez dans un instant.';

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
  String get errorInvalid => 'Demande refusée. Vérifiez les informations saisies.';

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
  String get profileMyProfile => 'Mon profil';

  @override
  String get profileEdit => 'Modifier';

  @override
  String get profileSettings => 'Réglages';

  @override
  String get profileMoreOptions => 'Plus d\'options';

  @override
  String get profilePass => 'Passer';

  @override
  String profileLikeName(String name) {
    return 'J\'aime $name';
  }

  @override
  String get profileThisPerson => 'cette personne';

  @override
  String get profileFallbackName => 'Utilisateur';

  @override
  String get profileFallbackReportName => 'Cet utilisateur';

  @override
  String get profileDefaultLocation => 'France';

  @override
  String get profileDistanceUnderOneKm => 'à moins de 1 km';

  @override
  String profileDistanceKm(int km) {
    return 'à $km km';
  }

  @override
  String get profileGenderMale => 'Homme';

  @override
  String get profileGenderFemale => 'Femme';

  @override
  String get profileFactPractice => 'Pratique';

  @override
  String get profileFactKashrut => 'Cacherout';

  @override
  String get profileShabbat => 'Shabbat';

  @override
  String get profileFactGender => 'Genre';

  @override
  String get profileEssentials => 'L\'essentiel';

  @override
  String get profileInAFewWords => 'En quelques mots';

  @override
  String get profileAbout => 'À propos';

  @override
  String get profileLookingFor => 'Ce que je recherche';

  @override
  String get profileAddPhotos => 'Ajouter des photos';

  @override
  String get profileVerified => 'Vérifié';

  @override
  String get profileVerifiedPlus => 'Vérifié+';

  @override
  String get profileVerifyMyProfile => 'Vérifier mon profil';

  @override
  String profileVerificationStatus(String status) {
    return 'Statut de vérification : $status';
  }

  @override
  String get profilePhotoPrevious => 'Photo précédente';

  @override
  String get profilePhotoNext => 'Photo suivante';

  @override
  String profilePhotoCounter(int current, int total) {
    return 'Photo $current sur $total';
  }

  @override
  String get profileMatchLabel => 'Match';

  @override
  String get profileMatchTitle => 'C\'est un match.';

  @override
  String profileMatchBody(String name) {
    return 'Vous pouvez maintenant discuter avec $name.';
  }

  @override
  String get profileMatchBodyUnnamed => 'Vous pouvez maintenant discuter avec cette personne.';

  @override
  String get profileSendMessage => 'Envoyer un message';

  @override
  String profileCompletionEyebrow(int done, int total) {
    return 'Profil · $done/$total';
  }

  @override
  String get profileCompletionTitle => 'Complétez votre profil';

  @override
  String profileCompletionRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étapes restantes',
      one: '$count étape restante',
    );
    return '$_temp0';
  }

  @override
  String get profileCompletionAction => 'Compléter maintenant';

  @override
  String get profileStepPhotosDone => 'Photos ajoutées';

  @override
  String get profileStepPhotosTodo => 'Ajoutez au moins 2 photos';

  @override
  String get profileStepBioDone => 'Bio complétée';

  @override
  String get profileStepBioTodo => 'Décrivez-vous en quelques lignes';

  @override
  String get profileStepCityDone => 'Ville renseignée';

  @override
  String get profileStepCityTodo => 'Indiquez votre ville';

  @override
  String get profileStepVerifiedDone => 'Profil vérifié';

  @override
  String get profileStepVerifiedTodo => 'Faites vérifier votre profil';

  @override
  String get profileCoupleMode => 'Mode couple';

  @override
  String get profileCoupleInCoupleTitle => 'En couple';

  @override
  String profileCoupleInCoupleBody(String name) {
    return 'Vous êtes en mode couple avec $name.';
  }

  @override
  String get profileCoupleElsewhereTitle => 'Déjà en mode couple';

  @override
  String get profileCoupleElsewhereBody => 'Vous êtes déjà en mode couple avec quelqu\'un d\'autre.';

  @override
  String get profileCoupleReceivedTitle => 'Demande reçue';

  @override
  String profileCoupleReceivedBody(String name) {
    return '$name souhaite activer le mode couple avec vous.';
  }

  @override
  String get profileCoupleRespond => 'Répondre';

  @override
  String get profileCouplePendingTitle => 'Demande envoyée';

  @override
  String profileCouplePendingBody(String name) {
    return '$name n\'a pas encore répondu.';
  }

  @override
  String get profileCoupleCancelRequest => 'Annuler la demande';

  @override
  String get profileCoupleAvailableTitle => 'Passer au mode couple';

  @override
  String get profileCoupleAvailableBody => 'Vous avez matché. Activez le mode couple pour partager des activités ensemble.';

  @override
  String profileCoupleActivate(String name) {
    return 'Activer avec $name';
  }

  @override
  String profileCoupleRequestSent(String name) {
    return 'Demande envoyée à $name.';
  }

  @override
  String get profileCompatibility => 'Compatibilité';

  @override
  String get profileCompatibilityVeryHigh => 'Très compatible';

  @override
  String get profileCompatibilityHigh => 'Compatible';

  @override
  String get profileCompatibilityAverage => 'Compatibilité moyenne';

  @override
  String get profileCompatibilityLow => 'Peu compatible';

  @override
  String get profileCompatibilityBasis => 'Calculée à partir de vos deux profils.';

  @override
  String get profileCompatibilityUnavailable => 'Compatibilité indisponible pour le moment.';

  @override
  String profileCompatibilityUnlockTitle(String name) {
    return 'Découvrez votre score de compatibilité avec $name.';
  }

  @override
  String get profileCompatibilityUnlockBody => 'Calculé à partir de vos pratiques, vos intentions et vos valeurs.';

  @override
  String get profileCompatibilityUnlock => 'Débloquer avec mazl+';

  @override
  String get profileFactorIntentions => 'Intentions';

  @override
  String get profileFactorAge => 'Âge';

  @override
  String get profileFactorDistance => 'Distance';

  @override
  String get profileVerdictSameIntention => 'Vous cherchez la même chose';

  @override
  String get profileVerdictDifferentIntention => 'Intentions différentes';

  @override
  String get profileVerdictSameDenomination => 'Même dénomination';

  @override
  String get profileVerdictSimilarPractice => 'Pratique similaire';

  @override
  String get profileVerdictDifferentPractice => 'Pratique différente';

  @override
  String get profileVerdictVeryCloseAge => 'Âge très proche';

  @override
  String get profileVerdictCloseAge => 'Âge proche';

  @override
  String get profileVerdictModerateAgeGap => 'Différence d\'âge modérée';

  @override
  String get profileVerdictLargeAgeGap => 'Grande différence d\'âge';

  @override
  String get profileVerdictVeryNear => 'Très proche (< 10 km)';

  @override
  String get profileVerdictNear => 'Proche (< 25 km)';

  @override
  String get profileVerdictModerateDistance => 'Distance modérée';

  @override
  String get profileVerdictFar => 'Assez loin';

  @override
  String profileCompatibilityCriteria(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count critères analysés',
      one: '1 critère analysé',
    );
    return '$_temp0';
  }

  @override
  String get profileCompatibilityScoreTitle => 'Score de compatibilité';

  @override
  String profileCompatibilityWith(String name) {
    return 'Avec $name';
  }

  @override
  String get profileCompatibilityDetails => 'Détails';

  @override
  String get profileCompatibilityIncomplete => 'Complétez vos profils pour voir plus de détails';

  @override
  String get profileCompatibilityNote => 'Le score est basé sur vos préférences et points communs';

  @override
  String get profileCompatibilityGotIt => 'Compris';

  @override
  String get profilePromptsMine => 'Mes Prompts';

  @override
  String get profilePromptsSubtitle => 'Répondez à des questions pour montrer votre personnalité';

  @override
  String profilePromptsMaxReached(int max) {
    return 'Maximum $max prompts atteint';
  }

  @override
  String get profilePromptsAllUsed => 'Tous les prompts sont déjà utilisés';

  @override
  String get profilePromptAdd => 'Ajouter un prompt';

  @override
  String get profilePromptChoose => 'Choisissez un prompt';

  @override
  String get profilePromptYourAnswer => 'Votre réponse…';

  @override
  String get profilePromptDeleteTitle => 'Supprimer ce prompt ?';

  @override
  String get profileIrreversibleSentence => 'Cette action est irréversible.';

  @override
  String get profileIrreversible => 'Cette action est irréversible';

  @override
  String get profilePromptDeleted => 'Prompt supprimé';

  @override
  String get profilePromptsGetToKnowMe => 'Apprenez à me connaître';

  @override
  String get profilePromptCategoryPersonality => 'Personnalité';

  @override
  String get profilePromptCategoryLifestyle => 'Mode de vie';

  @override
  String get profilePromptCategoryJewish => 'Judaïsme';

  @override
  String get profilePromptCategoryConversation => 'Conversation';

  @override
  String get profileOther => 'Autre';

  @override
  String get profilePromptPerfectSunday => 'Mon dimanche parfait...';

  @override
  String get profilePromptFunFact => 'Un fait surprenant sur moi...';

  @override
  String get profilePromptLifeGoal => 'Un de mes objectifs dans la vie...';

  @override
  String get profilePromptPetPeeve => 'Ce qui m\'énerve le plus...';

  @override
  String get profilePromptProudOf => 'Je suis fier(e) de...';

  @override
  String get profilePromptLookingFor => 'Je cherche quelqu\'un qui...';

  @override
  String get profilePromptIdealVacation => 'Mes vacances idéales...';

  @override
  String get profilePromptFavoriteFood => 'Mon plat préféré...';

  @override
  String get profilePromptHiddenTalent => 'Mon talent caché...';

  @override
  String get profilePromptBingeWatching => 'En ce moment je regarde...';

  @override
  String get profilePromptShabbatIdeal => 'Mon Shabbat idéal...';

  @override
  String get profilePromptFamilyTradition => 'Une tradition familiale que j\'adore...';

  @override
  String get profilePromptFavoriteHoliday => 'Ma fête juive préférée...';

  @override
  String get profilePromptFridayNight => 'Le vendredi soir chez moi...';

  @override
  String get profilePromptIsraelMemory => 'Mon meilleur souvenir en Israël...';

  @override
  String get profilePromptJewishValue => 'Une valeur juive qui me guide...';

  @override
  String get profilePromptDebateMe => 'Débattez avec moi sur…';

  @override
  String get profilePromptTeachMe => 'Apprenez-moi quelque chose sur…';

  @override
  String get profilePromptTogetherWeCould => 'Ensemble on pourrait...';

  @override
  String get profilePromptFirstDate => 'Premier date idéal...';

  @override
  String get profileIntentionHint => 'Montrez aux autres ce que vous recherchez';

  @override
  String get profileIntentionMarriage => 'Mariage';

  @override
  String get profileIntentionSerious => 'Relation sérieuse';

  @override
  String get profileIntentionOpen => 'Ouvert à tout';

  @override
  String get profileIntentionOpenSelector => 'Ouvert(e) à tout';

  @override
  String get profileIntentionFriendsFirst => 'Amitié d\'abord';

  @override
  String get profileIntentionUndecided => 'Je ne sais pas';

  @override
  String get profileIntentionMarriageDescription => 'Je cherche mon/ma futur(e) mari/femme';

  @override
  String get profileIntentionSeriousDescription => 'Je cherche une relation durable';

  @override
  String get profileIntentionOpenDescription => 'On verra où ça nous mène';

  @override
  String get profileIntentionFriendsFirstDescription => 'Commençons par apprendre à se connaître';

  @override
  String get profileDenomination => 'Dénomination';

  @override
  String get profileDenominationSecular => 'Laïque';

  @override
  String get profileDenominationTraditional => 'Traditionaliste';

  @override
  String get profileDenominationMasorti => 'Massorti';

  @override
  String get profileDenominationLiberal => 'Libéral';

  @override
  String get profileDenominationModernOrthodox => 'Orthodoxe moderne';

  @override
  String get profileDenominationOrthodox => 'Orthodoxe';

  @override
  String get profileDenominationChabad => 'Habad';

  @override
  String get profileFieldKashrut => 'Kashrout';

  @override
  String get profileKashrutNone => 'Non';

  @override
  String get profileKashrutHome => 'Cacher à la maison';

  @override
  String get profileKashrutStrict => 'Cacher strict';

  @override
  String get profileKashrutGlatt => 'Glatt cacher';

  @override
  String get profileKashrutOptionHome => 'À la maison';

  @override
  String get profileKashrutOptionStrict => 'Strict';

  @override
  String get profileKashrutOptionGlatt => 'Glatt';

  @override
  String get profileShabbatNotObservant => 'Non observant';

  @override
  String get profileShabbatPartial => 'Shabbat en partie';

  @override
  String get profileShabbatObserved => 'Shabbat observé';

  @override
  String get profileShabbatStrict => 'Shabbat strict';

  @override
  String get profileShabbatFamily => 'Shabbat en famille';

  @override
  String get profileShabbatOptionPartial => 'Partiellement';

  @override
  String get profileShabbatOptionObservant => 'Observant';

  @override
  String get profileShabbatOptionStrict => 'Très observant';

  @override
  String get profileSynagogue => 'Synagogue';

  @override
  String get profileSynagogueDaily => 'Quotidien';

  @override
  String get profileSynagogueWeekly => 'Chaque semaine';

  @override
  String get profileSynagogueHolidays => 'Fêtes';

  @override
  String get profileSynagogueRarely => 'Rarement';

  @override
  String get profileEditTitle => 'Modifier le profil';

  @override
  String get profilePhotos => 'Photos';

  @override
  String get profilePhotosHint => 'Maintenez appuyé pour définir comme principale';

  @override
  String get profileBioHint => 'Parlez de vous…';

  @override
  String get profileBasicInfo => 'Informations de base';

  @override
  String get profileFirstName => 'Prénom';

  @override
  String get profileCity => 'Ville';

  @override
  String get profilePracticeTitle => 'Ma pratique';

  @override
  String get profilePrimaryPhoto => 'Principal';

  @override
  String get profileEnterFirstName => 'Entrez votre prénom';

  @override
  String get profileEnterCity => 'Entrez votre ville';

  @override
  String get profileUpdated => 'Profil mis à jour';

  @override
  String get profilePhotoAdded => 'Photo ajoutée';

  @override
  String get profileUploadUnavailable => 'Upload non disponible pour le moment';

  @override
  String get profileDeletePhotoTitle => 'Supprimer la photo ?';

  @override
  String get profilePhotoDeleted => 'Photo supprimée';

  @override
  String get profileServiceUnavailable => 'Service temporairement indisponible';

  @override
  String get profilePrimaryUpdated => 'Photo principale mise à jour';

  @override
  String profileSetupStep(int step, int total) {
    return 'Étape $step/$total';
  }

  @override
  String get profileSetupNext => 'Suivant';

  @override
  String get profileSetupFinish => 'Terminer';

  @override
  String get profileSetupNameRequired => 'Indiquez votre prénom pour continuer';

  @override
  String get profileSetupBirthdateRequired => 'Indiquez votre date de naissance';

  @override
  String get profileSetupGenderRequired => 'Indiquez votre genre';

  @override
  String get profileBirthdate => 'Date de naissance';

  @override
  String get profileBirthdateHint => 'JJ/MM/AAAA';

  @override
  String get profileSetupAboutYouTitle => 'Parlez-nous de vous';

  @override
  String get profileSetupAboutYouSubtitle => 'Ces informations seront visibles sur votre profil';

  @override
  String get profileFirstNameHint => 'Comment vous appelez-vous ?';

  @override
  String get profileIAm => 'Je suis';

  @override
  String get profileAMan => 'Un homme';

  @override
  String get profileAWoman => 'Une femme';

  @override
  String get profileCityHint => 'Où habitez-vous ?';

  @override
  String get profileSetupPhotosTitle => 'Ajoutez des photos';

  @override
  String get profileSetupPhotosSubtitle => 'Ajoutez au moins 2 photos pour continuer';

  @override
  String get profileSetupPhotosTip => 'Les profils avec des photos de bonne qualité reçoivent 3x plus de matchs.';

  @override
  String get profileSetupPracticeTitle => 'Votre pratique';

  @override
  String get profileSetupPracticeSubtitle => 'Aidez-nous à trouver quelqu\'un qui vous correspond';

  @override
  String get profileSetupLookingTitle => 'Ce que vous recherchez';

  @override
  String get profileSetupLookingSubtitle => 'Aidez-nous à vous montrer les bons profils';

  @override
  String get profileILookFor => 'Je recherche';

  @override
  String get profileAgeRange => 'Tranche d\'âge';

  @override
  String get profileMaxDistance => 'Distance maximale';

  @override
  String profileDistanceSliderLabel(int km) {
    return '$km km';
  }

  @override
  String get profileGoal => 'Objectif';

  @override
  String get profileShadchanNote => 'Notre AI Shadchan utilisera ces préférences pour vous proposer des profils compatibles.';

  @override
  String get profileReportThisProfile => 'Signaler ce profil';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du téléphone';
}
