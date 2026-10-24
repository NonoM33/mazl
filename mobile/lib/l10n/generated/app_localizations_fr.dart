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
  String get coupleFeedFailureNetwork => 'Serveur injoignable. Réessayez.';

  @override
  String get coupleFeedFailureMalformed => 'Réponse inattendue du serveur.';

  @override
  String get coupleFeedFailureNotInCouple => 'Le mode couple n\'est pas actif.';

  @override
  String get coupleFeedFailureNotFound => 'Introuvable.';

  @override
  String get coupleFeedFailureFull => 'Cet événement est complet.';

  @override
  String get coupleFeedFailureServer =>
      'Le serveur n\'a pas pu répondre. Réessayez.';

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
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du téléphone';
}
