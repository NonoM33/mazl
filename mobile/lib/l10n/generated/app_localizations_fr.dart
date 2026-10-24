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
