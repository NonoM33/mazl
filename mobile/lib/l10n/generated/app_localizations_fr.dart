// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get boostTitle => 'Boost';

  @override
  String get boostHeadlineActive => 'Boost actif';

  @override
  String get boostHeadlineIdle => 'Boostez votre profil';

  @override
  String get boostTagline => 'Soyez vu par 10x plus de personnes.';

  @override
  String boostMinutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min restantes',
      one: '$minutes min restante',
    );
    return '$_temp0';
  }

  @override
  String get boostDuringTitle => 'Pendant ce boost';

  @override
  String get boostViews => 'Vues';

  @override
  String get boostLikes => 'Likes';

  @override
  String get boostBenefitsTitle => 'Avantages du Boost';

  @override
  String get boostBenefitFirst => 'Apparaissez en premier dans les suggestions';

  @override
  String boostBenefitVisibility(int minutes) {
    return '10x plus de visibilité pendant $minutes min';
  }

  @override
  String get boostBenefitMatches => 'Plus de chances de matcher';

  @override
  String get boostBenefitStats => 'Stats en temps réel pendant le boost';

  @override
  String get boostActivate => 'Activer le Boost';

  @override
  String boostRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boosts restants',
      one: '$count boost restant',
    );
    return '$_temp0';
  }

  @override
  String get boostActivated =>
      'Boost activé. Votre profil est maintenant en avant.';

  @override
  String get boostActivateFailed => 'Erreur lors de l\'activation';

  @override
  String get boostUpsellTitle => 'Boosts illimités';

  @override
  String get boostUpsellBody => 'Boostez sans limite avec mazl+';

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
  String get likesTitle => 'Likes';

  @override
  String likesSection(String count) {
    return 'Ils vous ont aimé · $count';
  }

  @override
  String likesWaiting(int count, String label) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$label personnes attendent votre réponse.',
      one: '$label personne attend votre réponse.',
    );
    return '$_temp0';
  }

  @override
  String get likesSeeWhoWithPlus => 'Voir qui vous a aimé avec mazl+';

  @override
  String likesMatchWith(String name) {
    return 'Match avec $name';
  }

  @override
  String get likesMessageAction => 'Message';

  @override
  String likesYouLiked(String name) {
    return 'Vous avez liké $name';
  }

  @override
  String get likesEmptyTitle => 'Pas encore de likes';

  @override
  String get likesEmptyBody =>
      'Continuez à découvrir des profils et complétez votre profil pour attirer plus de likes.';

  @override
  String get likesEmptyAction => 'Découvrir des profils';

  @override
  String get likesPremiumBody =>
      'Découvrez qui vous a aimé et matchez tout de suite avec les personnes qui vous plaisent.';

  @override
  String get likesPremiumOffers => 'Voir les offres';

  @override
  String likesCardOpen(String title) {
    return 'Voir le like de $title';
  }

  @override
  String likesCardPass(String name) {
    return 'Passer $name';
  }

  @override
  String likesCardLike(String name) {
    return 'Aimer $name';
  }

  @override
  String get likesLockedLabel => 'Profil masqué';

  @override
  String get likesLockedHint => 'Disponible avec mazl+';

  @override
  String likesDistance(int km) {
    return '$km km';
  }

  @override
  String get matchingDiscoverDailyPicks => 'Sélections du jour';

  @override
  String get matchingFilters => 'Filtres';

  @override
  String get matchingDiscoverEmptyTitle => 'Vous avez tout vu.';

  @override
  String get matchingDiscoverEmptyBody =>
      'Revenez plus tard ou élargissez vos filtres pour voir de nouveaux profils.';

  @override
  String get matchingDiscoverOpenFilters => 'Ouvrir les filtres';

  @override
  String get matchingDiscoverRefresh => 'Actualiser';

  @override
  String get matchingDiscoverUndo => 'Annuler';

  @override
  String get matchingDiscoverSuperLike => 'Super like';

  @override
  String get matchingDiscoverBoost => 'Boost';

  @override
  String matchingDiscoverBoostOn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return 'Boost activé. Vous êtes en tête de pile pendant $_temp0.';
  }

  @override
  String get matchingDiscoverBoostFailed => 'Impossible d\'activer le boost';

  @override
  String get matchingCardPass => 'Passer';

  @override
  String get matchingCardLike => 'J\'aime';

  @override
  String get matchingCardViewProfile => 'Voir le profil';

  @override
  String get matchingCardAnonymous => 'Anonyme';

  @override
  String matchingCardDistance(int km) {
    return 'à $km km';
  }

  @override
  String get matchingCardVerified => 'Vérifiée';

  @override
  String matchingAvatarNewMatch(String name) {
    return 'Nouveau match, $name';
  }

  @override
  String matchingAvatarMatch(String name) {
    return 'Match, $name';
  }

  @override
  String get matchingMatchTitle => 'C\'est un match';

  @override
  String matchingMatchLineNamed(String name) {
    return '$name et vous vous êtes plu.';
  }

  @override
  String get matchingMatchLineAnonymous => 'Vous vous êtes plu.';

  @override
  String get matchingMatchSendMessage => 'Envoyer un message';

  @override
  String get matchingMatchKeepDiscovering => 'Continuer à découvrir';

  @override
  String matchingSeeMoreWithPlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voir les $count autres avec mazl+',
      one: 'Voir $count autre avec mazl+',
    );
    return '$_temp0';
  }

  @override
  String get matchingMatchesTitle => 'Matchs';

  @override
  String get matchingMatchesWhoLikedYou => 'Qui vous a aimé';

  @override
  String matchingMatchesNewSection(int count) {
    return 'Nouveaux · $count';
  }

  @override
  String matchingMatchesConversationsSection(int count) {
    return 'Conversations · $count';
  }

  @override
  String get matchingMatchesLoadFailed => 'Impossible de charger les matchs';

  @override
  String get matchingMatchesEmptyTitle => 'Pas encore de match';

  @override
  String get matchingMatchesEmptyBody => 'Continuez à découvrir des profils.';

  @override
  String get matchingMatchesUnknownName => 'Inconnu';

  @override
  String get matchingMatchesWriteHint => 'Écrivez-lui';

  @override
  String matchingMatchesViewProfileOf(String name) {
    return 'Voir le profil de $name';
  }

  @override
  String matchingMatchesSeeMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voir les $count autres',
      one: 'Voir $count autre',
    );
    return '$_temp0';
  }

  @override
  String matchingMatchedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count jours',
      one: 'Il y a $count jour',
    );
    return '$_temp0';
  }

  @override
  String matchingMatchedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count semaines',
      one: 'Il y a $count semaine',
    );
    return '$_temp0';
  }

  @override
  String matchingMatchedMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count mois',
      one: 'Il y a $count mois',
    );
    return '$_temp0';
  }

  @override
  String get matchingCouplePromoTitle => 'Ça y est, vous avez matché ?';

  @override
  String get matchingCouplePromoDismiss => 'Masquer';

  @override
  String get matchingCouplePromoBody =>
      'Questions quotidiennes, étapes, calendrier juif partagé : construisez votre relation avec mazl.';

  @override
  String get matchingCouplePromoAction => 'Activer le mode couple';

  @override
  String get matchingPicksSeenAll => 'Vous avez vu toutes vos sélections.';

  @override
  String matchingPicksNextIn(int hours, int minutes) {
    return 'Prochaines sélections dans ${hours}h ${minutes}m';
  }

  @override
  String matchingPicksUpdatedIn(int hours, int minutes) {
    return 'Mis à jour dans ${hours}h ${minutes}m';
  }

  @override
  String matchingPicksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profils sélectionnés pour vous',
      one: '$count profil sélectionné pour vous',
    );
    return '$_temp0';
  }

  @override
  String get matchingPicksDiscoverMore => 'Découvrir plus de profils';

  @override
  String get matchingPicksBadge => 'Pick';

  @override
  String matchingPicksMatchBody(String name) {
    return 'Vous avez matché avec $name.';
  }

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

  @override
  String get shadchanTitle => 'AI Shadchan';

  @override
  String get shadchanHeaderTitle => 'Votre Shadchan personnel';

  @override
  String get shadchanHeaderBody =>
      'Notre IA analyse vos préférences pour vous proposer des profils ultra-compatibles';

  @override
  String get shadchanTodayTitle => 'Suggestions du jour';

  @override
  String shadchanNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles',
      one: '$count nouvelle',
    );
    return '$_temp0';
  }

  @override
  String get shadchanEmptyTitle => 'Vous avez parcouru toutes vos suggestions.';

  @override
  String get shadchanEmptyBody =>
      'Revenez demain pour de nouvelles propositions de votre Shadchan.';

  @override
  String get shadchanEmptyAction => 'Découvrir plus de profils';

  @override
  String shadchanPassed(String name) {
    return '$name ignorée';
  }

  @override
  String shadchanLiked(String name) {
    return '$name ajoutée à vos likes';
  }

  @override
  String get shadchanHowTitle => 'Comment ça marche ?';

  @override
  String get shadchanHowStepAnalyze =>
      'Notre IA analyse votre profil et vos préférences';

  @override
  String get shadchanHowStepCompare =>
      'Elle compare avec les profils compatibles';

  @override
  String get shadchanHowStepDaily =>
      'Vous recevez des suggestions personnalisées chaque jour';

  @override
  String get shadchanWhy => 'Pourquoi cette suggestion ?';

  @override
  String get shadchanMatchBadge => 'Match';

  @override
  String get shadchanReasonSamePractice => 'Même niveau de pratique';

  @override
  String get shadchanReasonInterests => 'Intérêts communs : voyages, cuisine';

  @override
  String get shadchanReasonGoals => 'Objectifs similaires';

  @override
  String get shadchanReasonFamily => 'Valeurs familiales alignées';

  @override
  String get shadchanReasonMusic => 'Passion commune pour la musique';

  @override
  String get shadchanReasonLocation => 'Zones de vie compatibles';

  @override
  String get shadchanReasonReligion => 'Pratique religieuse similaire';

  @override
  String get shadchanReasonProfession => 'Secteur professionnel proche';

  @override
  String get shadchanReasonCouple => 'Même vision du couple';

  @override
  String get visitorsTitle => 'Qui a visité mon profil';

  @override
  String visitorsTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visites',
      one: '$count visite',
    );
    return '$_temp0';
  }

  @override
  String visitorsThisWeek(int count) {
    return '$count cette semaine';
  }

  @override
  String get visitorsBannerTitle => 'Découvrez qui vous a visité';

  @override
  String get visitorsBannerBody => 'Passez à mazl+ pour voir les profils';

  @override
  String get visitorsEmptyTitle => 'Pas encore de visiteurs';

  @override
  String get visitorsEmptyBody =>
      'Complétez votre profil et utilisez un Boost pour attirer plus de visiteurs.';

  @override
  String get visitorsEmptyAction => 'Activer un Boost';

  @override
  String get visitorsLockedTitle => 'Réservé à mazl+';

  @override
  String get visitorsLockedBody =>
      'Passez à mazl+ pour découvrir qui a visité votre profil et les contacter directement.';

  @override
  String get visitorsLockedAction => 'Découvrir mazl+';

  @override
  String get visitorsNew => 'NEW';

  @override
  String visitorsAgoMinutes(int count) {
    return 'Il y a $count min';
  }

  @override
  String visitorsAgoHours(int count) {
    return 'Il y a ${count}h';
  }

  @override
  String visitorsAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count jours',
      one: 'Il y a $count jour',
    );
    return '$_temp0';
  }

  @override
  String visitorsAgoWeeks(int count) {
    return 'Il y a $count sem.';
  }
}
