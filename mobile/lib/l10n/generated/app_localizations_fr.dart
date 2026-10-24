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
  String get coupleFeedDashboardSettingsTooltip => 'Réglages';

  @override
  String get coupleFeedDashboardMe => 'Moi';

  @override
  String get coupleFeedDashboardPartnerFallback => 'Partenaire';

  @override
  String coupleFeedDashboardDaysTogether(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString jours ensemble',
      one: '$countString jour ensemble',
      zero: '0 jours ensemble',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedDashboardDailyQuestion => 'Question du jour';

  @override
  String get coupleFeedDashboardAnswer => 'Répondre';

  @override
  String get coupleFeedDashboardAnswerHint => 'Votre réponse…';

  @override
  String get coupleFeedDashboardSend => 'Envoyer';

  @override
  String get coupleFeedDashboardAnswerSent =>
      'Réponse envoyée. Votre partenaire sera notifié(e).';

  @override
  String get coupleFeedDashboardActivities => 'Activités en couple';

  @override
  String get coupleFeedDashboardMilestones => 'Nos étapes';

  @override
  String get coupleFeedDashboardSeeAll => 'Voir tout';

  @override
  String get coupleFeedDashboardEvents => 'Événements en couple';

  @override
  String get coupleFeedDashboardJewishCalendar => 'Calendrier juif';

  @override
  String get coupleFeedStoriesTitle => 'Histoires de couples';

  @override
  String get coupleFeedDashboardSeeAllStories => 'Voir toutes';

  @override
  String get coupleFeedDashboardEventSampleTitle => 'Cours de cuisine casher';

  @override
  String get coupleFeedDashboardEventSampleWhen =>
      'Dimanche 20 janvier - 15h00';

  @override
  String get coupleFeedDashboardEventSampleTag => 'Couples';

  @override
  String get coupleFeedDashboardAllEvents => 'Voir tous les événements';

  @override
  String get coupleFeedDashboardParasha => 'Shabbat Beshalach';

  @override
  String get coupleFeedDashboardShabbatTimes =>
      'Entrée : 17h23 - Sortie : 18h34';

  @override
  String get coupleFeedDashboardShabbatDinner => 'Dîner';

  @override
  String get coupleFeedDashboardShabbatPrayer => 'Prière';

  @override
  String get coupleFeedDashboardShabbatRest => 'Repos';

  @override
  String get coupleFeedStoryShareTitle => 'Partagez votre histoire';

  @override
  String get coupleFeedDashboardShareStoryLine =>
      'Inspirez la communauté MAZL avec votre histoire';

  @override
  String get coupleFeedDashboardSeeStories => 'Voir les histoires';

  @override
  String get coupleFeedMilestoneFirstWeekTitle => 'Première semaine';

  @override
  String get coupleFeedMilestoneFirstWeekLine => '7 jours ensemble';

  @override
  String get coupleFeedMilestoneFirstMonthTitle => 'Premier mois';

  @override
  String get coupleFeedMilestoneFirstMonthLine => '30 jours d\'amour';

  @override
  String get coupleFeedMilestoneThreeMonthsTitle => 'Trimestre';

  @override
  String get coupleFeedMilestoneThreeMonthsLine => '3 mois de bonheur';

  @override
  String get coupleFeedMilestoneSixMonthsTitle => 'Mi-année';

  @override
  String get coupleFeedMilestoneSixMonthsLine => '6 mois main dans la main';

  @override
  String get coupleFeedMilestoneFirstYearTitle => 'Première année';

  @override
  String get coupleFeedMilestoneFirstYearLine => '365 jours de Mazl';

  @override
  String get coupleFeedQuestion1 =>
      'Quel est votre moment préféré de la semaine ensemble ?';

  @override
  String get coupleFeedQuestion1Category => 'Connexion';

  @override
  String get coupleFeedQuestion2 =>
      'Si vous pouviez voyager n\'importe où, où iriez-vous ?';

  @override
  String get coupleFeedQuestion2Category => 'Rêves';

  @override
  String get coupleFeedQuestion3 =>
      'Qu\'est-ce qui vous a fait sourire aujourd\'hui ?';

  @override
  String get coupleFeedQuestion3Category => 'Quotidien';

  @override
  String get coupleFeedQuestion4 =>
      'Comment aimeriez-vous célébrer votre prochain Shabbat ?';

  @override
  String get coupleFeedQuestion4Category => 'Judaïsme';

  @override
  String get coupleFeedQuestion4Option1 => 'Dîner romantique à la maison';

  @override
  String get coupleFeedQuestion4Option2 => 'Invitation chez des amis';

  @override
  String get coupleFeedQuestion4Option3 => 'Restaurant casher';

  @override
  String get coupleFeedQuestion4Option4 => 'Shabbaton communautaire';

  @override
  String get coupleFeedQuestion5 =>
      'Quel trait de caractère admirez-vous le plus chez votre partenaire ?';

  @override
  String get coupleFeedQuestion5Category => 'Appréciation';

  @override
  String get coupleFeedIdeaShabbatCookingTitle => 'Cuisine Shabbat';

  @override
  String get coupleFeedIdeaShabbatCookingCategory => 'Maison';

  @override
  String get coupleFeedIdeaTorahTitle => 'Étude Torah';

  @override
  String get coupleFeedIdeaDateNightTitle => 'Date night';

  @override
  String get coupleFeedIdeaDateNightCategory => 'Romance';

  @override
  String get coupleFeedIdeaSportTitle => 'Sport ensemble';

  @override
  String get coupleFeedIdeaChesedTitle => 'Hesed ensemble';

  @override
  String get coupleFeedIdeaChesedCategory => 'Communauté';

  @override
  String get coupleFeedIdeaTravelCategory => 'Aventure';

  @override
  String get coupleFeedCategoryWellness => 'Bien-être';

  @override
  String get coupleFeedCategoryGastronomy => 'Gastronomie';

  @override
  String get coupleFeedFilterGastronomy => 'Gastro';

  @override
  String get coupleFeedCategoryCulture => 'Culture';

  @override
  String get coupleFeedCategorySport => 'Sport';

  @override
  String get coupleFeedCategoryTravel => 'Voyage';

  @override
  String get coupleFeedCategorySpiritual => 'Spirituel';

  @override
  String get coupleFeedCategoryDiy => 'DIY';

  @override
  String get coupleFeedCategoryRomantic => 'Romantique';

  @override
  String get coupleFeedFilterAll => 'Tout';

  @override
  String get coupleFeedEventCategoryDinner => 'Dîner';

  @override
  String get coupleFeedEventCategoryTasting => 'Dégustation';

  @override
  String get coupleFeedEventCategoryParty => 'Soirée';

  @override
  String get coupleFeedEventCategoryWorkshop => 'Atelier';

  @override
  String get coupleFeedEventCategoryBrunch => 'Brunch';

  @override
  String get coupleFeedEventCategorySpiritual => 'Spirituel';

  @override
  String get coupleFeedEventCategoryTravel => 'Week-end';

  @override
  String get coupleFeedEventCategoryConcert => 'Concert';

  @override
  String get coupleFeedEventCategoryGame => 'Jeux';

  @override
  String get coupleFeedEventCategoryOther => 'Événement';

  @override
  String get coupleFeedPriceFree => 'Gratuit';

  @override
  String coupleFeedEventPricePerCouple(String price) {
    return '$price/couple';
  }

  @override
  String coupleFeedDurationMinutes(int minutes) {
    return '${minutes}min';
  }

  @override
  String coupleFeedDurationHours(int hours) {
    return '${hours}h';
  }

  @override
  String coupleFeedDurationHoursMinutes(int hours, int minutes) {
    return '${hours}h${minutes}min';
  }

  @override
  String coupleFeedRatingWithReviews(String rating, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$rating ($countString avis)',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedKosher => 'Casher';

  @override
  String get coupleFeedFeatured => 'À la une';

  @override
  String get coupleFeedPartnerMazl => 'Partenaire MAZL';

  @override
  String coupleFeedPartnerDiscountMazl(int percent) {
    return '-$percent % Partenaire MAZL';
  }

  @override
  String coupleFeedPartnerDiscount(int percent) {
    return '-$percent % Partenaire';
  }

  @override
  String get coupleFeedActivitiesTitle => 'Activités';

  @override
  String get coupleFeedSavedTitle => 'Activités sauvegardées';

  @override
  String get coupleFeedActivitiesEmptyTitle => 'Aucune activité pour le moment';

  @override
  String get coupleFeedActivitiesEmptyLine =>
      'De nouvelles idées arrivent bientôt.';

  @override
  String get coupleFeedRefresh => 'Actualiser';

  @override
  String get coupleFeedSeeDetail => 'Voir le détail';

  @override
  String coupleFeedActivitySavedSnack(String title) {
    return '$title sauvegardé';
  }

  @override
  String coupleFeedActivitySaveCardError(String title) {
    return 'Impossible de sauvegarder « $title ». Réessayez.';
  }

  @override
  String coupleFeedActivityPassCardError(String title) {
    return 'Impossible de passer « $title ». Réessayez.';
  }

  @override
  String get coupleFeedActivityNotFoundTitle => 'Activité introuvable';

  @override
  String get coupleFeedActivityNotFoundLine => 'Elle n\'est plus proposée.';

  @override
  String get coupleFeedActivityRemoveError =>
      'Impossible de retirer cette activité. Réessayez.';

  @override
  String get coupleFeedActivitySaveError =>
      'Impossible de sauvegarder cette activité. Réessayez.';

  @override
  String get coupleFeedActivitySavedConfirm => 'Activité sauvegardée';

  @override
  String coupleFeedCodeCopied(String code) {
    return 'Code $code copié';
  }

  @override
  String get coupleFeedRemoveFromSaved => 'Retirer des activités sauvegardées';

  @override
  String coupleFeedActivityShareText(String title) {
    return 'Idée de date pour nous : \"$title\" (via MAZL)';
  }

  @override
  String get coupleFeedPromoCodeLabel => 'Code promo MAZL';

  @override
  String get coupleFeedCopyCode => 'Copier le code';

  @override
  String get coupleFeedDescription => 'Description';

  @override
  String get coupleFeedTags => 'Tags';

  @override
  String get coupleFeedAddress => 'Adresse';

  @override
  String get coupleFeedContact => 'Contact';

  @override
  String get coupleFeedCall => 'Appeler';

  @override
  String get coupleFeedWebsite => 'Site web';

  @override
  String get coupleFeedFromPrice => 'À partir de';

  @override
  String get coupleFeedBook => 'Réserver';

  @override
  String get coupleFeedSavedRemoveTitle => 'Retirer de la liste ?';

  @override
  String coupleFeedSavedRemoveBody(String title) {
    return 'Voulez-vous retirer \"$title\" de vos activités sauvegardées ?';
  }

  @override
  String get coupleFeedSavedRemoved => 'Activité retirée';

  @override
  String coupleFeedSavedRemoveError(String title) {
    return 'Impossible de retirer « $title ». Réessayez.';
  }

  @override
  String get coupleFeedSavedEmptyTitle => 'Aucune activité sauvegardée';

  @override
  String get coupleFeedSavedEmptyLine =>
      'Glissez une carte vers le haut pour la garder.';

  @override
  String get coupleFeedSavedEmptyAction => 'Découvrir des activités';

  @override
  String get coupleFeedEventsTitle => 'Événements';

  @override
  String get coupleFeedEventsUpcoming => 'À venir';

  @override
  String coupleFeedEventsRegisteredTab(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Inscrits ($countString)';
  }

  @override
  String get coupleFeedEventsEmptyAll => 'Aucun événement disponible';

  @override
  String get coupleFeedEventsEmptyRegistered =>
      'Vous n\'êtes inscrit à aucun événement';

  @override
  String get coupleFeedEventsDiscover => 'Découvrir les événements';

  @override
  String coupleFeedEventRegisteredSnack(String title) {
    return 'Inscrits à \"$title\"';
  }

  @override
  String coupleFeedEventRegisteredSnackDetail(String title) {
    return 'Inscrits à « $title »';
  }

  @override
  String get coupleFeedEventRegisterError =>
      'Inscription impossible. Réessayez.';

  @override
  String get coupleFeedEventCancelError =>
      'Impossible d\'annuler l\'inscription. Réessayez.';

  @override
  String get coupleFeedEventCancelTitle => 'Annuler l\'inscription ?';

  @override
  String coupleFeedEventCancelBody(String title) {
    return 'Voulez-vous vraiment annuler votre inscription à \"$title\" ?';
  }

  @override
  String get coupleFeedEventCancelNo => 'Non';

  @override
  String get coupleFeedEventCancelYes => 'Oui, annuler';

  @override
  String get coupleFeedEventCancelled => 'Inscription annulée';

  @override
  String get coupleFeedEventFull => 'Complet';

  @override
  String coupleFeedEventSpots(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString places',
      one: '$countString place',
    );
    return '$_temp0';
  }

  @override
  String coupleFeedEventSpotsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString places restantes',
      one: '$countString place restante',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedEventRegister => 'S\'inscrire';

  @override
  String get coupleFeedEventCancelMine => 'Annuler mon inscription';

  @override
  String get coupleFeedEventNotFoundTitle => 'Événement introuvable';

  @override
  String get coupleFeedEventNotFoundLine => 'Il n\'est plus proposé.';

  @override
  String get coupleFeedEventFactPlace => 'Lieu';

  @override
  String get coupleFeedEventFactDressCode => 'Tenue';

  @override
  String get coupleFeedEventFactOrganizer => 'Organisé par';

  @override
  String get coupleFeedEventIncluded => 'Ce qui est inclus';

  @override
  String get coupleFeedLoadFailedTitle => 'Chargement impossible';

  @override
  String get coupleFeedStoriesEmptyTitle =>
      'Pas encore d\'histoires de couples';

  @override
  String get coupleFeedStoriesEmptyLine =>
      'Les premières histoires d\'amour MAZL seront bientôt partagées.';

  @override
  String coupleFeedStoryShareText(String name1, String name2, String excerpt) {
    return '$name1 et $name2 se sont rencontrés sur MAZL. Leur histoire : $excerpt...';
  }

  @override
  String coupleFeedStoryStatusSince(String status, String date) {
    return '$status · depuis $date';
  }

  @override
  String get coupleFeedStatusDating => 'En couple';

  @override
  String get coupleFeedStatusEngaged => 'Fiancés';

  @override
  String get coupleFeedStatusMarried => 'Mariés';

  @override
  String get coupleFeedStoryShareLine =>
      'Inspirez la communauté MAZL en partageant votre histoire.';

  @override
  String get coupleFeedStoryStatusLabel => 'Votre statut';

  @override
  String get coupleFeedStoryTextLabel => 'Votre histoire (min. 100 caractères)';

  @override
  String get coupleFeedStoryTextHint =>
      'Comment vous êtes-vous rencontrés ? Qu\'est-ce qui vous a plu chez l\'autre ?…';

  @override
  String get coupleFeedStoryPhotosLabel => 'Photos (optionnel)';

  @override
  String get coupleFeedStoryPhotosHint => 'Ajoutez des photos de couple';

  @override
  String get coupleFeedStorySubmit => 'Soumettre notre histoire';

  @override
  String get coupleFeedStoryTooShort =>
      'Votre histoire doit faire au moins 100 caractères';

  @override
  String get coupleFeedStoryThanks =>
      'Merci. Votre histoire sera publiée après validation.';

  @override
  String get coupleSpaceTabActivities => 'Activités';

  @override
  String get coupleSpaceTabCalendar => 'Calendrier';

  @override
  String get coupleSpaceTabEvents => 'Événements';

  @override
  String get coupleSpaceTabSpace => 'Notre espace';

  @override
  String get coupleSpaceTitle => 'Notre espace';

  @override
  String get coupleSpaceSettingsTooltip => 'Réglages';

  @override
  String get coupleSpaceYou => 'Vous';

  @override
  String get coupleSpacePartnerFallback => 'Votre Moitié';

  @override
  String coupleSpaceTogetherSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return 'Ensemble depuis $_temp0';
  }

  @override
  String get coupleSpaceStoryBegins => 'Votre histoire commence';

  @override
  String get coupleSpaceStatSavedActivities => 'Activités\nsauvegardées';

  @override
  String get coupleSpaceStatUpcomingEvents => 'Événements\nà venir';

  @override
  String get coupleSpaceStatMemories => 'Souvenirs\ncréés';

  @override
  String get coupleSpaceQuickActions => 'Actions rapides';

  @override
  String get coupleSpaceQuickAddMemory => 'Ajouter\nun souvenir';

  @override
  String get coupleSpaceQuickAddBucket => 'Ajouter à\nla bucket list';

  @override
  String get coupleSpaceQuickAddDate => 'Ajouter\nune date';

  @override
  String get coupleSpaceMemoriesTitle => 'Nos souvenirs';

  @override
  String get coupleSpaceMemoriesEmptyTitle => 'Aucun souvenir pour l\'instant';

  @override
  String get coupleSpaceMemoriesEmptyHint =>
      'Ajoutez vos premiers souvenirs ensemble.';

  @override
  String get coupleSpaceBucketTitle => 'Bucket list';

  @override
  String coupleSpaceBucketProgress(int done, int total) {
    return 'Bucket list · $done/$total';
  }

  @override
  String get coupleSpaceBucketEmptyTitle => 'Votre bucket list est vide';

  @override
  String get coupleSpaceBucketEmptyHint =>
      'Ajoutez des expériences à vivre ensemble.';

  @override
  String get coupleSpaceDatesTitle => 'Dates importantes';

  @override
  String get coupleSpaceSeeAll => 'Voir tout';

  @override
  String get coupleSpaceDatesEmptyTitle => 'Aucune date importante';

  @override
  String get coupleSpaceDatesEmptyHint =>
      'Ajoutez vos anniversaires, fêtes, etc.';

  @override
  String get coupleSpaceBadgesTitle => 'Nos badges';

  @override
  String get coupleSpaceBadgesEmptyTitle => 'Aucun badge pour l\'instant';

  @override
  String get coupleSpaceBadgesEmptyHint =>
      'Faites des activités ensemble pour débloquer des badges.';

  @override
  String get coupleSpaceGoalDone => 'Objectif accompli';

  @override
  String get coupleSpaceGoalFailed =>
      'Impossible de valider cet objectif. Réessayez.';

  @override
  String coupleSpaceRefreshFailed(String reason) {
    return 'Actualisation impossible. $reason';
  }

  @override
  String get coupleSpaceLoadFailedTitle => 'Chargement impossible';

  @override
  String get coupleSpaceSheetAdd => 'Ajouter';

  @override
  String get coupleSpaceAddMemoryTitle => 'Ajouter un souvenir';

  @override
  String get coupleSpaceFieldTitle => 'Titre';

  @override
  String get coupleSpaceFieldDescription => 'Description';

  @override
  String get coupleSpaceAddBucketTitle => 'Ajouter à la bucket list';

  @override
  String get coupleSpaceBucketFieldLabel => 'Que voulez-vous faire ensemble ?';

  @override
  String get coupleSpaceBucketFieldHint => 'Ex: Voir les aurores boréales';

  @override
  String get coupleSpaceAddDateTitle => 'Ajouter une date importante';

  @override
  String get coupleSpaceDateFieldHint => 'Ex: Notre anniversaire';

  @override
  String get coupleSpaceFieldDate => 'Date';

  @override
  String coupleSpaceAddFailed(String reason) {
    return 'Ajout impossible. $reason';
  }

  @override
  String get coupleSpaceSetupTitle => 'Mode couple';

  @override
  String get coupleSpaceSetupWho => 'Avec qui ?';

  @override
  String get coupleSpaceSetupSend => 'Envoyer la demande';

  @override
  String get coupleSpaceSetupNoMatches => 'Aucun match pour l\'instant.';

  @override
  String get coupleSpaceSetupMatchesError =>
      'Impossible de charger vos matchs.';

  @override
  String get coupleSpaceSetupSentTitle => 'Demande envoyée';

  @override
  String coupleSpaceSetupSentBody(String name) {
    return '$name doit accepter. Nous vous préviendrons dès sa réponse.';
  }

  @override
  String get coupleSpaceSetupSentBodyAnonymous =>
      'Cette personne doit accepter. Nous vous préviendrons dès sa réponse.';

  @override
  String get coupleSpaceSetupGotIt => 'Compris';

  @override
  String get coupleSpaceSetupCancelRequest => 'Annuler la demande';

  @override
  String get coupleSpaceMazelTovTitle => 'Mazal tov';

  @override
  String coupleSpaceMazelTovCongrats(String name) {
    return 'Félicitations à vous et à $name';
  }

  @override
  String get coupleSpaceMazelTovWelcome =>
      'MAZL vous accompagne dans cette nouvelle étape.';

  @override
  String get coupleSpaceMazelTovStart => 'Commencer notre aventure';

  @override
  String coupleSpaceRequestTitle(String name) {
    return '$name souhaite activer le mode couple avec vous';
  }

  @override
  String get coupleSpaceRequestTitleAnonymous =>
      'Cette personne souhaite activer le mode couple avec vous';

  @override
  String get coupleSpaceRequestAccept => 'Accepter';

  @override
  String get coupleSpaceRequestDecline => 'Non merci';

  @override
  String coupleSpaceFlowDeclinedNamed(String name) {
    return '$name n\'a pas donné suite à votre demande.';
  }

  @override
  String get coupleSpaceFlowDeclined => 'Votre demande n\'a pas abouti.';

  @override
  String get coupleSpaceFlowEnded => 'Le mode couple a pris fin.';

  @override
  String get coupleSpaceArchiveMessage =>
      'J\'ai trouvé l\'amour sur Mazl. Je ne suis plus disponible. Bonne chance dans votre recherche.';

  @override
  String get coupleSpaceFailNotMatched =>
      'Le mode couple ne s\'active qu\'avec un match.';

  @override
  String get coupleSpaceFailAlreadyInCouple =>
      'L\'un de vous est déjà en mode couple.';

  @override
  String get coupleSpaceFailRequestPending =>
      'Une demande est déjà en attente avec cette personne.';

  @override
  String get coupleSpaceFailRequestGone =>
      'Cette demande n\'est plus en attente.';

  @override
  String get coupleSpaceFailUnavailable =>
      'Cette personne n\'est pas disponible.';

  @override
  String get coupleSpaceFailSelf =>
      'Vous ne pouvez pas vous envoyer une demande.';

  @override
  String get coupleSpaceFailNotInCouple => 'Le mode couple n\'est pas actif.';

  @override
  String get coupleSpaceFailCannotLeave =>
      'Impossible de quitter le mode couple pour le moment.';

  @override
  String get coupleSpaceFailUnknown =>
      'Une erreur est survenue, réessayez dans un instant.';

  @override
  String get coupleSpaceFailEventFull => 'Cet événement est complet.';

  @override
  String get coupleSpaceFailServer =>
      'Le serveur n\'a pas pu répondre. Réessayez.';

  @override
  String get coupleSpaceFailUnexpected => 'Réponse inattendue du serveur.';

  @override
  String get coupleSpaceStatusSingle => 'Célibataire';

  @override
  String get coupleSpaceStatusDating => 'En train de dater';

  @override
  String get coupleSpaceStatusInRelationship => 'En couple';

  @override
  String get coupleSpaceStatusEngaged => 'Fiancé(e)';

  @override
  String get coupleSpaceStatusMarried => 'Marié(e)';

  @override
  String coupleSpaceDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '$count semaine',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois',
      one: '$count mois',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ans',
      one: '$count an',
    );
    return '$_temp0';
  }

  @override
  String get coupleSpaceAnniversaryTag => 'Joyeux anniversaire MAZL';

  @override
  String coupleSpaceAnniversaryDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours ensemble',
      one: 'jour ensemble',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceAnniversaryWith(String name) {
    return 'avec $name';
  }

  @override
  String coupleSpaceAnniversaryNext(String milestone, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return 'Prochain : $milestone dans $_temp0';
  }

  @override
  String get coupleSpaceAnniversaryHappy => 'Joyeux anniversaire';

  @override
  String coupleSpaceAnniversaryDaysWith(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return '$_temp0 avec $name';
  }

  @override
  String get coupleSpaceAnniversaryThanks => 'Merci';

  @override
  String coupleSpaceAnniversaryShare(int count, String milestone) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return 'Nous fêtons $_temp0 ensemble sur MAZL. $milestone';
  }

  @override
  String get coupleSpaceMilestonesTitle => 'Vos milestones';

  @override
  String coupleSpaceMilestoneIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return 'dans $_temp0';
  }

  @override
  String get coupleSpaceCalendarTitle => 'Calendrier';

  @override
  String get coupleSpaceCalendarShabbatIdeas => 'Idées pour ce Shabbat';

  @override
  String get coupleSpaceCalendarUpcoming => 'Prochaines fêtes';

  @override
  String get coupleSpaceCalendarPrevMonth => 'Mois précédent';

  @override
  String get coupleSpaceCalendarNextMonth => 'Mois suivant';

  @override
  String get coupleSpaceCalendarOngoing => 'En cours';

  @override
  String coupleSpaceCalendarCountdown(int count) {
    return 'J-$count';
  }

  @override
  String get coupleSpaceCalendarIdeas => 'Idées en couple';

  @override
  String coupleSpaceCalendarRangeSameMonth(
    String startDay,
    String endDay,
    String month,
  ) {
    return '$startDay – $endDay $month';
  }

  @override
  String coupleSpaceCalendarRangeOtherMonth(String start, String end) {
    return '$start – $end';
  }

  @override
  String get eventsTitle => 'Événements';

  @override
  String get eventsCalendarTooltip => 'Calendrier';

  @override
  String get eventsFilterAll => 'Tous';

  @override
  String get eventsFilterHolidays => 'Fêtes';

  @override
  String get eventsTypeShabbat => 'Shabbat';

  @override
  String get eventsTypeShabbatDinner => 'Shabbat Dinner';

  @override
  String get eventsTypeSpeedDating => 'Speed Dating';

  @override
  String get eventsTypeHoliday => 'Fête';

  @override
  String get eventsTypeLecture => 'Cours';

  @override
  String get eventsTypeSocial => 'Social';

  @override
  String get eventsTypeOther => 'Événement';

  @override
  String get eventsLoading => 'Chargement...';

  @override
  String get eventsLoadError => 'Impossible de charger les événements';

  @override
  String get eventsEmptyTitle => 'Aucun événement';

  @override
  String get eventsEmptyHint =>
      'Revenez bientôt pour découvrir\nde nouveaux événements.';

  @override
  String get eventsTomorrow => 'Demain';

  @override
  String eventsInDays(int days) {
    return 'Dans ${days}j';
  }

  @override
  String eventsDateAtTime(String date, String time) {
    return '$date à $time';
  }

  @override
  String get eventsFree => 'Gratuit';

  @override
  String eventsAttendeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants',
      one: '$count participant',
      zero: '0 participants',
    );
    return '$_temp0';
  }

  @override
  String get eventsAlmostFull => 'Presque complet';

  @override
  String get eventsFull => 'Complet';

  @override
  String get eventsNotFound => 'Événement introuvable';

  @override
  String get eventsInfoDate => 'Date';

  @override
  String get eventsInfoTime => 'Heure';

  @override
  String get eventsInfoPlace => 'Lieu';

  @override
  String get eventsInfoParticipants => 'Participants';

  @override
  String get eventsInfoPrice => 'Prix';

  @override
  String get eventsDescription => 'Description';

  @override
  String eventsCapacity(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$count / $max places',
      one: '$count / $max place',
    );
    return '$_temp0';
  }

  @override
  String eventsRegisteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inscrits',
      one: '$count inscrit',
      zero: '0 inscrits',
    );
    return '$_temp0';
  }

  @override
  String eventsPricePerPerson(String price) {
    return '$price par personne';
  }

  @override
  String get eventsRsvpConfirmedBanner =>
      'Vous êtes inscrit(e) à cet événement';

  @override
  String get eventsRsvpCancel => 'Annuler mon inscription';

  @override
  String eventsRsvpJoinPaid(String price) {
    return 'S\'inscrire - $price';
  }

  @override
  String get eventsRsvpJoinFree => 'S\'inscrire gratuitement';

  @override
  String get eventsRsvpCancelled => 'Inscription annulée';

  @override
  String get eventsRsvpDone => 'Inscription confirmée';

  @override
  String eventsShareMessage(String title) {
    return 'Rejoignez-moi à \"$title\" sur MAZL';
  }

  @override
  String get jewishCalendarShabbatTitle => 'Ce Shabbat';

  @override
  String jewishCalendarParashat(String name) {
    return 'Parashat $name';
  }

  @override
  String jewishCalendarParshaPair(String first, String second) {
    return '$first $second';
  }

  @override
  String get jewishCalendarCandleLighting => 'Allumage';

  @override
  String get jewishCalendarHavdalah => 'Havdala';

  @override
  String get jewishCalendarCategoryPreparation => 'Préparation';

  @override
  String get jewishCalendarCategorySpiritual => 'Spirituel';

  @override
  String get jewishCalendarCategoryRelaxation => 'Détente';

  @override
  String get jewishCalendarActivityShabbatDinnerTitle =>
      'Préparer le dîner ensemble';

  @override
  String get jewishCalendarActivityShabbatDinnerBody =>
      'Cuisinez la Halla et le repas de fête';

  @override
  String get jewishCalendarActivityShabbatCandlesTitle => 'Allumer les bougies';

  @override
  String get jewishCalendarActivityShabbatCandlesBody =>
      'Moment de spiritualité partagé';

  @override
  String get jewishCalendarActivityShabbatWalkTitle => 'Promenade Shabbat';

  @override
  String get jewishCalendarActivityShabbatWalkBody =>
      'Balade tranquille après le repas';

  @override
  String get jewishCalendarActivityShabbatParashaTitle => 'Étude de la Parasha';

  @override
  String get jewishCalendarActivityShabbatParashaBody =>
      'Apprenez ensemble la portion de la semaine';

  @override
  String get jewishCalendarActivityPesachSederTitle => 'Préparer le Seder';

  @override
  String get jewishCalendarActivityPesachSederBody =>
      'Organisez la table ensemble';

  @override
  String get jewishCalendarActivityPesachCleaningTitle =>
      'Faire le ménage de Pessah';

  @override
  String get jewishCalendarActivityPesachCleaningBody =>
      'Nettoyage de printemps en équipe';

  @override
  String get jewishCalendarHolidayRoshHashanaName => 'Rosh Hashana';

  @override
  String get jewishCalendarHolidayRoshHashanaDescription => 'Nouvel an juif';

  @override
  String get jewishCalendarHolidayYomKippurName => 'Yom Kippour';

  @override
  String get jewishCalendarHolidayYomKippurDescription =>
      'Jour du Grand Pardon';

  @override
  String get jewishCalendarHolidaySukkotName => 'Souccot';

  @override
  String get jewishCalendarHolidaySukkotDescription => 'Fête des cabanes';

  @override
  String get jewishCalendarHolidaySheminiAtzeretName => 'Shemini Atseret';

  @override
  String get jewishCalendarHolidaySheminiAtzeretDescription =>
      'Huitième jour de rassemblement';

  @override
  String get jewishCalendarHolidaySimchatTorahName => 'Simhat Torah';

  @override
  String get jewishCalendarHolidaySimchatTorahDescription => 'Joie de la Torah';

  @override
  String get jewishCalendarHolidayHanukkahName => 'Hanoucca';

  @override
  String get jewishCalendarHolidayHanukkahDescription => 'Fête des lumières';

  @override
  String get jewishCalendarHolidayTuBishvatName => 'Tou Bichvat';

  @override
  String get jewishCalendarHolidayTuBishvatDescription =>
      'Nouvel an des arbres';

  @override
  String get jewishCalendarHolidayPurimName => 'Pourim';

  @override
  String get jewishCalendarHolidayPurimDescription => 'Fête des sorts';

  @override
  String get jewishCalendarHolidayPesachName => 'Pessah';

  @override
  String get jewishCalendarHolidayPesachDescription => 'Fête de la liberté';

  @override
  String get jewishCalendarHolidayYomHashoahName => 'Yom HaShoah';

  @override
  String get jewishCalendarHolidayYomHashoahDescription =>
      'Jour du souvenir de la Shoah';

  @override
  String get jewishCalendarHolidayYomHazikaronName => 'Yom HaZikaron';

  @override
  String get jewishCalendarHolidayYomHazikaronDescription =>
      'Jour du souvenir des soldats';

  @override
  String get jewishCalendarHolidayYomHaatzmautName => 'Yom HaAtsmaout';

  @override
  String get jewishCalendarHolidayYomHaatzmautDescription =>
      'Jour de l\'indépendance d\'Israël';

  @override
  String get jewishCalendarHolidayYomYerushalayimName => 'Yom Yeroushalayim';

  @override
  String get jewishCalendarHolidayYomYerushalayimDescription =>
      'Jour de la réunification de Jérusalem';

  @override
  String get jewishCalendarHolidayLagBaomerName => 'Lag BaOmer';

  @override
  String get jewishCalendarHolidayLagBaomerDescription => '33eme jour du Omer';

  @override
  String get jewishCalendarHolidayShavuotName => 'Shavouot';

  @override
  String get jewishCalendarHolidayShavuotDescription => 'Don de la Torah';

  @override
  String get jewishCalendarIdeaFestiveDinner => 'Dîner festif';

  @override
  String get jewishCalendarIdeaTashlich => 'Tashlich ensemble';

  @override
  String get jewishCalendarIdeaMutualForgiveness =>
      'Se demander pardon mutuellement';

  @override
  String get jewishCalendarIdeaBuildSukkah => 'Construire la Soucca ensemble';

  @override
  String get jewishCalendarIdeaInviteFriends => 'Inviter des amis';

  @override
  String get jewishCalendarIdeaPrayerForRain => 'Prière pour la pluie';

  @override
  String get jewishCalendarIdeaDanceWithTorah => 'Danser avec la Torah';

  @override
  String get jewishCalendarIdeaLightCandlesTogether =>
      'Allumer les bougies ensemble';

  @override
  String get jewishCalendarIdeaHomemadeSufganiyot => 'Soufganiot maison';

  @override
  String get jewishCalendarIdeaCoupleCostumes => 'Déguisement en couple';

  @override
  String get jewishCalendarIdeaMishloachManot => 'Mishloach Manot ensemble';

  @override
  String get jewishCalendarIdeaRomanticSeder => 'Seder romantique';

  @override
  String get jewishCalendarIdeaTripToIsrael => 'Voyage en Israël';

  @override
  String get jewishCalendarIdeaIsraeliBarbecue => 'BBQ israélien';

  @override
  String get jewishCalendarIdeaConcertOrParty => 'Concert/soirée';

  @override
  String get jewishCalendarIdeaCampfire => 'Feu de camp';

  @override
  String get jewishCalendarIdeaPicnic => 'Pique-nique';

  @override
  String get jewishCalendarIdeaHomemadeCheesecake => 'Cheesecake maison';

  @override
  String get jewishCalendarIdeaStudyNight => 'Nuit d\'étude';

  @override
  String get jewishCalendarParshaBereshis => 'Bereshis';

  @override
  String get jewishCalendarParshaNoach => 'Noach';

  @override
  String get jewishCalendarParshaLechLecha => 'Lech Lecha';

  @override
  String get jewishCalendarParshaVayera => 'Vayera';

  @override
  String get jewishCalendarParshaChayeiSara => 'Chayei Sara';

  @override
  String get jewishCalendarParshaToldos => 'Toldos';

  @override
  String get jewishCalendarParshaVayetzei => 'Vayetzei';

  @override
  String get jewishCalendarParshaVayishlach => 'Vayishlach';

  @override
  String get jewishCalendarParshaVayeshev => 'Vayeshev';

  @override
  String get jewishCalendarParshaMiketz => 'Miketz';

  @override
  String get jewishCalendarParshaVayigash => 'Vayigash';

  @override
  String get jewishCalendarParshaVayechi => 'Vayechi';

  @override
  String get jewishCalendarParshaShemos => 'Shemos';

  @override
  String get jewishCalendarParshaVaera => 'Vaera';

  @override
  String get jewishCalendarParshaBo => 'Bo';

  @override
  String get jewishCalendarParshaBeshalach => 'Beshalach';

  @override
  String get jewishCalendarParshaYisro => 'Yisro';

  @override
  String get jewishCalendarParshaMishpatim => 'Mishpatim';

  @override
  String get jewishCalendarParshaTerumah => 'Terumah';

  @override
  String get jewishCalendarParshaTetzaveh => 'Tetzaveh';

  @override
  String get jewishCalendarParshaKiSisa => 'Ki Sisa';

  @override
  String get jewishCalendarParshaVayakhel => 'Vayakhel';

  @override
  String get jewishCalendarParshaPekudei => 'Pekudei';

  @override
  String get jewishCalendarParshaVayikra => 'Vayikra';

  @override
  String get jewishCalendarParshaTzav => 'Tzav';

  @override
  String get jewishCalendarParshaShmini => 'Shmini';

  @override
  String get jewishCalendarParshaTazria => 'Tazria';

  @override
  String get jewishCalendarParshaMetzora => 'Metzora';

  @override
  String get jewishCalendarParshaAchreiMos => 'Achrei Mos';

  @override
  String get jewishCalendarParshaKedoshim => 'Kedoshim';

  @override
  String get jewishCalendarParshaEmor => 'Emor';

  @override
  String get jewishCalendarParshaBehar => 'Behar';

  @override
  String get jewishCalendarParshaBechukosai => 'Bechukosai';

  @override
  String get jewishCalendarParshaBamidbar => 'Bamidbar';

  @override
  String get jewishCalendarParshaNasso => 'Nasso';

  @override
  String get jewishCalendarParshaBehaaloscha => 'Beha\'aloscha';

  @override
  String get jewishCalendarParshaShlach => 'Sh\'lach';

  @override
  String get jewishCalendarParshaKorach => 'Korach';

  @override
  String get jewishCalendarParshaChukas => 'Chukas';

  @override
  String get jewishCalendarParshaBalak => 'Balak';

  @override
  String get jewishCalendarParshaPinchas => 'Pinchas';

  @override
  String get jewishCalendarParshaMatos => 'Matos';

  @override
  String get jewishCalendarParshaMasei => 'Masei';

  @override
  String get jewishCalendarParshaDevarim => 'Devarim';

  @override
  String get jewishCalendarParshaVaeschanan => 'Vaeschanan';

  @override
  String get jewishCalendarParshaEikev => 'Eikev';

  @override
  String get jewishCalendarParshaReeh => 'Re\'eh';

  @override
  String get jewishCalendarParshaShoftim => 'Shoftim';

  @override
  String get jewishCalendarParshaKiSeitzei => 'Ki Seitzei';

  @override
  String get jewishCalendarParshaKiSavo => 'Ki Savo';

  @override
  String get jewishCalendarParshaNitzavim => 'Nitzavim';

  @override
  String get jewishCalendarParshaVayeilech => 'Vayeilech';

  @override
  String get jewishCalendarParshaHaazinu => 'Ha\'Azinu';

  @override
  String get jewishCalendarParshaVzosHaberacha => 'Vezos Habracha';

  @override
  String get navigationDiscover => 'Découvrir';

  @override
  String get navigationMatches => 'Matchs';

  @override
  String get navigationMessages => 'Messages';

  @override
  String get navigationEvents => 'Événements';

  @override
  String get navigationProfile => 'Profil';

  @override
  String get navigationShowTabs => 'Afficher les onglets';

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
  String get profileMatchBodyUnnamed =>
      'Vous pouvez maintenant discuter avec cette personne.';

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
  String get profileCoupleElsewhereBody =>
      'Vous êtes déjà en mode couple avec quelqu\'un d\'autre.';

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
  String get profileCoupleAvailableBody =>
      'Vous avez matché. Activez le mode couple pour partager des activités ensemble.';

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
  String get profileCompatibilityBasis =>
      'Calculée à partir de vos deux profils.';

  @override
  String get profileCompatibilityUnavailable =>
      'Compatibilité indisponible pour le moment.';

  @override
  String profileCompatibilityUnlockTitle(String name) {
    return 'Découvrez votre score de compatibilité avec $name.';
  }

  @override
  String get profileCompatibilityUnlockBody =>
      'Calculé à partir de vos pratiques, vos intentions et vos valeurs.';

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
  String get profileCompatibilityIncomplete =>
      'Complétez vos profils pour voir plus de détails';

  @override
  String get profileCompatibilityNote =>
      'Le score est basé sur vos préférences et points communs';

  @override
  String get profileCompatibilityGotIt => 'Compris';

  @override
  String get profilePromptsMine => 'Mes Prompts';

  @override
  String get profilePromptsSubtitle =>
      'Répondez à des questions pour montrer votre personnalité';

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
  String get profilePromptFamilyTradition =>
      'Une tradition familiale que j\'adore...';

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
  String get profileIntentionHint =>
      'Montrez aux autres ce que vous recherchez';

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
  String get profileIntentionMarriageDescription =>
      'Je cherche mon/ma futur(e) mari/femme';

  @override
  String get profileIntentionSeriousDescription =>
      'Je cherche une relation durable';

  @override
  String get profileIntentionOpenDescription => 'On verra où ça nous mène';

  @override
  String get profileIntentionFriendsFirstDescription =>
      'Commençons par apprendre à se connaître';

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
  String get profilePhotosHint =>
      'Maintenez appuyé pour définir comme principale';

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
  String get profileSetupBirthdateRequired =>
      'Indiquez votre date de naissance';

  @override
  String get profileSetupGenderRequired => 'Indiquez votre genre';

  @override
  String get profileBirthdate => 'Date de naissance';

  @override
  String get profileBirthdateHint => 'JJ/MM/AAAA';

  @override
  String get profileSetupAboutYouTitle => 'Parlez-nous de vous';

  @override
  String get profileSetupAboutYouSubtitle =>
      'Ces informations seront visibles sur votre profil';

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
  String get profileSetupPhotosSubtitle =>
      'Ajoutez au moins 2 photos pour continuer';

  @override
  String get profileSetupPhotosTip =>
      'Les profils avec des photos de bonne qualité reçoivent 3x plus de matchs.';

  @override
  String get profileSetupPracticeTitle => 'Votre pratique';

  @override
  String get profileSetupPracticeSubtitle =>
      'Aidez-nous à trouver quelqu\'un qui vous correspond';

  @override
  String get profileSetupLookingTitle => 'Ce que vous recherchez';

  @override
  String get profileSetupLookingSubtitle =>
      'Aidez-nous à vous montrer les bons profils';

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
  String get profileShadchanNote =>
      'Notre AI Shadchan utilisera ces préférences pour vous proposer des profils compatibles.';

  @override
  String get profileReportThisProfile => 'Signaler ce profil';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du téléphone';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSectionAccount => 'Compte';

  @override
  String get settingsEditProfile => 'Modifier le profil';

  @override
  String get settingsEmail => 'Email';

  @override
  String get settingsNotSignedIn => 'Non connecté';

  @override
  String get settingsDefaultUserName => 'Utilisateur';

  @override
  String get settingsSectionDiscovery => 'Découverte';

  @override
  String get settingsLocation => 'Localisation';

  @override
  String get settingsLocationNotSet => 'Non défini';

  @override
  String get settingsMaxDistance => 'Distance maximale';

  @override
  String settingsDistanceKm(int distance) {
    final intl.NumberFormat distanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String distanceString = distanceNumberFormat.format(distance);

    return '$distanceString km';
  }

  @override
  String get settingsAgeRange => 'Tranche d\'âge';

  @override
  String settingsAgeRangeValue(int min, int max) {
    final intl.NumberFormat minNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String minString = minNumberFormat.format(min);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$minString - $maxString ans';
  }

  @override
  String get settingsSectionJewish => 'Paramètres juifs';

  @override
  String get settingsShabbatMode => 'Mode Shabbat';

  @override
  String get settingsShabbatAutoPause => 'Pause automatique';

  @override
  String get settingsHolidayAlerts => 'Alertes fêtes';

  @override
  String get settingsHolidayAlertsHint => 'Notifications avant les fêtes';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsNotifMatches => 'Nouveaux matchs';

  @override
  String get settingsNotifMessages => 'Messages';

  @override
  String get settingsNotifSuperLikes => 'Super Likes';

  @override
  String get settingsSectionCouple => 'Mode Couple';

  @override
  String get settingsSectionSubscription => 'Abonnement';

  @override
  String get settingsRestorePurchases => 'Restaurer les achats';

  @override
  String get settingsRestoreSuccess => 'Achats restaurés avec succès.';

  @override
  String get settingsRestoreError =>
      'La restauration des achats a échoué. Réessayez.';

  @override
  String settingsSubscriptionRenewsOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'renouvellement le $dateString';
  }

  @override
  String settingsSubscriptionEndsOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'jusqu’au $dateString';
  }

  @override
  String get settingsSectionPrivacy => 'Confidentialité et sécurité';

  @override
  String get settingsBlockedUsers => 'Utilisateurs bloqués';

  @override
  String get settingsBlockedUsersHint => 'Gérer les personnes bloquées';

  @override
  String get settingsProfileVerification => 'Vérification du profil';

  @override
  String get settingsVerified => 'Vérifié';

  @override
  String get settingsNotVerified => 'Non vérifié';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsHelp => 'Aide et support';

  @override
  String get settingsTerms => 'Conditions d\'utilisation';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLogOut => 'Se déconnecter';

  @override
  String get settingsLogOutMessage => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get settingsDeleteAccount => 'Supprimer mon compte';

  @override
  String get settingsDeleteReasonPrompt =>
      'Pourquoi souhaitez-vous nous quitter ?';

  @override
  String get settingsDeleteReasonFoundSomeone => 'J\'ai trouvé quelqu\'un';

  @override
  String get settingsDeleteReasonNoLongerUsing =>
      'Je n\'utilise plus l\'application';

  @override
  String get settingsDeleteReasonBreak => 'Je souhaite faire une pause';

  @override
  String get settingsDeleteReasonTechnical => 'Problèmes techniques';

  @override
  String get settingsDeleteReasonService => 'Le service ne me convient pas';

  @override
  String get settingsDeleteReasonOther => 'Autre raison';

  @override
  String get settingsDeleteFinalTitle => 'Confirmation finale';

  @override
  String get settingsDeleteIrreversible => 'Cette action est irréversible.';

  @override
  String get settingsDeleteDataList =>
      'Toutes vos données seront supprimées :\n• Votre profil et vos photos\n• Vos matchs et conversations\n• Votre historique de likes\n• Vos paramètres';

  @override
  String get settingsDeleteKeep => 'Garder mon compte';

  @override
  String get settingsDeleteError => 'Erreur lors de la suppression';

  @override
  String get settingsCitySearchHint => 'Rechercher une ville...';

  @override
  String get settingsCitySearchHelp =>
      'Saisissez le nom de votre ville et sélectionnez une suggestion';

  @override
  String get settingsSaved => 'Paramètres sauvegardés';

  @override
  String get settingsCoupleLeave => 'Quitter le mode couple';

  @override
  String get settingsCoupleLeaveMessage =>
      'Vous pourrez le réactiver plus tard si vous le souhaitez.';

  @override
  String get settingsCoupleLeaveConfirm => 'Quitter';

  @override
  String get settingsCoupleLeft => 'Mode couple quitté';

  @override
  String get settingsCoupleLeaveError =>
      'Impossible de quitter le mode couple. Réessayez.';

  @override
  String get settingsCoupleCancelRequestError =>
      'Impossible d\'annuler la demande. Réessayez.';

  @override
  String get settingsCoupleActive => 'Mode couple actif';

  @override
  String settingsCoupleWithPartner(String name) {
    return 'Avec $name';
  }

  @override
  String get settingsCoupleWithYourPartner => 'Avec votre partenaire';

  @override
  String get settingsCoupleOpenSpace => 'Espace couple';

  @override
  String get settingsCoupleOpenCalendar => 'Calendrier';

  @override
  String get settingsCoupleSinceToday => 'Depuis aujourd\'hui';

  @override
  String settingsCoupleDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
    );
    return '$_temp0';
  }

  @override
  String get settingsCoupleRequestSent => 'Demande envoyée';

  @override
  String settingsCoupleRequestSentTo(String name) {
    return 'Demande envoyée à $name';
  }

  @override
  String get settingsCoupleWaiting => 'En attente de sa réponse';

  @override
  String get settingsCoupleCancelRequest => 'Annuler la demande';

  @override
  String get settingsCoupleInvitation => 'Vous avez trouvé l\'amour ?';

  @override
  String get settingsCoupleActivate => 'Activer';

  @override
  String get settingsShabbatCity => 'Basé sur Paris, France';

  @override
  String get settingsShabbatSettingsHeader => 'Réglages';

  @override
  String get settingsShabbatEnable => 'Activer le mode Shabbat';

  @override
  String get settingsShabbatEnableHint =>
      'Pause automatique des notifications pendant Shabbat';

  @override
  String get settingsShabbatIncludeHolidays => 'Inclure les fêtes';

  @override
  String get settingsShabbatIncludeHolidaysHint =>
      'Pause aussi pendant Yom Tov';

  @override
  String get settingsShabbatBuffer => 'Marge avant l\'allumage';

  @override
  String settingsMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String settingsMinutesSpoken(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
      zero: '0 minutes',
    );
    return '$_temp0';
  }

  @override
  String get settingsShabbatEdit => 'Modifier';

  @override
  String get settingsShabbatExplanation =>
      'Les notifications sont mises en pause et les messages attendent. Vous recevrez tout après la fin de Shabbat, et votre statut affichera « Mode Shabbat ».';

  @override
  String get settingsShabbatHeroTitle => 'Shabbat\nshalom.';

  @override
  String get settingsShabbatHeroSubtitle =>
      'Mazl se repose avec vous. Vos messages vous attendront à la havdala.';

  @override
  String get settingsShabbatCandleLighting => 'Allumage';

  @override
  String get settingsShabbatHavdalah => 'Havdala';

  @override
  String get settingsBlockedUserFallbackName => 'Utilisateur';

  @override
  String get settingsBlockedUnblockTitle => 'Débloquer cet utilisateur ?';

  @override
  String settingsBlockedUnblockMessage(String name) {
    return 'Voulez-vous débloquer $name ?\n\nCette personne pourra à nouveau voir votre profil et vous contacter.';
  }

  @override
  String get settingsBlockedUnblockMessageUnnamed =>
      'Voulez-vous débloquer cet utilisateur ?\n\nCette personne pourra à nouveau voir votre profil et vous contacter.';

  @override
  String get settingsBlockedUnblock => 'Débloquer';

  @override
  String settingsBlockedUnblocked(String name) {
    return '$name a été débloqué';
  }

  @override
  String get settingsBlockedUnblockedUnnamed => 'L\'utilisateur a été débloqué';

  @override
  String get settingsBlockedUnblockError => 'Erreur lors du déblocage';

  @override
  String get settingsBlockedEmptyTitle => 'Aucun utilisateur bloqué';

  @override
  String get settingsBlockedEmptyHint =>
      'Les personnes que vous bloquez\napparaîtront ici';

  @override
  String settingsBlockedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Bloqué le $dateString';
  }
}
