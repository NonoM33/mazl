// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
  String get chatHeaderOnline => 'En ligne';

  @override
  String get chatHeaderVideoCall => 'Appel vidéo';

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
  String get icebreakerWidgetTitle => 'Besoin d\'inspiration ?';

  @override
  String get icebreakerWidgetSubtitle =>
      'Voici quelques idées pour briser la glace';

  @override
  String get icebreakerTopicFallback => 'ça';

  @override
  String icebreakerPromptLoved(String promptText, String followUp) {
    return 'J\'ai adoré ta réponse à \"$promptText\". $followUp';
  }

  @override
  String icebreakerPromptSmiled(String promptText) {
    return 'Ta réponse sur \"$promptText\" m\'a fait sourire. Tu peux m\'en dire plus ?';
  }

  @override
  String icebreakerPromptCurious(String answer, String topic) {
    return 'Je suis curieux(se) de savoir pourquoi tu as répondu \"$answer\" à la question sur $topic';
  }

  @override
  String get icebreakerFollowUpIntrigued => 'Ça m\'intrigue.';

  @override
  String get icebreakerFollowUpKnowMore => 'J\'aimerais en savoir plus.';

  @override
  String get icebreakerFollowUpTellMe => 'Tu me racontes ?';

  @override
  String get icebreakerFollowUpInteresting => 'Ça a l\'air intéressant.';

  @override
  String get icebreakerBioTravelRecent =>
      'Tu as voyagé où récemment ? J\'adorerais entendre tes histoires.';

  @override
  String get icebreakerBioTravelDream =>
      'Quelle est ta prochaine destination de rêve ?';

  @override
  String get icebreakerBioMusicGenre =>
      'Quel genre de musique tu écoutes en ce moment ?';

  @override
  String get icebreakerBioMusicConcert =>
      'Tu as été à un bon concert récemment ?';

  @override
  String get icebreakerBioCookingNow =>
      'Tu cuisines quoi de bon en ce moment ?';

  @override
  String get icebreakerBioCookingSignature =>
      'C\'est quoi ton plat signature ?';

  @override
  String get icebreakerBioSportWhich => 'Tu pratiques quel sport ?';

  @override
  String get icebreakerBioSportWatchOrPlay =>
      'Tu préfères regarder ou pratiquer ?';

  @override
  String get icebreakerBioReadingNow => 'Tu lis quoi en ce moment ?';

  @override
  String get icebreakerBioReadingLastBook =>
      'C\'est quoi le dernier livre qui t\'a marqué ?';

  @override
  String get icebreakerBioCinemaRecent => 'Tu as vu un bon film récemment ?';

  @override
  String get icebreakerBioCinemaOrSeries => 'Tu préfères cinéma ou séries ?';

  @override
  String get icebreakerBioHikingTrails =>
      'Tu connais de beaux sentiers dans le coin ?';

  @override
  String get icebreakerBioHikingBest => 'C\'est quoi ta plus belle rando ?';

  @override
  String get icebreakerBioPhotoSubjects =>
      'Tu prends des photos de quoi principalement ?';

  @override
  String get icebreakerBioPhotoCamera => 'Tu utilises quoi comme appareil ?';

  @override
  String get icebreakerOrthodoxSynagogue =>
      'Tu as une synagogue préférée dans le coin ?';

  @override
  String get icebreakerOrthodoxShabbat =>
      'Comment tu passes généralement Shabbat ?';

  @override
  String get icebreakerOrthodoxKosherRestaurant =>
      'Tu as un restaurant casher préféré ?';

  @override
  String get icebreakerTraditionalTraditions =>
      'Quelles traditions juives sont les plus importantes pour toi ?';

  @override
  String get icebreakerTraditionalShabbat =>
      'Tu célèbres Shabbat comment généralement ?';

  @override
  String get icebreakerTraditionalHoliday => 'Tu as une fête juive préférée ?';

  @override
  String get icebreakerSecularCulture =>
      'C\'est quoi ton rapport à la culture juive ?';

  @override
  String get icebreakerSecularFamilyTraditions =>
      'Tu as des traditions familiales que tu gardes ?';

  @override
  String get icebreakerSecularHolidays => 'Tu célèbres quelles fêtes ?';

  @override
  String get icebreakerDefaultHoliday => 'C\'est quoi ta fête juive préférée ?';

  @override
  String get icebreakerDefaultFamilyTraditions =>
      'Tu as des traditions familiales spéciales ?';

  @override
  String get icebreakerDefaultPracticingFamily =>
      'Tu as grandi dans une famille pratiquante ?';

  @override
  String icebreakerLocationKnowWell(String location) {
    return 'Tu connais bien $location ? Tu me conseilles quoi ?';
  }

  @override
  String icebreakerLocationFavoriteSpot(String location) {
    return 'C\'est quoi ton coin préféré à $location ?';
  }

  @override
  String icebreakerLocationOriginallyFrom(String location) {
    return 'Tu es originaire de $location ou tu t\'y es installé(e) ?';
  }

  @override
  String icebreakerLocationRestaurant(String location) {
    return 'Il y a un bon restaurant que tu recommandes à $location ?';
  }

  @override
  String get icebreakerGenericDinnerGuest =>
      'Si tu pouvais dîner avec n\'importe qui, vivant ou mort, ce serait qui ?';

  @override
  String get icebreakerGenericPerfectDay =>
      'C\'est quoi ta définition d\'une journée parfaite ?';

  @override
  String get icebreakerGenericHiddenTalent =>
      'Tu as un talent caché que peu de gens connaissent ?';

  @override
  String get icebreakerGenericSpontaneous =>
      'C\'est quoi le truc le plus spontané que tu aies fait ?';

  @override
  String get icebreakerGenericSeaOrMountain =>
      'Tu préfères vacances à la mer ou à la montagne ?';

  @override
  String get icebreakerGenericLottery =>
      'Si tu gagnais au loto demain, tu ferais quoi en premier ?';

  @override
  String get icebreakerGenericGuiltyPleasure =>
      'C\'est quoi ton guilty pleasure ?';

  @override
  String get icebreakerGenericDream =>
      'Tu as un rêve que tu n\'as pas encore réalisé ?';

  @override
  String get icebreakerGenericBestAdvice =>
      'C\'est quoi le meilleur conseil qu\'on t\'ait donné ?';

  @override
  String get icebreakerGenericBreakfastOrDinner =>
      'Tu préfères petit-déjeuner ou dîner dehors ?';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du téléphone';
}
