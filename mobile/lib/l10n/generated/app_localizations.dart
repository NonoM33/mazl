import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('he'),
    Locale('ru'),
  ];

  /// Conversations : titre de l'écran (grand titre, 40 px).
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get chatListTitle;

  /// Conversations : texte d'aide du champ qui filtre la liste par prénom.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get chatListSearchHint;

  /// Conversations : titre (34 px) quand la liste n'a pas pu être chargée.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger'**
  String get chatListLoadErrorTitle;

  /// Conversations : phrase sous le titre d'erreur de chargement.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion, puis réessayez.'**
  String get chatListLoadErrorBody;

  /// Conversations : titre (34 px) quand le membre n'a encore aucune conversation.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de conversations'**
  String get chatListEmptyTitle;

  /// Conversations : phrase sous le titre de l'état vide.
  ///
  /// In fr, this message translates to:
  /// **'Vos échanges apparaîtront ici dès votre premier match.'**
  String get chatListEmptyBody;

  /// Conversations : bouton de l'état vide qui ouvre l'écran de découverte des profils.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get chatListEmptyAction;

  /// Conversations : message quand la recherche par prénom ne trouve personne. {query} est ce que le membre a tapé.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour « {query} ».'**
  String chatListNoResults(String query);

  /// Conversations : nom affiché quand le prénom de l'autre membre n'est pas connu.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get chatListUnknownMember;

  /// Conversations et conversation vide : aperçu d'une conversation sans message, et petite étiquette au-dessus de « Dites bonjour ».
  ///
  /// In fr, this message translates to:
  /// **'Nouveau match'**
  String get chatNewMatch;

  /// Conversations : phrase lue par le lecteur d'écran pour une ligne qui a des messages non lus. {name} est le prénom de l'autre membre.
  ///
  /// In fr, this message translates to:
  /// **'{name}, message non lu'**
  String chatListUnreadLabel(String name);

  /// Chat : aperçu d'un message qui est une photo (liste des conversations, citation, bandeau de réponse).
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get chatPhotoLabel;

  /// Chat : aperçu d'un message vocal (liste des conversations, citation, bandeau de réponse).
  ///
  /// In fr, this message translates to:
  /// **'Message vocal'**
  String get chatVoiceLabel;

  /// Chat : texte d'un message que son auteur a retiré (bulle en italique, aperçu, citation).
  ///
  /// In fr, this message translates to:
  /// **'Message retiré'**
  String get chatRemovedLabel;

  /// Chat : mot qui remplace le prénom de l'autre membre tant qu'on ne le connaît pas (« Réponse à Votre correspondant »).
  ///
  /// In fr, this message translates to:
  /// **'Votre correspondant'**
  String get chatOtherFallbackName;

  /// Chat : auteur d'un message quand c'est le membre lui-même (citation, liste des réactions).
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get chatAuthorYou;

  /// Chat, en-tête : à la place du prénom pendant le chargement.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get chatHeaderLoading;

  /// Chat, en-tête : statut sous le prénom quand l'autre membre est en train d'écrire (couleur d'accent, une ligne).
  ///
  /// In fr, this message translates to:
  /// **'écrit…'**
  String get chatHeaderTyping;

  /// Chat, en-tête : statut sous le prénom quand l'autre membre n'écrit pas.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get chatHeaderOnline;

  /// Chat, en-tête : info-bulle du bouton qui lance un appel vidéo.
  ///
  /// In fr, this message translates to:
  /// **'Appel vidéo'**
  String get chatHeaderVideoCall;

  /// Chat, en-tête : info-bulle du bouton « ⋯ » qui ouvre les options de la conversation.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get chatHeaderOptions;

  /// Chat, feuille d'options : ouvre le profil de l'autre membre.
  ///
  /// In fr, this message translates to:
  /// **'Voir le profil'**
  String get chatOptionsViewProfile;

  /// Chat, feuille d'options : coupe les notifications de cette conversation.
  ///
  /// In fr, this message translates to:
  /// **'Couper les notifications'**
  String get chatOptionsMute;

  /// Chat, feuille d'options : bloque l'autre membre (action destructive, en rouge).
  ///
  /// In fr, this message translates to:
  /// **'Bloquer'**
  String get chatOptionsBlock;

  /// Chat : message bref après avoir coupé les notifications de la conversation.
  ///
  /// In fr, this message translates to:
  /// **'Notifications coupées pour cette conversation'**
  String get chatMutedConfirmation;

  /// Chat : nom donné à la boîte de dialogue de blocage ou de signalement quand le prénom n'est pas connu.
  ///
  /// In fr, this message translates to:
  /// **'Cet utilisateur'**
  String get chatBlockFallbackName;

  /// Chat : libellé lu par le lecteur d'écran pendant le chargement des premiers messages (bulles grises).
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la conversation'**
  String get chatLoading;

  /// Chat : grand titre (40 px) d'une conversation sans aucun message.
  ///
  /// In fr, this message translates to:
  /// **'Dites bonjour.'**
  String get chatEmptyTitle;

  /// Chat : phrase sous le titre d'une conversation sans aucun message.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez le premier message pour briser la glace.'**
  String get chatEmptyBody;

  /// Chat : repère au-dessus du premier message, avec la date du match déjà mise en forme (« 21 oct. »). Affiché en majuscules espacées.
  ///
  /// In fr, this message translates to:
  /// **'Match · {date}'**
  String chatMatchStart(String date);

  /// Chat : pilule flottante au-dessus de la zone de saisie quand des messages sont arrivés pendant que le membre lisait plus haut.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 nouveau message} other{{count} nouveaux messages}}'**
  String chatNewMessages(int count);

  /// Chat : phrase lue par le lecteur d'écran pour la bulle aux trois points (l'autre membre écrit).
  ///
  /// In fr, this message translates to:
  /// **'Votre correspondant écrit'**
  String get chatTypingSemantics;

  /// Chat : sous le dernier message envoyé et lu. {time} est l'heure de lecture déjà mise en forme (« 21:42 »).
  ///
  /// In fr, this message translates to:
  /// **'Vu à {time}'**
  String chatSeenAt(String time);

  /// Chat : sous une bulle dont l'envoi a échoué (rouge, 12 px) ; un toucher ouvre le choix réessayer ou supprimer.
  ///
  /// In fr, this message translates to:
  /// **'Échec · Réessayer'**
  String get chatFailedRetry;

  /// Chat, menu d'appui long : répondre à ce message.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get chatMenuReply;

  /// Chat, menu d'appui long : copie le texte du message.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get chatMenuCopy;

  /// Chat, menu d'appui long : retire un de ses propres messages envoyé il y a moins de 15 minutes (en rouge).
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get chatMenuUnsend;

  /// Chat : libellé lu par le lecteur d'écran pour le voile qui ferme le menu d'appui long.
  ///
  /// In fr, this message translates to:
  /// **'Fermer le menu'**
  String get chatMenuClose;

  /// Chat : message bref après avoir copié un message.
  ///
  /// In fr, this message translates to:
  /// **'Message copié'**
  String get chatCopied;

  /// Chat : message bref après avoir signalé un message.
  ///
  /// In fr, this message translates to:
  /// **'Merci, nous examinons ce message.'**
  String get chatReportThanks;

  /// Chat : titre de la feuille qui liste qui a réagi avec quel émoji.
  ///
  /// In fr, this message translates to:
  /// **'Réactions'**
  String get chatReactionsTitle;

  /// Chat : titre de la feuille qui demande pourquoi on signale un message.
  ///
  /// In fr, this message translates to:
  /// **'Signaler ce message'**
  String get chatReportTitle;

  /// Chat, signalement : motif « arnaque ».
  ///
  /// In fr, this message translates to:
  /// **'Arnaque ou demande d\'argent'**
  String get chatReportReasonScam;

  /// Chat, signalement : motif « harcèlement ».
  ///
  /// In fr, this message translates to:
  /// **'Harcèlement ou propos déplacés'**
  String get chatReportReasonHarassment;

  /// Chat, signalement : motif « contenu inapproprié ».
  ///
  /// In fr, this message translates to:
  /// **'Contenu inapproprié'**
  String get chatReportReasonInappropriate;

  /// Chat, signalement : motif « autre ».
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get chatReportReasonOther;

  /// Chat : titre de la feuille de conseils ouverte par « En savoir plus » sur la carte d'avertissement.
  ///
  /// In fr, this message translates to:
  /// **'Se protéger des arnaques'**
  String get chatScamAdviceTitle;

  /// Chat, conseils anti-arnaque : première ligne.
  ///
  /// In fr, this message translates to:
  /// **'N\'envoyez jamais d\'argent, de carte cadeau ou de cryptomonnaie.'**
  String get chatScamAdviceMoney;

  /// Chat, conseils anti-arnaque : deuxième ligne. WhatsApp, Telegram et Signal sont des noms d'applications.
  ///
  /// In fr, this message translates to:
  /// **'Méfiez-vous de qui vous demande de poursuivre sur WhatsApp, Telegram ou Signal très vite.'**
  String get chatScamAdviceApps;

  /// Chat, conseils anti-arnaque : troisième ligne.
  ///
  /// In fr, this message translates to:
  /// **'Faites un appel vidéo avant de vous engager.'**
  String get chatScamAdviceVideo;

  /// Chat, conseils anti-arnaque : dernière ligne.
  ///
  /// In fr, this message translates to:
  /// **'En cas de doute, signalez la conversation : nous l\'examinons.'**
  String get chatScamAdviceReport;

  /// Chat : titre (14 px) de la carte d'avertissement sous un message suspect.
  ///
  /// In fr, this message translates to:
  /// **'Restez prudent'**
  String get chatScamTitle;

  /// Chat : phrase de la carte d'avertissement sous un message suspect.
  ///
  /// In fr, this message translates to:
  /// **'Ne transférez jamais d\'argent à quelqu\'un que vous n\'avez pas rencontré.'**
  String get chatScamBody;

  /// Chat : lien de la carte d'avertissement qui ouvre les conseils.
  ///
  /// In fr, this message translates to:
  /// **'En savoir plus'**
  String get chatScamLearnMore;

  /// Chat : pastille au centre d'une photo reçue et floutée ; un toucher la dévoile.
  ///
  /// In fr, this message translates to:
  /// **'Voir la photo'**
  String get chatPhotoReveal;

  /// Chat : message bref quand un message vocal ne peut pas être lu.
  ///
  /// In fr, this message translates to:
  /// **'Lecture impossible'**
  String get chatVoicePlayFailed;

  /// Chat : libellé lu par le lecteur d'écran du bouton lecture d'un message vocal.
  ///
  /// In fr, this message translates to:
  /// **'Lire le message vocal'**
  String get chatVoicePlay;

  /// Chat : libellé lu par le lecteur d'écran du bouton pause d'un message vocal.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en pause'**
  String get chatVoicePause;

  /// Chat : texte d'aide du champ de saisie du message.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get chatComposerHint;

  /// Chat : info-bulle du bouton « + » qui ouvre le choix de photos.
  ///
  /// In fr, this message translates to:
  /// **'Joindre des photos'**
  String get chatComposerAttach;

  /// Chat : libellé lu par le lecteur d'écran du bouton flèche qui envoie le texte.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get chatComposerSend;

  /// Chat : libellé lu par le lecteur d'écran du bouton qui envoie un vocal verrouillé.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le vocal'**
  String get chatComposerSendVoice;

  /// Chat : message bref quand une photo n'a pas pu être ajoutée (autorisations refusées).
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter la photo. Vérifiez les autorisations.'**
  String get chatComposerPhotoError;

  /// Chat : message bref quand l'accès au micro est refusé.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez le micro dans les réglages pour envoyer un vocal.'**
  String get chatComposerMicDenied;

  /// Chat : message bref quand l'enregistrement n'a pas pu démarrer.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer pour le moment. Réessayez.'**
  String get chatComposerRecordError;

  /// Chat : message bref quand le vocal est trop court.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez le micro plus longtemps pour enregistrer.'**
  String get chatComposerHoldLonger;

  /// Chat : message bref quand on touche le micro sans le maintenir.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez le micro pour enregistrer un vocal.'**
  String get chatComposerHoldHint;

  /// Chat : libellé lu par le lecteur d'écran du bouton micro.
  ///
  /// In fr, this message translates to:
  /// **'Maintenir pour enregistrer un vocal'**
  String get chatMicSemantics;

  /// Chat, feuille des pièces jointes : ligne qui ouvre la galerie.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get chatAttachPhotos;

  /// Chat, feuille des pièces jointes : sous « Photos », combien on peut en choisir.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à 10 à la fois'**
  String get chatAttachPhotosLimit;

  /// Chat, feuille des pièces jointes : ligne qui ouvre l'appareil photo.
  ///
  /// In fr, this message translates to:
  /// **'Appareil photo'**
  String get chatAttachCamera;

  /// Chat : info-bulle de la corbeille qui annule un enregistrement verrouillé.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'enregistrement'**
  String get chatRecordingCancel;

  /// Chat, enregistrement : indication quand le doigt est assez loin pour annuler (rouge, 12 px).
  ///
  /// In fr, this message translates to:
  /// **'Relâchez pour annuler'**
  String get chatRecordingRelease;

  /// Chat, enregistrement : indication pendant qu'on maintient le micro. Le signe ‹ pointe vers le côté où glisser pour annuler ; il se retourne tout seul de droite à gauche.
  ///
  /// In fr, this message translates to:
  /// **'‹ Glisser pour annuler'**
  String get chatRecordingSlide;

  /// Chat : info-bulle de la croix du bandeau « Réponse à… » au-dessus de la zone de saisie.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réponse'**
  String get chatReplyCancel;

  /// Chat : en haut du bandeau de réponse. {name} est le prénom de l'auteur du message cité.
  ///
  /// In fr, this message translates to:
  /// **'Réponse à {name}'**
  String chatReplyToOther(String name);

  /// Chat : en haut du bandeau de réponse quand le membre répond à l'un de ses propres messages.
  ///
  /// In fr, this message translates to:
  /// **'Réponse à votre message'**
  String get chatReplyToMine;

  /// Chat : erreur 401, la connexion du membre a expiré.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée, reconnectez-vous.'**
  String get chatErrorSessionExpired;

  /// Chat : un message ne peut plus être retiré (au-delà de 15 minutes, ou pas le sien).
  ///
  /// In fr, this message translates to:
  /// **'Ce message ne peut plus être retiré.'**
  String get chatErrorCannotUnsend;

  /// Chat : la conversation n'existe plus ou n'est plus accessible (404).
  ///
  /// In fr, this message translates to:
  /// **'Cette conversation n’est plus disponible.'**
  String get chatErrorConversationGone;

  /// Chat : l'un des deux membres a bloqué l'autre. Aussi affiché à la place de la zone de saisie.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez plus écrire dans cette conversation.'**
  String get chatErrorBlocked;

  /// Chat : le fichier envoyé est trop lourd (413).
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop volumineux.'**
  String get chatErrorTooLarge;

  /// Chat : trop d'envois en peu de temps (429).
  ///
  /// In fr, this message translates to:
  /// **'Trop d’envois, patientez un instant.'**
  String get chatErrorRateLimited;

  /// Chat : le serveur est en panne (5xx).
  ///
  /// In fr, this message translates to:
  /// **'Le serveur est indisponible, réessayez.'**
  String get chatErrorServer;

  /// Chat : le serveur a refusé le fichier (format ou contenu).
  ///
  /// In fr, this message translates to:
  /// **'Fichier refusé, essayez-en un autre.'**
  String get chatErrorFileRejected;

  /// Chat : le serveur a refusé le message (400 ou 422).
  ///
  /// In fr, this message translates to:
  /// **'Message refusé.'**
  String get chatErrorMessageRejected;

  /// Chat : le serveur n'a pas répondu à temps.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé, vérifiez votre connexion.'**
  String get chatErrorTimeout;

  /// Chat : le téléphone n'a pas de connexion.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet.'**
  String get chatErrorNetwork;

  /// Chat : erreur sans cause connue.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue.'**
  String get chatErrorUnknown;

  /// Chat : plus de dix photos choisies pour un seul message.
  ///
  /// In fr, this message translates to:
  /// **'Dix photos au maximum par message.'**
  String get chatErrorTooManyPhotos;

  /// Chat : action impossible sur un message pas encore envoyé (réaction).
  ///
  /// In fr, this message translates to:
  /// **'Ce message n’est pas encore envoyé.'**
  String get chatErrorNotYetSent;

  /// Chat : le message visé n'existe plus.
  ///
  /// In fr, this message translates to:
  /// **'Ce message n’existe plus.'**
  String get chatErrorMessageGone;

  /// Chat : on ne peut retirer que ses propres messages.
  ///
  /// In fr, this message translates to:
  /// **'Seul l’auteur peut retirer un message.'**
  String get chatErrorNotAuthor;

  /// Chat : l'émoji choisi n'est pas l'une des six réactions permises.
  ///
  /// In fr, this message translates to:
  /// **'Réaction indisponible.'**
  String get chatErrorReactionUnavailable;

  /// Chat : l'envoi n'a pas pu démarrer (identité du membre introuvable).
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’envoyer pour le moment.'**
  String get chatErrorSendUnavailable;

  /// Chat : le premier chargement de la conversation a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la conversation.'**
  String get chatErrorLoadFailed;

  /// Bouton qui ferme une boîte de dialogue ou une feuille sans rien faire.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// Bouton qui passe à l'étape suivante.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get commonContinue;

  /// Bouton qui relance une action qui a échoué (chargement, envoi).
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// Bouton ou info-bulle qui ferme un écran, une feuille ou une boîte de dialogue.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// Info-bulle du bouton qui revient à l'écran précédent.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// Erreur : le serveur n'a pas répondu à temps.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé. Vérifiez votre connexion.'**
  String get errorTimeout;

  /// Erreur : le téléphone n'a pas de connexion ou le serveur est injoignable.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Vérifiez votre réseau et réessayez.'**
  String get errorNetwork;

  /// Erreur : le serveur a une panne (HTTP 5xx).
  ///
  /// In fr, this message translates to:
  /// **'Le serveur est indisponible. Réessayez dans un instant.'**
  String get errorServer;

  /// Erreur : la connexion du membre a expiré (HTTP 401), il doit se reconnecter.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée. Reconnectez-vous.'**
  String get errorSessionExpired;

  /// Erreur : le membre n'a pas le droit de faire cette action (HTTP 403).
  ///
  /// In fr, this message translates to:
  /// **'Action non autorisée.'**
  String get errorForbidden;

  /// Erreur : l'élément demandé (profil, message, événement) n'existe plus (HTTP 404).
  ///
  /// In fr, this message translates to:
  /// **'Introuvable : cet élément n\'existe plus.'**
  String get errorNotFound;

  /// Erreur : l'action n'est plus possible, l'état a changé entre-temps (HTTP 409).
  ///
  /// In fr, this message translates to:
  /// **'Cette action n\'est plus possible.'**
  String get errorConflict;

  /// Erreur : la photo ou le fichier envoyé est trop lourd (HTTP 413).
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop volumineux.'**
  String get errorTooLarge;

  /// Erreur : trop de tentatives en peu de temps (HTTP 429).
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patientez un instant.'**
  String get errorRateLimited;

  /// Erreur : le serveur a refusé la demande, données invalides (HTTP 400/422).
  ///
  /// In fr, this message translates to:
  /// **'Demande refusée. Vérifiez les informations saisies.'**
  String get errorInvalid;

  /// Erreur sans cause connue.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get errorUnknown;

  /// Bouton qui enregistre les modifications d'un formulaire.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// Bouton qui supprime un élément (photo, date, activité).
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// Bouton qui retire un élément d'une liste sans le détruire (favori, réaction).
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get commonRemove;

  /// Bouton qui saute une étape facultative (onboarding, question).
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get commonSkip;

  /// Bouton court qui ouvre le détail d'un élément.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get commonSee;

  /// Bouton qui ouvre la feuille de partage du téléphone.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get commonShare;

  /// Bouton qui signale un membre ou un contenu à la modération.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get commonReport;

  /// Bouton qui referme une boîte de dialogue d'information.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Bouton qui remet une action à plus tard.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get commonLater;

  /// Date relative : le jour même (liste de messages, événements).
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get commonToday;

  /// Date relative : la veille.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get commonYesterday;

  /// Champ de profil laissé vide par le membre.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get commonNotSpecified;

  /// Titre d'un écran ou d'un bloc dont le chargement a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get commonLoadError;

  /// Suggestions de premier message : titre de la carte.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d\'inspiration ?'**
  String get icebreakerWidgetTitle;

  /// Suggestions de premier message : sous-titre de la carte.
  ///
  /// In fr, this message translates to:
  /// **'Voici quelques idées pour briser la glace'**
  String get icebreakerWidgetSubtitle;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Mot qui remplace le sujet de la question quand on n'en trouve pas (« …à la question sur ça »).
  ///
  /// In fr, this message translates to:
  /// **'ça'**
  String get icebreakerTopicFallback;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Réagit à une réponse du profil. {promptText} est la question du profil ; {followUp} est une phrase courte qui conclut.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai adoré ta réponse à \"{promptText}\". {followUp}'**
  String icebreakerPromptLoved(String promptText, String followUp);

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Réagit à une réponse du profil. {promptText} est la question du profil.
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse sur \"{promptText}\" m\'a fait sourire. Tu peux m\'en dire plus ?'**
  String icebreakerPromptSmiled(String promptText);

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Curiosité sur une réponse du profil. {answer} est la réponse (raccourcie), {topic} deux mots de la question (ou « ça »).
  ///
  /// In fr, this message translates to:
  /// **'Je suis curieux(se) de savoir pourquoi tu as répondu \"{answer}\" à la question sur {topic}'**
  String icebreakerPromptCurious(String answer, String topic);

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Phrase courte qui conclut la réaction à une réponse du profil.
  ///
  /// In fr, this message translates to:
  /// **'Ça m\'intrigue.'**
  String get icebreakerFollowUpIntrigued;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Phrase courte qui conclut la réaction à une réponse du profil.
  ///
  /// In fr, this message translates to:
  /// **'J\'aimerais en savoir plus.'**
  String get icebreakerFollowUpKnowMore;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Phrase courte qui conclut la réaction à une réponse du profil.
  ///
  /// In fr, this message translates to:
  /// **'Tu me racontes ?'**
  String get icebreakerFollowUpTellMe;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Phrase courte qui conclut la réaction à une réponse du profil.
  ///
  /// In fr, this message translates to:
  /// **'Ça a l\'air intéressant.'**
  String get icebreakerFollowUpInteresting;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : voyage (la bio en parle).
  ///
  /// In fr, this message translates to:
  /// **'Tu as voyagé où récemment ? J\'adorerais entendre tes histoires.'**
  String get icebreakerBioTravelRecent;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : voyage.
  ///
  /// In fr, this message translates to:
  /// **'Quelle est ta prochaine destination de rêve ?'**
  String get icebreakerBioTravelDream;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : musique.
  ///
  /// In fr, this message translates to:
  /// **'Quel genre de musique tu écoutes en ce moment ?'**
  String get icebreakerBioMusicGenre;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : musique.
  ///
  /// In fr, this message translates to:
  /// **'Tu as été à un bon concert récemment ?'**
  String get icebreakerBioMusicConcert;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : cuisine.
  ///
  /// In fr, this message translates to:
  /// **'Tu cuisines quoi de bon en ce moment ?'**
  String get icebreakerBioCookingNow;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : cuisine.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi ton plat signature ?'**
  String get icebreakerBioCookingSignature;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : sport.
  ///
  /// In fr, this message translates to:
  /// **'Tu pratiques quel sport ?'**
  String get icebreakerBioSportWhich;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : sport.
  ///
  /// In fr, this message translates to:
  /// **'Tu préfères regarder ou pratiquer ?'**
  String get icebreakerBioSportWatchOrPlay;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : lecture.
  ///
  /// In fr, this message translates to:
  /// **'Tu lis quoi en ce moment ?'**
  String get icebreakerBioReadingNow;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : lecture.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi le dernier livre qui t\'a marqué ?'**
  String get icebreakerBioReadingLastBook;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : cinéma.
  ///
  /// In fr, this message translates to:
  /// **'Tu as vu un bon film récemment ?'**
  String get icebreakerBioCinemaRecent;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : cinéma.
  ///
  /// In fr, this message translates to:
  /// **'Tu préfères cinéma ou séries ?'**
  String get icebreakerBioCinemaOrSeries;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : randonnée.
  ///
  /// In fr, this message translates to:
  /// **'Tu connais de beaux sentiers dans le coin ?'**
  String get icebreakerBioHikingTrails;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : randonnée.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi ta plus belle rando ?'**
  String get icebreakerBioHikingBest;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : photographie.
  ///
  /// In fr, this message translates to:
  /// **'Tu prends des photos de quoi principalement ?'**
  String get icebreakerBioPhotoSubjects;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : photographie.
  ///
  /// In fr, this message translates to:
  /// **'Tu utilises quoi comme appareil ?'**
  String get icebreakerBioPhotoCamera;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : orthodoxe.
  ///
  /// In fr, this message translates to:
  /// **'Tu as une synagogue préférée dans le coin ?'**
  String get icebreakerOrthodoxSynagogue;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : orthodoxe.
  ///
  /// In fr, this message translates to:
  /// **'Comment tu passes généralement Shabbat ?'**
  String get icebreakerOrthodoxShabbat;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : orthodoxe.
  ///
  /// In fr, this message translates to:
  /// **'Tu as un restaurant casher préféré ?'**
  String get icebreakerOrthodoxKosherRestaurant;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : traditionaliste (massorti).
  ///
  /// In fr, this message translates to:
  /// **'Quelles traditions juives sont les plus importantes pour toi ?'**
  String get icebreakerTraditionalTraditions;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : traditionaliste (massorti).
  ///
  /// In fr, this message translates to:
  /// **'Tu célèbres Shabbat comment généralement ?'**
  String get icebreakerTraditionalShabbat;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : traditionaliste (massorti).
  ///
  /// In fr, this message translates to:
  /// **'Tu as une fête juive préférée ?'**
  String get icebreakerTraditionalHoliday;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : laïque.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi ton rapport à la culture juive ?'**
  String get icebreakerSecularCulture;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : laïque.
  ///
  /// In fr, this message translates to:
  /// **'Tu as des traditions familiales que tu gardes ?'**
  String get icebreakerSecularFamilyTraditions;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : laïque.
  ///
  /// In fr, this message translates to:
  /// **'Tu célèbres quelles fêtes ?'**
  String get icebreakerSecularHolidays;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : non précisée.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi ta fête juive préférée ?'**
  String get icebreakerDefaultHoliday;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : non précisée.
  ///
  /// In fr, this message translates to:
  /// **'Tu as des traditions familiales spéciales ?'**
  String get icebreakerDefaultFamilyTraditions;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Pratique : non précisée.
  ///
  /// In fr, this message translates to:
  /// **'Tu as grandi dans une famille pratiquante ?'**
  String get icebreakerDefaultPracticingFamily;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : la ville de l'autre membre. {location} est cette ville.
  ///
  /// In fr, this message translates to:
  /// **'Tu connais bien {location} ? Tu me conseilles quoi ?'**
  String icebreakerLocationKnowWell(String location);

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : la ville de l'autre membre. {location} est cette ville.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi ton coin préféré à {location} ?'**
  String icebreakerLocationFavoriteSpot(String location);

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : la ville de l'autre membre. {location} est cette ville.
  ///
  /// In fr, this message translates to:
  /// **'Tu es originaire de {location} ou tu t\'y es installé(e) ?'**
  String icebreakerLocationOriginallyFrom(String location);

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : la ville de l'autre membre. {location} est cette ville.
  ///
  /// In fr, this message translates to:
  /// **'Il y a un bon restaurant que tu recommandes à {location} ?'**
  String icebreakerLocationRestaurant(String location);

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : question générale, sans lien avec le profil.
  ///
  /// In fr, this message translates to:
  /// **'Si tu pouvais dîner avec n\'importe qui, vivant ou mort, ce serait qui ?'**
  String get icebreakerGenericDinnerGuest;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : question générale, sans lien avec le profil.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi ta définition d\'une journée parfaite ?'**
  String get icebreakerGenericPerfectDay;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : question générale, sans lien avec le profil.
  ///
  /// In fr, this message translates to:
  /// **'Tu as un talent caché que peu de gens connaissent ?'**
  String get icebreakerGenericHiddenTalent;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : question générale, sans lien avec le profil.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi le truc le plus spontané que tu aies fait ?'**
  String get icebreakerGenericSpontaneous;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : question générale, sans lien avec le profil.
  ///
  /// In fr, this message translates to:
  /// **'Tu préfères vacances à la mer ou à la montagne ?'**
  String get icebreakerGenericSeaOrMountain;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : question générale, sans lien avec le profil.
  ///
  /// In fr, this message translates to:
  /// **'Si tu gagnais au loto demain, tu ferais quoi en premier ?'**
  String get icebreakerGenericLottery;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : question générale, sans lien avec le profil.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi ton guilty pleasure ?'**
  String get icebreakerGenericGuiltyPleasure;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : question générale, sans lien avec le profil.
  ///
  /// In fr, this message translates to:
  /// **'Tu as un rêve que tu n\'as pas encore réalisé ?'**
  String get icebreakerGenericDream;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : question générale, sans lien avec le profil.
  ///
  /// In fr, this message translates to:
  /// **'C\'est quoi le meilleur conseil qu\'on t\'ait donné ?'**
  String get icebreakerGenericBestAdvice;

  /// Brouillon de premier message que le membre envoie à un autre membre (on se tutoie entre membres). Sujet : question générale, sans lien avec le profil.
  ///
  /// In fr, this message translates to:
  /// **'Tu préfères petit-déjeuner ou dîner dehors ?'**
  String get icebreakerGenericBreakfastOrDinner;

  /// Réglages : ligne et titre de la feuille où l'on choisit la langue de l'app.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// Réglages, choix de langue : suivre la langue réglée sur le téléphone plutôt qu'une langue fixe.
  ///
  /// In fr, this message translates to:
  /// **'Langue du téléphone'**
  String get settingsLanguageSystem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'he', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
