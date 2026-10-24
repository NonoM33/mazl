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
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du téléphone';
}
