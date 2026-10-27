// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get authLoginEyebrow => 'Rencontres · Communauté juive';

  @override
  String get authLoginTagline =>
      'Des rencontres sérieuses, entre personnes qui partagent vos valeurs.';

  @override
  String get authLoginApple => 'Continuer avec Apple';

  @override
  String get authLoginGoogle => 'Continuer avec Google';

  @override
  String get authLoginDev => 'Connexion fictive (dev)';

  @override
  String authLegal(String terms, String privacy) {
    return 'En continuant, vous acceptez les $terms et la $privacy.';
  }

  @override
  String get authLegalTermsLink => 'Conditions';

  @override
  String get authLegalPrivacyLink => 'Confidentialité';

  @override
  String get authErrorGeneric => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get authErrorCancelled => 'Connexion annulée.';

  @override
  String get authErrorUnsupported =>
      'Cette méthode de connexion n\'est pas disponible sur cet appareil.';

  @override
  String authErrorAccountDisabled(String contact) {
    return 'Votre compte est désactivé. Écrivez-nous à $contact.';
  }

  @override
  String get authRouteErrorTitle => 'Page introuvable';

  @override
  String get authRouteErrorBody => 'Une erreur est survenue';

  @override
  String get authRouteErrorHome => 'Retour à l\'accueil';

  @override
  String get authLoginReviewLink => 'Connexion par identifiant';

  @override
  String get authReviewTitle => 'Connexion par identifiant';

  @override
  String get authReviewIntro =>
      'Saisissez l\'identifiant et le mot de passe qui vous ont été remis.';

  @override
  String get authReviewUsernameLabel => 'Identifiant';

  @override
  String get authReviewPasswordLabel => 'Mot de passe';

  @override
  String get authReviewShowPassword => 'Afficher le mot de passe';

  @override
  String get authReviewHidePassword => 'Masquer le mot de passe';

  @override
  String get authReviewSubmit => 'Se connecter';

  @override
  String get authErrorInvalidCredentials =>
      'Identifiant ou mot de passe incorrect.';

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
  String get chatListTitle => 'Messages';

  @override
  String get chatListSearchHint => 'Rechercher';

  @override
  String get chatListLoadErrorTitle => 'Impossible de charger';

  @override
  String get chatListLoadErrorBody =>
      'Vérifiez votre connexion, puis réessayez.';

  @override
  String get chatListEmptyTitle => 'Pas encore de conversations';

  @override
  String get chatListEmptyBody =>
      'Vos échanges apparaîtront ici dès votre premier match.';

  @override
  String get chatListEmptyAction => 'Découvrir';

  @override
  String chatListNoResults(String query) {
    return 'Aucun résultat pour « $query ».';
  }

  @override
  String get chatListUnknownMember => 'Utilisateur';

  @override
  String get chatNewMatch => 'Nouveau match';

  @override
  String chatListUnreadLabel(String name) {
    return '$name, message non lu';
  }

  @override
  String get chatPhotoLabel => 'Photo';

  @override
  String get chatVoiceLabel => 'Message vocal';

  @override
  String get chatRemovedLabel => 'Message retiré';

  @override
  String get chatOtherFallbackName => 'Votre correspondant';

  @override
  String get chatAuthorYou => 'Vous';

  @override
  String get chatHeaderLoading => 'Chargement…';

  @override
  String get chatHeaderTyping => 'écrit…';

  @override
  String get chatHeaderOptions => 'Options';

  @override
  String get chatOptionsViewProfile => 'Voir le profil';

  @override
  String get chatOptionsMute => 'Couper les notifications';

  @override
  String get chatOptionsBlock => 'Bloquer';

  @override
  String get chatMutedConfirmation =>
      'Notifications coupées pour cette conversation';

  @override
  String get chatBlockFallbackName => 'Cet utilisateur';

  @override
  String get chatLoading => 'Chargement de la conversation';

  @override
  String get chatEmptyTitle => 'Dites bonjour.';

  @override
  String get chatEmptyBody =>
      'Envoyez le premier message pour briser la glace.';

  @override
  String chatMatchStart(String date) {
    return 'Match · $date';
  }

  @override
  String chatNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux messages',
      one: '1 nouveau message',
    );
    return '$_temp0';
  }

  @override
  String get chatTypingSemantics => 'Votre correspondant écrit';

  @override
  String chatSeenAt(String time) {
    return 'Vu à $time';
  }

  @override
  String get chatFailedRetry => 'Échec · Réessayer';

  @override
  String get chatMenuReply => 'Répondre';

  @override
  String get chatMenuCopy => 'Copier';

  @override
  String get chatMenuUnsend => 'Retirer';

  @override
  String get chatMenuClose => 'Fermer le menu';

  @override
  String get chatCopied => 'Message copié';

  @override
  String get chatReportThanks => 'Merci, nous examinons ce message.';

  @override
  String get chatReactionsTitle => 'Réactions';

  @override
  String get chatReportTitle => 'Signaler ce message';

  @override
  String get chatReportReasonScam => 'Arnaque ou demande d\'argent';

  @override
  String get chatReportReasonHarassment => 'Harcèlement ou propos déplacés';

  @override
  String get chatReportReasonInappropriate => 'Contenu inapproprié';

  @override
  String get chatReportReasonOther => 'Autre';

  @override
  String get chatScamAdviceTitle => 'Se protéger des arnaques';

  @override
  String get chatScamAdviceMoney =>
      'N\'envoyez jamais d\'argent, de carte cadeau ou de cryptomonnaie.';

  @override
  String get chatScamAdviceApps =>
      'Méfiez-vous de qui vous demande de poursuivre sur WhatsApp, Telegram ou Signal très vite.';

  @override
  String get chatScamAdviceVideo =>
      'Faites un appel vidéo avant de vous engager.';

  @override
  String get chatScamAdviceReport =>
      'En cas de doute, signalez la conversation : nous l\'examinons.';

  @override
  String get chatScamTitle => 'Restez prudent';

  @override
  String get chatScamBody =>
      'Ne transférez jamais d\'argent à quelqu\'un que vous n\'avez pas rencontré.';

  @override
  String get chatScamLearnMore => 'En savoir plus';

  @override
  String get chatPhotoReveal => 'Voir la photo';

  @override
  String get chatVoicePlayFailed => 'Lecture impossible';

  @override
  String get chatVoicePlay => 'Lire le message vocal';

  @override
  String get chatVoicePause => 'Mettre en pause';

  @override
  String get chatComposerHint => 'Message';

  @override
  String get chatComposerAttach => 'Joindre des photos';

  @override
  String get chatComposerSend => 'Envoyer';

  @override
  String get chatComposerSendVoice => 'Envoyer le vocal';

  @override
  String get chatComposerPhotoError =>
      'Impossible d\'ajouter la photo. Vérifiez les autorisations.';

  @override
  String get chatComposerMicDenied =>
      'Autorisez le micro dans les réglages pour envoyer un vocal.';

  @override
  String get chatComposerRecordError =>
      'Impossible d\'enregistrer pour le moment. Réessayez.';

  @override
  String get chatComposerHoldLonger =>
      'Maintenez le micro plus longtemps pour enregistrer.';

  @override
  String get chatComposerHoldHint =>
      'Maintenez le micro pour enregistrer un vocal.';

  @override
  String get chatMicSemantics => 'Maintenir pour enregistrer un vocal';

  @override
  String get chatAttachPhotos => 'Photos';

  @override
  String get chatAttachPhotosLimit => 'Jusqu\'à 10 à la fois';

  @override
  String get chatAttachCamera => 'Appareil photo';

  @override
  String get chatRecordingCancel => 'Annuler l\'enregistrement';

  @override
  String get chatRecordingRelease => 'Relâchez pour annuler';

  @override
  String get chatRecordingSlide => '‹ Glisser pour annuler';

  @override
  String get chatReplyCancel => 'Annuler la réponse';

  @override
  String chatReplyToOther(String name) {
    return 'Réponse à $name';
  }

  @override
  String get chatReplyToMine => 'Réponse à votre message';

  @override
  String get chatErrorSessionExpired => 'Session expirée, reconnectez-vous.';

  @override
  String get chatErrorCannotUnsend => 'Ce message ne peut plus être retiré.';

  @override
  String get chatErrorConversationGone =>
      'Cette conversation n’est plus disponible.';

  @override
  String get chatErrorBlocked =>
      'Vous ne pouvez plus écrire dans cette conversation.';

  @override
  String get chatErrorTooLarge => 'Fichier trop volumineux.';

  @override
  String get chatErrorRateLimited => 'Trop d’envois, patientez un instant.';

  @override
  String get chatErrorServer => 'Le serveur est indisponible, réessayez.';

  @override
  String get chatErrorFileRejected => 'Fichier refusé, essayez-en un autre.';

  @override
  String get chatErrorMessageRejected => 'Message refusé.';

  @override
  String get chatErrorTimeout => 'Délai dépassé, vérifiez votre connexion.';

  @override
  String get chatErrorNetwork => 'Pas de connexion internet.';

  @override
  String get chatErrorUnknown => 'Une erreur est survenue.';

  @override
  String get chatErrorTooManyPhotos => 'Dix photos au maximum par message.';

  @override
  String get chatErrorNotYetSent => 'Ce message n’est pas encore envoyé.';

  @override
  String get chatErrorMessageGone => 'Ce message n’existe plus.';

  @override
  String get chatErrorNotAuthor => 'Seul l’auteur peut retirer un message.';

  @override
  String get chatErrorReactionUnavailable => 'Réaction indisponible.';

  @override
  String get chatErrorSendUnavailable => 'Impossible d’envoyer pour le moment.';

  @override
  String get chatErrorLoadFailed => 'Impossible de charger la conversation.';

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
  String linkOpenError(String target) {
    return 'Impossible d\'ouvrir $target pour le moment.';
  }

  @override
  String get coupleAgendaTitle => 'Agenda à deux';

  @override
  String get coupleAgendaLegendDate => 'Date importante';

  @override
  String get coupleAgendaLegendHoliday => 'Fête';

  @override
  String get coupleAgendaLegendRitual => 'Rituel';

  @override
  String get coupleAgendaAddMoment => 'Ajouter un moment';

  @override
  String get coupleAgendaNothing => 'Rien ce jour-là';

  @override
  String get coupleAgendaRitualsLabel => 'Vos rituels';

  @override
  String get coupleAgendaDatesLabel => 'Dates importantes';

  @override
  String get coupleAgendaRitualsEmptyTitle => 'Pas encore de rituel';

  @override
  String get coupleAgendaRitualsEmptyLine =>
      'Un rendez-vous régulier à deux, comme Shabbat ou une soirée sans écran.';

  @override
  String get coupleAgendaAddRitual => 'Ajouter un rituel';

  @override
  String coupleAgendaRitualsFailed(String reason) {
    return 'Rituels indisponibles. $reason';
  }

  @override
  String coupleAgendaDatesFailed(String reason) {
    return 'Dates indisponibles. $reason';
  }

  @override
  String coupleAgendaWeekly(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'sun': 'Chaque dimanche',
      'mon': 'Chaque lundi',
      'tue': 'Chaque mardi',
      'wed': 'Chaque mercredi',
      'thu': 'Chaque jeudi',
      'fri': 'Chaque vendredi',
      'sat': 'Chaque samedi',
      'other': 'Chaque semaine',
    });
    return '$_temp0';
  }

  @override
  String get coupleAgendaNoDay => 'Sans jour fixe';

  @override
  String coupleAgendaAtTime(String when, String time) {
    return '$when à $time';
  }

  @override
  String coupleAgendaRemindHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: 'une heure',
    );
    return 'rappel $_temp0 avant';
  }

  @override
  String coupleAgendaRemindMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return 'rappel $_temp0 avant';
  }

  @override
  String coupleAgendaRemindHoursCandles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: 'une heure',
    );
    return 'rappel $_temp0 avant les bougies';
  }

  @override
  String coupleAgendaRemindMinutesCandles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return 'rappel $_temp0 avant les bougies';
  }

  @override
  String get coupleAgendaNoReminder => 'sans rappel';

  @override
  String coupleAgendaRitualMeta(String when, String reminder) {
    return '$when · $reminder';
  }

  @override
  String coupleAgendaRitualSemantics(String title, String meta) {
    return '$title, $meta';
  }

  @override
  String coupleAgendaToggleFailed(String reason) {
    return 'Modification impossible. $reason';
  }

  @override
  String get coupleAgendaRemindersPremium =>
      'Les rappels font partie de MAZL Couple';

  @override
  String get coupleAgendaDatesEmptyTitle => 'Aucune date importante';

  @override
  String get coupleAgendaDatesEmptyLine =>
      'Ajoutez un anniversaire ou une date qui compte avec « Ajouter un moment ».';

  @override
  String coupleAgendaDateWhen(String date, String relative) {
    return '$date · $relative';
  }

  @override
  String coupleAgendaDaysUntil(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count jours',
      one: 'demain',
      zero: 'aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String coupleAgendaDateReminder(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return 'Rappel $_temp0 avant';
  }

  @override
  String coupleAgendaDateTitle(String title, String date) {
    return '$title · $date';
  }

  @override
  String get coupleAgendaConciergeLine =>
      'La conciergerie peut vous aider à préparer ce moment.';

  @override
  String get coupleAgendaPrepare => 'Préparer avec la conciergerie';

  @override
  String get coupleAgendaAddRitualTitle => 'Nouveau rituel';

  @override
  String get coupleAgendaRitualFieldTitle => 'Nom du rituel';

  @override
  String get coupleAgendaRitualFieldDay => 'Jour de la semaine';

  @override
  String get coupleAgendaRitualFieldTime => 'Heure (facultatif)';

  @override
  String get coupleAgendaRitualPickTime => 'Choisir une heure';

  @override
  String get coupleAgendaRitualClearTime => 'Retirer l\'heure';

  @override
  String coupleAgendaDaySemantics(String date, String marks) {
    return '$date, $marks';
  }

  @override
  String get coupleCheckinTitle => 'Bilan du couple';

  @override
  String coupleCheckinEyebrow(String month) {
    return 'Bilan · $month';
  }

  @override
  String get coupleCheckinHeading => 'Comment ça va entre vous ?';

  @override
  String get coupleCheckinIntro =>
      'Deux minutes, chacun de son côté. Vos réponses restent entre vous deux.';

  @override
  String get coupleCheckinTalk => 'On se parle vraiment';

  @override
  String get coupleCheckinTime => 'On passe assez de temps à deux';

  @override
  String get coupleCheckinClose => 'On se sent proches';

  @override
  String get coupleCheckinScaleLow => 'Pas du tout';

  @override
  String get coupleCheckinScaleHigh => 'Tout à fait';

  @override
  String coupleCheckinScoreLabel(String question, int n) {
    return '$question : $n sur 5';
  }

  @override
  String get coupleCheckinSend => 'Envoyer';

  @override
  String get coupleCheckinSendFailed =>
      'Votre bilan n\'est pas parti. Vos notes sont gardées, vous pouvez réessayer.';

  @override
  String get coupleCheckinEmptyTitle => 'Le bilan arrive bientôt';

  @override
  String get coupleCheckinEmptyLine =>
      'Une fois par mois, deux minutes pour prendre des nouvelles de votre couple.';

  @override
  String get coupleCheckinDoneHeading => 'Merci, c\'est envoyé';

  @override
  String coupleCheckinWaiting(String name) {
    return 'En attente de $name : vous verrez la synthèse ensemble.';
  }

  @override
  String coupleCheckinAligned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '$count point',
    );
    return 'En phase sur $_temp0 sur 3';
  }

  @override
  String get coupleCheckinAttentionTalkUp =>
      'Vous vous parlez davantage. Gardez ce rythme, même cinq minutes par jour.';

  @override
  String get coupleCheckinAttentionTalkDown =>
      'Les échanges ont baissé. Un moment sans téléphone pour vous parler, cette semaine ?';

  @override
  String get coupleCheckinAttentionTalkSame =>
      'Se parler vraiment reste le point à soigner. Posez-vous ensemble la question du jour.';

  @override
  String get coupleCheckinAttentionTalkNone =>
      'Se parler vraiment est le point à soigner ce mois-ci. Commencez par la question du jour.';

  @override
  String get coupleCheckinAttentionTimeUp =>
      'Vous passez plus de temps à deux. Prévoyez dès maintenant la prochaine sortie.';

  @override
  String get coupleCheckinAttentionTimeDown =>
      'Le temps à deux a baissé. Une soirée sans écran cette semaine ?';

  @override
  String get coupleCheckinAttentionTimeSame =>
      'Le temps à deux reste à renforcer. Bloquez une soirée dans l\'agenda.';

  @override
  String get coupleCheckinAttentionTimeNone =>
      'Le temps à deux est le point à soigner. Bloquez une soirée dans l\'agenda.';

  @override
  String get coupleCheckinAttentionCloseUp =>
      'Vous vous sentez plus proches. Dites-vous ce qui a changé.';

  @override
  String get coupleCheckinAttentionCloseDown =>
      'Vous vous sentez moins proches. Prenez un moment pour vous dire ce qui compte pour vous.';

  @override
  String get coupleCheckinAttentionCloseSame =>
      'La proximité reste à cultiver. Un petit geste attentionné aujourd\'hui ?';

  @override
  String get coupleCheckinAttentionCloseNone =>
      'La proximité est le point à cultiver. Un petit geste attentionné aujourd\'hui ?';

  @override
  String get coupleConciergeEyebrow => 'Inclus dans MAZL Couple';

  @override
  String get coupleConciergeTitle => 'Votre conciergerie';

  @override
  String get coupleConciergeIntro =>
      'Demandez, on s\'occupe du reste. L\'assistant prépare des idées tout de suite, l\'équipe MAZL réserve et confirme.';

  @override
  String get coupleConciergeQuickTable => 'Réserver une table';

  @override
  String get coupleConciergeQuickSurprise => 'Organiser une surprise';

  @override
  String get coupleConciergeQuickGift => 'Trouver un cadeau';

  @override
  String get coupleConciergeQuickWeekend => 'Planifier un week-end';

  @override
  String get coupleConciergeStartTable =>
      'Je voudrais réserver une table pour deux';

  @override
  String get coupleConciergeStartSurprise =>
      'Je voudrais organiser une surprise pour';

  @override
  String get coupleConciergeStartGift => 'Je cherche un cadeau pour';

  @override
  String get coupleConciergeStartWeekend =>
      'Je voudrais planifier un week-end à';

  @override
  String get coupleConciergeInProgress => 'En cours';

  @override
  String get coupleConciergeClosedSection => 'Terminées';

  @override
  String get coupleConciergeStatusClosed => 'Terminée';

  @override
  String get coupleConciergeStatusCancelled => 'Annulée';

  @override
  String get coupleConciergeNoRequests =>
      'Aucune demande pour l\'instant. Écrivez-nous ce que vous imaginez.';

  @override
  String coupleConciergeBefore(String day) {
    return 'Avant $day';
  }

  @override
  String coupleConciergeOnDate(String date) {
    return 'Pour le $date';
  }

  @override
  String get coupleConciergeStep1 => 'Demande reçue';

  @override
  String get coupleConciergeStep2 => 'Idée choisie';

  @override
  String get coupleConciergeStep3 => 'Réservé par l\'équipe';

  @override
  String coupleConciergeStepSemantics(int step, String label) {
    return 'étape $step sur 3 : $label';
  }

  @override
  String get coupleConciergePrivacy =>
      'Vos demandes sont lues par un assistant automatique puis par l\'équipe MAZL.';

  @override
  String get coupleConciergeComposerHint => 'Demandez à la conciergerie…';

  @override
  String get coupleConciergeSend => 'Envoyer';

  @override
  String get coupleConciergeWaiting => 'L\'assistant prépare une réponse';

  @override
  String get coupleConciergeRoleAssistant => 'Assistant';

  @override
  String get coupleConciergeRoleTeam => 'Équipe MAZL';

  @override
  String get coupleConciergePartnerFallback => 'Votre partenaire';

  @override
  String get coupleConciergeThreadEyebrow => 'Votre demande';

  @override
  String get coupleConciergeNewEyebrow => 'Nouvelle demande';

  @override
  String get coupleConciergeNewLine =>
      'Dites-nous ce que vous imaginez, ou choisissez une demande rapide.';

  @override
  String get coupleConciergeOptionsLabel => 'Idées proposées';

  @override
  String get coupleConciergeChosen => 'Choisie';

  @override
  String get coupleConciergeBook => 'Oui, réservez';

  @override
  String get coupleConciergeOtherIdea => 'Autre idée';

  @override
  String get coupleConciergeOtherIdeaMessage =>
      'Pouvez-vous me proposer une autre idée ?';

  @override
  String get coupleConciergeCancel => 'Annuler la demande';

  @override
  String get coupleConciergeCancelTitle => 'Annuler cette demande ?';

  @override
  String get coupleConciergeCancelBody =>
      'L\'équipe MAZL ne s\'en occupera plus.';

  @override
  String get coupleConciergeCancelConfirm => 'Oui, annuler';

  @override
  String get coupleConciergeKeep => 'Garder la demande';

  @override
  String get coupleConciergeNoteClosed => 'Cette demande est terminée.';

  @override
  String get coupleConciergeNoteCancelled => 'Cette demande est annulée.';

  @override
  String get coupleConciergeNoteFresh =>
      'L\'équipe MAZL a reçu votre demande et vous répond ici.';

  @override
  String get coupleConciergeNoteChosen =>
      'L\'équipe MAZL réserve votre idée et vous confirme ici.';

  @override
  String get coupleConciergeNoteBooked =>
      'C\'est réservé : les détails sont dans la conversation.';

  @override
  String get coupleConciergeDiscover => 'Découvrir MAZL Couple';

  @override
  String get coupleConciergePaywallLine =>
      'Un service qui s\'occupe de tout, pour vous deux. L\'assistant prépare des idées, l\'équipe MAZL réserve et confirme.';

  @override
  String get coupleTabToday => 'Aujourd\'hui';

  @override
  String get coupleTabAgenda => 'Agenda';

  @override
  String get coupleTabOutings => 'Sorties';

  @override
  String get coupleTabConcierge => 'Conciergerie';

  @override
  String get coupleTabUs => 'Nous deux';

  @override
  String get coupleFailSubscriptionRequired =>
      'Cette fonction fait partie de MAZL Couple.';

  @override
  String get coupleFailRateLimited =>
      'Vous avez atteint la limite de messages du jour avec l\'assistant. Revenez demain.';

  @override
  String get coupleFailAlreadyDone => 'Vous avez déjà répondu ce mois-ci.';

  @override
  String get coupleFailRouteMissing =>
      'Cette fonction n\'est pas encore disponible.';

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
  String get coupleOutingsEyebrow => 'Près de chez vous';

  @override
  String coupleOutingsEyebrowCity(String city) {
    return 'Près de chez vous · $city';
  }

  @override
  String get coupleOutingsTitle => 'Sorties à deux';

  @override
  String get coupleOutingsSavedTooltip => 'Sauvegardées';

  @override
  String get coupleOutingsFilterTonight => 'Ce soir';

  @override
  String get coupleOutingsFilterWeek => 'Ce week-end';

  @override
  String get coupleOutingsFilterKosher => 'Casher';

  @override
  String get coupleOutingsFilterCheap => 'Moins de 50 €';

  @override
  String get coupleOutingsFilterMazl => 'Événements MAZL';

  @override
  String get coupleOutingsEventBadge => 'Événement MAZL couples';

  @override
  String get coupleOutingsBookForUs => 'Réserver pour nous deux';

  @override
  String get coupleOutingsView => 'Voir';

  @override
  String get coupleOutingsSave => 'Sauvegarder';

  @override
  String get coupleOutingsUnsave => 'Retirer des sauvegardes';

  @override
  String coupleOutingsPerCouple(String price) {
    return '$price par couple';
  }

  @override
  String get coupleOutingsFree => 'Gratuit';

  @override
  String get coupleOutingsMetaSeparator => ' · ';

  @override
  String get coupleOutingsPicksLabel => 'Sélection pour vous deux';

  @override
  String get coupleOutingsNote =>
      'Les idées tiennent compte de votre cacherout, de vos goûts sauvegardés et de vos dates à venir.';

  @override
  String get coupleOutingsEmptyFilterTitle => 'Rien pour ce filtre';

  @override
  String get coupleOutingsEmptyFilterLine =>
      'Essayez un autre filtre ou regardez toutes les sorties.';

  @override
  String get coupleOutingsShowAll => 'Tout voir';

  @override
  String get coupleOutingsEmptyTitle => 'Pas de sortie pour le moment';

  @override
  String get coupleOutingsEmptyLine => 'De nouvelles idées arrivent bientôt.';

  @override
  String get coupleOutingsSaveFailed =>
      'Impossible de modifier vos sauvegardes. Réessayez.';

  @override
  String get couplePremiumWordmarkSuffix => 'couple';

  @override
  String get couplePremiumHeadline => 'Le plus dur, c\'est de le garder.';

  @override
  String get couplePremiumIntro =>
      'Vous vous êtes trouvés. MAZL Couple vous aide au quotidien : vos rituels, vos sorties, et une conciergerie qui s\'occupe du reste.';

  @override
  String get couplePremiumPerkConciergeTitle => 'Conciergerie';

  @override
  String get couplePremiumPerkConciergeMeta =>
      'Réservations, surprises, cadeaux : demandez, on s\'en occupe';

  @override
  String get couplePremiumPerkRitualsTitle => 'Vos rituels et vos dates';

  @override
  String get couplePremiumPerkRitualsMeta =>
      'Shabbat, anniversaires, fêtes : rappelés à temps, à deux';

  @override
  String get couplePremiumPerkOutingsTitle => 'Sorties choisies pour vous';

  @override
  String get couplePremiumPerkOutingsMeta =>
      'Casher, près de chez vous, et les événements MAZL couples';

  @override
  String get couplePremiumPerkQuestionTitle => 'La question du jour';

  @override
  String get couplePremiumPerkQuestionMeta =>
      'Une question par jour pour continuer à se découvrir';

  @override
  String get couplePremiumPerkCheckinTitle => 'Le bilan du couple';

  @override
  String get couplePremiumPerkCheckinMeta =>
      'Comment ça va entre vous, et des conseillers si besoin';

  @override
  String get couplePremiumFor => 'Pour vous deux';

  @override
  String get couplePremiumPerMonth => 'par mois';

  @override
  String get couplePremiumShared =>
      'Un seul abonnement : l\'autre en profite aussitôt, sans rien payer.';

  @override
  String get couplePremiumIncludesPlus =>
      'mazl+ est inclus pour vous deux tant que l\'abonnement couple est actif.';

  @override
  String get couplePremiumPriceLater =>
      'Le prix s\'affiche dès que l\'App Store répond.';

  @override
  String get couplePremiumSubscribe => 'S\'abonner pour nous deux';

  @override
  String get couplePremiumRestore => 'Restaurer un achat';

  @override
  String get couplePremiumLegal =>
      'Renouvellement automatique chaque mois, résiliable à tout moment dans les réglages de l\'App Store. Le prix affiché vient d\'Apple, dans votre devise.';

  @override
  String get couplePremiumWelcome => 'MAZL Couple est actif pour vous deux.';

  @override
  String get couplePremiumActiveTitle => 'MAZL Couple est actif';

  @override
  String get couplePremiumPaidByMe => 'Payé par vous';

  @override
  String couplePremiumPaidByPartner(String partner) {
    return 'Payé par $partner';
  }

  @override
  String couplePremiumRenews(String date) {
    return 'Renouvelé le $date';
  }

  @override
  String get couplePremiumManage => 'Gérer l\'abonnement';

  @override
  String get couplePremiumManageFailed =>
      'Impossible d\'ouvrir les réglages de l\'App Store.';

  @override
  String get couplePremiumLinkFailed => 'Impossible d\'ouvrir ce lien.';

  @override
  String get coupleQuestionTitle => 'Question du jour';

  @override
  String coupleQuestionEyebrow(int day) {
    return 'Question du jour · $day';
  }

  @override
  String get coupleQuestionEmptyTitle => 'La question du jour arrive bientôt';

  @override
  String get coupleQuestionEmptyLine =>
      'Chaque jour, une question à se poser à deux. Revenez un peu plus tard.';

  @override
  String get coupleQuestionPartnerFallback => 'Votre partenaire';

  @override
  String coupleQuestionPartnerAnsweredTitle(String name) {
    return '$name a répondu';
  }

  @override
  String get coupleQuestionPartnerAnsweredLine =>
      'Répondez à votre tour pour lire sa réponse.';

  @override
  String coupleQuestionPartnerPendingTitle(String name) {
    return '$name n\'a pas encore répondu';
  }

  @override
  String get coupleQuestionPartnerPendingLine =>
      'Vous lirez sa réponse quand vous aurez chacun répondu.';

  @override
  String get coupleQuestionHiddenTitle => 'Sa réponse est masquée';

  @override
  String get coupleQuestionHiddenLine =>
      'Elle s\'affichera dès que vous aurez répondu.';

  @override
  String get coupleQuestionYourAnswer => 'Votre réponse';

  @override
  String get coupleQuestionHint => 'Écrivez ce qui vous vient…';

  @override
  String coupleQuestionCounter(int count, int max) {
    return '$count / $max';
  }

  @override
  String coupleQuestionSendTo(String name) {
    return 'Envoyer à $name';
  }

  @override
  String get coupleQuestionSend => 'Envoyer';

  @override
  String get coupleQuestionSending => 'Envoi en cours';

  @override
  String get coupleQuestionSendFailed =>
      'Votre réponse n\'est pas partie. Elle reste dans le champ, vous pouvez réessayer.';

  @override
  String coupleQuestionPartnerAnswerTitle(String name) {
    return 'Réponse de $name';
  }

  @override
  String coupleQuestionPartnerWaiting(String name) {
    return '$name n\'a pas encore répondu. Revenez lire sa réponse plus tard.';
  }

  @override
  String get coupleQuestionHistory => 'Vos réponses précédentes';

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
  String get coupleSpaceSetupExplain =>
      'Choisissez votre match. Dès que votre demande est acceptée, vous passez tous les deux en mode couple.';

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
  String coupleTodayEyebrow(int days) {
    return 'MAZL Couple · jour $days';
  }

  @override
  String coupleTodayTitle(String me, String partner) {
    return 'Bonjour $me\net $partner.';
  }

  @override
  String coupleTodayTitleNoName(String partner) {
    return 'Bonjour,\nvous et $partner.';
  }

  @override
  String get coupleTodayQuestionLabel => 'Question du jour';

  @override
  String coupleTodayQuestionPartnerAnswered(String partner) {
    return '$partner a répondu · à vous';
  }

  @override
  String coupleTodayQuestionMineAnswered(String partner) {
    return 'Vous avez répondu · en attente de $partner';
  }

  @override
  String coupleTodayQuestionWaiting(String partner) {
    return 'En attente de $partner';
  }

  @override
  String get coupleTodayQuestionBoth => 'Vous avez répondu tous les deux';

  @override
  String get coupleTodayAnswer => 'Répondre';

  @override
  String get coupleTodayView => 'Voir';

  @override
  String get coupleTodayShabbatTonight => 'Shabbat ensemble ce soir';

  @override
  String get coupleTodayShabbatFriday => 'Shabbat ensemble vendredi';

  @override
  String coupleTodayClock(String hour, String minute) {
    return '$hour h $minute';
  }

  @override
  String coupleTodayShabbatCandles(String time) {
    return 'Allumage des bougies à $time · Paris';
  }

  @override
  String get coupleTodayShabbatAgenda => 'Ouvrir l\'agenda';

  @override
  String get coupleTodayUpcomingLabel => 'À venir';

  @override
  String get coupleTodayUpcomingEmpty =>
      'Rien de prévu dans les 45 prochains jours. Ajoutez une date ou un rituel dans l\'agenda.';

  @override
  String get coupleTodayDaysToday => 'Aujourd\'hui';

  @override
  String get coupleTodayDaysTomorrow => 'Demain';

  @override
  String coupleTodayDaysAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dans $count jours',
      one: 'Dans $count jour',
    );
    return '$_temp0';
  }

  @override
  String coupleTodayIdeaFor(String weekday) {
    return 'Idée pour $weekday';
  }

  @override
  String get coupleTodayIdeaGeneric => 'Une idée pour vous';

  @override
  String get coupleTodayMoodQuestion => 'Comment ça va entre vous ?';

  @override
  String get coupleTodayMoodGreat => 'Très bien';

  @override
  String get coupleTodayMoodGood => 'Bien';

  @override
  String get coupleTodayMoodMeh => 'Bof';

  @override
  String get coupleTodayMoodTalk => 'On doit parler';

  @override
  String coupleTodayMoodTalkNotice(String partner) {
    return 'Nous avons prévenu $partner, sans un mot.';
  }

  @override
  String get coupleTodayMoodFailed =>
      'Impossible d\'enregistrer votre humeur. Réessayez.';

  @override
  String coupleTodayCheckinDue(String month) {
    return 'Le bilan de $month vous attend';
  }

  @override
  String get coupleTodayPremiumLine => 'Découvrir MAZL Couple';

  @override
  String coupleUsDay(int count) {
    return 'Jour $count';
  }

  @override
  String get coupleUsYouLabel => 'Vous';

  @override
  String get coupleUsQuestionLabel => 'Question du jour';

  @override
  String coupleUsQuestionPartnerAnswered(String name) {
    return '$name a répondu · à vous';
  }

  @override
  String get coupleUsQuestionYourTurn => 'À vous de répondre';

  @override
  String get coupleUsQuestionYouAnswered => 'Vous avez répondu';

  @override
  String coupleUsWaitingFor(String name) {
    return 'En attente de $name';
  }

  @override
  String get coupleUsAnswerButton => 'Répondre';

  @override
  String get coupleUsSeeButton => 'Voir';

  @override
  String get coupleUsHistoryLink => 'Voir l\'historique des réponses';

  @override
  String get coupleUsCheckinLabel => 'Bilan';

  @override
  String coupleUsCheckinDue(String month) {
    return 'Le bilan de $month vous attend';
  }

  @override
  String get coupleUsCheckinStart => 'Faire le bilan';

  @override
  String coupleUsCheckinAligned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En phase sur $count points sur 3',
      one: 'En phase sur $count point sur 3',
    );
    return '$_temp0';
  }

  @override
  String get coupleUsCheckinLowestTalk =>
      'Le thème à soigner ce mois-ci : se parler.';

  @override
  String get coupleUsCheckinLowestTime =>
      'Le thème à soigner ce mois-ci : le temps à deux.';

  @override
  String get coupleUsCheckinLowestClose =>
      'Le thème à soigner ce mois-ci : se sentir proches.';

  @override
  String get coupleUsSettingsLabel => 'Réglages du couple';

  @override
  String get coupleUsStatusInRelationship => 'En couple';

  @override
  String get coupleUsStatusEngaged => 'Fiancés';

  @override
  String get coupleUsStatusMarried => 'Mariés';

  @override
  String get coupleUsPremiumTitle => 'MAZL Couple';

  @override
  String get coupleUsPremiumActiveByYou => 'Actif · payé par vous';

  @override
  String coupleUsPremiumActiveByPartner(String name) {
    return 'Actif · payé par $name';
  }

  @override
  String get coupleUsPremiumActive => 'Actif';

  @override
  String get coupleUsPremiumDiscover => 'Découvrir MAZL Couple';

  @override
  String get coupleUsHistoryTitle => 'Vos réponses';

  @override
  String get coupleUsHistoryEmptyTitle => 'Pas encore de réponses';

  @override
  String get coupleUsHistoryEmptyLine =>
      'Répondez à la question du jour : vos réponses, et celles de l\'autre, s\'afficheront ici.';

  @override
  String coupleUsHistoryNoPartnerAnswer(String name) {
    return '$name n\'a pas répondu';
  }

  @override
  String get duoTutorialWelcomeTitle => 'MAZL, pensé pour le Duo';

  @override
  String get duoTutorialWelcomeBody =>
      'Fermé, vos onglets s\'alignent dans la colonne, sous le pouce. Suivez les gestes avec votre téléphone, en même temps que nous.';

  @override
  String get duoTutorialOpenTitle => 'Ouvrez-le';

  @override
  String get duoTutorialOpenBody =>
      'Dépliez votre iPhone à plat. Les conversations s\'affichent à côté de la liste.';

  @override
  String get duoTutorialBookTitle => 'Pliez-le comme un livre';

  @override
  String get duoTutorialBookBody =>
      'Entrouvrez-le à mi-chemin. Le pli devient la ligne entre deux colonnes : la liste d\'un côté, le détail de l\'autre.';

  @override
  String get duoTutorialTableTitle => 'Posez-le sur la table';

  @override
  String get duoTutorialTableBody =>
      'Tenez-le comme un ordinateur portable. La photo reste en haut, les boutons en bas, sous votre pouce.';

  @override
  String get duoTutorialReadyTitle => 'C\'est parti';

  @override
  String get duoTutorialReadyBody =>
      'Vous connaissez toutes les poses. Retrouvez ce tutoriel à tout moment dans les Réglages.';

  @override
  String get duoTutorialSkip => 'Passer';

  @override
  String get duoTutorialNext => 'Suivant';

  @override
  String get duoTutorialStart => 'Commencer';

  @override
  String get duoTutorialDone => 'C\'est fait';

  @override
  String duoTutorialProgress(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get duoTutorialSettingsTitle => 'MAZL sur iPhone Duo';

  @override
  String get duoTutorialSettingsSubtitle => 'Revoir le tutoriel';

  @override
  String get eventsTitle => 'Événements';

  @override
  String get eventsFilterAll => 'Tous';

  @override
  String get eventsFilterHolidays => 'Fêtes';

  @override
  String get eventsTypeShabbat => 'Shabbat';

  @override
  String get eventsTypeShabbatDinner => 'Dîner de Shabbat';

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
  String get eventsNoOthers =>
      'Pas d\'autre événement pour l\'instant. Revenez bientôt.';

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
  String get eventsComingSoon => 'Bientôt disponible';

  @override
  String get eventsNotifyMe => 'Me prévenir';

  @override
  String get eventsNotifyRequested => 'Vous serez prévenu';

  @override
  String get eventsNotifyRequestedDone =>
      'Nous vous préviendrons à l\'ouverture des inscriptions.';

  @override
  String get eventsNotifyCancelled => 'Alerte retirée';

  @override
  String get eventsNotifyError =>
      'Impossible d\'enregistrer votre demande. Réessayez.';

  @override
  String get eventsMapOpenInMaps => 'Ouvrir dans Plans';

  @override
  String get eventsMapArea => 'Zone approximative';

  @override
  String get eventsMapExplore => 'Touchez pour explorer';

  @override
  String get eventsMapDone => 'Terminé';

  @override
  String get eventsMapSemantics => 'Carte du quartier de l\'événement';

  @override
  String eventsTimeRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get eventsShareError => 'Impossible de partager pour le moment.';

  @override
  String get genreLookingForRequired => 'Indiquez ce que vous recherchez';

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
  String get layoutPaneChatTitle => 'Choisissez une conversation';

  @override
  String get layoutPaneChatMessage => 'Elle s\'ouvre ici, à côté de la liste.';

  @override
  String get layoutPaneProfileTitle => 'Choisissez un match';

  @override
  String get layoutPaneProfileMessage =>
      'Son profil s\'affiche ici, à côté de la liste.';

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
  String get matchingFiltersReset => 'Réinitialiser';

  @override
  String get matchingFiltersAge => 'Tranche d\'âge';

  @override
  String matchingFiltersYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ans',
      one: '$count an',
    );
    return '$_temp0';
  }

  @override
  String get matchingFiltersDistance => 'Distance maximale';

  @override
  String matchingFiltersKm(int count) {
    return '$count km';
  }

  @override
  String get matchingFiltersDenomination => 'Courant religieux';

  @override
  String get matchingFiltersKashrut => 'Kashrout';

  @override
  String get matchingFiltersShabbatSection => 'Shabbat';

  @override
  String get matchingFiltersChoiceHint =>
      'Plusieurs choix possibles. Les profils qui n\'ont pas répondu ne sont pas proposés.';

  @override
  String get matchingFiltersOptions => 'Options';

  @override
  String get matchingFiltersVerifiedTitle => 'Profils vérifiés uniquement';

  @override
  String get matchingFiltersVerifiedHint =>
      'Voir seulement les profils vérifiés';

  @override
  String get matchingFiltersPhotoTitle => 'Avec photo uniquement';

  @override
  String get matchingFiltersPhotoHint => 'Exclure les profils sans photo';

  @override
  String get matchingFiltersUpsellTitle => 'Débloquer tous les filtres';

  @override
  String get matchingFiltersUpsellBody =>
      'Passez à mazl+ pour des recherches précises';

  @override
  String get matchingFiltersApply => 'Appliquer les filtres';

  @override
  String get matchingFiltersSaved => 'Filtres enregistrés';

  @override
  String get matchingFiltersSaveFailed => 'Erreur lors de la sauvegarde';

  @override
  String get matchingFiltersAdvanced => 'Filtres avancés';

  @override
  String get matchingFiltersLoadFailed =>
      'Vos filtres avancés n\'ont pas pu être chargés.';

  @override
  String get matchingFiltersConsentNeeded =>
      'Ces critères demandent votre accord pour traiter votre pratique religieuse. Ils n\'ont pas été enregistrés.';

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
  String get onboardingStart => 'Commencer';

  @override
  String onboardingStep(String current, String total) {
    return '$current / $total';
  }

  @override
  String onboardingPageOf(int current, int total) {
    return 'Page $current sur $total';
  }

  @override
  String get onboardingPage1Title => 'Bienvenue sur MAZL';

  @override
  String get onboardingPage1Body =>
      'L\'application de rencontres pensée pour la communauté juive.';

  @override
  String get onboardingPage2Title => 'Trouvez votre mazal';

  @override
  String get onboardingPage2Body =>
      'Découvrez des profils compatibles avec vos valeurs et votre pratique.';

  @override
  String get onboardingPage3Title => 'Mode Couple';

  @override
  String get onboardingPage3Body =>
      'Une fois l\'amour trouvé, MAZL vous accompagne : trouvez l\'amour, et gardez-le.';

  @override
  String get onboardingPage3Feature1 => 'Souvenirs et dates importantes';

  @override
  String get onboardingPage3Feature2 => 'Bucket list à deux';

  @override
  String get onboardingPage3Feature3 => 'Calendrier juif partagé';

  @override
  String get onboardingPage3Feature4 => 'Activités et suggestions';

  @override
  String get onboardingPage4Title => 'Mode Shabbat';

  @override
  String get onboardingPage4Body =>
      'Les horaires d\'allumage et de havdala de votre ville, et un écran de repos.';

  @override
  String get onboardingPage5Title => 'Suggestions du jour';

  @override
  String get onboardingPage5Body =>
      'Chaque jour, une courte sélection de profils vous attend dans Découvrir.';

  @override
  String get packsSuperLikesLabel => 'Super Likes';

  @override
  String get packsSuperLikesTitle => 'Vous n’avez plus de Super Likes.';

  @override
  String get packsSuperLikesSubtitle =>
      'Reprenez-en : ceux que vous achetez n’expirent jamais.';

  @override
  String get packsBoostsLabel => 'Boosts';

  @override
  String get packsBoostsTitle => 'Vous n’avez plus de Boost.';

  @override
  String packsBoostsSubtitle(int minutes) {
    return 'Mettez votre profil en tête pendant $minutes min. Un Boost acheté n’expire jamais.';
  }

  @override
  String packsPackSuperLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Super Likes',
      one: '$count Super Like',
    );
    return '$_temp0';
  }

  @override
  String packsPackBoosts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Boosts',
      one: '$count Boost',
    );
    return '$_temp0';
  }

  @override
  String packsPackSemantics(String quantity, String price) {
    return 'Acheter $quantity pour $price';
  }

  @override
  String get packsLoading => 'Chargement des offres';

  @override
  String get packsStoreUnavailable =>
      'La boutique n’est pas disponible pour le moment. Réessayez dans un instant.';

  @override
  String get packsPending =>
      'Achat en attente d’approbation. Votre solde sera mis à jour dès qu’il sera validé.';

  @override
  String get packsBoostAlreadyActive => 'Un Boost est déjà en cours.';

  @override
  String get packsErrorExhausted =>
      'Il ne vous reste plus rien à utiliser pour le moment.';

  @override
  String get plusFeatureUnlimitedLikesTitle => 'Likes illimités';

  @override
  String get plusFeatureUnlimitedLikesDescription =>
      'Likez autant que vous voulez, sans limite quotidienne.';

  @override
  String get plusFeatureSeeWhoLikesYouTitle => 'Voir qui vous a aimé';

  @override
  String get plusFeatureSeeWhoLikesYouDescription =>
      'Voyez qui vous a aimé avant même de le croiser.';

  @override
  String get plusFeatureSuperLikesTitle => 'Super Likes';

  @override
  String get plusFeatureSuperLikesDescription =>
      'Faites-vous remarquer avec 5 Super Likes par jour.';

  @override
  String get plusFeatureBoostTitle => 'Boost';

  @override
  String get plusFeatureBoostDescription =>
      'Soyez en tête de pile pendant 30 minutes.';

  @override
  String get plusFeatureReadReceiptsTitle => 'Confirmations de lecture';

  @override
  String get plusFeatureReadReceiptsDescription =>
      'Sachez quand vos messages ont été lus.';

  @override
  String get plusFeatureAdvancedFiltersTitle => 'Filtres avancés';

  @override
  String get plusFeatureAdvancedFiltersDescription =>
      'Filtrez par pratique, communauté, et plus.';

  @override
  String get plusFeaturePrioritySupportTitle => 'Support prioritaire';

  @override
  String get plusFeaturePrioritySupportDescription =>
      'Obtenez une réponse rapide de notre équipe.';

  @override
  String get plusReservedLabel => 'Réservé à mazl+';

  @override
  String get plusDiscover => 'Découvrir mazl+';

  @override
  String get plusNotNow => 'Pas maintenant';

  @override
  String plusDailyLimitLabel(int limit) {
    return 'Limite du jour · $limit / $limit';
  }

  @override
  String get plusDailyLimitTitle => 'Vos likes du jour sont partis.';

  @override
  String get plusDailyLimitBody =>
      'Ils reviennent à minuit. Ou continuez sans compter, et voyez qui vous a déjà aimé.';

  @override
  String get plusDailyLimitNext => 'Prochains likes dans';

  @override
  String get plusDailyLimitWait => 'Attendre minuit';

  @override
  String get plusOfferTagline => 'Rencontrez sans compter.';

  @override
  String get plusPerkUnlimitedLikesDetail => 'Fini les 10 par jour.';

  @override
  String get plusPerkSeeWhoDetail => 'Avant même de les croiser.';

  @override
  String get plusPerkSuperLikesTitle => '5 Super Likes par jour';

  @override
  String get plusPerkSuperLikesDetail => 'Au lieu d’un seul.';

  @override
  String get plusPerkBoostTitle => 'Un Boost par jour';

  @override
  String get plusPerkBoostDetail => 'En tête de pile pendant 30 minutes.';

  @override
  String get plusPerkFiltersDetail => 'Pratique, communauté, et plus.';

  @override
  String get plusYourPlan => 'Votre formule';

  @override
  String plusMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months mois',
      one: '1 mois',
    );
    return '$_temp0';
  }

  @override
  String plusPerMonth(String price) {
    return '$price par mois';
  }

  @override
  String plusPlanSavings(int percent) {
    return '-$percent %';
  }

  @override
  String plusPlanSemantics(String duration, String price, String perMonth) {
    return '$duration, $price, $perMonth';
  }

  @override
  String plusPlanSemanticsSaving(
    String duration,
    String price,
    String perMonth,
    String saving,
  ) {
    return '$duration, $price, $perMonth, économie $saving';
  }

  @override
  String plusContinuePrice(String price) {
    return 'Continuer · $price';
  }

  @override
  String get plusAndroidSoon => 'Bientôt disponible sur Android';

  @override
  String get plusRestore => 'Restaurer';

  @override
  String get plusTerms => 'Conditions';

  @override
  String get plusPrivacy => 'Confidentialité';

  @override
  String get plusLegalAppStore =>
      'Renouvellement automatique, résiliable à tout moment dans les réglages de l’App Store.';

  @override
  String get plusLegalGooglePlay =>
      'Renouvellement automatique, résiliable à tout moment dans les réglages de Google Play.';

  @override
  String get plusPendingApproval =>
      'Achat en attente d’approbation. Votre abonnement s’activera dès qu’il sera validé.';

  @override
  String get plusOfferRestored => 'Abonnement restauré';

  @override
  String get plusOfferNothingFound => 'Aucun abonnement trouvé';

  @override
  String get plusPlansSoon =>
      'Les abonnements seront disponibles prochainement.';

  @override
  String get plusErrorPurchaseInProgress => 'Un achat est déjà en cours.';

  @override
  String get plusErrorOwnedByAnotherAccount =>
      'Cet achat App Store est déjà associé à un autre compte mazl.';

  @override
  String get plusErrorInvalidTransaction =>
      'Nous n’avons pas pu valider cet achat auprès de l’App Store. Il sera revérifié au prochain lancement.';

  @override
  String get plusErrorInvalidBody =>
      'Votre achat n’a pas pu être transmis correctement. Réessayez dans un instant.';

  @override
  String get plusErrorSignInAgain =>
      'Reconnectez-vous à mazl pour finaliser votre achat.';

  @override
  String get plusErrorOffline =>
      'Connexion impossible. Votre achat est conservé et sera validé dès que possible.';

  @override
  String get plusErrorGeneric =>
      'L’achat n’a pas pu aboutir. Réessayez dans un instant.';

  @override
  String get plusErrorInactive => 'Votre abonnement n’est pas actif.';

  @override
  String get plusErrorRestoreFailed =>
      'La restauration a échoué. Réessayez dans un instant.';

  @override
  String get plusActiveSubscription => 'Abonnement actif';

  @override
  String plusActiveSubscriptionPlan(String plan) {
    return 'Abonnement actif · $plan';
  }

  @override
  String get plusWelcomeTitle => 'Bienvenue dans mazl+.';

  @override
  String get plusWelcomeSubtitle => 'Tout est déverrouillé. Par où commencer ?';

  @override
  String plusWelcomeLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes vous ont aimé',
      one: '1 personne vous a aimé',
    );
    return '$_temp0';
  }

  @override
  String get plusWelcomeLikesDetail => 'Les voir maintenant';

  @override
  String get plusWelcomeBoostTitle => 'Lancer votre Boost';

  @override
  String get plusWelcomeBoostDetail => 'En tête de pile pendant 30 minutes';

  @override
  String get plusWelcomeFiltersTitle => 'Affiner vos filtres';

  @override
  String get plusWelcomeFiltersDetail => 'Pratique, communauté, et plus';

  @override
  String plusTitleDetail(String title, String detail) {
    return '$title. $detail';
  }

  @override
  String get plusSubscriptionTitle => 'Abonnement';

  @override
  String get plusStatusActive => 'Actif';

  @override
  String get plusStatusCancelled => 'Résilié';

  @override
  String get plusFactPlan => 'Formule';

  @override
  String get plusFactRenewal => 'Renouvellement';

  @override
  String get plusFactExpiration => 'Expiration';

  @override
  String plusPlanAndPrice(String duration, String price) {
    return '$duration · $price';
  }

  @override
  String plusSuperLikesOf(int left, int max) {
    return '$left sur $max';
  }

  @override
  String get plusBoostAvailable => 'Disponible';

  @override
  String get plusBoostUsed => 'Utilisé aujourd’hui';

  @override
  String get plusLikesLabel => 'Likes';

  @override
  String get plusLikesUnlimited => 'Illimités';

  @override
  String get plusManageAppStore => 'Gérer dans l’App Store';

  @override
  String get plusManageGooglePlay => 'Gérer dans Google Play';

  @override
  String get plusManageFailed =>
      'Impossible d’ouvrir la gestion de l’abonnement.';

  @override
  String get plusRestorePurchases => 'Restaurer mes achats';

  @override
  String get plusNoActiveSubscription => 'Aucun abonnement actif.';

  @override
  String get plusPurchasesRestored => 'Achats restaurés.';

  @override
  String get plusNothingToRestore => 'Aucun abonnement trouvé.';

  @override
  String get plusSettingsPitch =>
      'Likes illimités, voir qui vous a aimé, Boost';

  @override
  String get plusUpgradeTo => 'Passer à mazl+';

  @override
  String plusSettingsSemanticsActive(String detail) {
    return 'mazl+. $detail';
  }

  @override
  String plusSettingsSemanticsUpgrade(String detail) {
    return 'Passer à mazl+. $detail';
  }

  @override
  String get privacyGateUnverifiable =>
      'Impossible de vérifier votre accord. Vérifiez votre connexion.';

  @override
  String get privacyGateAsk =>
      'Pour renseigner votre pratique, donnez votre accord';

  @override
  String get privacyGive => 'Donner mon accord';

  @override
  String get privacyLockedHint =>
      'Disponible une fois votre accord donné pour la pratique religieuse.';

  @override
  String get privacySheetLabel => 'Données sensibles · RGPD article 9';

  @override
  String get privacySheetTitle =>
      'Votre pratique religieuse, avec votre accord';

  @override
  String get privacySheetBody =>
      'Ces informations aident à proposer des profils compatibles. Ce sont des données sensibles, traitées seulement avec votre accord explicite, distinct des conditions d\'utilisation. Vous pouvez refuser et utiliser MAZL quand même.';

  @override
  String get privacySheetCheckbox =>
      'J\'ai lu ce texte et je donne mon accord explicite.';

  @override
  String get privacySheetAccept => 'J\'accepte';

  @override
  String get privacySheetDecline => 'Continuer sans';

  @override
  String get privacySheetErrorOutdated =>
      'Le texte a été mis à jour. Fermez cette fenêtre et rouvrez-la.';

  @override
  String get privacySheetErrorSave =>
      'Votre choix n\'a pas pu être enregistré. Réessayez.';

  @override
  String get privacySettingsTitle => 'Données de pratique religieuse';

  @override
  String get privacySettingsGrantedShort => 'Accordé';

  @override
  String get privacySettingsDeniedShort => 'Non accordé';

  @override
  String get privacySettingsGrantedTitle => 'Accord donné';

  @override
  String get privacySettingsNotGrantedTitle => 'Accord non donné';

  @override
  String get privacySettingsWithdraw => 'Retirer mon accord';

  @override
  String get privacySettingsWithdrawTitle => 'Retirer votre accord ?';

  @override
  String get privacySettingsWithdrawBody =>
      'Votre courant, votre kashrout, votre pratique du Shabbat et votre intention seront effacés de votre profil.';

  @override
  String get privacySettingsWithdrawFailed =>
      'Impossible de retirer votre accord. Réessayez.';

  @override
  String get privacySettingsLoadFailed =>
      'Impossible de charger votre accord. Vérifiez votre connexion.';

  @override
  String get analyticsSheetLabel => 'Mesure d\'audience';

  @override
  String get analyticsSheetTitle => 'Aider à améliorer MAZL';

  @override
  String get analyticsSheetBody =>
      'MAZL compte les écrans visités et les grandes étapes (inscription, achat) pour s\'améliorer. Jamais le contenu de vos messages, vos photos ni votre pratique religieuse. Votre identifiant est pseudonymisé et rien n\'est partagé avec des tiers. Vous pouvez refuser : MAZL fonctionne pareil.';

  @override
  String get analyticsSheetAccept => 'Accepter';

  @override
  String get analyticsSheetDecline => 'Refuser';

  @override
  String get analyticsSheetErrorOutdated =>
      'Le texte a été mis à jour. Fermez cette fenêtre puis rouvrez-la.';

  @override
  String get analyticsSheetErrorSave =>
      'Votre choix n\'a pas pu être enregistré. Réessayez.';

  @override
  String get analyticsSettingsTitle => 'Mesure d\'audience';

  @override
  String get analyticsSettingsGrantedShort => 'Activée';

  @override
  String get analyticsSettingsDeniedShort => 'Désactivée';

  @override
  String get analyticsSettingsGrantedTitle => 'Mesure d\'audience activée';

  @override
  String get analyticsSettingsNotGrantedTitle =>
      'Mesure d\'audience désactivée';

  @override
  String get analyticsSettingsAccept => 'Accepter la mesure d\'audience';

  @override
  String get analyticsSettingsWithdraw => 'Retirer mon accord';

  @override
  String get analyticsSettingsLoadFailed =>
      'Impossible de lire votre choix. Vérifiez votre connexion.';

  @override
  String get analyticsSettingsSaveFailed =>
      'Votre choix n\'a pas pu être enregistré. Réessayez.';

  @override
  String get profileMyProfile => 'Mon profil';

  @override
  String get profileEdit => 'Modifier';

  @override
  String get profileSettings => 'Réglages';

  @override
  String get profileMoreOptions => 'Plus d\'options';

  @override
  String get profileDecline => 'Refuser';

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
  String get profileSetupPreferencesNote =>
      'Ces préférences composent votre fil Découvrir. Vous pourrez les modifier à tout moment.';

  @override
  String get profileReportThisProfile => 'Signaler ce profil';

  @override
  String get profileChoiceNotSent => 'Votre choix n\'est pas parti. Réessayez.';

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
  String get settingsShabbatAutoPause => 'Horaires de Shabbat';

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
  String get settingsSales => 'Conditions de vente';

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
  String settingsShabbatBasedOn(String place) {
    return 'Basé sur $place';
  }

  @override
  String get settingsShabbatDefaultPlace => 'Paris, France';

  @override
  String get settingsShabbatUnknownPlaceHint =>
      'Les horaires sont ceux de Paris, car votre ville n\'est pas connue. Ajoutez-la dans les réglages pour des horaires exacts.';

  @override
  String get settingsShabbatExplanation =>
      'Allumage 18 minutes avant le coucher du soleil, havdala à la tombée de la nuit. Pour changer de lieu, modifiez votre ville dans les réglages.';

  @override
  String get settingsShabbatHeroTitle => 'Shabbat\nshalom.';

  @override
  String get settingsShabbatHeroSubtitle => 'Mazl se repose avec vous.';

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

  @override
  String get settingsRestoreNothing => 'Aucun abonnement trouvé.';

  @override
  String storefrontCampaignUntil(String date) {
    return 'Jusqu\'au $date';
  }

  @override
  String storefrontDiscountBadge(int percent) {
    return 'Offre -$percent %';
  }

  @override
  String get storefrontCampaignDefaultCta => 'Profiter de l\'offre';

  @override
  String storefrontPlanSemanticsHighlight(String plan, String highlight) {
    return '$plan. $highlight';
  }

  @override
  String get settingsFestiveIconTitle => 'Icône des fêtes';

  @override
  String get settingsFestiveIconSubtitle =>
      'L\'icône de l\'app change à l\'approche des fêtes. iOS affiche une alerte à chaque changement.';

  @override
  String get verificationTitle => 'Vérification';

  @override
  String get verificationLevel1 => 'Niveau 1';

  @override
  String get verificationLevel2 => 'Niveau 2';

  @override
  String get verificationVerifiedPill => 'Vérifiée';

  @override
  String get verificationConsent =>
      'Nous comparons votre visage à vos photos. Les images ne sont pas conservées ; seule une empreinte chiffrée l\'est, supprimable à tout moment.';

  @override
  String get verificationPhotoVerifiedLine =>
      'Votre visage correspond à vos photos.';

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

  @override
  String get verificationStateNoneTitle => 'Vérifiez votre profil';

  @override
  String get verificationStatePartialTitle => 'Vérification en cours';

  @override
  String get verificationStateDoneTitle => 'Profil entièrement vérifié';

  @override
  String get verificationStateNoneBody =>
      'Prouvez que vos photos sont les vôtres. Un badge s\'affiche sur votre profil et rassure les autres membres.';

  @override
  String get verificationStatePartialBody =>
      'Votre badge est déjà visible sur votre profil. Terminez l\'autre niveau pour inspirer encore plus confiance.';

  @override
  String get verificationStateDoneBody =>
      'Les autres membres voient votre badge et savent que vous êtes bien la personne de vos photos.';

  @override
  String verificationProgress(int done) {
    return '$done sur 2 niveaux vérifiés';
  }

  @override
  String get verificationPhotoCardTitle => 'Vérification de la photo';

  @override
  String get verificationIdentityCardTitle => 'Vérification de l\'identité';

  @override
  String get verificationPillTodo => 'À faire';

  @override
  String get verificationPillBusy => 'En cours';

  @override
  String get verificationPillRefused => 'Refusée';

  @override
  String get verificationPillBlocked => 'Limite atteinte';

  @override
  String get verificationPhotoPitch =>
      'Un selfie en direct est comparé à vos photos de profil.';

  @override
  String get verificationPhotoBenefitBadge =>
      'Un badge de confiance sur votre profil';

  @override
  String get verificationPhotoBenefitProof =>
      'La preuve que vos photos sont bien les vôtres';

  @override
  String get verificationPhotoBenefitQuick =>
      'Quelques secondes et trois mouvements de tête';

  @override
  String get verificationIdentityBenefitBadge =>
      'Un niveau de confiance de plus sur votre badge';

  @override
  String get verificationIdentityBenefitChip =>
      'Lecture sans contact de la puce de votre document';

  @override
  String get verificationIdentityBenefitNeeds =>
      'Un passeport ou une carte d\'identité à puce est nécessaire';

  @override
  String verificationVerifiedOnDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Le $dateString';
  }

  @override
  String get webSessionsTitle => 'Ordinateurs connectés';

  @override
  String get webSessionsSectionLabel => 'MAZL sur ordinateur';

  @override
  String get webSessionsIntro =>
      'Utilisez MAZL sur ordinateur sur app.mazl.app. Chaque ordinateur reste connecté 7 jours au plus.';

  @override
  String get webSessionsConnect => 'Connecter un ordinateur';

  @override
  String get webSessionsConnected => 'Ordinateur connecté.';

  @override
  String get webSessionsLoadFailed =>
      'Impossible de charger vos ordinateurs. Vérifiez votre connexion.';

  @override
  String get webSessionsEmpty =>
      'Aucun ordinateur n\'est connecté pour le moment.';

  @override
  String get webSessionsListLabel => 'Ordinateurs';

  @override
  String get webSessionsRevoke => 'Déconnecter';

  @override
  String webSessionsRevokeNamed(String browser) {
    return 'Déconnecter $browser';
  }

  @override
  String get webSessionsRevokeFailed =>
      'Impossible de déconnecter cet ordinateur. Réessayez.';

  @override
  String get webSessionsRevokeAll => 'Déconnecter tous les ordinateurs';

  @override
  String get webSessionsRevokeAllTitle => 'Déconnecter tous les ordinateurs ?';

  @override
  String get webSessionsRevokeAllBody =>
      'Vous devrez vous reconnecter sur chaque ordinateur.';

  @override
  String get webSessionsRevokeAllConfirm => 'Déconnecter tout';

  @override
  String get webSessionsRevokeAllFailed =>
      'Impossible de déconnecter les ordinateurs. Réessayez.';

  @override
  String get webSessionsMethodQr => 'Connecté par QR code';

  @override
  String get webSessionsMethodGoogle => 'Connecté avec Google';

  @override
  String get webSessionsMethodApple => 'Connecté avec Apple';

  @override
  String get webSessionsActiveNow => 'Actif à l\'instant';

  @override
  String webSessionsActiveMinutes(int count) {
    return 'Actif il y a $count min';
  }

  @override
  String webSessionsActiveHours(int count) {
    return 'Actif il y a $count h';
  }

  @override
  String get webSessionsActiveYesterday => 'Actif hier';

  @override
  String webSessionsActiveDays(int count) {
    return 'Actif il y a $count j';
  }

  @override
  String webSessionsClockTime(String hour, String minute) {
    return '$hour h $minute';
  }

  @override
  String get webSessionsScanInstruction =>
      'Scannez le QR code affiché sur app.mazl.app';

  @override
  String get webSessionsScanCameraLabel => 'Caméra de lecture du QR code';

  @override
  String get webSessionsCameraUnavailable =>
      'La caméra n\'est pas accessible. Autorisez l\'accès à la caméra dans les réglages de votre iPhone pour scanner un code.';

  @override
  String get webSessionsScanNotMazl => 'Ce QR code n\'est pas un code MAZL.';

  @override
  String get webSessionsScanExpired =>
      'Ce code a expiré. Affichez un nouveau code sur l\'ordinateur.';

  @override
  String get webSessionsScanTooMany =>
      'Trop de tentatives. Patientez un instant avant de réessayer.';

  @override
  String get webSessionsApproveInvalid =>
      'Cette demande n\'est plus valide. Affichez un nouveau code sur l\'ordinateur.';

  @override
  String get webSessionsConnectionProblem =>
      'Connexion impossible. Vérifiez votre réseau, puis réessayez.';

  @override
  String get webSessionsGenericProblem =>
      'Une erreur est survenue. Réessayez dans un instant.';

  @override
  String get webSessionsConfirmLabel => 'Connexion à MAZL sur ordinateur';

  @override
  String get webSessionsConfirmTitle => 'Connecter cet ordinateur ?';

  @override
  String get webSessionsConfirmBrowser => 'Navigateur';

  @override
  String get webSessionsConfirmAddress => 'Adresse';

  @override
  String get webSessionsConfirmAskedAt => 'Demande faite à';

  @override
  String get webSessionsConfirmWarning =>
      'Ne scannez que le code affiché sur votre propre ordinateur. Si quelqu\'un vous demande de scanner un code, refusez.';

  @override
  String get webSessionsConfirmApprove => 'Connecter';

  @override
  String get webSessionsConfirmDeny => 'Refuser';
}
