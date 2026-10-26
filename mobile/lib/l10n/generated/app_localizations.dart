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

  /// Connexion : petite étiquette en majuscules espacées au-dessus du logo.
  ///
  /// In fr, this message translates to:
  /// **'Rencontres · Communauté juive'**
  String get authLoginEyebrow;

  /// Connexion : promesse en une phrase sous le logo (largeur 300 px, 3 lignes au plus).
  ///
  /// In fr, this message translates to:
  /// **'Des rencontres sérieuses, entre personnes qui partagent vos valeurs.'**
  String get authLoginTagline;

  /// Connexion : bouton « Sign in with Apple » (iPhone seulement).
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get authLoginApple;

  /// Connexion : bouton de connexion avec le compte Google.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get authLoginGoogle;

  /// Connexion : bouton réservé au développement (versions de test uniquement), jamais montré aux membres.
  ///
  /// In fr, this message translates to:
  /// **'Connexion fictive (dev)'**
  String get authLoginDev;

  /// Connexion : mention légale sous les boutons. {terms} et {privacy} sont deux liens (« Conditions », « Confidentialité ») insérés tels quels dans la phrase.
  ///
  /// In fr, this message translates to:
  /// **'En continuant, vous acceptez les {terms} et la {privacy}.'**
  String authLegal(String terms, String privacy);

  /// Connexion : mot cliquable « Conditions » dans la mention légale (insère dans la phrase {terms}).
  ///
  /// In fr, this message translates to:
  /// **'Conditions'**
  String get authLegalTermsLink;

  /// Connexion : mot cliquable « Confidentialité » dans la mention légale (insère dans la phrase {privacy}).
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get authLegalPrivacyLink;

  /// Connexion et inscription : erreur sans cause connue.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get authErrorGeneric;

  /// Connexion avec Apple ou Google : le membre a fermé la fenêtre de connexion.
  ///
  /// In fr, this message translates to:
  /// **'Connexion annulée.'**
  String get authErrorCancelled;

  /// Connexion avec Apple : proposée sur iPhone et Mac seulement.
  ///
  /// In fr, this message translates to:
  /// **'Cette méthode de connexion n\'est pas disponible sur cet appareil.'**
  String get authErrorUnsupported;

  /// Connexion : bandeau affiché quand l'app a mis fin à la session parce que le compte a été désactivé. {contact} est l'adresse à laquelle écrire, insérée telle quelle.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte est désactivé. Écrivez-nous à {contact}.'**
  String authErrorAccountDisabled(String contact);

  /// Page d'erreur de l'app : titre quand l'adresse demandée n'existe pas.
  ///
  /// In fr, this message translates to:
  /// **'Page introuvable'**
  String get authRouteErrorTitle;

  /// Page d'erreur de l'app : phrase sous le titre.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get authRouteErrorBody;

  /// Page d'erreur de l'app : bouton qui ramène à l'accueil.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get authRouteErrorHome;

  /// Titre de la barre d'en-tête de l'écran Boost. « Boost » est le nom de la fonction (mettre son profil en avant 30 minutes).
  ///
  /// In fr, this message translates to:
  /// **'Boost'**
  String get boostTitle;

  /// Titre de la carte colorée quand un Boost est en cours.
  ///
  /// In fr, this message translates to:
  /// **'Boost actif'**
  String get boostHeadlineActive;

  /// Titre de la carte colorée quand aucun Boost n'est en cours.
  ///
  /// In fr, this message translates to:
  /// **'Boostez votre profil'**
  String get boostHeadlineIdle;

  /// Sous le titre de la carte colorée, hors Boost en cours : la promesse de la fonction.
  ///
  /// In fr, this message translates to:
  /// **'Soyez vu par 10x plus de personnes.'**
  String get boostTagline;

  /// Temps restant d'un Boost en cours, sous le titre de la carte colorée. {minutes} est un entier de minutes (« min » abrégé).
  ///
  /// In fr, this message translates to:
  /// **'{minutes, plural, one{{minutes} min restante} other{{minutes} min restantes}}'**
  String boostMinutesLeft(int minutes);

  /// Titre de la carte de statistiques d'un Boost en cours.
  ///
  /// In fr, this message translates to:
  /// **'Pendant ce boost'**
  String get boostDuringTitle;

  /// Légende sous le nombre de vues du profil pendant le Boost.
  ///
  /// In fr, this message translates to:
  /// **'Vues'**
  String get boostViews;

  /// Légende sous le nombre de likes reçus pendant le Boost.
  ///
  /// In fr, this message translates to:
  /// **'Likes'**
  String get boostLikes;

  /// Titre de la carte qui liste les avantages du Boost (hors Boost en cours).
  ///
  /// In fr, this message translates to:
  /// **'Avantages du Boost'**
  String get boostBenefitsTitle;

  /// Premier avantage du Boost (une ligne, après une icône).
  ///
  /// In fr, this message translates to:
  /// **'Apparaissez en premier dans les suggestions'**
  String get boostBenefitFirst;

  /// Deuxième avantage du Boost. {minutes} est la durée du Boost en minutes (« min » abrégé).
  ///
  /// In fr, this message translates to:
  /// **'10x plus de visibilité pendant {minutes} min'**
  String boostBenefitVisibility(int minutes);

  /// Troisième avantage du Boost.
  ///
  /// In fr, this message translates to:
  /// **'Plus de chances de matcher'**
  String get boostBenefitMatches;

  /// Quatrième avantage du Boost.
  ///
  /// In fr, this message translates to:
  /// **'Stats en temps réel pendant le boost'**
  String get boostBenefitStats;

  /// Gros bouton violet qui active un Boost.
  ///
  /// In fr, this message translates to:
  /// **'Activer le Boost'**
  String get boostActivate;

  /// Sous le bouton d'activation : combien de Boosts le membre peut encore lancer. {count} est un entier.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} boost restant} other{{count} boosts restants}}'**
  String boostRemaining(int count);

  /// Message bref (fond vert) après l'activation d'un Boost depuis l'écran Boost.
  ///
  /// In fr, this message translates to:
  /// **'Boost activé. Votre profil est maintenant en avant.'**
  String get boostActivated;

  /// Message bref (fond rouge) quand l'activation du Boost a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'activation'**
  String get boostActivateFailed;

  /// Titre de l'encart qui propose mazl+ quand il reste au plus un Boost.
  ///
  /// In fr, this message translates to:
  /// **'Boosts illimités'**
  String get boostUpsellTitle;

  /// Sous le titre de l'encart mazl+ (12 px, une ligne). « mazl+ » est un nom de marque.
  ///
  /// In fr, this message translates to:
  /// **'Boostez sans limite avec mazl+'**
  String get boostUpsellBody;

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

  /// Message court quand un lien (page web ou adresse e-mail) ne peut pas s'ouvrir sur le téléphone. {target} est l'adresse ou l'e-mail visé, affiché tel quel.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir {target} pour le moment.'**
  String linkOpenError(String target);

  /// Catégorie d'activité : détente, spa, bien-être. Puce de filtre et étiquette de carte.
  ///
  /// In fr, this message translates to:
  /// **'Bien-être'**
  String get coupleFeedCategoryWellness;

  /// Catégorie d'activité : restaurants et cuisine. Étiquette de carte.
  ///
  /// In fr, this message translates to:
  /// **'Gastronomie'**
  String get coupleFeedCategoryGastronomy;

  /// Puce de filtre courte pour la catégorie gastronomie. Doit rester très court (une puce de 80 px environ).
  ///
  /// In fr, this message translates to:
  /// **'Gastro'**
  String get coupleFeedFilterGastronomy;

  /// Catégorie d'activité : spectacles, musées, culture.
  ///
  /// In fr, this message translates to:
  /// **'Culture'**
  String get coupleFeedCategoryCulture;

  /// Catégorie d'activité : sport.
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get coupleFeedCategorySport;

  /// Catégorie d'activité : voyage et escapades. Sert aussi de titre à l'idée « Voyage » du tableau de bord.
  ///
  /// In fr, this message translates to:
  /// **'Voyage'**
  String get coupleFeedCategoryTravel;

  /// Catégorie d'activité : spirituel, étude, tradition.
  ///
  /// In fr, this message translates to:
  /// **'Spirituel'**
  String get coupleFeedCategorySpiritual;

  /// Catégorie d'activité : créer soi-même (DIY, « do it yourself »).
  ///
  /// In fr, this message translates to:
  /// **'DIY'**
  String get coupleFeedCategoryDiy;

  /// Catégorie d'activité : moments romantiques.
  ///
  /// In fr, this message translates to:
  /// **'Romantique'**
  String get coupleFeedCategoryRomantic;

  /// Première puce de chaque barre de filtres : aucun filtre, tout afficher. Très court.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get coupleFeedFilterAll;

  /// Catégorie d'événement pour couples : dîner.
  ///
  /// In fr, this message translates to:
  /// **'Dîner'**
  String get coupleFeedEventCategoryDinner;

  /// Catégorie d'événement : dégustation (vin, fromages...).
  ///
  /// In fr, this message translates to:
  /// **'Dégustation'**
  String get coupleFeedEventCategoryTasting;

  /// Catégorie d'événement : soirée festive.
  ///
  /// In fr, this message translates to:
  /// **'Soirée'**
  String get coupleFeedEventCategoryParty;

  /// Catégorie d'événement : atelier créatif ou pratique.
  ///
  /// In fr, this message translates to:
  /// **'Atelier'**
  String get coupleFeedEventCategoryWorkshop;

  /// Catégorie d'événement : brunch.
  ///
  /// In fr, this message translates to:
  /// **'Brunch'**
  String get coupleFeedEventCategoryBrunch;

  /// Catégorie d'événement : spirituel (étude, Shabbat communautaire).
  ///
  /// In fr, this message translates to:
  /// **'Spirituel'**
  String get coupleFeedEventCategorySpiritual;

  /// Catégorie d'événement : escapade d'un week-end.
  ///
  /// In fr, this message translates to:
  /// **'Week-end'**
  String get coupleFeedEventCategoryTravel;

  /// Catégorie d'événement : concert.
  ///
  /// In fr, this message translates to:
  /// **'Concert'**
  String get coupleFeedEventCategoryConcert;

  /// Catégorie d'événement : soirée jeux.
  ///
  /// In fr, this message translates to:
  /// **'Jeux'**
  String get coupleFeedEventCategoryGame;

  /// Catégorie d'événement inconnue ou absente : libellé par défaut.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get coupleFeedEventCategoryOther;

  /// Prix d'une activité ou d'un événement gratuit, dans une pastille. Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get coupleFeedPriceFree;

  /// Prix d'un événement, par couple. {price} est déjà écrit avec la devise (ex. « 75 € »).
  ///
  /// In fr, this message translates to:
  /// **'{price}/couple'**
  String coupleFeedEventPricePerCouple(String price);

  /// Durée d'une activité de moins d'une heure. {minutes} est un nombre.
  ///
  /// In fr, this message translates to:
  /// **'{minutes}min'**
  String coupleFeedDurationMinutes(int minutes);

  /// Durée d'une activité d'un nombre entier d'heures.
  ///
  /// In fr, this message translates to:
  /// **'{hours}h'**
  String coupleFeedDurationHours(int hours);

  /// Durée d'une activité en heures et minutes.
  ///
  /// In fr, this message translates to:
  /// **'{hours}h{minutes}min'**
  String coupleFeedDurationHoursMinutes(int hours, int minutes);

  /// Note d'une activité suivie du nombre d'avis, sur la fiche détail. {rating} est déjà formatée (ex. « 4,8 »).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, other{{rating} ({count} avis)}}'**
  String coupleFeedRatingWithReviews(String rating, int count);

  /// Pastille : l'activité ou l'événement est casher (kosher). Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Casher'**
  String get coupleFeedKosher;

  /// Pastille : événement mis en avant. Court.
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get coupleFeedFeatured;

  /// Pastille d'accent : l'activité vient d'un partenaire de MAZL.
  ///
  /// In fr, this message translates to:
  /// **'Partenaire MAZL'**
  String get coupleFeedPartnerMazl;

  /// Pastille d'accent sur la carte : réduction de {percent} % chez un partenaire de MAZL.
  ///
  /// In fr, this message translates to:
  /// **'-{percent} % Partenaire MAZL'**
  String coupleFeedPartnerDiscountMazl(int percent);

  /// Pastille d'accent sur la fiche détail : réduction de {percent} % chez un partenaire.
  ///
  /// In fr, this message translates to:
  /// **'-{percent} % Partenaire'**
  String coupleFeedPartnerDiscount(int percent);

  /// Grand titre de l'écran du fil d'activités à deux.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get coupleFeedActivitiesTitle;

  /// Titre de l'écran des activités enregistrées et info-bulle du bouton qui y mène.
  ///
  /// In fr, this message translates to:
  /// **'Activités sauvegardées'**
  String get coupleFeedSavedTitle;

  /// Titre de l'état vide du fil d'activités.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité pour le moment'**
  String get coupleFeedActivitiesEmptyTitle;

  /// Phrase sous le titre de l'état vide du fil d'activités.
  ///
  /// In fr, this message translates to:
  /// **'De nouvelles idées arrivent bientôt.'**
  String get coupleFeedActivitiesEmptyLine;

  /// Bouton de l'état vide : recharger le fil.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get coupleFeedRefresh;

  /// Info-bulle du bouton rond « i » qui ouvre la fiche détail d'une activité.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail'**
  String get coupleFeedSeeDetail;

  /// Message en bas d'écran après avoir glissé une activité vers le haut. Une ligne ; {title} peut être long.
  ///
  /// In fr, this message translates to:
  /// **'{title} sauvegardé'**
  String coupleFeedActivitySavedSnack(String title);

  /// Erreur : la sauvegarde d'une activité du fil a échoué ; la carte revient.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de sauvegarder « {title} ». Réessayez.'**
  String coupleFeedActivitySaveCardError(String title);

  /// Erreur : le passage d'une activité du fil a échoué ; la carte revient.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de passer « {title} ». Réessayez.'**
  String coupleFeedActivityPassCardError(String title);

  /// Titre de l'écran quand l'activité n'existe plus.
  ///
  /// In fr, this message translates to:
  /// **'Activité introuvable'**
  String get coupleFeedActivityNotFoundTitle;

  /// Phrase sous le titre quand l'activité n'existe plus.
  ///
  /// In fr, this message translates to:
  /// **'Elle n\'est plus proposée.'**
  String get coupleFeedActivityNotFoundLine;

  /// Erreur : retirer l'activité de la liste enregistrée a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de retirer cette activité. Réessayez.'**
  String get coupleFeedActivityRemoveError;

  /// Erreur : enregistrer l'activité a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de sauvegarder cette activité. Réessayez.'**
  String get coupleFeedActivitySaveError;

  /// Message en bas d'écran après avoir enregistré l'activité depuis sa fiche.
  ///
  /// In fr, this message translates to:
  /// **'Activité sauvegardée'**
  String get coupleFeedActivitySavedConfirm;

  /// Message en bas d'écran après avoir copié un code promo ; {code} est le code.
  ///
  /// In fr, this message translates to:
  /// **'Code {code} copié'**
  String coupleFeedCodeCopied(String code);

  /// Info-bulle du bouton marque-page quand l'activité est déjà enregistrée.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des activités sauvegardées'**
  String get coupleFeedRemoveFromSaved;

  /// Texte envoyé par le partage de la fiche d'une activité ; {title} est le nom de l'activité.
  ///
  /// In fr, this message translates to:
  /// **'Idée de date pour nous : \"{title}\" (via MAZL)'**
  String coupleFeedActivityShareText(String title);

  /// Petit titre (petites majuscules) au-dessus du code promo d'un partenaire.
  ///
  /// In fr, this message translates to:
  /// **'Code promo MAZL'**
  String get coupleFeedPromoCodeLabel;

  /// Info-bulle du bouton qui copie le code promo.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get coupleFeedCopyCode;

  /// Titre de section (petites majuscules) au-dessus de la description d'une activité ou d'un événement.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get coupleFeedDescription;

  /// Titre de section (petites majuscules) au-dessus des mots-clés d'une activité.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get coupleFeedTags;

  /// Titre de section ou nom de ligne : adresse du lieu.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get coupleFeedAddress;

  /// Titre de section au-dessus des boutons d'appel et de site web.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get coupleFeedContact;

  /// Bouton contour : appeler le téléphone de l'activité (moitié de la largeur).
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get coupleFeedCall;

  /// Bouton contour : ouvrir le site de l'activité (moitié de la largeur).
  ///
  /// In fr, this message translates to:
  /// **'Site web'**
  String get coupleFeedWebsite;

  /// Petit texte au-dessus du prix, dans la barre du bas de la fiche d'une activité.
  ///
  /// In fr, this message translates to:
  /// **'À partir de'**
  String get coupleFeedFromPrice;

  /// Bouton principal de la fiche d'une activité : ouvrir la page de réservation.
  ///
  /// In fr, this message translates to:
  /// **'Réserver'**
  String get coupleFeedBook;

  /// Titre de la boîte de dialogue qui demande de retirer une activité enregistrée.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la liste ?'**
  String get coupleFeedSavedRemoveTitle;

  /// Corps de la boîte de dialogue de retrait d'une activité enregistrée ; {title} est son nom.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous retirer \"{title}\" de vos activités sauvegardées ?'**
  String coupleFeedSavedRemoveBody(String title);

  /// Message en bas d'écran après le retrait d'une activité enregistrée.
  ///
  /// In fr, this message translates to:
  /// **'Activité retirée'**
  String get coupleFeedSavedRemoved;

  /// Erreur : le retrait d'une activité enregistrée a échoué ; la ligne revient.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de retirer « {title} ». Réessayez.'**
  String coupleFeedSavedRemoveError(String title);

  /// Titre de l'état vide des activités enregistrées.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité sauvegardée'**
  String get coupleFeedSavedEmptyTitle;

  /// Phrase de l'état vide : explique le geste pour enregistrer (glisser vers le haut).
  ///
  /// In fr, this message translates to:
  /// **'Glissez une carte vers le haut pour la garder.'**
  String get coupleFeedSavedEmptyLine;

  /// Bouton de l'état vide : retourner au fil d'activités.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir des activités'**
  String get coupleFeedSavedEmptyAction;

  /// Grand titre de l'écran des événements pour couples.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get coupleFeedEventsTitle;

  /// Premier onglet de l'écran des événements : les événements à venir. Court.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get coupleFeedEventsUpcoming;

  /// Second onglet : les événements où le couple est inscrit, avec leur nombre {count} entre parenthèses. Court.
  ///
  /// In fr, this message translates to:
  /// **'Inscrits ({count})'**
  String coupleFeedEventsRegisteredTab(int count);

  /// Titre de l'état vide de l'onglet des événements à venir.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement disponible'**
  String get coupleFeedEventsEmptyAll;

  /// Titre de l'état vide de l'onglet des inscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'êtes inscrit à aucun événement'**
  String get coupleFeedEventsEmptyRegistered;

  /// Bouton de l'état vide des inscriptions : revenir aux événements à venir.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir les événements'**
  String get coupleFeedEventsDiscover;

  /// Message vert après l'inscription depuis la liste ; {title} est le nom de l'événement.
  ///
  /// In fr, this message translates to:
  /// **'Inscrits à \"{title}\"'**
  String coupleFeedEventRegisteredSnack(String title);

  /// Message vert après l'inscription depuis la fiche d'un événement ; {title} est son nom.
  ///
  /// In fr, this message translates to:
  /// **'Inscrits à « {title} »'**
  String coupleFeedEventRegisteredSnackDetail(String title);

  /// Erreur : l'inscription à un événement a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Inscription impossible. Réessayez.'**
  String get coupleFeedEventRegisterError;

  /// Erreur : l'annulation d'une inscription a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'annuler l\'inscription. Réessayez.'**
  String get coupleFeedEventCancelError;

  /// Titre de la boîte de dialogue qui demande d'annuler une inscription.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'inscription ?'**
  String get coupleFeedEventCancelTitle;

  /// Corps de la boîte de dialogue d'annulation d'inscription ; {title} est le nom de l'événement.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment annuler votre inscription à \"{title}\" ?'**
  String coupleFeedEventCancelBody(String title);

  /// Bouton de la boîte de dialogue d'annulation : garder l'inscription. Très court.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get coupleFeedEventCancelNo;

  /// Bouton rouge de la boîte de dialogue d'annulation : confirmer l'annulation. Court.
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler'**
  String get coupleFeedEventCancelYes;

  /// Message en bas d'écran après l'annulation d'une inscription.
  ///
  /// In fr, this message translates to:
  /// **'Inscription annulée'**
  String get coupleFeedEventCancelled;

  /// Texte rouge et libellé de bouton : l'événement n'a plus de place. Court.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get coupleFeedEventFull;

  /// Nombre de places restantes, sur une carte d'événement, à côté d'une icône. Très court.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} place} other{{count} places}}'**
  String coupleFeedEventSpots(int count);

  /// Nombre de places restantes, sur la fiche d'un événement, à droite du prix.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} place restante} other{{count} places restantes}}'**
  String coupleFeedEventSpotsLeft(int count);

  /// Bouton plein : s'inscrire à un événement.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get coupleFeedEventRegister;

  /// Bouton contour de la fiche d'un événement : annuler son inscription.
  ///
  /// In fr, this message translates to:
  /// **'Annuler mon inscription'**
  String get coupleFeedEventCancelMine;

  /// Titre de l'écran quand l'événement n'existe plus.
  ///
  /// In fr, this message translates to:
  /// **'Événement introuvable'**
  String get coupleFeedEventNotFoundTitle;

  /// Phrase sous le titre quand l'événement n'existe plus.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'est plus proposé.'**
  String get coupleFeedEventNotFoundLine;

  /// Nom de ligne de la fiche d'un événement : le lieu (à gauche), la valeur est à droite.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get coupleFeedEventFactPlace;

  /// Nom de ligne de la fiche d'un événement : la tenue demandée.
  ///
  /// In fr, this message translates to:
  /// **'Tenue'**
  String get coupleFeedEventFactDressCode;

  /// Nom de ligne de la fiche d'un événement : qui l'organise.
  ///
  /// In fr, this message translates to:
  /// **'Organisé par'**
  String get coupleFeedEventFactOrganizer;

  /// Titre de section de la fiche d'un événement : ce que le prix comprend.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui est inclus'**
  String get coupleFeedEventIncluded;

  /// Titre de l'écran d'erreur quand le contenu à deux n'a pas pu être chargé.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible'**
  String get coupleFeedLoadFailedTitle;

  /// Onglet de la barre du bas de l'espace couple : les activités à deux. Libellé court, une ligne sous l'icône.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get coupleSpaceTabActivities;

  /// Onglet de la barre du bas de l'espace couple : le calendrier juif. Libellé court, une ligne sous l'icône.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get coupleSpaceTabCalendar;

  /// Onglet de la barre du bas de l'espace couple : les événements proposés aux couples. Libellé court, une ligne sous l'icône.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get coupleSpaceTabEvents;

  /// Onglet de la barre du bas de l'espace couple : l'espace privé du couple (souvenirs, bucket list, dates). Libellé court, une ligne sous l'icône.
  ///
  /// In fr, this message translates to:
  /// **'Notre espace'**
  String get coupleSpaceTabSpace;

  /// Titre de l'écran « Notre espace » (l'espace privé du couple).
  ///
  /// In fr, this message translates to:
  /// **'Notre espace'**
  String get coupleSpaceTitle;

  /// Info-bulle du bouton rond en haut de « Notre espace » qui ouvre les réglages du mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get coupleSpaceSettingsTooltip;

  /// Nom affiché pour le membre quand il n'a pas de nom, dans l'en-tête « Vous & Votre Moitié ».
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get coupleSpaceYou;

  /// Nom affiché pour le partenaire quand son nom est inconnu, dans l'en-tête du couple. « Votre Moitié » = l'autre moitié, avec tendresse.
  ///
  /// In fr, this message translates to:
  /// **'Votre Moitié'**
  String get coupleSpacePartnerFallback;

  /// En-tête du couple : depuis combien de jours le couple est ensemble. {count} est toujours au moins 1.
  ///
  /// In fr, this message translates to:
  /// **'Ensemble depuis {count, plural, one{{count} jour} other{{count} jours}}'**
  String coupleSpaceTogetherSince(int count);

  /// En-tête du couple quand la date de début est inconnue ou aujourd'hui.
  ///
  /// In fr, this message translates to:
  /// **'Votre histoire commence'**
  String get coupleSpaceStoryBegins;

  /// Tuile de chiffre : nombre d'activités sauvegardées. Le saut de ligne est voulu ; chaque ligne tient dans environ 80 px (police 12).
  ///
  /// In fr, this message translates to:
  /// **'Activités\nsauvegardées'**
  String get coupleSpaceStatSavedActivities;

  /// Tuile de chiffre : nombre d'événements auxquels le couple est inscrit. Le saut de ligne est voulu ; chaque ligne tient dans environ 80 px (police 12).
  ///
  /// In fr, this message translates to:
  /// **'Événements\nà venir'**
  String get coupleSpaceStatUpcomingEvents;

  /// Tuile de chiffre : nombre de souvenirs créés. Le saut de ligne est voulu ; chaque ligne tient dans environ 80 px (police 12).
  ///
  /// In fr, this message translates to:
  /// **'Souvenirs\ncréés'**
  String get coupleSpaceStatMemories;

  /// Titre de la section des trois raccourcis d'ajout (souvenir, bucket list, date).
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get coupleSpaceQuickActions;

  /// Raccourci : ajouter un souvenir. Le saut de ligne est voulu ; chaque ligne tient dans environ 80 px (police 12).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter\nun souvenir'**
  String get coupleSpaceQuickAddMemory;

  /// Raccourci : ajouter un objectif à la bucket list (liste d'expériences à vivre ensemble). Le saut de ligne est voulu ; chaque ligne tient dans environ 80 px (police 12).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à\nla bucket list'**
  String get coupleSpaceQuickAddBucket;

  /// Raccourci : ajouter une date importante (anniversaire, fête). Le saut de ligne est voulu ; chaque ligne tient dans environ 80 px (police 12).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter\nune date'**
  String get coupleSpaceQuickAddDate;

  /// Titre de la section des souvenirs du couple.
  ///
  /// In fr, this message translates to:
  /// **'Nos souvenirs'**
  String get coupleSpaceMemoriesTitle;

  /// État vide de la section des souvenirs : titre.
  ///
  /// In fr, this message translates to:
  /// **'Aucun souvenir pour l\'instant'**
  String get coupleSpaceMemoriesEmptyTitle;

  /// État vide de la section des souvenirs : invitation à en ajouter.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos premiers souvenirs ensemble.'**
  String get coupleSpaceMemoriesEmptyHint;

  /// Titre de la section « bucket list » (liste d'expériences à vivre ensemble). « bucket list » est un anglicisme courant en français.
  ///
  /// In fr, this message translates to:
  /// **'Bucket list'**
  String get coupleSpaceBucketTitle;

  /// Titre de la section bucket list quand elle contient des objectifs : {done} réalisés sur {total}.
  ///
  /// In fr, this message translates to:
  /// **'Bucket list · {done}/{total}'**
  String coupleSpaceBucketProgress(int done, int total);

  /// État vide de la bucket list : titre.
  ///
  /// In fr, this message translates to:
  /// **'Votre bucket list est vide'**
  String get coupleSpaceBucketEmptyTitle;

  /// État vide de la bucket list : invitation à ajouter des expériences.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des expériences à vivre ensemble.'**
  String get coupleSpaceBucketEmptyHint;

  /// Titre de la section des dates importantes du couple (anniversaires, fêtes).
  ///
  /// In fr, this message translates to:
  /// **'Dates importantes'**
  String get coupleSpaceDatesTitle;

  /// Bouton texte à droite du titre « Dates importantes » : ouvre le calendrier complet.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get coupleSpaceSeeAll;

  /// État vide de la section des dates importantes : titre.
  ///
  /// In fr, this message translates to:
  /// **'Aucune date importante'**
  String get coupleSpaceDatesEmptyTitle;

  /// État vide de la section des dates importantes : invitation à en ajouter.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos anniversaires, fêtes, etc.'**
  String get coupleSpaceDatesEmptyHint;

  /// Message bref (snackbar) quand un objectif de la bucket list est marqué comme accompli.
  ///
  /// In fr, this message translates to:
  /// **'Objectif accompli'**
  String get coupleSpaceGoalDone;

  /// Message d'erreur (snackbar) quand un objectif de la bucket list n'a pas pu être marqué comme accompli.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de valider cet objectif. Réessayez.'**
  String get coupleSpaceGoalFailed;

  /// Message d'erreur (snackbar) quand l'actualisation de l'espace échoue ; les anciennes données restent affichées. {reason} est la cause, une phrase déjà traduite.
  ///
  /// In fr, this message translates to:
  /// **'Actualisation impossible. {reason}'**
  String coupleSpaceRefreshFailed(String reason);

  /// Titre de l'état d'erreur d'un écran du mode couple (activités, événements, espace) ; une phrase explique la cause dessous et un bouton « Réessayer ».
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible'**
  String get coupleSpaceLoadFailedTitle;

  /// Bouton principal des trois feuilles d'ajout (souvenir, bucket list, date).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get coupleSpaceSheetAdd;

  /// Titre de la feuille d'ajout d'un souvenir.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un souvenir'**
  String get coupleSpaceAddMemoryTitle;

  /// Libellé du champ titre (souvenir, date importante).
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get coupleSpaceFieldTitle;

  /// Libellé du champ description d'un souvenir.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get coupleSpaceFieldDescription;

  /// Titre de la feuille d'ajout d'un objectif à la bucket list.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à la bucket list'**
  String get coupleSpaceAddBucketTitle;

  /// Libellé du champ de la feuille bucket list : ce que le couple veut vivre.
  ///
  /// In fr, this message translates to:
  /// **'Que voulez-vous faire ensemble ?'**
  String get coupleSpaceBucketFieldLabel;

  /// Exemple grisé dans le champ de la bucket list. « Ex: » abrège « exemple ».
  ///
  /// In fr, this message translates to:
  /// **'Ex: Voir les aurores boréales'**
  String get coupleSpaceBucketFieldHint;

  /// Titre de la feuille d'ajout d'une date importante.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une date importante'**
  String get coupleSpaceAddDateTitle;

  /// Exemple grisé dans le champ titre d'une date importante. « Ex: » abrège « exemple ».
  ///
  /// In fr, this message translates to:
  /// **'Ex: Notre anniversaire'**
  String get coupleSpaceDateFieldHint;

  /// Libellé de la ligne qui ouvre le sélecteur de date, dans la feuille d'ajout d'une date importante.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get coupleSpaceFieldDate;

  /// Erreur affichée dans une feuille d'ajout quand le serveur refuse. {reason} est la cause, une phrase déjà traduite.
  ///
  /// In fr, this message translates to:
  /// **'Ajout impossible. {reason}'**
  String coupleSpaceAddFailed(String reason);

  /// Titre de l'écran où l'on choisit un match pour activer le mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Mode couple'**
  String get coupleSpaceSetupTitle;

  /// Titre de la liste des matchs, au-dessus des personnes que l'on peut inviter en mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Avec qui ?'**
  String get coupleSpaceSetupWho;

  /// Bouton qui envoie la demande de mode couple à la personne choisie.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get coupleSpaceSetupSend;

  /// État vide de la liste des matchs sur l'écran du mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Aucun match pour l\'instant.'**
  String get coupleSpaceSetupNoMatches;

  /// Erreur quand la liste des matchs ne se charge pas, sur l'écran du mode couple ; un bouton « Réessayer » suit.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos matchs.'**
  String get coupleSpaceSetupMatchesError;

  /// Titre de la confirmation après l'envoi d'une demande de mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get coupleSpaceSetupSentTitle;

  /// Confirmation d'une demande de mode couple envoyée : {name} est la personne invitée, qui doit accepter.
  ///
  /// In fr, this message translates to:
  /// **'{name} doit accepter. Nous vous préviendrons dès sa réponse.'**
  String coupleSpaceSetupSentBody(String name);

  /// Confirmation d'une demande de mode couple envoyée quand le nom de la personne invitée est inconnu.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne doit accepter. Nous vous préviendrons dès sa réponse.'**
  String get coupleSpaceSetupSentBodyAnonymous;

  /// Bouton qui ferme la confirmation de la demande envoyée.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get coupleSpaceSetupGotIt;

  /// Bouton qui retire la demande de mode couple encore en attente.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la demande'**
  String get coupleSpaceSetupCancelRequest;

  /// Grand titre de l'écran de célébration quand le mode couple vient de s'activer. Le texte hébreu « מזל טוב » est affiché au-dessus, sauf en hébreu où il est ce titre.
  ///
  /// In fr, this message translates to:
  /// **'Mazal tov'**
  String get coupleSpaceMazelTovTitle;

  /// Message de l'écran de célébration : félicitations au membre et à son partenaire, {name}.
  ///
  /// In fr, this message translates to:
  /// **'Félicitations à vous et à {name}'**
  String coupleSpaceMazelTovCongrats(String name);

  /// Sous-titre de l'écran de célébration. « MAZL » est le nom de l'app et ne se traduit pas.
  ///
  /// In fr, this message translates to:
  /// **'MAZL vous accompagne dans cette nouvelle étape.'**
  String get coupleSpaceMazelTovWelcome;

  /// Bouton de l'écran de célébration : entre dans l'espace couple. Une seule ligne, environ 24 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Commencer notre aventure'**
  String get coupleSpaceMazelTovStart;

  /// Titre de la boîte de dialogue qui s'ouvre quand quelqu'un demande d'activer le mode couple : {name} est la personne qui demande.
  ///
  /// In fr, this message translates to:
  /// **'{name} souhaite activer le mode couple avec vous'**
  String coupleSpaceRequestTitle(String name);

  /// Titre de la même boîte de dialogue quand le nom de la personne qui demande est inconnu.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne souhaite activer le mode couple avec vous'**
  String get coupleSpaceRequestTitleAnonymous;

  /// Bouton qui accepte la demande de mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get coupleSpaceRequestAccept;

  /// Bouton poli qui refuse la demande de mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Non merci'**
  String get coupleSpaceRequestDecline;

  /// Message bref (snackbar) : la demande de mode couple envoyée n'a pas été suivie par {name} (refusée ou laissée sans réponse).
  ///
  /// In fr, this message translates to:
  /// **'{name} n\'a pas donné suite à votre demande.'**
  String coupleSpaceFlowDeclinedNamed(String name);

  /// Message bref (snackbar) : la demande de mode couple envoyée n'a pas abouti, la personne n'est pas nommée.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande n\'a pas abouti.'**
  String get coupleSpaceFlowDeclined;

  /// Message bref (snackbar) : le mode couple a été terminé (par l'autre membre).
  ///
  /// In fr, this message translates to:
  /// **'Le mode couple a pris fin.'**
  String get coupleSpaceFlowEnded;

  /// Message envoyé AUTOMATIQUEMENT, au nom du membre, aux autres conversations quand son couple se forme : il annonce qu'il n'est plus disponible. Écrit à la première personne, sans accord de genre ; le nom de l'app s'écrit « Mazl ».
  ///
  /// In fr, this message translates to:
  /// **'J\'ai trouvé l\'amour sur Mazl. Je ne suis plus disponible. Bonne chance dans votre recherche.'**
  String get coupleSpaceArchiveMessage;

  /// Erreur : le mode couple se propose seulement à une personne avec laquelle il y a un match.
  ///
  /// In fr, this message translates to:
  /// **'Le mode couple ne s\'active qu\'avec un match.'**
  String get coupleSpaceFailNotMatched;

  /// Erreur : l'un des deux membres est déjà en mode couple avec quelqu'un.
  ///
  /// In fr, this message translates to:
  /// **'L\'un de vous est déjà en mode couple.'**
  String get coupleSpaceFailAlreadyInCouple;

  /// Erreur : une demande de mode couple attend déjà une réponse entre ces deux personnes.
  ///
  /// In fr, this message translates to:
  /// **'Une demande est déjà en attente avec cette personne.'**
  String get coupleSpaceFailRequestPending;

  /// Erreur : la demande de mode couple a été répondue ou annulée entre-temps.
  ///
  /// In fr, this message translates to:
  /// **'Cette demande n\'est plus en attente.'**
  String get coupleSpaceFailRequestGone;

  /// Erreur : la personne ne peut pas recevoir de demande (compte supprimé, bloqué).
  ///
  /// In fr, this message translates to:
  /// **'Cette personne n\'est pas disponible.'**
  String get coupleSpaceFailUnavailable;

  /// Erreur : on ne peut pas envoyer une demande de mode couple à soi-même.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas vous envoyer une demande.'**
  String get coupleSpaceFailSelf;

  /// Erreur : le mode couple n'est pas activé pour ce membre (le serveur répond « pas en couple »).
  ///
  /// In fr, this message translates to:
  /// **'Le mode couple n\'est pas actif.'**
  String get coupleSpaceFailNotInCouple;

  /// Erreur : on ne peut pas quitter le mode couple maintenant.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de quitter le mode couple pour le moment.'**
  String get coupleSpaceFailCannotLeave;

  /// Erreur générique d'une action du mode couple, cause inconnue.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue, réessayez dans un instant.'**
  String get coupleSpaceFailUnknown;

  /// Erreur : l'événement n'a plus de place.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement est complet.'**
  String get coupleSpaceFailEventFull;

  /// Erreur : le serveur n'a pas pu répondre à une demande de contenu du mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur n\'a pas pu répondre. Réessayez.'**
  String get coupleSpaceFailServer;

  /// Erreur : la réponse du serveur n'a pas la forme attendue.
  ///
  /// In fr, this message translates to:
  /// **'Réponse inattendue du serveur.'**
  String get coupleSpaceFailUnexpected;

  /// Grand titre de l'écran du calendrier juif.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get coupleSpaceCalendarTitle;

  /// Titre de la liste d'idées d'activités à deux pour le Shabbat de la semaine.
  ///
  /// In fr, this message translates to:
  /// **'Idées pour ce Shabbat'**
  String get coupleSpaceCalendarShabbatIdeas;

  /// Titre de la liste des prochaines fêtes juives.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines fêtes'**
  String get coupleSpaceCalendarUpcoming;

  /// Info-bulle du bouton rond qui affiche le mois précédent du calendrier.
  ///
  /// In fr, this message translates to:
  /// **'Mois précédent'**
  String get coupleSpaceCalendarPrevMonth;

  /// Info-bulle du bouton rond qui affiche le mois suivant du calendrier.
  ///
  /// In fr, this message translates to:
  /// **'Mois suivant'**
  String get coupleSpaceCalendarNextMonth;

  /// Étiquette en capitales sur la carte d'une fête qui a lieu en ce moment. Très court, une ligne.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get coupleSpaceCalendarOngoing;

  /// Étiquette en capitales sur la carte d'une fête dans {count} jours au plus (« J-3 » = dans 3 jours). Très court, une ligne.
  ///
  /// In fr, this message translates to:
  /// **'J-{count}'**
  String coupleSpaceCalendarCountdown(int count);

  /// Petit titre au-dessus des idées d'activités à deux, sur la carte d'une fête.
  ///
  /// In fr, this message translates to:
  /// **'Idées en couple'**
  String get coupleSpaceCalendarIdeas;

  /// Dates d'une fête sur plusieurs jours dans le même mois : du {startDay} au {endDay}, {month} est le mois abrégé (ex. « avr. »). Garder l'ordre habituel de la langue.
  ///
  /// In fr, this message translates to:
  /// **'{startDay} – {endDay} {month}'**
  String coupleSpaceCalendarRangeSameMonth(
    String startDay,
    String endDay,
    String month,
  );

  /// Dates d'une fête sur plusieurs jours à cheval sur deux mois : {start} et {end} sont déjà des dates courtes (ex. « 28 mars », « 4 avr. »).
  ///
  /// In fr, this message translates to:
  /// **'{start} – {end}'**
  String coupleSpaceCalendarRangeOtherMonth(String start, String end);

  /// Titre de la liste des événements (soirées, cours, fêtes).
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get eventsTitle;

  /// Liste des événements : puce de filtre qui montre tous les types.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get eventsFilterAll;

  /// Liste des événements : puce de filtre des fêtes (pluriel).
  ///
  /// In fr, this message translates to:
  /// **'Fêtes'**
  String get eventsFilterHolidays;

  /// Type d'événement : repas ou moment de Shabbat. Puce de filtre et badge d'une carte.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat'**
  String get eventsTypeShabbat;

  /// Type d'événement : dîner de Shabbat. Badge de l'écran de détail.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat Dinner'**
  String get eventsTypeShabbatDinner;

  /// Type d'événement : soirée de rencontres rapides (speed dating).
  ///
  /// In fr, this message translates to:
  /// **'Speed Dating'**
  String get eventsTypeSpeedDating;

  /// Type d'événement : fête juive. Badge d'une carte (singulier).
  ///
  /// In fr, this message translates to:
  /// **'Fête'**
  String get eventsTypeHoliday;

  /// Type d'événement : cours ou conférence.
  ///
  /// In fr, this message translates to:
  /// **'Cours'**
  String get eventsTypeLecture;

  /// Type d'événement : rencontre conviviale.
  ///
  /// In fr, this message translates to:
  /// **'Social'**
  String get eventsTypeSocial;

  /// Type d'événement inconnu ou non classé.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get eventsTypeOther;

  /// Liste des événements : petit texte du bandeau qui apparaît pendant un changement de filtre.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get eventsLoading;

  /// Liste des événements : message quand le chargement échoue et qu'il n'y a rien à montrer.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les événements'**
  String get eventsLoadError;

  /// Liste des événements : titre de l'état vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement'**
  String get eventsEmptyTitle;

  /// Liste des événements : explication de l'état vide, sur deux lignes centrées (le retour à la ligne est voulu).
  ///
  /// In fr, this message translates to:
  /// **'Revenez bientôt pour découvrir\nde nouveaux événements.'**
  String get eventsEmptyHint;

  /// Carte d'événement : « demain », en tête de la ligne de date et sur le badge.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get eventsTomorrow;

  /// Carte d'événement : badge orange qui annonce un événement dans quelques jours (2 ou 3). Très court, abrégé.
  ///
  /// In fr, this message translates to:
  /// **'Dans {days}j'**
  String eventsInDays(int days);

  /// Carte d'événement : la date puis l'heure. {date} est déjà écrite, par exemple « samedi 24 octobre » ou « Demain ».
  ///
  /// In fr, this message translates to:
  /// **'{date} à {time}'**
  String eventsDateAtTime(String date, String time);

  /// Événement gratuit : badge de prix et ligne Prix.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get eventsFree;

  /// Carte d'événement sans limite de places : nombre de participants.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 participants} one{{count} participant} other{{count} participants}}'**
  String eventsAttendeesCount(int count);

  /// Carte et détail d'événement : petit badge orange quand il reste peu de places.
  ///
  /// In fr, this message translates to:
  /// **'Presque complet'**
  String get eventsAlmostFull;

  /// Détail d'événement : badge rouge et bouton désactivé quand il n'y a plus de place.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get eventsFull;

  /// Détail d'événement : message quand l'événement n'existe plus ou ne charge pas.
  ///
  /// In fr, this message translates to:
  /// **'Événement introuvable'**
  String get eventsNotFound;

  /// Détail d'événement : petit libellé au-dessus de la date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get eventsInfoDate;

  /// Détail d'événement : petit libellé au-dessus de l'heure.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get eventsInfoTime;

  /// Détail d'événement : petit libellé au-dessus du lieu.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get eventsInfoPlace;

  /// Détail d'événement : petit libellé au-dessus du nombre de participants.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get eventsInfoParticipants;

  /// Détail d'événement : petit libellé au-dessus du prix.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get eventsInfoPrice;

  /// Détail d'événement : titre du texte de présentation.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get eventsDescription;

  /// Détail d'événement avec places limitées : inscrits sur capacité, par exemple « 12 / 20 places ». Le pluriel suit la capacité.
  ///
  /// In fr, this message translates to:
  /// **'{max, plural, one{{count} / {max} place} other{{count} / {max} places}}'**
  String eventsCapacity(int count, int max);

  /// Détail d'événement sans limite de places : nombre de personnes inscrites.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 inscrits} one{{count} inscrit} other{{count} inscrits}}'**
  String eventsRegisteredCount(int count);

  /// Détail d'événement : le prix par personne. {price} est déjà formaté avec sa devise, par exemple « 25 € ».
  ///
  /// In fr, this message translates to:
  /// **'{price} par personne'**
  String eventsPricePerPerson(String price);

  /// Détail d'événement : bandeau vert quand le membre est inscrit.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes inscrit(e) à cet événement'**
  String get eventsRsvpConfirmedBanner;

  /// Détail d'événement : bouton rouge qui annule l'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Annuler mon inscription'**
  String get eventsRsvpCancel;

  /// Détail d'événement payant : bouton d'inscription avec le prix. {price} est déjà formaté, par exemple « 25 € ».
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire - {price}'**
  String eventsRsvpJoinPaid(String price);

  /// Détail d'événement gratuit : bouton d'inscription.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire gratuitement'**
  String get eventsRsvpJoinFree;

  /// Message bref : l'inscription à l'événement est annulée.
  ///
  /// In fr, this message translates to:
  /// **'Inscription annulée'**
  String get eventsRsvpCancelled;

  /// Message bref : l'inscription à l'événement est confirmée.
  ///
  /// In fr, this message translates to:
  /// **'Inscription confirmée'**
  String get eventsRsvpDone;

  /// Message pré-écrit envoyé par le bouton Partager d'un événement. Les guillemets entourent le titre. MAZL est le nom de l'app.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez-moi à \"{title}\" sur MAZL'**
  String eventsShareMessage(String title);

  /// Message d'erreur bref (snackbar) à la dernière étape de la configuration du profil : le choix « Je recherche » (un homme ou une femme) est obligatoire, sans lui le fil Découvrir ne peut pas être construit.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez ce que vous recherchez'**
  String get genreLookingForRequired;

  /// Petit titre (capitales) de la carte du Shabbat de la semaine, dans le calendrier juif.
  ///
  /// In fr, this message translates to:
  /// **'Ce Shabbat'**
  String get jewishCalendarShabbatTitle;

  /// Titre de la carte du Shabbat : la lecture hebdomadaire de la Torah. {name} est le nom de la paracha déjà écrit (ex. « Bereshis »). « Parashat » = « paracha de ».
  ///
  /// In fr, this message translates to:
  /// **'Parashat {name}'**
  String jewishCalendarParashat(String name);

  /// Deux parachiot lues le même Shabbat (ex. « Vayakhel Pekudei »), {first} et {second} sont leurs noms déjà écrits.
  ///
  /// In fr, this message translates to:
  /// **'{first} {second}'**
  String jewishCalendarParshaPair(String first, String second);

  /// Libellé au-dessus de l'heure d'allumage des bougies de Shabbat, sur la carte du Shabbat. Une ligne, environ 20 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Allumage'**
  String get jewishCalendarCandleLighting;

  /// Libellé au-dessus de l'heure de la havdala (fin du Shabbat) sur la carte du Shabbat. Une ligne, environ 20 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Havdala'**
  String get jewishCalendarHavdalah;

  /// Petite étiquette (capitales) d'une idée d'activité du Shabbat ou d'une fête : il s'agit de préparer quelque chose.
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get jewishCalendarCategoryPreparation;

  /// Petite étiquette (capitales) d'une idée d'activité : moment spirituel.
  ///
  /// In fr, this message translates to:
  /// **'Spirituel'**
  String get jewishCalendarCategorySpiritual;

  /// Petite étiquette (capitales) d'une idée d'activité : moment de détente.
  ///
  /// In fr, this message translates to:
  /// **'Détente'**
  String get jewishCalendarCategoryRelaxation;

  /// Titre d'une idée d'activité à deux : le vendredi soir, préparer le repas de Shabbat.
  ///
  /// In fr, this message translates to:
  /// **'Préparer le dîner ensemble'**
  String get jewishCalendarActivityShabbatDinnerTitle;

  /// Phrase sous le titre d'une idée d'activité à deux (le vendredi soir, préparer le repas de Shabbat).
  ///
  /// In fr, this message translates to:
  /// **'Cuisinez la Halla et le repas de fête'**
  String get jewishCalendarActivityShabbatDinnerBody;

  /// Titre d'une idée d'activité à deux : allumer les bougies de Shabbat.
  ///
  /// In fr, this message translates to:
  /// **'Allumer les bougies'**
  String get jewishCalendarActivityShabbatCandlesTitle;

  /// Phrase sous le titre d'une idée d'activité à deux (allumer les bougies de Shabbat).
  ///
  /// In fr, this message translates to:
  /// **'Moment de spiritualité partagé'**
  String get jewishCalendarActivityShabbatCandlesBody;

  /// Titre d'une idée d'activité à deux : se promener le Shabbat.
  ///
  /// In fr, this message translates to:
  /// **'Promenade Shabbat'**
  String get jewishCalendarActivityShabbatWalkTitle;

  /// Phrase sous le titre d'une idée d'activité à deux (se promener le Shabbat).
  ///
  /// In fr, this message translates to:
  /// **'Balade tranquille après le repas'**
  String get jewishCalendarActivityShabbatWalkBody;

  /// Titre d'une idée d'activité à deux : étudier la paracha de la semaine.
  ///
  /// In fr, this message translates to:
  /// **'Étude de la Parasha'**
  String get jewishCalendarActivityShabbatParashaTitle;

  /// Phrase sous le titre d'une idée d'activité à deux (étudier la paracha de la semaine).
  ///
  /// In fr, this message translates to:
  /// **'Apprenez ensemble la portion de la semaine'**
  String get jewishCalendarActivityShabbatParashaBody;

  /// Titre d'une idée d'activité à deux : préparer le repas du Seder de Pessah.
  ///
  /// In fr, this message translates to:
  /// **'Préparer le Seder'**
  String get jewishCalendarActivityPesachSederTitle;

  /// Phrase sous le titre d'une idée d'activité à deux (préparer le repas du Seder de Pessah).
  ///
  /// In fr, this message translates to:
  /// **'Organisez la table ensemble'**
  String get jewishCalendarActivityPesachSederBody;

  /// Titre d'une idée d'activité à deux : faire le grand ménage avant Pessah.
  ///
  /// In fr, this message translates to:
  /// **'Faire le ménage de Pessah'**
  String get jewishCalendarActivityPesachCleaningTitle;

  /// Phrase sous le titre d'une idée d'activité à deux (faire le grand ménage avant Pessah).
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage de printemps en équipe'**
  String get jewishCalendarActivityPesachCleaningBody;

  /// Nom de la fête juive « Rosh Hashana » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Rosh Hashana'**
  String get jewishCalendarHolidayRoshHashanaName;

  /// Courte explication sous le nom de la fête « Rosh Hashana » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel an juif'**
  String get jewishCalendarHolidayRoshHashanaDescription;

  /// Nom de la fête juive « Yom Kippour » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Yom Kippour'**
  String get jewishCalendarHolidayYomKippurName;

  /// Courte explication sous le nom de la fête « Yom Kippour » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Jour du Grand Pardon'**
  String get jewishCalendarHolidayYomKippurDescription;

  /// Nom de la fête juive « Souccot » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Souccot'**
  String get jewishCalendarHolidaySukkotName;

  /// Courte explication sous le nom de la fête « Souccot » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Fête des cabanes'**
  String get jewishCalendarHolidaySukkotDescription;

  /// Nom de la fête juive « Shemini Atseret » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Shemini Atseret'**
  String get jewishCalendarHolidaySheminiAtzeretName;

  /// Courte explication sous le nom de la fête « Shemini Atseret » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Huitième jour de rassemblement'**
  String get jewishCalendarHolidaySheminiAtzeretDescription;

  /// Nom de la fête juive « Simhat Torah » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Simhat Torah'**
  String get jewishCalendarHolidaySimchatTorahName;

  /// Courte explication sous le nom de la fête « Simhat Torah » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Joie de la Torah'**
  String get jewishCalendarHolidaySimchatTorahDescription;

  /// Nom de la fête juive « Hanoucca » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Hanoucca'**
  String get jewishCalendarHolidayHanukkahName;

  /// Courte explication sous le nom de la fête « Hanoucca » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Fête des lumières'**
  String get jewishCalendarHolidayHanukkahDescription;

  /// Nom de la fête juive « Tou Bichvat » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Tou Bichvat'**
  String get jewishCalendarHolidayTuBishvatName;

  /// Courte explication sous le nom de la fête « Tou Bichvat » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel an des arbres'**
  String get jewishCalendarHolidayTuBishvatDescription;

  /// Nom de la fête juive « Pourim » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Pourim'**
  String get jewishCalendarHolidayPurimName;

  /// Courte explication sous le nom de la fête « Pourim » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Fête des sorts'**
  String get jewishCalendarHolidayPurimDescription;

  /// Nom de la fête juive « Pessah » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Pessah'**
  String get jewishCalendarHolidayPesachName;

  /// Courte explication sous le nom de la fête « Pessah » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Fête de la liberté'**
  String get jewishCalendarHolidayPesachDescription;

  /// Nom de la fête juive « Yom HaShoah » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Yom HaShoah'**
  String get jewishCalendarHolidayYomHashoahName;

  /// Courte explication sous le nom de la fête « Yom HaShoah » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Jour du souvenir de la Shoah'**
  String get jewishCalendarHolidayYomHashoahDescription;

  /// Nom de la fête juive « Yom HaZikaron » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Yom HaZikaron'**
  String get jewishCalendarHolidayYomHazikaronName;

  /// Courte explication sous le nom de la fête « Yom HaZikaron » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Jour du souvenir des soldats'**
  String get jewishCalendarHolidayYomHazikaronDescription;

  /// Nom de la fête juive « Yom HaAtsmaout » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Yom HaAtsmaout'**
  String get jewishCalendarHolidayYomHaatzmautName;

  /// Courte explication sous le nom de la fête « Yom HaAtsmaout » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Jour de l\'indépendance d\'Israël'**
  String get jewishCalendarHolidayYomHaatzmautDescription;

  /// Nom de la fête juive « Yom Yeroushalayim » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Yom Yeroushalayim'**
  String get jewishCalendarHolidayYomYerushalayimName;

  /// Courte explication sous le nom de la fête « Yom Yeroushalayim » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Jour de la réunification de Jérusalem'**
  String get jewishCalendarHolidayYomYerushalayimDescription;

  /// Nom de la fête juive « Lag BaOmer » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Lag BaOmer'**
  String get jewishCalendarHolidayLagBaomerName;

  /// Courte explication sous le nom de la fête « Lag BaOmer » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'33eme jour du Omer'**
  String get jewishCalendarHolidayLagBaomerDescription;

  /// Nom de la fête juive « Shavouot » dans le calendrier (titre de sa carte). Utiliser le nom usuel de la langue ; en hébreu, le nom hébreu courant.
  ///
  /// In fr, this message translates to:
  /// **'Shavouot'**
  String get jewishCalendarHolidayShavuotName;

  /// Courte explication sous le nom de la fête « Shavouot » : ce qu'elle célèbre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Don de la Torah'**
  String get jewishCalendarHolidayShavuotDescription;

  /// Puce d'idée d'activité à deux pour une fête juive (« Dîner festif »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Dîner festif'**
  String get jewishCalendarIdeaFestiveDinner;

  /// Puce d'idée d'activité à deux pour une fête juive (« Tashlich ensemble »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Tashlich ensemble'**
  String get jewishCalendarIdeaTashlich;

  /// Puce d'idée d'activité à deux pour une fête juive (« Se demander pardon mutuellement »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Se demander pardon mutuellement'**
  String get jewishCalendarIdeaMutualForgiveness;

  /// Puce d'idée d'activité à deux pour une fête juive (« Construire la Soucca ensemble »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Construire la Soucca ensemble'**
  String get jewishCalendarIdeaBuildSukkah;

  /// Puce d'idée d'activité à deux pour une fête juive (« Inviter des amis »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Inviter des amis'**
  String get jewishCalendarIdeaInviteFriends;

  /// Puce d'idée d'activité à deux pour une fête juive (« Prière pour la pluie »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Prière pour la pluie'**
  String get jewishCalendarIdeaPrayerForRain;

  /// Puce d'idée d'activité à deux pour une fête juive (« Danser avec la Torah »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Danser avec la Torah'**
  String get jewishCalendarIdeaDanceWithTorah;

  /// Puce d'idée d'activité à deux pour une fête juive (« Allumer les bougies ensemble »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Allumer les bougies ensemble'**
  String get jewishCalendarIdeaLightCandlesTogether;

  /// Puce d'idée d'activité à deux pour une fête juive (« Soufganiot maison »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Soufganiot maison'**
  String get jewishCalendarIdeaHomemadeSufganiyot;

  /// Puce d'idée d'activité à deux pour une fête juive (« Déguisement en couple »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Déguisement en couple'**
  String get jewishCalendarIdeaCoupleCostumes;

  /// Puce d'idée d'activité à deux pour une fête juive (« Mishloach Manot ensemble »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Mishloach Manot ensemble'**
  String get jewishCalendarIdeaMishloachManot;

  /// Puce d'idée d'activité à deux pour une fête juive (« Seder romantique »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Seder romantique'**
  String get jewishCalendarIdeaRomanticSeder;

  /// Puce d'idée d'activité à deux pour une fête juive (« Voyage en Israël »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Voyage en Israël'**
  String get jewishCalendarIdeaTripToIsrael;

  /// Puce d'idée d'activité à deux pour une fête juive (« BBQ israélien »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'BBQ israélien'**
  String get jewishCalendarIdeaIsraeliBarbecue;

  /// Puce d'idée d'activité à deux pour une fête juive (« Concert/soirée »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Concert/soirée'**
  String get jewishCalendarIdeaConcertOrParty;

  /// Puce d'idée d'activité à deux pour une fête juive (« Feu de camp »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Feu de camp'**
  String get jewishCalendarIdeaCampfire;

  /// Puce d'idée d'activité à deux pour une fête juive (« Pique-nique »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Pique-nique'**
  String get jewishCalendarIdeaPicnic;

  /// Puce d'idée d'activité à deux pour une fête juive (« Cheesecake maison »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Cheesecake maison'**
  String get jewishCalendarIdeaHomemadeCheesecake;

  /// Puce d'idée d'activité à deux pour une fête juive (« Nuit d'étude »). Court, une ligne ou deux sur une puce.
  ///
  /// In fr, this message translates to:
  /// **'Nuit d\'étude'**
  String get jewishCalendarIdeaStudyNight;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Bereshis ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Bereshis'**
  String get jewishCalendarParshaBereshis;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Noach ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Noach'**
  String get jewishCalendarParshaNoach;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Lech Lecha ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Lech Lecha'**
  String get jewishCalendarParshaLechLecha;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vayera ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vayera'**
  String get jewishCalendarParshaVayera;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Chayei Sara ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Chayei Sara'**
  String get jewishCalendarParshaChayeiSara;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Toldos ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Toldos'**
  String get jewishCalendarParshaToldos;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vayetzei ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vayetzei'**
  String get jewishCalendarParshaVayetzei;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vayishlach ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vayishlach'**
  String get jewishCalendarParshaVayishlach;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vayeshev ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vayeshev'**
  String get jewishCalendarParshaVayeshev;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Miketz ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Miketz'**
  String get jewishCalendarParshaMiketz;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vayigash ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vayigash'**
  String get jewishCalendarParshaVayigash;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vayechi ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vayechi'**
  String get jewishCalendarParshaVayechi;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Shemos ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Shemos'**
  String get jewishCalendarParshaShemos;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vaera ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vaera'**
  String get jewishCalendarParshaVaera;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Bo ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Bo'**
  String get jewishCalendarParshaBo;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Beshalach ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Beshalach'**
  String get jewishCalendarParshaBeshalach;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Yisro ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Yisro'**
  String get jewishCalendarParshaYisro;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Mishpatim ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Mishpatim'**
  String get jewishCalendarParshaMishpatim;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Terumah ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Terumah'**
  String get jewishCalendarParshaTerumah;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Tetzaveh ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Tetzaveh'**
  String get jewishCalendarParshaTetzaveh;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Ki Sisa ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Ki Sisa'**
  String get jewishCalendarParshaKiSisa;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vayakhel ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vayakhel'**
  String get jewishCalendarParshaVayakhel;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Pekudei ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Pekudei'**
  String get jewishCalendarParshaPekudei;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vayikra ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vayikra'**
  String get jewishCalendarParshaVayikra;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Tzav ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Tzav'**
  String get jewishCalendarParshaTzav;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Shmini ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Shmini'**
  String get jewishCalendarParshaShmini;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Tazria ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Tazria'**
  String get jewishCalendarParshaTazria;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Metzora ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Metzora'**
  String get jewishCalendarParshaMetzora;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Achrei Mos ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Achrei Mos'**
  String get jewishCalendarParshaAchreiMos;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Kedoshim ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Kedoshim'**
  String get jewishCalendarParshaKedoshim;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Emor ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Emor'**
  String get jewishCalendarParshaEmor;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Behar ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Behar'**
  String get jewishCalendarParshaBehar;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Bechukosai ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Bechukosai'**
  String get jewishCalendarParshaBechukosai;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Bamidbar ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Bamidbar'**
  String get jewishCalendarParshaBamidbar;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Nasso ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Nasso'**
  String get jewishCalendarParshaNasso;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Beha'aloscha ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Beha\'aloscha'**
  String get jewishCalendarParshaBehaaloscha;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Sh'lach ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Sh\'lach'**
  String get jewishCalendarParshaShlach;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Korach ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Korach'**
  String get jewishCalendarParshaKorach;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Chukas ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Chukas'**
  String get jewishCalendarParshaChukas;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Balak ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Balak'**
  String get jewishCalendarParshaBalak;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Pinchas ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Pinchas'**
  String get jewishCalendarParshaPinchas;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Matos ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Matos'**
  String get jewishCalendarParshaMatos;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Masei ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Masei'**
  String get jewishCalendarParshaMasei;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Devarim ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Devarim'**
  String get jewishCalendarParshaDevarim;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vaeschanan ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vaeschanan'**
  String get jewishCalendarParshaVaeschanan;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Eikev ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Eikev'**
  String get jewishCalendarParshaEikev;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Re'eh ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Re\'eh'**
  String get jewishCalendarParshaReeh;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Shoftim ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Shoftim'**
  String get jewishCalendarParshaShoftim;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Ki Seitzei ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Ki Seitzei'**
  String get jewishCalendarParshaKiSeitzei;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Ki Savo ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Ki Savo'**
  String get jewishCalendarParshaKiSavo;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Nitzavim ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Nitzavim'**
  String get jewishCalendarParshaNitzavim;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vayeilech ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vayeilech'**
  String get jewishCalendarParshaVayeilech;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Ha'Azinu ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Ha\'Azinu'**
  String get jewishCalendarParshaHaazinu;

  /// Nom de la paracha (lecture hebdomadaire de la Torah) « Vezos Habracha ». Nom propre : translittération usuelle de la langue, nom hébreu courant en hébreu.
  ///
  /// In fr, this message translates to:
  /// **'Vezos Habracha'**
  String get jewishCalendarParshaVzosHaberacha;

  /// Onglet Messages sur un écran large (face intérieure du téléphone pliable, tablette) : titre du volet de droite tant qu'aucune conversation n'est ouverte. Une ligne, une vingtaine de caractères au plus par ligne.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une conversation'**
  String get layoutPaneChatTitle;

  /// Onglet Messages sur un écran large : phrase sous le titre du volet vide, qui explique que la conversation choisie dans la liste s'affichera dans ce volet. Deux lignes au plus.
  ///
  /// In fr, this message translates to:
  /// **'Elle s\'ouvre ici, à côté de la liste.'**
  String get layoutPaneChatMessage;

  /// Onglet Matchs sur un écran large : titre du volet de droite tant qu'aucun profil n'est ouvert. Une ligne, une vingtaine de caractères au plus par ligne.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un match'**
  String get layoutPaneProfileTitle;

  /// Onglet Matchs sur un écran large : phrase sous le titre du volet vide, qui explique que le profil choisi dans la liste s'affichera dans ce volet. Deux lignes au plus.
  ///
  /// In fr, this message translates to:
  /// **'Son profil s\'affiche ici, à côté de la liste.'**
  String get layoutPaneProfileMessage;

  /// Titre de l'écran qui liste les membres qui ont aimé le profil.
  ///
  /// In fr, this message translates to:
  /// **'Likes'**
  String get likesTitle;

  /// Petit titre au-dessus de la liste des likes. {count} est le nombre de likes reçus, arrondi par tranches (« 3 », « 10+ », « 25+ »).
  ///
  /// In fr, this message translates to:
  /// **'Ils vous ont aimé · {count}'**
  String likesSection(String count);

  /// Phrase sous le titre pour un compte gratuit. {label} est le nombre affiché (« 3 », « 10+ »), {count} la valeur qui choisit le pluriel.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{label} personne attend votre réponse.} other{{label} personnes attendent votre réponse.}}'**
  String likesWaiting(int count, String label);

  /// Bouton en contour sous la grille des likes verrouillés. « mazl+ » (nom de marque) sera mis en gras avec son « + » coloré : il doit rester écrit tel quel dans la phrase.
  ///
  /// In fr, this message translates to:
  /// **'Voir qui vous a aimé avec mazl+'**
  String get likesSeeWhoWithPlus;

  /// Message bref après avoir aimé un profil depuis la liste. {name} est le prénom.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez liké {name}'**
  String likesYouLiked(String name);

  /// Titre de l'écran des likes quand personne n'a encore aimé le profil.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de likes'**
  String get likesEmptyTitle;

  /// Texte sous le titre de l'écran des likes vide : conseil pour recevoir des likes.
  ///
  /// In fr, this message translates to:
  /// **'Continuez à découvrir des profils et complétez votre profil pour attirer plus de likes.'**
  String get likesEmptyBody;

  /// Bouton de l'écran des likes vide : retourne à Découvrir.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir des profils'**
  String get likesEmptyAction;

  /// Texte de la feuille qui présente mazl+ quand on touche un like verrouillé.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez qui vous a aimé et matchez tout de suite avec les personnes qui vous plaisent.'**
  String get likesPremiumBody;

  /// Bouton de la feuille mazl+ : ouvre l'écran des offres.
  ///
  /// In fr, this message translates to:
  /// **'Voir les offres'**
  String get likesPremiumOffers;

  /// Libellé d'accessibilité d'une carte de like : ouvre l'aperçu. {title} est « Prénom, âge ».
  ///
  /// In fr, this message translates to:
  /// **'Voir le like de {title}'**
  String likesCardOpen(String title);

  /// Info-bulle du bouton rond (croix) sous une carte de like. {name} est le prénom.
  ///
  /// In fr, this message translates to:
  /// **'Passer {name}'**
  String likesCardPass(String name);

  /// Info-bulle du bouton rond (cœur) sous une carte de like. {name} est le prénom.
  ///
  /// In fr, this message translates to:
  /// **'Aimer {name}'**
  String likesCardLike(String name);

  /// Libellé d'accessibilité d'une tuile de like verrouillée (compte gratuit).
  ///
  /// In fr, this message translates to:
  /// **'Profil masqué'**
  String get likesLockedLabel;

  /// Indication d'accessibilité d'une tuile de like verrouillée. « mazl+ » est un nom de marque.
  ///
  /// In fr, this message translates to:
  /// **'Disponible avec mazl+'**
  String get likesLockedHint;

  /// Pastille de distance dans l'aperçu d'un like. {km} est un nombre entier de kilomètres.
  ///
  /// In fr, this message translates to:
  /// **'{km} km'**
  String likesDistance(int km);

  /// Info-bulle du bouton en haut de Découvrir qui ouvre les sélections du jour.
  ///
  /// In fr, this message translates to:
  /// **'Sélections du jour'**
  String get matchingDiscoverDailyPicks;

  /// Info-bulle du bouton filtres en haut de Découvrir, et titre de l'écran des filtres.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get matchingFilters;

  /// Titre de Découvrir quand tous les profils proposés ont été vus.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez tout vu.'**
  String get matchingDiscoverEmptyTitle;

  /// Texte sous le titre de Découvrir quand il n'y a plus de profil à voir.
  ///
  /// In fr, this message translates to:
  /// **'Revenez plus tard ou élargissez vos filtres pour voir de nouveaux profils.'**
  String get matchingDiscoverEmptyBody;

  /// Bouton de Découvrir (état vide) qui ouvre l'écran des filtres.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les filtres'**
  String get matchingDiscoverOpenFilters;

  /// Bouton de Découvrir (état vide) qui recharge les profils.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get matchingDiscoverRefresh;

  /// Info-bulle du petit bouton rond de la carte qui envoie un super like. Nom de la fonction, gardé tel quel dans les apps de rencontre.
  ///
  /// In fr, this message translates to:
  /// **'Super like'**
  String get matchingDiscoverSuperLike;

  /// Info-bulle du petit bouton rond de la carte qui active un Boost (fonction mazl+). Nom de la fonction.
  ///
  /// In fr, this message translates to:
  /// **'Boost'**
  String get matchingDiscoverBoost;

  /// Message bref après l'activation d'un Boost. {minutes} est la durée du Boost en minutes.
  ///
  /// In fr, this message translates to:
  /// **'Boost activé. Vous êtes en tête de pile pendant {minutes, plural, one{{minutes} minute} other{{minutes} minutes}}.'**
  String matchingDiscoverBoostOn(int minutes);

  /// Message bref quand le Boost n'a pas pu être activé.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'activer le boost'**
  String get matchingDiscoverBoostFailed;

  /// Info-bulle du gros bouton rond de la carte qui passe le profil (équivalent d'un balayage à gauche).
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get matchingCardPass;

  /// Info-bulle du gros bouton rond de la carte (cœur) qui aime le profil (équivalent d'un balayage à droite).
  ///
  /// In fr, this message translates to:
  /// **'J\'aime'**
  String get matchingCardLike;

  /// Indication d'accessibilité sur le nom de la carte : toucher ouvre le profil complet.
  ///
  /// In fr, this message translates to:
  /// **'Voir le profil'**
  String get matchingCardViewProfile;

  /// Nom affiché quand un profil n'a pas de prénom.
  ///
  /// In fr, this message translates to:
  /// **'Anonyme'**
  String get matchingCardAnonymous;

  /// Distance sous le nom, après la ville, séparée par un point médian. {km} est un nombre entier de kilomètres.
  ///
  /// In fr, this message translates to:
  /// **'à {km} km'**
  String matchingCardDistance(int km);

  /// Pastille blanche en haut de la photo : le profil a passé la vérification d'identité. Doit tenir sur une ligne de 12 px de haut.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiée'**
  String get matchingCardVerified;

  /// Libellé d'accessibilité d'un match récent dans la rangée des matchs. {name} est le prénom.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau match, {name}'**
  String matchingAvatarNewMatch(String name);

  /// Libellé d'accessibilité d'un match dans la rangée des matchs. {name} est le prénom.
  ///
  /// In fr, this message translates to:
  /// **'Match, {name}'**
  String matchingAvatarMatch(String name);

  /// Titre de la feuille qui s'ouvre quand deux membres se plaisent mutuellement.
  ///
  /// In fr, this message translates to:
  /// **'C\'est un match'**
  String get matchingMatchTitle;

  /// Phrase sous le titre de la feuille de match. {name} est le prénom de l'autre membre.
  ///
  /// In fr, this message translates to:
  /// **'{name} et vous vous êtes plu.'**
  String matchingMatchLineNamed(String name);

  /// Phrase sous le titre de la feuille de match quand l'autre membre n'a pas de prénom.
  ///
  /// In fr, this message translates to:
  /// **'Vous vous êtes plu.'**
  String get matchingMatchLineAnonymous;

  /// Bouton principal de la feuille de match : ouvre la conversation.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un message'**
  String get matchingMatchSendMessage;

  /// Bouton secondaire de la feuille de match : ferme la feuille et revient aux profils.
  ///
  /// In fr, this message translates to:
  /// **'Continuer à découvrir'**
  String get matchingMatchKeepDiscovering;

  /// Bouton en contour sous les likes visibles de l'écran Matchs. « mazl+ » (nom de marque) sera mis en gras avec son « + » coloré : il doit rester écrit tel quel. {count} est le nombre de likes encore cachés.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Voir {count} autre avec mazl+} other{Voir les {count} autres avec mazl+}}'**
  String matchingSeeMoreWithPlus(int count);

  /// Titre de l'onglet et de l'écran des matchs (gros titre).
  ///
  /// In fr, this message translates to:
  /// **'Matchs'**
  String get matchingMatchesTitle;

  /// Info-bulle du bouton cœur en haut de l'écran des matchs : ouvre la liste des membres qui ont aimé le profil.
  ///
  /// In fr, this message translates to:
  /// **'Qui vous a aimé'**
  String get matchingMatchesWhoLikedYou;

  /// Petit titre au-dessus de la rangée des pastilles de matchs. {count} est le nombre de matchs récents (moins de 7 jours).
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux · {count}'**
  String matchingMatchesNewSection(int count);

  /// Petit titre au-dessus de la liste des matchs avec lesquels on peut discuter. {count} est leur nombre.
  ///
  /// In fr, this message translates to:
  /// **'Conversations · {count}'**
  String matchingMatchesConversationsSection(int count);

  /// Texte de l'écran des matchs quand leur chargement a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les matchs'**
  String get matchingMatchesLoadFailed;

  /// Titre de l'écran des matchs quand il n'y en a pas encore.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de match'**
  String get matchingMatchesEmptyTitle;

  /// Texte sous le titre de l'écran des matchs vide.
  ///
  /// In fr, this message translates to:
  /// **'Continuez à découvrir des profils.'**
  String get matchingMatchesEmptyBody;

  /// Nom affiché pour un match dont le prénom n'est pas connu.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get matchingMatchesUnknownName;

  /// Ligne discrète sous le nom d'un match qui n'a pas de ville : invite à écrire le premier message.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez-lui'**
  String get matchingMatchesWriteHint;

  /// Libellé d'accessibilité de la photo ronde d'un match : ouvre son profil. {name} est le prénom.
  ///
  /// In fr, this message translates to:
  /// **'Voir le profil de {name}'**
  String matchingMatchesViewProfileOf(String name);

  /// Bouton en contour sous les likes visibles (compte mazl+) quand il y en a d'autres. {count} est le nombre restant.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Voir {count} autre} other{Voir les {count} autres}}'**
  String matchingMatchesSeeMore(int count);

  /// Ancienneté d'un match (2 à 6 jours), à droite de sa ligne. {count} est un entier de jours.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Il y a {count} jour} other{Il y a {count} jours}}'**
  String matchingMatchedDaysAgo(int count);

  /// Ancienneté d'un match (7 à 29 jours), à droite de sa ligne. {count} est un entier de semaines.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Il y a {count} semaine} other{Il y a {count} semaines}}'**
  String matchingMatchedWeeksAgo(int count);

  /// Ancienneté d'un match (30 jours ou plus), à droite de sa ligne. {count} est un entier de mois.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Il y a {count} mois} other{Il y a {count} mois}}'**
  String matchingMatchedMonthsAgo(int count);

  /// Titre de la bannière qui propose le mode couple dans l'écran des matchs (gros texte, jusqu'à deux lignes).
  ///
  /// In fr, this message translates to:
  /// **'Ça y est, vous avez matché ?'**
  String get matchingCouplePromoTitle;

  /// Info-bulle de la croix qui masque la bannière du mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get matchingCouplePromoDismiss;

  /// Texte de la bannière du mode couple : ce que le mode couple apporte. « mazl » est le nom de la marque.
  ///
  /// In fr, this message translates to:
  /// **'Questions quotidiennes, étapes, calendrier juif partagé : construisez votre relation avec mazl.'**
  String get matchingCouplePromoBody;

  /// Bouton de la bannière du mode couple : ouvre l'activation du mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Activer le mode couple'**
  String get matchingCouplePromoAction;

  /// Titre de l'écran des sélections du jour quand toutes ont été vues.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez vu toutes vos sélections.'**
  String get matchingPicksSeenAll;

  /// Sous le titre de l'écran vide des sélections : dans combien de temps les suivantes arrivent. {hours} et {minutes} sont des entiers.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines sélections dans {hours}h {minutes}m'**
  String matchingPicksNextIn(int hours, int minutes);

  /// Sous le compteur de profils de l'écran des sélections : dans combien de temps elles se renouvellent. {hours} et {minutes} sont des entiers.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour dans {hours}h {minutes}m'**
  String matchingPicksUpdatedIn(int hours, int minutes);

  /// Phrase en haut de l'écran des sélections du jour. {count} est le nombre de profils proposés.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} profil sélectionné pour vous} other{{count} profils sélectionnés pour vous}}'**
  String matchingPicksCount(int count);

  /// Bouton de l'écran des sélections vides : ouvre Découvrir.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir plus de profils'**
  String get matchingPicksDiscoverMore;

  /// Petit badge doré sur la photo d'un profil sélectionné (10 px de haut, un mot).
  ///
  /// In fr, this message translates to:
  /// **'Pick'**
  String get matchingPicksBadge;

  /// Bouton en haut à droite de l'écran des filtres : remet tous les filtres à leur valeur de départ.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get matchingFiltersReset;

  /// Titre de la section « tranche d'âge » de l'écran des filtres.
  ///
  /// In fr, this message translates to:
  /// **'Tranche d\'âge'**
  String get matchingFiltersAge;

  /// Âge minimal ou maximal affiché au-dessus du curseur d'âge. {count} est un entier entre 18 et 70.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} an} other{{count} ans}}'**
  String matchingFiltersYears(int count);

  /// Titre de la section « distance maximale » de l'écran des filtres.
  ///
  /// In fr, this message translates to:
  /// **'Distance maximale'**
  String get matchingFiltersDistance;

  /// Distance maximale choisie, en gros chiffres au-dessus du curseur. {count} est un entier de kilomètres.
  ///
  /// In fr, this message translates to:
  /// **'{count} km'**
  String matchingFiltersKm(int count);

  /// Titre de la section « courant religieux » de l'écran des filtres (fonction mazl+, plusieurs choix possibles).
  ///
  /// In fr, this message translates to:
  /// **'Courant religieux'**
  String get matchingFiltersDenomination;

  /// Titre de la section « kashrout » (mazl+) de l'écran des filtres : le niveau de pratique des repas casher des autres membres.
  ///
  /// In fr, this message translates to:
  /// **'Kashrout'**
  String get matchingFiltersKashrut;

  /// Titre de la section « Shabbat » (mazl+) de l'écran des filtres : l'observance du Shabbat des autres membres.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat'**
  String get matchingFiltersShabbatSection;

  /// Petite note sous les trois listes de choix de pratique religieuse. Deux phrases : on peut cocher plusieurs réponses ; un profil sans réponse à cette question est écarté dès qu'un choix est coché.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs choix possibles. Les profils qui n\'ont pas répondu ne sont pas proposés.'**
  String get matchingFiltersChoiceHint;

  /// Titre de la section des options à bascule (profils vérifiés, avec photo).
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get matchingFiltersOptions;

  /// Interrupteur : ne montrer que les profils dont l'identité est vérifiée.
  ///
  /// In fr, this message translates to:
  /// **'Profils vérifiés uniquement'**
  String get matchingFiltersVerifiedTitle;

  /// Explication sous l'interrupteur « profils vérifiés uniquement ».
  ///
  /// In fr, this message translates to:
  /// **'Voir seulement les profils vérifiés'**
  String get matchingFiltersVerifiedHint;

  /// Interrupteur : ne montrer que les profils qui ont une photo.
  ///
  /// In fr, this message translates to:
  /// **'Avec photo uniquement'**
  String get matchingFiltersPhotoTitle;

  /// Explication sous l'interrupteur « avec photo uniquement ».
  ///
  /// In fr, this message translates to:
  /// **'Exclure les profils sans photo'**
  String get matchingFiltersPhotoHint;

  /// Titre de l'encart dégradé qui propose mazl+ aux comptes gratuits, en bas de l'écran des filtres.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer tous les filtres'**
  String get matchingFiltersUpsellTitle;

  /// Sous le titre de l'encart mazl+ (12 px, une ligne). « mazl+ » est un nom de marque.
  ///
  /// In fr, this message translates to:
  /// **'Passez à mazl+ pour des recherches précises'**
  String get matchingFiltersUpsellBody;

  /// Gros bouton qui apparaît dès qu'un filtre change : enregistre les filtres et revient à Découvrir.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer les filtres'**
  String get matchingFiltersApply;

  /// Message bref (fond vert) après l'enregistrement des filtres.
  ///
  /// In fr, this message translates to:
  /// **'Filtres enregistrés'**
  String get matchingFiltersSaved;

  /// Message bref (fond rouge) quand l'enregistrement des filtres a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sauvegarde'**
  String get matchingFiltersSaveFailed;

  /// Titre de la section qui remplace les filtres avancés (mazl+) quand le serveur ne les a pas rendus.
  ///
  /// In fr, this message translates to:
  /// **'Filtres avancés'**
  String get matchingFiltersAdvanced;

  /// Message affiché à la place des filtres avancés quand leur chargement a échoué ; un bouton « Réessayer » suit.
  ///
  /// In fr, this message translates to:
  /// **'Vos filtres avancés n\'ont pas pu être chargés.'**
  String get matchingFiltersLoadFailed;

  /// Message bref (fond rouge) quand le membre a refusé le consentement de l'article 9 au moment d'enregistrer un critère de pratique religieuse.
  ///
  /// In fr, this message translates to:
  /// **'Ces critères demandent votre accord pour traiter votre pratique religieuse. Ils n\'ont pas été enregistrés.'**
  String get matchingFiltersConsentNeeded;

  /// Barre d'onglets : onglet des profils à découvrir. Lu par le lecteur d'écran, l'onglet n'affiche qu'une icône.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get navigationDiscover;

  /// Barre d'onglets : onglet des matchs. Lu par le lecteur d'écran, l'onglet n'affiche qu'une icône.
  ///
  /// In fr, this message translates to:
  /// **'Matchs'**
  String get navigationMatches;

  /// Barre d'onglets : onglet des conversations. Lu par le lecteur d'écran, l'onglet n'affiche qu'une icône.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get navigationMessages;

  /// Barre d'onglets : onglet des événements. Lu par le lecteur d'écran, l'onglet n'affiche qu'une icône.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get navigationEvents;

  /// Barre d'onglets : onglet du profil du membre. Lu par le lecteur d'écran, l'onglet n'affiche qu'une icône.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navigationProfile;

  /// Barre d'onglets repliée en pastille : ce que lit le lecteur d'écran pour la pastille qui déplie la barre.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les onglets'**
  String get navigationShowTabs;

  /// Présentation : bouton de la dernière page, qui ouvre la connexion.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// Présentation : repère en haut d'une page, numéro de la page sur le total, chiffres déjà complétés par un zéro (« 01 / 05 »).
  ///
  /// In fr, this message translates to:
  /// **'{current} / {total}'**
  String onboardingStep(String current, String total);

  /// Présentation : libellé lu par le lecteur d'écran pour les barres de progression.
  ///
  /// In fr, this message translates to:
  /// **'Page {current} sur {total}'**
  String onboardingPageOf(int current, int total);

  /// Présentation, page 1 : titre.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur MAZL'**
  String get onboardingPage1Title;

  /// Présentation, page 1 : texte.
  ///
  /// In fr, this message translates to:
  /// **'L\'application de rencontres pensée pour la communauté juive.'**
  String get onboardingPage1Body;

  /// Présentation, page 2 : titre. « mazal » est le mot hébreu pour la chance.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez votre mazal'**
  String get onboardingPage2Title;

  /// Présentation, page 2 : texte. « pratique » désigne la pratique religieuse.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez des profils compatibles avec vos valeurs et votre pratique.'**
  String get onboardingPage2Body;

  /// Présentation, page 3 : titre (le mode Couple de l'app).
  ///
  /// In fr, this message translates to:
  /// **'Mode Couple'**
  String get onboardingPage3Title;

  /// Présentation, page 3 : texte.
  ///
  /// In fr, this message translates to:
  /// **'Une fois l\'amour trouvé, MAZL vous accompagne : trouvez l\'amour, et gardez-le.'**
  String get onboardingPage3Body;

  /// Présentation, page 3 : première ligne de la liste du mode Couple.
  ///
  /// In fr, this message translates to:
  /// **'Souvenirs et dates importantes'**
  String get onboardingPage3Feature1;

  /// Présentation, page 3 : deuxième ligne de la liste.
  ///
  /// In fr, this message translates to:
  /// **'Bucket list à deux'**
  String get onboardingPage3Feature2;

  /// Présentation, page 3 : troisième ligne de la liste.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier juif partagé'**
  String get onboardingPage3Feature3;

  /// Présentation, page 3 : quatrième ligne de la liste.
  ///
  /// In fr, this message translates to:
  /// **'Activités et suggestions'**
  String get onboardingPage3Feature4;

  /// Présentation, page 4 : titre (le mode Shabbat de l'app).
  ///
  /// In fr, this message translates to:
  /// **'Mode Shabbat'**
  String get onboardingPage4Title;

  /// Présentation, page 4 : texte.
  ///
  /// In fr, this message translates to:
  /// **'Les horaires d\'allumage et de havdala de votre ville, et un écran de repos.'**
  String get onboardingPage4Body;

  /// Présentation, page 5 : titre (les suggestions du jour, écran atteint depuis Découvrir).
  ///
  /// In fr, this message translates to:
  /// **'Suggestions du jour'**
  String get onboardingPage5Title;

  /// Présentation, page 5 : texte.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour, une courte sélection de profils vous attend dans Découvrir.'**
  String get onboardingPage5Body;

  /// Petit libellé au-dessus du titre de la feuille d’achat de Super Likes (ouverte quand il n’en reste plus). Nom de la fonction, même terme que sur le bouton étoile de Découvrir.
  ///
  /// In fr, this message translates to:
  /// **'Super Likes'**
  String get packsSuperLikesLabel;

  /// Titre de la feuille d’achat de Super Likes, quand le serveur dit qu’il n’en reste aucun à envoyer.
  ///
  /// In fr, this message translates to:
  /// **'Vous n’avez plus de Super Likes.'**
  String get packsSuperLikesTitle;

  /// Phrase sous le titre de la feuille d’achat de Super Likes. Dit que les crédits achetés ne s’effacent pas à minuit, contrairement à l’inclus du jour.
  ///
  /// In fr, this message translates to:
  /// **'Reprenez-en : ceux que vous achetez n’expirent jamais.'**
  String get packsSuperLikesSubtitle;

  /// Petit libellé au-dessus du titre de la feuille d’achat de Boosts. Nom de la fonction, même terme que dans l’écran Boost.
  ///
  /// In fr, this message translates to:
  /// **'Boosts'**
  String get packsBoostsLabel;

  /// Titre de la feuille d’achat de Boosts, quand le serveur dit qu’il n’en reste aucun à activer.
  ///
  /// In fr, this message translates to:
  /// **'Vous n’avez plus de Boost.'**
  String get packsBoostsTitle;

  /// Phrase sous le titre de la feuille d’achat de Boosts. {minutes} est la durée d’un Boost en minutes (« min » abrégé).
  ///
  /// In fr, this message translates to:
  /// **'Mettez votre profil en tête pendant {minutes} min. Un Boost acheté n’expire jamais.'**
  String packsBoostsSubtitle(int minutes);

  /// Quantité d’un pack de Super Likes, en gros sur la ligne du pack. {count} est un entier (5, 15). Le nom du pack reste celui d’App Store Connect (« 5 Super Likes ») dans toutes les langues : ne pas traduire.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} Super Like} other{{count} Super Likes}}'**
  String packsPackSuperLikes(int count);

  /// Quantité d’un pack de Boosts, en gros sur la ligne du pack. {count} est un entier (1, 3). Le nom du pack reste celui d’App Store Connect (« 3 Boosts ») dans toutes les langues : ne pas traduire.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} Boost} other{{count} Boosts}}'**
  String packsPackBoosts(int count);

  /// Texte lu par le lecteur d’écran sur la ligne d’un pack. {quantity} est la quantité déjà écrite (« 5 Super Likes »), {price} le prix du store avec sa devise (« 3,99 € »).
  ///
  /// In fr, this message translates to:
  /// **'Acheter {quantity} pour {price}'**
  String packsPackSemantics(String quantity, String price);

  /// Texte lu par le lecteur d’écran pendant que les prix des packs se chargent depuis le store. Rien d’écrit à l’écran : seulement un indicateur de chargement.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des offres'**
  String get packsLoading;

  /// Dans la feuille d’achat, quand le store ne rend aucun prix (indisponible, hors ligne). Un bouton « Réessayer » suit.
  ///
  /// In fr, this message translates to:
  /// **'La boutique n’est pas disponible pour le moment. Réessayez dans un instant.'**
  String get packsStoreUnavailable;

  /// Message sous les packs quand l’achat attend une approbation (Ask to Buy : un parent doit valider). Le solde arrivera plus tard.
  ///
  /// In fr, this message translates to:
  /// **'Achat en attente d’approbation. Votre solde sera mis à jour dès qu’il sera validé.'**
  String get packsPending;

  /// Message bref quand on tente d’activer un Boost alors qu’un autre court déjà. Rien n’est débité.
  ///
  /// In fr, this message translates to:
  /// **'Un Boost est déjà en cours.'**
  String get packsBoostAlreadyActive;

  /// Message d’erreur générique quand le serveur répond 402 (plus de Super Likes ni de Boosts à dépenser) et qu’aucune feuille d’achat ne s’ouvre pour le dire. Affiché par apiErrorText.
  ///
  /// In fr, this message translates to:
  /// **'Il ne vous reste plus rien à utiliser pour le moment.'**
  String get packsErrorExhausted;

  /// Titre de la fenêtre « Réservé à mazl+ » pour la fonction « likes sans limite quotidienne », et titre du premier avantage de l'offre mazl+.
  ///
  /// In fr, this message translates to:
  /// **'Likes illimités'**
  String get plusFeatureUnlimitedLikesTitle;

  /// Phrase sous le titre de la fenêtre « Réservé à mazl+ » pour les likes illimités.
  ///
  /// In fr, this message translates to:
  /// **'Likez autant que vous voulez, sans limite quotidienne.'**
  String get plusFeatureUnlimitedLikesDescription;

  /// Titre de la fenêtre « Réservé à mazl+ » pour la fonction « voir qui a aimé votre profil », titre d'un avantage de l'offre, et titre de la première action de l'écran de bienvenue quand le nombre de likes est inconnu.
  ///
  /// In fr, this message translates to:
  /// **'Voir qui vous a aimé'**
  String get plusFeatureSeeWhoLikesYouTitle;

  /// Phrase sous le titre de la fenêtre « Réservé à mazl+ » pour la fonction « voir qui vous a aimé ». « Croiser » = tomber sur son profil dans Découvrir.
  ///
  /// In fr, this message translates to:
  /// **'Voyez qui vous a aimé avant même de le croiser.'**
  String get plusFeatureSeeWhoLikesYouDescription;

  /// Titre de la fenêtre « Réservé à mazl+ » pour les Super Likes, et libellé de la ligne « Super Likes » de l'écran Abonnement. Nom de la fonction : même terme que sur le bouton de la carte dans Découvrir.
  ///
  /// In fr, this message translates to:
  /// **'Super Likes'**
  String get plusFeatureSuperLikesTitle;

  /// Phrase sous le titre de la fenêtre « Réservé à mazl+ » pour les Super Likes. Le chiffre 5 est le quota quotidien des abonnés.
  ///
  /// In fr, this message translates to:
  /// **'Faites-vous remarquer avec 5 Super Likes par jour.'**
  String get plusFeatureSuperLikesDescription;

  /// Titre de la fenêtre « Réservé à mazl+ » pour le Boost, et libellé de la ligne « Boost » de l'écran Abonnement. Nom de la fonction : même terme que dans l'écran Boost.
  ///
  /// In fr, this message translates to:
  /// **'Boost'**
  String get plusFeatureBoostTitle;

  /// Phrase sous le titre de la fenêtre « Réservé à mazl+ » pour le Boost. « En tête de pile » = votre profil est montré en premier aux autres membres.
  ///
  /// In fr, this message translates to:
  /// **'Soyez en tête de pile pendant 30 minutes.'**
  String get plusFeatureBoostDescription;

  /// Titre de la fenêtre « Réservé à mazl+ » pour les confirmations de lecture des messages.
  ///
  /// In fr, this message translates to:
  /// **'Confirmations de lecture'**
  String get plusFeatureReadReceiptsTitle;

  /// Phrase sous le titre de la fenêtre « Réservé à mazl+ » pour les confirmations de lecture.
  ///
  /// In fr, this message translates to:
  /// **'Sachez quand vos messages ont été lus.'**
  String get plusFeatureReadReceiptsDescription;

  /// Titre de la fenêtre « Réservé à mazl+ » pour les filtres avancés, et titre d'un avantage de l'offre.
  ///
  /// In fr, this message translates to:
  /// **'Filtres avancés'**
  String get plusFeatureAdvancedFiltersTitle;

  /// Phrase sous le titre de la fenêtre « Réservé à mazl+ » pour les filtres avancés. « Pratique » = pratique religieuse (casher, Shabbat…).
  ///
  /// In fr, this message translates to:
  /// **'Filtrez par pratique, communauté, et plus.'**
  String get plusFeatureAdvancedFiltersDescription;

  /// Titre de la fenêtre « Réservé à mazl+ » pour le support prioritaire.
  ///
  /// In fr, this message translates to:
  /// **'Support prioritaire'**
  String get plusFeaturePrioritySupportTitle;

  /// Phrase sous le titre de la fenêtre « Réservé à mazl+ » pour le support prioritaire.
  ///
  /// In fr, this message translates to:
  /// **'Obtenez une réponse rapide de notre équipe.'**
  String get plusFeaturePrioritySupportDescription;

  /// Petit titre en capitales au-dessus du titre de la fenêtre qui explique une fonction réservée aux abonnés. « mazl+ » est le nom de marque : il reste écrit tel quel.
  ///
  /// In fr, this message translates to:
  /// **'Réservé à mazl+'**
  String get plusReservedLabel;

  /// Bouton plein des fenêtres du bas et de l'écran Abonnement : ouvre l'offre mazl+. « mazl+ » est le nom de marque, il reste écrit tel quel dans la phrase (« mazl » sera mis en gras, son « + » en couleur).
  ///
  /// In fr, this message translates to:
  /// **'Découvrir mazl+'**
  String get plusDiscover;

  /// Bouton discret de la fenêtre « Réservé à mazl+ » : ferme la fenêtre sans ouvrir l'offre.
  ///
  /// In fr, this message translates to:
  /// **'Pas maintenant'**
  String get plusNotNow;

  /// Petit titre en capitales de la fenêtre « likes du jour épuisés ». {limit} est le nombre de likes gratuits par jour, écrit deux fois (utilisés / total).
  ///
  /// In fr, this message translates to:
  /// **'Limite du jour · {limit} / {limit}'**
  String plusDailyLimitLabel(int limit);

  /// Grand titre de la fenêtre affichée quand les likes gratuits du jour sont épuisés.
  ///
  /// In fr, this message translates to:
  /// **'Vos likes du jour sont partis.'**
  String get plusDailyLimitTitle;

  /// Texte sous le titre de la fenêtre « likes du jour épuisés » : les likes reviennent à minuit, ou l'abonnement lève la limite.
  ///
  /// In fr, this message translates to:
  /// **'Ils reviennent à minuit. Ou continuez sans compter, et voyez qui vous a déjà aimé.'**
  String get plusDailyLimitBody;

  /// Libellé à gauche du compte à rebours (hh:mm:ss) dans la fenêtre « likes du jour épuisés ». Le compte à rebours s'affiche juste après, à droite : le texte doit rester court.
  ///
  /// In fr, this message translates to:
  /// **'Prochains likes dans'**
  String get plusDailyLimitNext;

  /// Bouton discret de la fenêtre « likes du jour épuisés » : ferme la fenêtre sans ouvrir l'offre.
  ///
  /// In fr, this message translates to:
  /// **'Attendre minuit'**
  String get plusDailyLimitWait;

  /// Phrase d'accroche sous le logo « mazl+ » en haut de l'écran d'offre.
  ///
  /// In fr, this message translates to:
  /// **'Rencontrez sans compter.'**
  String get plusOfferTagline;

  /// Ligne grise sous « Likes illimités » dans la liste des avantages de l'offre. 10 = nombre de likes gratuits par jour.
  ///
  /// In fr, this message translates to:
  /// **'Fini les 10 par jour.'**
  String get plusPerkUnlimitedLikesDetail;

  /// Ligne grise sous « Voir qui vous a aimé » dans la liste des avantages de l'offre.
  ///
  /// In fr, this message translates to:
  /// **'Avant même de les croiser.'**
  String get plusPerkSeeWhoDetail;

  /// Titre d'un avantage de l'offre mazl+ (le quota des abonnés).
  ///
  /// In fr, this message translates to:
  /// **'5 Super Likes par jour'**
  String get plusPerkSuperLikesTitle;

  /// Ligne grise sous « 5 Super Likes par jour » : un compte gratuit n'en a qu'un par jour.
  ///
  /// In fr, this message translates to:
  /// **'Au lieu d’un seul.'**
  String get plusPerkSuperLikesDetail;

  /// Titre d'un avantage de l'offre mazl+.
  ///
  /// In fr, this message translates to:
  /// **'Un Boost par jour'**
  String get plusPerkBoostTitle;

  /// Ligne grise sous « Un Boost par jour » dans la liste des avantages de l'offre.
  ///
  /// In fr, this message translates to:
  /// **'En tête de pile pendant 30 minutes.'**
  String get plusPerkBoostDetail;

  /// Ligne grise sous « Filtres avancés » dans la liste des avantages de l'offre. « Pratique » = pratique religieuse.
  ///
  /// In fr, this message translates to:
  /// **'Pratique, communauté, et plus.'**
  String get plusPerkFiltersDetail;

  /// Petit titre en capitales au-dessus de la liste des durées d'abonnement (1, 3, 6, 12 mois).
  ///
  /// In fr, this message translates to:
  /// **'Votre formule'**
  String get plusYourPlan;

  /// Durée d'une formule d'abonnement, en mois : « 1 mois », « 3 mois », « 12 mois ». Sert de titre à chaque ligne de formule et de durée dans l'écran Abonnement et dans les réglages.
  ///
  /// In fr, this message translates to:
  /// **'{months, plural, =1{1 mois} other{{months} mois}}'**
  String plusMonths(int months);

  /// Prix par mois d'une formule, sous sa durée. {price} est le prix déjà formaté avec la devise du magasin (« 15,00 € »).
  ///
  /// In fr, this message translates to:
  /// **'{price} par mois'**
  String plusPerMonth(String price);

  /// Pastille d'économie d'une formule longue par rapport au prix du mois seul. {percent} est un nombre entier (25, 42, 58). Doit rester très court.
  ///
  /// In fr, this message translates to:
  /// **'-{percent} %'**
  String plusPlanSavings(int percent);

  /// Phrase lue par le lecteur d'écran pour une ligne de formule sans économie. {duration} = « 3 mois », {price} = prix total, {perMonth} = « 15,00 € par mois ».
  ///
  /// In fr, this message translates to:
  /// **'{duration}, {price}, {perMonth}'**
  String plusPlanSemantics(String duration, String price, String perMonth);

  /// Phrase lue par le lecteur d'écran pour une ligne de formule avec économie. {saving} = « -25 % ».
  ///
  /// In fr, this message translates to:
  /// **'{duration}, {price}, {perMonth}, économie {saving}'**
  String plusPlanSemanticsSaving(
    String duration,
    String price,
    String perMonth,
    String saving,
  );

  /// Bouton d'achat de l'écran d'offre. {price} est le prix total de la formule choisie, déjà formaté avec la devise du magasin.
  ///
  /// In fr, this message translates to:
  /// **'Continuer · {price}'**
  String plusContinuePrice(String price);

  /// Texte du bouton d'achat (désactivé) et message d'achat sur Android, où l'abonnement n'est pas encore vendu.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible sur Android'**
  String get plusAndroidSoon;

  /// Bouton texte en haut à droite de l'écran d'offre : restaure un achat déjà fait avec cet identifiant Apple.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer'**
  String get plusRestore;

  /// Lien en bas de l'écran d'offre vers les conditions d'utilisation.
  ///
  /// In fr, this message translates to:
  /// **'Conditions'**
  String get plusTerms;

  /// Lien en bas de l'écran d'offre vers la politique de confidentialité.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get plusPrivacy;

  /// Mention légale obligatoire sous le bouton d'achat sur iPhone : l'abonnement se renouvelle seul et se résilie dans les réglages du compte Apple. À traduire fidèlement, sans rien ajouter ni retirer.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement automatique, résiliable à tout moment dans les réglages de l’App Store.'**
  String get plusLegalAppStore;

  /// Mention légale obligatoire sous le bouton d'achat sur Android : l'abonnement se renouvelle seul et se résilie dans les réglages de Google Play. À traduire fidèlement, sans rien ajouter ni retirer.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement automatique, résiliable à tout moment dans les réglages de Google Play.'**
  String get plusLegalGooglePlay;

  /// Message bref après un achat qui attend l'accord d'un parent ou du magasin (Ask to Buy).
  ///
  /// In fr, this message translates to:
  /// **'Achat en attente d’approbation. Votre abonnement s’activera dès qu’il sera validé.'**
  String get plusPendingApproval;

  /// Message bref (vert) quand « Restaurer » depuis l'écran d'offre a retrouvé un abonnement.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement restauré'**
  String get plusOfferRestored;

  /// Message bref quand « Restaurer » depuis l'écran d'offre ne trouve aucun abonnement.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement trouvé'**
  String get plusOfferNothingFound;

  /// Message bref quand le magasin n'a pas encore de produit à vendre (formules de secours affichées).
  ///
  /// In fr, this message translates to:
  /// **'Les abonnements seront disponibles prochainement.'**
  String get plusPlansSoon;

  /// Message bref quand on lance un second achat alors qu'un premier n'est pas terminé.
  ///
  /// In fr, this message translates to:
  /// **'Un achat est déjà en cours.'**
  String get plusErrorPurchaseInProgress;

  /// Message d'erreur : l'abonnement acheté avec cet identifiant Apple est déjà lié à un autre compte mazl.
  ///
  /// In fr, this message translates to:
  /// **'Cet achat App Store est déjà associé à un autre compte mazl.'**
  String get plusErrorOwnedByAnotherAccount;

  /// Message d'erreur : le serveur n'a pas pu valider la transaction Apple ; elle sera revérifiée au prochain lancement de l'app.
  ///
  /// In fr, this message translates to:
  /// **'Nous n’avons pas pu valider cet achat auprès de l’App Store. Il sera revérifié au prochain lancement.'**
  String get plusErrorInvalidTransaction;

  /// Message d'erreur : le serveur a refusé les données envoyées pour l'achat.
  ///
  /// In fr, this message translates to:
  /// **'Votre achat n’a pas pu être transmis correctement. Réessayez dans un instant.'**
  String get plusErrorInvalidBody;

  /// Message d'erreur : la session a expiré pendant l'achat. L'achat est conservé et sera validé après reconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Reconnectez-vous à mazl pour finaliser votre achat.'**
  String get plusErrorSignInAgain;

  /// Message d'erreur : pas de réseau ou serveur injoignable pendant la validation d'un achat. L'achat est gardé et sera validé plus tard.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Votre achat est conservé et sera validé dès que possible.'**
  String get plusErrorOffline;

  /// Message d'erreur général quand un achat échoue sans cause plus précise.
  ///
  /// In fr, this message translates to:
  /// **'L’achat n’a pas pu aboutir. Réessayez dans un instant.'**
  String get plusErrorGeneric;

  /// Message d'erreur : le serveur a bien reçu l'achat mais l'abonnement n'est pas actif (par exemple déjà expiré).
  ///
  /// In fr, this message translates to:
  /// **'Votre abonnement n’est pas actif.'**
  String get plusErrorInactive;

  /// Message d'erreur quand la restauration des achats échoue.
  ///
  /// In fr, this message translates to:
  /// **'La restauration a échoué. Réessayez dans un instant.'**
  String get plusErrorRestoreFailed;

  /// Petit titre en capitales de l'écran de bienvenue (quand la formule est inconnue) et sous-titre de la ligne mazl+ des réglages quand aucun détail n'est connu.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement actif'**
  String get plusActiveSubscription;

  /// Petit titre en capitales de l'écran de bienvenue. {plan} est la durée de la formule (« 6 mois »).
  ///
  /// In fr, this message translates to:
  /// **'Abonnement actif · {plan}'**
  String plusActiveSubscriptionPlan(String plan);

  /// Grand titre de l'écran de bienvenue après l'achat. « mazl+ » est le nom de marque : il reste écrit tel quel (« mazl » en gras, son « + » en couleur).
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans mazl+.'**
  String get plusWelcomeTitle;

  /// Phrase sous le titre de l'écran de bienvenue, avant les trois actions proposées.
  ///
  /// In fr, this message translates to:
  /// **'Tout est déverrouillé. Par où commencer ?'**
  String get plusWelcomeSubtitle;

  /// Titre de la première action de l'écran de bienvenue : combien de membres ont aimé le profil ({count} est toujours au moins 1).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 personne vous a aimé} other{{count} personnes vous ont aimé}}'**
  String plusWelcomeLikesCount(int count);

  /// Ligne grise de la première action de l'écran de bienvenue : ouvre la liste des likes.
  ///
  /// In fr, this message translates to:
  /// **'Les voir maintenant'**
  String get plusWelcomeLikesDetail;

  /// Titre de la deuxième action de l'écran de bienvenue : mène à Découvrir pour lancer un Boost.
  ///
  /// In fr, this message translates to:
  /// **'Lancer votre Boost'**
  String get plusWelcomeBoostTitle;

  /// Ligne grise de l'action « Lancer votre Boost » de l'écran de bienvenue (sans point final).
  ///
  /// In fr, this message translates to:
  /// **'En tête de pile pendant 30 minutes'**
  String get plusWelcomeBoostDetail;

  /// Titre de la troisième action de l'écran de bienvenue : ouvre les filtres.
  ///
  /// In fr, this message translates to:
  /// **'Affiner vos filtres'**
  String get plusWelcomeFiltersTitle;

  /// Ligne grise de l'action « Affiner vos filtres » de l'écran de bienvenue (sans point final). « Pratique » = pratique religieuse.
  ///
  /// In fr, this message translates to:
  /// **'Pratique, communauté, et plus'**
  String get plusWelcomeFiltersDetail;

  /// Phrase lue par le lecteur d'écran pour une action de l'écran de bienvenue : son titre puis sa ligne grise.
  ///
  /// In fr, this message translates to:
  /// **'{title}. {detail}'**
  String plusTitleDetail(String title, String detail);

  /// Grand titre de l'écran de gestion de l'abonnement mazl+.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get plusSubscriptionTitle;

  /// Pastille de la carte mazl+ quand l'abonnement se renouvelle.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get plusStatusActive;

  /// Pastille de la carte mazl+ quand l'abonnement a été résilié et se termine à l'échéance.
  ///
  /// In fr, this message translates to:
  /// **'Résilié'**
  String get plusStatusCancelled;

  /// Petit libellé (affiché en capitales) au-dessus de la durée et du prix de la formule, sur la carte mazl+.
  ///
  /// In fr, this message translates to:
  /// **'Formule'**
  String get plusFactPlan;

  /// Petit libellé (affiché en capitales) au-dessus de la date de prochain renouvellement, sur la carte mazl+.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement'**
  String get plusFactRenewal;

  /// Petit libellé (affiché en capitales) au-dessus de la date de fin quand l'abonnement est résilié.
  ///
  /// In fr, this message translates to:
  /// **'Expiration'**
  String get plusFactExpiration;

  /// Formule sur la carte mazl+ : durée puis prix. {duration} = « 6 mois », {price} = prix du magasin « 59,99 € ».
  ///
  /// In fr, this message translates to:
  /// **'{duration} · {price}'**
  String plusPlanAndPrice(String duration, String price);

  /// Valeur de la ligne Super Likes de l'écran Abonnement : restants sur total du jour (« 4 sur 5 »).
  ///
  /// In fr, this message translates to:
  /// **'{left} sur {max}'**
  String plusSuperLikesOf(int left, int max);

  /// Valeur de la ligne Boost de l'écran Abonnement quand le Boost du jour n'est pas encore utilisé.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get plusBoostAvailable;

  /// Valeur de la ligne Boost de l'écran Abonnement quand le Boost du jour est déjà utilisé.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé aujourd’hui'**
  String get plusBoostUsed;

  /// Libellé de la ligne Likes de l'écran Abonnement.
  ///
  /// In fr, this message translates to:
  /// **'Likes'**
  String get plusLikesLabel;

  /// Valeur de la ligne Likes de l'écran Abonnement : pas de limite quotidienne.
  ///
  /// In fr, this message translates to:
  /// **'Illimités'**
  String get plusLikesUnlimited;

  /// Bouton en contour de l'écran Abonnement sur iPhone : ouvre la gestion des abonnements de l'App Store.
  ///
  /// In fr, this message translates to:
  /// **'Gérer dans l’App Store'**
  String get plusManageAppStore;

  /// Bouton en contour de l'écran Abonnement sur Android : ouvre la gestion des abonnements de Google Play.
  ///
  /// In fr, this message translates to:
  /// **'Gérer dans Google Play'**
  String get plusManageGooglePlay;

  /// Message bref quand la page de gestion des abonnements du magasin ne s'ouvre pas.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir la gestion de l’abonnement.'**
  String get plusManageFailed;

  /// Bouton texte en bas de l'écran Abonnement.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer mes achats'**
  String get plusRestorePurchases;

  /// Texte de l'écran Abonnement quand le membre n'a pas d'abonnement.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement actif.'**
  String get plusNoActiveSubscription;

  /// Message bref de l'écran Abonnement après une restauration réussie.
  ///
  /// In fr, this message translates to:
  /// **'Achats restaurés.'**
  String get plusPurchasesRestored;

  /// Message bref de l'écran Abonnement quand la restauration ne trouve rien.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement trouvé.'**
  String get plusNothingToRestore;

  /// Sous-titre de la ligne « Passer à mazl+ » des réglages (compte gratuit) : les trois avantages phares. Une ligne, 13 px.
  ///
  /// In fr, this message translates to:
  /// **'Likes illimités, voir qui vous a aimé, Boost'**
  String get plusSettingsPitch;

  /// Titre de la ligne des réglages qui mène à l'offre (compte gratuit). « mazl+ » est le nom de marque : il reste écrit tel quel (« mazl » en gras, son « + » en couleur).
  ///
  /// In fr, this message translates to:
  /// **'Passer à mazl+'**
  String get plusUpgradeTo;

  /// Phrase lue par le lecteur d'écran pour la ligne mazl+ des réglages d'un abonné. {detail} = « 6 mois · renouvellement le 12 mars 2027 ».
  ///
  /// In fr, this message translates to:
  /// **'mazl+. {detail}'**
  String plusSettingsSemanticsActive(String detail);

  /// Phrase lue par le lecteur d'écran pour la ligne « Passer à mazl+ » des réglages d'un compte gratuit. {detail} = la liste des avantages phares.
  ///
  /// In fr, this message translates to:
  /// **'Passer à mazl+. {detail}'**
  String plusSettingsSemanticsUpgrade(String detail);

  /// Carte affichée à la place des champs de pratique religieuse (profil, inscription) quand l'app n'a pas pu lire l'état de l'accord de l'article 9 du RGPD (réseau coupé). Un bouton « Réessayer » suit.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier votre accord. Vérifiez votre connexion.'**
  String get privacyGateUnverifiable;

  /// Carte affichée à la place des champs de pratique religieuse tant que le membre n'a pas donné son accord explicite (RGPD article 9). Un bouton « Donner mon accord » suit.
  ///
  /// In fr, this message translates to:
  /// **'Pour renseigner votre pratique, donnez votre accord'**
  String get privacyGateAsk;

  /// Bouton qui ouvre la feuille de consentement aux données de pratique religieuse (carte du profil, écran des réglages). Le membre y donne son accord.
  ///
  /// In fr, this message translates to:
  /// **'Donner mon accord'**
  String get privacyGive;

  /// Phrase sous le champ « Intention » (grisé) tant que le membre n'a pas donné son accord pour les données de pratique religieuse.
  ///
  /// In fr, this message translates to:
  /// **'Disponible une fois votre accord donné pour la pratique religieuse.'**
  String get privacyLockedHint;

  /// Petit libellé en capitales au-dessus du titre de la feuille de consentement et de l'écran des réglages de consentement. Dit de quelle règle il s'agit (données sensibles, article 9 du RGPD).
  ///
  /// In fr, this message translates to:
  /// **'Données sensibles · RGPD article 9'**
  String get privacySheetLabel;

  /// Titre de la feuille qui demande l'accord explicite pour les données de pratique religieuse.
  ///
  /// In fr, this message translates to:
  /// **'Votre pratique religieuse, avec votre accord'**
  String get privacySheetTitle;

  /// Paragraphe d'explication sous le titre de la feuille de consentement, avant le texte juridique exact envoyé par le serveur. Dit à quoi servent les données, qu'elles sont sensibles, que l'accord est distinct des CGU et que refuser est possible.
  ///
  /// In fr, this message translates to:
  /// **'Ces informations aident à proposer des profils compatibles. Ce sont des données sensibles, traitées seulement avec votre accord explicite, distinct des conditions d\'utilisation. Vous pouvez refuser et utiliser MAZL quand même.'**
  String get privacySheetBody;

  /// Case à cocher de la feuille de consentement : le membre confirme avoir lu le texte juridique affiché au-dessus et donne son accord explicite. Le bouton « J'accepte » reste grisé tant qu'elle n'est pas cochée.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai lu ce texte et je donne mon accord explicite.'**
  String get privacySheetCheckbox;

  /// Bouton principal de la feuille de consentement : le membre accepte. Grisé tant que la case n'est pas cochée.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte'**
  String get privacySheetAccept;

  /// Bouton secondaire de la feuille de consentement : le membre refuse et continue sans renseigner sa pratique religieuse.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans'**
  String get privacySheetDecline;

  /// Erreur sous le texte de la feuille de consentement : le serveur a publié une nouvelle version du texte pendant que la feuille était ouverte, la réponse n'a donc pas été enregistrée.
  ///
  /// In fr, this message translates to:
  /// **'Le texte a été mis à jour. Fermez cette fenêtre et rouvrez-la.'**
  String get privacySheetErrorOutdated;

  /// Erreur sous le texte de la feuille de consentement : la réponse du membre (accord ou refus) n'a pas pu être enregistrée (réseau, serveur).
  ///
  /// In fr, this message translates to:
  /// **'Votre choix n\'a pas pu être enregistré. Réessayez.'**
  String get privacySheetErrorSave;

  /// Titre de l'écran des réglages du consentement aux données de pratique religieuse, et libellé de la ligne qui l'ouvre dans les Paramètres.
  ///
  /// In fr, this message translates to:
  /// **'Données de pratique religieuse'**
  String get privacySettingsTitle;

  /// Sous-titre de la ligne « Données de pratique religieuse » des Paramètres quand l'accord est donné et valide.
  ///
  /// In fr, this message translates to:
  /// **'Accordé'**
  String get privacySettingsGrantedShort;

  /// Sous-titre de la ligne « Données de pratique religieuse » des Paramètres quand l'accord n'est pas donné (refusé, retiré ou jamais demandé).
  ///
  /// In fr, this message translates to:
  /// **'Non accordé'**
  String get privacySettingsDeniedShort;

  /// Titre de l'écran de consentement quand l'accord est donné.
  ///
  /// In fr, this message translates to:
  /// **'Accord donné'**
  String get privacySettingsGrantedTitle;

  /// Titre de l'écran de consentement quand l'accord n'est pas donné.
  ///
  /// In fr, this message translates to:
  /// **'Accord non donné'**
  String get privacySettingsNotGrantedTitle;

  /// Bouton qui retire l'accord aux données de pratique religieuse (écran de consentement) et bouton de confirmation de la fenêtre qui s'ouvre ensuite.
  ///
  /// In fr, this message translates to:
  /// **'Retirer mon accord'**
  String get privacySettingsWithdraw;

  /// Titre de la fenêtre de confirmation avant de retirer l'accord.
  ///
  /// In fr, this message translates to:
  /// **'Retirer votre accord ?'**
  String get privacySettingsWithdrawTitle;

  /// Corps de la fenêtre de confirmation avant de retirer l'accord : liste les quatre informations de profil qui seront effacées (courant, kashrout, pratique du Shabbat, intention).
  ///
  /// In fr, this message translates to:
  /// **'Votre courant, votre kashrout, votre pratique du Shabbat et votre intention seront effacés de votre profil.'**
  String get privacySettingsWithdrawBody;

  /// Message bref (snackbar) quand le retrait de l'accord n'a pas pu être enregistré.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de retirer votre accord. Réessayez.'**
  String get privacySettingsWithdrawFailed;

  /// Texte de l'écran de consentement quand l'état de l'accord n'a pas pu être chargé. Un bouton « Réessayer » suit.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre accord. Vérifiez votre connexion.'**
  String get privacySettingsLoadFailed;

  /// Profil du membre : étiquette en capitales tout en haut de son propre profil.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get profileMyProfile;

  /// Bouton court qui ouvre la modification (profil, question de profil). Une ligne, environ 12 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get profileEdit;

  /// Info-bulle de l'icône qui ouvre les réglages, en haut de son propre profil.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get profileSettings;

  /// Info-bulle de l'icône « … » du profil d'un autre membre (bloquer, signaler).
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'options'**
  String get profileMoreOptions;

  /// Info-bulle de la croix ronde du profil d'un autre membre : passer cette personne sans l'aimer.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get profilePass;

  /// Bouton principal en bas du profil d'un autre membre : aimer cette personne. {name} est son prénom. Une seule ligne, environ 20 caractères.
  ///
  /// In fr, this message translates to:
  /// **'J\'aime {name}'**
  String profileLikeName(String name);

  /// Repli à la place du prénom quand il manque, par exemple « J'aime cette personne ». En minuscules, au nominatif.
  ///
  /// In fr, this message translates to:
  /// **'cette personne'**
  String get profileThisPerson;

  /// Nom affiché quand un membre n'a pas de prénom.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get profileFallbackName;

  /// Nom d'un membre sans prénom, dans la fenêtre de blocage et de signalement. Commence une phrase.
  ///
  /// In fr, this message translates to:
  /// **'Cet utilisateur'**
  String get profileFallbackReportName;

  /// Lieu affiché quand le membre n'a pas indiqué sa ville : le pays par défaut.
  ///
  /// In fr, this message translates to:
  /// **'France'**
  String get profileDefaultLocation;

  /// Distance d'un profil, quand la personne est à moins d'un kilomètre. Suit la ville : « Paris · à moins de 1 km ».
  ///
  /// In fr, this message translates to:
  /// **'à moins de 1 km'**
  String get profileDistanceUnderOneKm;

  /// Distance d'un profil en kilomètres. Suit la ville : « Paris · à 4 km ».
  ///
  /// In fr, this message translates to:
  /// **'à {km} km'**
  String profileDistanceKm(int km);

  /// Genre d'un membre, dans « L'essentiel ».
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get profileGenderMale;

  /// Genre d'un membre, dans « L'essentiel ».
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get profileGenderFemale;

  /// Rangée de « L'essentiel » (et critère de compatibilité) : le courant du judaïsme pratiqué, par exemple Massorti.
  ///
  /// In fr, this message translates to:
  /// **'Pratique'**
  String get profileFactPractice;

  /// Rangée de « L'essentiel » : le niveau de cacherout du membre.
  ///
  /// In fr, this message translates to:
  /// **'Cacherout'**
  String get profileFactKashrut;

  /// Titre d'un champ : l'observance du Shabbat (profil, modification, inscription).
  ///
  /// In fr, this message translates to:
  /// **'Shabbat'**
  String get profileShabbat;

  /// Rangée de « L'essentiel » : le genre du membre.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get profileFactGender;

  /// Titre de section en capitales : les faits principaux d'un profil (pratique, cacherout, Shabbat, genre).
  ///
  /// In fr, this message translates to:
  /// **'L\'essentiel'**
  String get profileEssentials;

  /// Titre de section en capitales : les réponses d'un membre à ses questions de profil.
  ///
  /// In fr, this message translates to:
  /// **'En quelques mots'**
  String get profileInAFewWords;

  /// Titre de section : la présentation écrite par le membre (profil et modification).
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get profileAbout;

  /// Titre de section : ce que le membre cherche (texte libre et choix d'intention).
  ///
  /// In fr, this message translates to:
  /// **'Ce que je recherche'**
  String get profileLookingFor;

  /// Bouton sous la galerie d'un profil sans photo : ouvre la modification des photos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des photos'**
  String get profileAddPhotos;

  /// Pastille d'un profil dont l'identité est vérifiée.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get profileVerified;

  /// Pastille d'un profil vérifié au niveau supérieur (selfie et pièce d'identité).
  ///
  /// In fr, this message translates to:
  /// **'Vérifié+'**
  String get profileVerifiedPlus;

  /// Pastille touchable sur son propre profil : mène à l'écran de vérification.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier mon profil'**
  String get profileVerifyMyProfile;

  /// Libellé d'accessibilité (lecteur d'écran) de la pastille de vérification. {status} est « Vérifié » ou « Vérifié+ ».
  ///
  /// In fr, this message translates to:
  /// **'Statut de vérification : {status}'**
  String profileVerificationStatus(String status);

  /// Libellé d'accessibilité de la zone tactile qui montre la photo précédente.
  ///
  /// In fr, this message translates to:
  /// **'Photo précédente'**
  String get profilePhotoPrevious;

  /// Libellé d'accessibilité de la zone tactile qui montre la photo suivante.
  ///
  /// In fr, this message translates to:
  /// **'Photo suivante'**
  String get profilePhotoNext;

  /// Libellé d'accessibilité du compteur de la galerie, par exemple « Photo 2 sur 4 ».
  ///
  /// In fr, this message translates to:
  /// **'Photo {current} sur {total}'**
  String profilePhotoCounter(int current, int total);

  /// Étiquette en capitales de la carte « Complétez votre profil » : étapes faites sur le total, par exemple « Profil · 2/4 ».
  ///
  /// In fr, this message translates to:
  /// **'Profil · {done}/{total}'**
  String profileCompletionEyebrow(int done, int total);

  /// Titre de la carte qui invite à finir son profil.
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre profil'**
  String get profileCompletionTitle;

  /// Sous le titre de la carte de complétion : le nombre d'étapes qu'il reste à faire (toujours au moins 1).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} étape restante} other{{count} étapes restantes}}'**
  String profileCompletionRemaining(int count);

  /// Bouton de la carte de complétion : ouvre la première étape qu'il reste à faire.
  ///
  /// In fr, this message translates to:
  /// **'Compléter maintenant'**
  String get profileCompletionAction;

  /// Étape de complétion faite (rayée) : au moins deux photos.
  ///
  /// In fr, this message translates to:
  /// **'Photos ajoutées'**
  String get profileStepPhotosDone;

  /// Étape de complétion à faire : ajouter des photos.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins 2 photos'**
  String get profileStepPhotosTodo;

  /// Étape de complétion faite (rayée) : la présentation est écrite.
  ///
  /// In fr, this message translates to:
  /// **'Bio complétée'**
  String get profileStepBioDone;

  /// Étape de complétion à faire : écrire sa présentation.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez-vous en quelques lignes'**
  String get profileStepBioTodo;

  /// Étape de complétion faite (rayée) : la ville est indiquée.
  ///
  /// In fr, this message translates to:
  /// **'Ville renseignée'**
  String get profileStepCityDone;

  /// Étape de complétion à faire : indiquer sa ville.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre ville'**
  String get profileStepCityTodo;

  /// Étape de complétion faite (rayée) : le profil est vérifié.
  ///
  /// In fr, this message translates to:
  /// **'Profil vérifié'**
  String get profileStepVerifiedDone;

  /// Étape de complétion à faire : faire vérifier son profil.
  ///
  /// In fr, this message translates to:
  /// **'Faites vérifier votre profil'**
  String get profileStepVerifiedTodo;

  /// Titre de section en capitales, sur le profil d'un match : l'entrée du mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Mode couple'**
  String get profileCoupleMode;

  /// Mode couple : titre quand le membre est déjà en couple avec cette personne.
  ///
  /// In fr, this message translates to:
  /// **'En couple'**
  String get profileCoupleInCoupleTitle;

  /// Mode couple : explication quand les deux sont déjà en couple. {name} est le prénom de la personne.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes en mode couple avec {name}.'**
  String profileCoupleInCoupleBody(String name);

  /// Mode couple : titre quand le membre qui regarde est déjà en couple avec quelqu'un d'autre.
  ///
  /// In fr, this message translates to:
  /// **'Déjà en mode couple'**
  String get profileCoupleElsewhereTitle;

  /// Mode couple : explication quand le membre qui regarde est déjà en couple avec quelqu'un d'autre.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes déjà en mode couple avec quelqu\'un d\'autre.'**
  String get profileCoupleElsewhereBody;

  /// Mode couple : titre quand l'autre personne a demandé le mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Demande reçue'**
  String get profileCoupleReceivedTitle;

  /// Mode couple : explication d'une demande reçue. {name} est le prénom de la personne.
  ///
  /// In fr, this message translates to:
  /// **'{name} souhaite activer le mode couple avec vous.'**
  String profileCoupleReceivedBody(String name);

  /// Mode couple : bouton qui ouvre la réponse à une demande reçue.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get profileCoupleRespond;

  /// Mode couple : titre quand le membre a envoyé une demande qui attend sa réponse.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get profileCouplePendingTitle;

  /// Mode couple : explication d'une demande en attente. {name} est le prénom de la personne.
  ///
  /// In fr, this message translates to:
  /// **'{name} n\'a pas encore répondu.'**
  String profileCouplePendingBody(String name);

  /// Mode couple : bouton qui annule une demande envoyée.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la demande'**
  String get profileCoupleCancelRequest;

  /// Mode couple : titre quand une demande peut être envoyée.
  ///
  /// In fr, this message translates to:
  /// **'Passer au mode couple'**
  String get profileCoupleAvailableTitle;

  /// Mode couple : invitation à l'activer après un match.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez matché. Activez le mode couple pour partager des activités ensemble.'**
  String get profileCoupleAvailableBody;

  /// Mode couple : bouton qui envoie la demande. {name} est le prénom de la personne. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Activer avec {name}'**
  String profileCoupleActivate(String name);

  /// Message bref (snackbar) après l'envoi d'une demande de mode couple. {name} est le prénom de la personne.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée à {name}.'**
  String profileCoupleRequestSent(String name);

  /// Titre de section en capitales sur le profil d'un autre membre, et titre de la carte de score.
  ///
  /// In fr, this message translates to:
  /// **'Compatibilité'**
  String get profileCompatibility;

  /// Palier de compatibilité le plus haut (score de 85 % ou plus).
  ///
  /// In fr, this message translates to:
  /// **'Très compatible'**
  String get profileCompatibilityVeryHigh;

  /// Palier de compatibilité : score de 60 à 84 %.
  ///
  /// In fr, this message translates to:
  /// **'Compatible'**
  String get profileCompatibilityHigh;

  /// Palier de compatibilité : score de 40 à 59 %.
  ///
  /// In fr, this message translates to:
  /// **'Compatibilité moyenne'**
  String get profileCompatibilityAverage;

  /// Palier de compatibilité : score sous 40 %.
  ///
  /// In fr, this message translates to:
  /// **'Peu compatible'**
  String get profileCompatibilityLow;

  /// Explication du score quand aucun critère détaillé n'est disponible.
  ///
  /// In fr, this message translates to:
  /// **'Calculée à partir de vos deux profils.'**
  String get profileCompatibilityBasis;

  /// Message neutre quand le score de compatibilité n'a pas pu être calculé (abonné).
  ///
  /// In fr, this message translates to:
  /// **'Compatibilité indisponible pour le moment.'**
  String get profileCompatibilityUnavailable;

  /// Invitation (non abonné) à débloquer le score. {name} est le prénom de la personne. Deux ou trois lignes.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez votre score de compatibilité avec {name}.'**
  String profileCompatibilityUnlockTitle(String name);

  /// Sous l'invitation à débloquer le score : ce sur quoi il est calculé.
  ///
  /// In fr, this message translates to:
  /// **'Calculé à partir de vos pratiques, vos intentions et vos valeurs.'**
  String get profileCompatibilityUnlockBody;

  /// Bouton qui ouvre l'abonnement mazl+ pour voir le score. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer avec mazl+'**
  String get profileCompatibilityUnlock;

  /// Nom d'un critère de compatibilité : ce que chacun recherche.
  ///
  /// In fr, this message translates to:
  /// **'Intentions'**
  String get profileFactorIntentions;

  /// Nom d'un critère de compatibilité : l'écart d'âge.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get profileFactorAge;

  /// Nom d'un critère de compatibilité : l'éloignement.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get profileFactorDistance;

  /// Constat d'un critère de compatibilité : les deux membres cherchent la même chose.
  ///
  /// In fr, this message translates to:
  /// **'Vous cherchez la même chose'**
  String get profileVerdictSameIntention;

  /// Constat d'un critère de compatibilité : les intentions diffèrent.
  ///
  /// In fr, this message translates to:
  /// **'Intentions différentes'**
  String get profileVerdictDifferentIntention;

  /// Constat d'un critère de compatibilité : le même courant du judaïsme.
  ///
  /// In fr, this message translates to:
  /// **'Même dénomination'**
  String get profileVerdictSameDenomination;

  /// Constat d'un critère de compatibilité : des courants proches.
  ///
  /// In fr, this message translates to:
  /// **'Pratique similaire'**
  String get profileVerdictSimilarPractice;

  /// Constat d'un critère de compatibilité : des courants éloignés.
  ///
  /// In fr, this message translates to:
  /// **'Pratique différente'**
  String get profileVerdictDifferentPractice;

  /// Constat d'un critère de compatibilité : 3 ans d'écart ou moins.
  ///
  /// In fr, this message translates to:
  /// **'Âge très proche'**
  String get profileVerdictVeryCloseAge;

  /// Constat d'un critère de compatibilité : 4 à 5 ans d'écart.
  ///
  /// In fr, this message translates to:
  /// **'Âge proche'**
  String get profileVerdictCloseAge;

  /// Constat d'un critère de compatibilité : 6 à 10 ans d'écart.
  ///
  /// In fr, this message translates to:
  /// **'Différence d\'âge modérée'**
  String get profileVerdictModerateAgeGap;

  /// Constat d'un critère de compatibilité : plus de 10 ans d'écart.
  ///
  /// In fr, this message translates to:
  /// **'Grande différence d\'âge'**
  String get profileVerdictLargeAgeGap;

  /// Constat d'un critère de compatibilité : à moins de 10 km.
  ///
  /// In fr, this message translates to:
  /// **'Très proche (< 10 km)'**
  String get profileVerdictVeryNear;

  /// Constat d'un critère de compatibilité : à moins de 25 km.
  ///
  /// In fr, this message translates to:
  /// **'Proche (< 25 km)'**
  String get profileVerdictNear;

  /// Constat d'un critère de compatibilité : entre 25 et 50 km.
  ///
  /// In fr, this message translates to:
  /// **'Distance modérée'**
  String get profileVerdictModerateDistance;

  /// Constat d'un critère de compatibilité : à plus de 50 km.
  ///
  /// In fr, this message translates to:
  /// **'Assez loin'**
  String get profileVerdictFar;

  /// Modification du profil : titre de la section des questions de profil.
  ///
  /// In fr, this message translates to:
  /// **'Mes Prompts'**
  String get profilePromptsMine;

  /// Modification du profil : sous-titre de la section des questions, petit corps.
  ///
  /// In fr, this message translates to:
  /// **'Répondez à des questions pour montrer votre personnalité'**
  String get profilePromptsSubtitle;

  /// Message bref (snackbar) quand le membre veut ajouter plus de questions que le maximum. {max} vaut 3.
  ///
  /// In fr, this message translates to:
  /// **'Maximum {max} prompts atteint'**
  String profilePromptsMaxReached(int max);

  /// Message bref (snackbar) quand il ne reste aucune question à ajouter.
  ///
  /// In fr, this message translates to:
  /// **'Tous les prompts sont déjà utilisés'**
  String get profilePromptsAllUsed;

  /// Bouton en pointillés qui ouvre la liste des questions de profil à choisir.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un prompt'**
  String get profilePromptAdd;

  /// Titre de la feuille qui liste les questions de profil à choisir.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un prompt'**
  String get profilePromptChoose;

  /// Indication du champ où le membre écrit sa réponse à une question de profil (150 caractères au plus).
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse…'**
  String get profilePromptYourAnswer;

  /// Titre de la boîte de dialogue qui confirme la suppression d'une question de profil.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce prompt ?'**
  String get profilePromptDeleteTitle;

  /// Phrase d'avertissement d'une confirmation de suppression (avec point final).
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get profileIrreversibleSentence;

  /// Phrase d'avertissement sous le titre de la feuille de suppression d'une photo (sans point final).
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible'**
  String get profileIrreversible;

  /// Message bref (snackbar) après la suppression d'une question de profil.
  ///
  /// In fr, this message translates to:
  /// **'Prompt supprimé'**
  String get profilePromptDeleted;

  /// Famille de questions de profil, titre de groupe dans la liste.
  ///
  /// In fr, this message translates to:
  /// **'Personnalité'**
  String get profilePromptCategoryPersonality;

  /// Famille de questions de profil, titre de groupe dans la liste.
  ///
  /// In fr, this message translates to:
  /// **'Mode de vie'**
  String get profilePromptCategoryLifestyle;

  /// Famille de questions de profil sur le judaïsme, titre de groupe dans la liste.
  ///
  /// In fr, this message translates to:
  /// **'Judaïsme'**
  String get profilePromptCategoryJewish;

  /// Famille de questions de profil pour lancer une conversation, titre de groupe dans la liste.
  ///
  /// In fr, this message translates to:
  /// **'Conversation'**
  String get profilePromptCategoryConversation;

  /// Choix « Autre » : famille de questions inconnue, ou courant du judaïsme non listé.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get profileOther;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Mon dimanche parfait...'**
  String get profilePromptPerfectSunday;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Un fait surprenant sur moi...'**
  String get profilePromptFunFact;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Un de mes objectifs dans la vie...'**
  String get profilePromptLifeGoal;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui m\'énerve le plus...'**
  String get profilePromptPetPeeve;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Je suis fier(e) de...'**
  String get profilePromptProudOf;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Je cherche quelqu\'un qui...'**
  String get profilePromptLookingFor;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Mes vacances idéales...'**
  String get profilePromptIdealVacation;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Mon plat préféré...'**
  String get profilePromptFavoriteFood;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Mon talent caché...'**
  String get profilePromptHiddenTalent;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'En ce moment je regarde...'**
  String get profilePromptBingeWatching;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Mon Shabbat idéal...'**
  String get profilePromptShabbatIdeal;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Une tradition familiale que j\'adore...'**
  String get profilePromptFamilyTradition;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Ma fête juive préférée...'**
  String get profilePromptFavoriteHoliday;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Le vendredi soir chez moi...'**
  String get profilePromptFridayNight;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Mon meilleur souvenir en Israël...'**
  String get profilePromptIsraelMemory;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Une valeur juive qui me guide...'**
  String get profilePromptJewishValue;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Débattez avec moi sur…'**
  String get profilePromptDebateMe;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Apprenez-moi quelque chose sur…'**
  String get profilePromptTeachMe;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Ensemble on pourrait...'**
  String get profilePromptTogetherWeCould;

  /// Question de profil du catalogue (le membre y répond en une phrase). Elle se termine par des points de suspension : la réponse la complète.
  ///
  /// In fr, this message translates to:
  /// **'Premier date idéal...'**
  String get profilePromptFirstDate;

  /// Modification du profil : sous-titre du choix d'intention, petit corps.
  ///
  /// In fr, this message translates to:
  /// **'Montrez aux autres ce que vous recherchez'**
  String get profileIntentionHint;

  /// Intention de relation : se marier. Pastille de profil, choix du sélecteur et choix d'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Mariage'**
  String get profileIntentionMarriage;

  /// Intention de relation : une relation sérieuse. Pastille de profil, choix du sélecteur et choix d'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Relation sérieuse'**
  String get profileIntentionSerious;

  /// Intention de relation : ouvert à tout, sur la pastille d'un profil.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert à tout'**
  String get profileIntentionOpen;

  /// Intention de relation : ouvert à tout, dans le sélecteur du profil (forme écrite avec le « e » facultatif).
  ///
  /// In fr, this message translates to:
  /// **'Ouvert(e) à tout'**
  String get profileIntentionOpenSelector;

  /// Intention de relation : commencer par l'amitié.
  ///
  /// In fr, this message translates to:
  /// **'Amitié d\'abord'**
  String get profileIntentionFriendsFirst;

  /// Choix d'objectif à l'inscription : le membre ne sait pas encore.
  ///
  /// In fr, this message translates to:
  /// **'Je ne sais pas'**
  String get profileIntentionUndecided;

  /// Sous l'intention « Mariage » : explication courte.
  ///
  /// In fr, this message translates to:
  /// **'Je cherche mon/ma futur(e) mari/femme'**
  String get profileIntentionMarriageDescription;

  /// Sous l'intention « Relation sérieuse » : explication courte.
  ///
  /// In fr, this message translates to:
  /// **'Je cherche une relation durable'**
  String get profileIntentionSeriousDescription;

  /// Sous l'intention « Ouvert à tout » : explication courte.
  ///
  /// In fr, this message translates to:
  /// **'On verra où ça nous mène'**
  String get profileIntentionOpenDescription;

  /// Sous l'intention « Amitié d'abord » : explication courte.
  ///
  /// In fr, this message translates to:
  /// **'Commençons par apprendre à se connaître'**
  String get profileIntentionFriendsFirstDescription;

  /// Titre d'un champ : le courant du judaïsme pratiqué (modification et inscription).
  ///
  /// In fr, this message translates to:
  /// **'Dénomination'**
  String get profileDenomination;

  /// Courant du judaïsme : laïque.
  ///
  /// In fr, this message translates to:
  /// **'Laïque'**
  String get profileDenominationSecular;

  /// Courant du judaïsme : traditionaliste (attaché aux traditions sans suivre une pratique stricte).
  ///
  /// In fr, this message translates to:
  /// **'Traditionaliste'**
  String get profileDenominationTraditional;

  /// Courant du judaïsme : massorti, le mouvement conservative.
  ///
  /// In fr, this message translates to:
  /// **'Massorti'**
  String get profileDenominationMasorti;

  /// Courant du judaïsme : libéral, réformé.
  ///
  /// In fr, this message translates to:
  /// **'Libéral'**
  String get profileDenominationLiberal;

  /// Courant du judaïsme : orthodoxe moderne (sioniste religieux).
  ///
  /// In fr, this message translates to:
  /// **'Orthodoxe moderne'**
  String get profileDenominationModernOrthodox;

  /// Courant du judaïsme : orthodoxe.
  ///
  /// In fr, this message translates to:
  /// **'Orthodoxe'**
  String get profileDenominationOrthodox;

  /// Courant du judaïsme : Habad-Loubavitch (nom propre).
  ///
  /// In fr, this message translates to:
  /// **'Habad'**
  String get profileDenominationChabad;

  /// Titre d'un champ : le niveau de cacherout (modification et inscription).
  ///
  /// In fr, this message translates to:
  /// **'Kashrout'**
  String get profileFieldKashrut;

  /// Cacherout : le membre ne la suit pas.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get profileKashrutNone;

  /// Cacherout, sur le profil : le membre la suit chez lui.
  ///
  /// In fr, this message translates to:
  /// **'Cacher à la maison'**
  String get profileKashrutHome;

  /// Cacherout, sur le profil : le membre la suit strictement.
  ///
  /// In fr, this message translates to:
  /// **'Cacher strict'**
  String get profileKashrutStrict;

  /// Cacherout, sur le profil : viande glatt.
  ///
  /// In fr, this message translates to:
  /// **'Glatt cacher'**
  String get profileKashrutGlatt;

  /// Cacherout, choix de la modification et de l'inscription : à la maison seulement.
  ///
  /// In fr, this message translates to:
  /// **'À la maison'**
  String get profileKashrutOptionHome;

  /// Cacherout, choix de la modification et de l'inscription : strict.
  ///
  /// In fr, this message translates to:
  /// **'Strict'**
  String get profileKashrutOptionStrict;

  /// Cacherout, choix de la modification et de l'inscription : glatt.
  ///
  /// In fr, this message translates to:
  /// **'Glatt'**
  String get profileKashrutOptionGlatt;

  /// Shabbat : le membre ne l'observe pas (profil, modification et inscription).
  ///
  /// In fr, this message translates to:
  /// **'Non observant'**
  String get profileShabbatNotObservant;

  /// Shabbat, sur le profil : observé en partie.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat en partie'**
  String get profileShabbatPartial;

  /// Shabbat, sur le profil : observé.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat observé'**
  String get profileShabbatObserved;

  /// Shabbat, sur le profil : observé strictement.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat strict'**
  String get profileShabbatStrict;

  /// Shabbat, sur le profil : vécu en famille.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat en famille'**
  String get profileShabbatFamily;

  /// Shabbat, choix de la modification et de l'inscription : en partie.
  ///
  /// In fr, this message translates to:
  /// **'Partiellement'**
  String get profileShabbatOptionPartial;

  /// Shabbat, choix de la modification et de l'inscription : observant.
  ///
  /// In fr, this message translates to:
  /// **'Observant'**
  String get profileShabbatOptionObservant;

  /// Shabbat, choix de la modification et de l'inscription : très observant.
  ///
  /// In fr, this message translates to:
  /// **'Très observant'**
  String get profileShabbatOptionStrict;

  /// Titre d'un champ de l'inscription : à quelle fréquence le membre va à la synagogue.
  ///
  /// In fr, this message translates to:
  /// **'Synagogue'**
  String get profileSynagogue;

  /// Fréquence des visites à la synagogue : tous les jours.
  ///
  /// In fr, this message translates to:
  /// **'Quotidien'**
  String get profileSynagogueDaily;

  /// Fréquence des visites à la synagogue : chaque semaine.
  ///
  /// In fr, this message translates to:
  /// **'Chaque semaine'**
  String get profileSynagogueWeekly;

  /// Fréquence des visites à la synagogue : pour les fêtes.
  ///
  /// In fr, this message translates to:
  /// **'Fêtes'**
  String get profileSynagogueHolidays;

  /// Fréquence des visites à la synagogue : rarement.
  ///
  /// In fr, this message translates to:
  /// **'Rarement'**
  String get profileSynagogueRarely;

  /// Titre de la barre du haut de l'écran de modification du profil.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profileEditTitle;

  /// Modification du profil : titre de la section des photos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get profilePhotos;

  /// Modification du profil : astuce sous le titre des photos, petit corps.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez appuyé pour définir comme principale'**
  String get profilePhotosHint;

  /// Indication du champ de présentation (500 caractères au plus).
  ///
  /// In fr, this message translates to:
  /// **'Parlez de vous…'**
  String get profileBioHint;

  /// Modification du profil : titre de la section prénom et ville.
  ///
  /// In fr, this message translates to:
  /// **'Informations de base'**
  String get profileBasicInfo;

  /// Titre d'un champ : le prénom du membre.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get profileFirstName;

  /// Titre d'un champ : la ville du membre.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get profileCity;

  /// Modification du profil : titre de la section courant, cacherout et Shabbat.
  ///
  /// In fr, this message translates to:
  /// **'Ma pratique'**
  String get profilePracticeTitle;

  /// Étiquette minuscule (10 pt) sur la photo principale de la grille. Un mot court.
  ///
  /// In fr, this message translates to:
  /// **'Principal'**
  String get profilePrimaryPhoto;

  /// Indication du champ de saisie du prénom dans la feuille de modification.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre prénom'**
  String get profileEnterFirstName;

  /// Indication du champ de saisie de la ville dans la feuille de modification.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre ville'**
  String get profileEnterCity;

  /// Message bref (snackbar) après l'enregistrement du profil.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour'**
  String get profileUpdated;

  /// Message bref (snackbar) après l'envoi d'une photo.
  ///
  /// In fr, this message translates to:
  /// **'Photo ajoutée'**
  String get profilePhotoAdded;

  /// Message bref (snackbar) quand l'envoi de photo n'est pas disponible.
  ///
  /// In fr, this message translates to:
  /// **'Upload non disponible pour le moment'**
  String get profileUploadUnavailable;

  /// Titre de la feuille qui confirme la suppression d'une photo.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo ?'**
  String get profileDeletePhotoTitle;

  /// Message bref (snackbar) après la suppression d'une photo.
  ///
  /// In fr, this message translates to:
  /// **'Photo supprimée'**
  String get profilePhotoDeleted;

  /// Message bref (snackbar) quand le service des photos ne répond pas.
  ///
  /// In fr, this message translates to:
  /// **'Service temporairement indisponible'**
  String get profileServiceUnavailable;

  /// Message bref (snackbar) après le choix d'une nouvelle photo principale.
  ///
  /// In fr, this message translates to:
  /// **'Photo principale mise à jour'**
  String get profilePrimaryUpdated;

  /// Titre de la barre du haut de l'inscription : étape en cours sur le total, par exemple « Étape 2/4 ».
  ///
  /// In fr, this message translates to:
  /// **'Étape {step}/{total}'**
  String profileSetupStep(int step, int total);

  /// Bouton plein du bas de l'inscription : passe à l'étape suivante.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get profileSetupNext;

  /// Bouton plein du bas de la dernière étape de l'inscription : enregistre le profil.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get profileSetupFinish;

  /// Message d'erreur bref (snackbar) : le prénom est obligatoire à l'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre prénom pour continuer'**
  String get profileSetupNameRequired;

  /// Message d'erreur bref (snackbar) : la date de naissance est obligatoire à l'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre date de naissance'**
  String get profileSetupBirthdateRequired;

  /// Message d'erreur bref (snackbar) : le genre est obligatoire à l'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez votre genre'**
  String get profileSetupGenderRequired;

  /// Titre du champ de la date de naissance, et titre du sélecteur de date.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get profileBirthdate;

  /// Indication du champ de date de naissance : l'ordre jour, mois, année tel qu'on l'écrit dans cette langue (même ordre que la date affichée).
  ///
  /// In fr, this message translates to:
  /// **'JJ/MM/AAAA'**
  String get profileBirthdateHint;

  /// Inscription, étape 1 : grand titre (28 pt).
  ///
  /// In fr, this message translates to:
  /// **'Parlez-nous de vous'**
  String get profileSetupAboutYouTitle;

  /// Inscription, étape 1 : sous-titre.
  ///
  /// In fr, this message translates to:
  /// **'Ces informations seront visibles sur votre profil'**
  String get profileSetupAboutYouSubtitle;

  /// Indication du champ du prénom à l'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Comment vous appelez-vous ?'**
  String get profileFirstNameHint;

  /// Inscription : titre du choix de son propre genre, suivi de « Un homme » / « Une femme ».
  ///
  /// In fr, this message translates to:
  /// **'Je suis'**
  String get profileIAm;

  /// Choix de genre à l'inscription (« Je suis… » ou « Je recherche… »). Une ligne dans une pastille de moitié d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Un homme'**
  String get profileAMan;

  /// Choix de genre à l'inscription (« Je suis… » ou « Je recherche… »). Une ligne dans une pastille de moitié d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Une femme'**
  String get profileAWoman;

  /// Indication du champ de la ville à l'inscription.
  ///
  /// In fr, this message translates to:
  /// **'Où habitez-vous ?'**
  String get profileCityHint;

  /// Inscription, étape 2 : grand titre.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des photos'**
  String get profileSetupPhotosTitle;

  /// Inscription, étape 2 : sous-titre.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins 2 photos pour continuer'**
  String get profileSetupPhotosSubtitle;

  /// Inscription, étape 2 : conseil dans un encadré, petit corps.
  ///
  /// In fr, this message translates to:
  /// **'Les profils avec des photos de bonne qualité reçoivent 3x plus de matchs.'**
  String get profileSetupPhotosTip;

  /// Inscription, étape 3 : grand titre.
  ///
  /// In fr, this message translates to:
  /// **'Votre pratique'**
  String get profileSetupPracticeTitle;

  /// Inscription, étape 3 : sous-titre.
  ///
  /// In fr, this message translates to:
  /// **'Aidez-nous à trouver quelqu\'un qui vous correspond'**
  String get profileSetupPracticeSubtitle;

  /// Inscription, étape 4 : grand titre.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous recherchez'**
  String get profileSetupLookingTitle;

  /// Inscription, étape 4 : sous-titre.
  ///
  /// In fr, this message translates to:
  /// **'Aidez-nous à vous montrer les bons profils'**
  String get profileSetupLookingSubtitle;

  /// Inscription, étape 4 : titre du choix du genre recherché, suivi de « Un homme » / « Une femme ».
  ///
  /// In fr, this message translates to:
  /// **'Je recherche'**
  String get profileILookFor;

  /// Inscription, étape 4 : titre du curseur de la tranche d'âge recherchée.
  ///
  /// In fr, this message translates to:
  /// **'Tranche d\'âge'**
  String get profileAgeRange;

  /// Inscription, étape 4 : titre du curseur de la distance maximale.
  ///
  /// In fr, this message translates to:
  /// **'Distance maximale'**
  String get profileMaxDistance;

  /// Inscription, étape 4 : bulle du curseur de distance, par exemple « 50 km ».
  ///
  /// In fr, this message translates to:
  /// **'{km} km'**
  String profileDistanceSliderLabel(int km);

  /// Inscription, étape 4 : titre du choix de l'objectif (mariage, relation sérieuse…).
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get profileGoal;

  /// Inscription, étape 4 : encadré en bas, petit corps. Dit à quoi servent les préférences : composer le fil Découvrir.
  ///
  /// In fr, this message translates to:
  /// **'Ces préférences composent votre fil Découvrir. Vous pourrez les modifier à tout moment.'**
  String get profileSetupPreferencesNote;

  /// Bouton texte en bas du profil d'un autre membre : ouvre la fenêtre de blocage et de signalement.
  ///
  /// In fr, this message translates to:
  /// **'Signaler ce profil'**
  String get profileReportThisProfile;

  /// Message bref (snackbar) sur la page d'un profil : le like, le passer ou le super like n'est pas parti (réseau, serveur).
  ///
  /// In fr, this message translates to:
  /// **'Votre choix n\'est pas parti. Réessayez.'**
  String get profileChoiceNotSent;

  /// Bloquer un membre : titre de l'option dans la feuille « Bloquer / Signaler » et bouton rouge de la boîte de confirmation.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer'**
  String get safetyBlock;

  /// Sous le titre « Bloquer », dans la feuille « Bloquer / Signaler » : ce que le blocage fait.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne ne pourra plus vous voir ni vous contacter'**
  String get safetyBlockSubtitle;

  /// Sous le titre « Signaler », dans la feuille « Bloquer / Signaler » : ce que le signalement permet.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un comportement inapproprié'**
  String get safetyReportSubtitle;

  /// Titre de la boîte de dialogue qui demande de confirmer le blocage d'un membre.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer cet utilisateur ?'**
  String get safetyBlockConfirmTitle;

  /// Introduit la liste des conséquences du blocage, dans la boîte de confirmation. {name} est le prénom du membre.
  ///
  /// In fr, this message translates to:
  /// **'En bloquant {name} :'**
  String safetyBlockConfirmIntro(String name);

  /// Conséquence du blocage (puce de la liste) : le membre bloqué ne voit plus le profil de la personne.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne ne pourra plus voir votre profil'**
  String get safetyBlockEffectHidden;

  /// Conséquence du blocage (puce de la liste) : la personne ne voit plus le profil du membre bloqué.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne verrez plus son profil'**
  String get safetyBlockEffectNotSeen;

  /// Conséquence du blocage (puce de la liste) : les conversations avec ce membre disparaissent.
  ///
  /// In fr, this message translates to:
  /// **'Vos conversations seront supprimées'**
  String get safetyBlockEffectChats;

  /// Conséquence du blocage (puce de la liste) : le membre bloqué n'est pas prévenu.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne ne sera pas notifiée'**
  String get safetyBlockEffectNotNotified;

  /// Message bref en bas de l'écran après un blocage réussi. {name} est le prénom du membre bloqué.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été bloqué'**
  String safetyBlocked(String name);

  /// Message bref en bas de l'écran quand le blocage a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du blocage'**
  String get safetyBlockFailed;

  /// Titre de la feuille de signalement d'un membre.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get safetyReportTitle;

  /// Question sous le titre de la feuille de signalement. {name} est le prénom du membre signalé.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi signalez-vous {name} ?'**
  String safetyReportWhy(String name);

  /// Texte d'aide du champ libre où l'on peut préciser le signalement.
  ///
  /// In fr, this message translates to:
  /// **'Détails supplémentaires (optionnel)'**
  String get safetyReportDetailsHint;

  /// Case à cocher de la feuille de signalement : bloquer aussi le membre.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer également cet utilisateur'**
  String get safetyReportAlsoBlock;

  /// Sous la case « Bloquer également » : ce que ça change.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne verrez plus ce profil'**
  String get safetyReportAlsoBlockHint;

  /// Bouton rouge qui envoie le signalement à la modération.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get safetyReportSend;

  /// Message bref en bas de l'écran après l'envoi d'un signalement.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre signalement. Notre équipe va l\'examiner.'**
  String get safetyReportThanks;

  /// Message bref en bas de l'écran quand l'envoi du signalement a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du signalement'**
  String get safetyReportFailed;

  /// Motif de signalement (liste de choix) : profil qui usurpe une identité.
  ///
  /// In fr, this message translates to:
  /// **'Faux profil'**
  String get safetyCategoryFakeProfile;

  /// Précision sous le motif « Faux profil ».
  ///
  /// In fr, this message translates to:
  /// **'Photos volées, identité fausse'**
  String get safetyCategoryFakeProfileHint;

  /// Motif de signalement (liste de choix) : photos choquantes.
  ///
  /// In fr, this message translates to:
  /// **'Photos inappropriées'**
  String get safetyCategoryInappropriatePhotos;

  /// Précision sous le motif « Photos inappropriées ».
  ///
  /// In fr, this message translates to:
  /// **'Contenu sexuel, violent ou choquant'**
  String get safetyCategoryInappropriatePhotosHint;

  /// Motif de signalement (liste de choix) : harcèlement.
  ///
  /// In fr, this message translates to:
  /// **'Harcèlement'**
  String get safetyCategoryHarassment;

  /// Précision sous le motif « Harcèlement ».
  ///
  /// In fr, this message translates to:
  /// **'Messages insistants, menaces, insultes'**
  String get safetyCategoryHarassmentHint;

  /// Motif de signalement (liste de choix) : spam ou arnaque.
  ///
  /// In fr, this message translates to:
  /// **'Spam / Arnaque'**
  String get safetyCategorySpam;

  /// Précision sous le motif « Spam / Arnaque ».
  ///
  /// In fr, this message translates to:
  /// **'Publicité, demande d\'argent, liens suspects'**
  String get safetyCategorySpamHint;

  /// Motif de signalement (liste de choix) : la personne est mineure.
  ///
  /// In fr, this message translates to:
  /// **'Mineur'**
  String get safetyCategoryUnderage;

  /// Précision sous le motif « Mineur ».
  ///
  /// In fr, this message translates to:
  /// **'La personne semble avoir moins de 18 ans'**
  String get safetyCategoryUnderageHint;

  /// Motif de signalement (liste de choix) : comportement en dehors de l'app, lors d'une rencontre.
  ///
  /// In fr, this message translates to:
  /// **'Comportement hors app'**
  String get safetyCategoryOfflineBehavior;

  /// Précision sous le motif « Comportement hors app ».
  ///
  /// In fr, this message translates to:
  /// **'Comportement inapproprié lors d\'une rencontre'**
  String get safetyCategoryOfflineBehaviorHint;

  /// Motif de signalement (liste de choix) : tout autre motif.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get safetyCategoryOther;

  /// Précision sous le motif « Autre ».
  ///
  /// In fr, this message translates to:
  /// **'Autre raison (précisez)'**
  String get safetyCategoryOtherHint;

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

  /// Titre de l'écran des réglages.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// Réglages : titre de la section qui regroupe le profil, l'e-mail et la langue. Affiché en petites capitales.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get settingsSectionAccount;

  /// Réglages, ligne qui ouvre la modification du profil.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get settingsEditProfile;

  /// Réglages, ligne qui montre l'adresse e-mail du compte (le libellé, pas l'adresse).
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// Réglages : texte à la place de l'adresse e-mail quand aucun compte n'est connecté.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté'**
  String get settingsNotSignedIn;

  /// Réglages : nom affiché en tête de l'écran quand le profil n'a pas de nom.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get settingsDefaultUserName;

  /// Réglages : titre de la section des préférences de recherche (lieu, distance, âge). Affiché en petites capitales.
  ///
  /// In fr, this message translates to:
  /// **'Découverte'**
  String get settingsSectionDiscovery;

  /// Réglages : ligne et titre de la feuille où l'on choisit sa ville.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get settingsLocation;

  /// Réglages : sous-titre de la ligne Localisation quand aucune ville n'est choisie.
  ///
  /// In fr, this message translates to:
  /// **'Non défini'**
  String get settingsLocationNotSet;

  /// Réglages : ligne et titre de la feuille où l'on règle la distance maximale des profils proposés.
  ///
  /// In fr, this message translates to:
  /// **'Distance maximale'**
  String get settingsMaxDistance;

  /// Une distance en kilomètres, par exemple « 50 km ». Sous-titre de la ligne et grand chiffre de la feuille.
  ///
  /// In fr, this message translates to:
  /// **'{distance} km'**
  String settingsDistanceKm(int distance);

  /// Réglages : ligne et titre de la feuille où l'on règle l'âge minimal et maximal des profils proposés.
  ///
  /// In fr, this message translates to:
  /// **'Tranche d\'âge'**
  String get settingsAgeRange;

  /// Une tranche d'âge, par exemple « 25 - 35 ans ». Sous-titre de la ligne et grand chiffre de la feuille.
  ///
  /// In fr, this message translates to:
  /// **'{min} - {max} ans'**
  String settingsAgeRangeValue(int min, int max);

  /// Réglages : titre de la section Shabbat et fêtes. Affiché en petites capitales.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres juifs'**
  String get settingsSectionJewish;

  /// Réglages : ligne qui ouvre l'écran du mode Shabbat. Le statut du membre affiche aussi ce nom.
  ///
  /// In fr, this message translates to:
  /// **'Mode Shabbat'**
  String get settingsShabbatMode;

  /// Réglages : sous-titre de la ligne Mode Shabbat (l'écran donne les horaires d'allumage des bougies et de havdala du lieu du membre).
  ///
  /// In fr, this message translates to:
  /// **'Horaires de Shabbat'**
  String get settingsShabbatAutoPause;

  /// Réglages : titre de la section qui contient la carte du mode couple. Affiché en petites capitales.
  ///
  /// In fr, this message translates to:
  /// **'Mode Couple'**
  String get settingsSectionCouple;

  /// Réglages : titre de la section de l'abonnement mazl+. Affiché en petites capitales.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get settingsSectionSubscription;

  /// Réglages : ligne qui retrouve les achats déjà faits avec le même compte de la boutique.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer les achats'**
  String get settingsRestorePurchases;

  /// Message bref : les achats ont bien été restaurés.
  ///
  /// In fr, this message translates to:
  /// **'Achats restaurés avec succès.'**
  String get settingsRestoreSuccess;

  /// Message bref : la restauration des achats a échoué, le membre peut réessayer.
  ///
  /// In fr, this message translates to:
  /// **'La restauration des achats a échoué. Réessayez.'**
  String get settingsRestoreError;

  /// Détail de l'abonnement, après la durée de la formule : date du prochain renouvellement. Exemple : « 6 mois · renouvellement le 12 mars 2027 ».
  ///
  /// In fr, this message translates to:
  /// **'renouvellement le {date}'**
  String settingsSubscriptionRenewsOn(DateTime date);

  /// Détail de l'abonnement quand il ne se renouvelle pas : date de fin. Exemple : « 6 mois · jusqu’au 12 mars 2027 ».
  ///
  /// In fr, this message translates to:
  /// **'jusqu’au {date}'**
  String settingsSubscriptionEndsOn(DateTime date);

  /// Réglages : titre de la section confidentialité (personnes bloquées, vérification du profil). Affiché en petites capitales.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité et sécurité'**
  String get settingsSectionPrivacy;

  /// Titre de l'écran et ligne des réglages qui listent les personnes que le membre a bloquées.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs bloqués'**
  String get settingsBlockedUsers;

  /// Réglages : sous-titre de la ligne Utilisateurs bloqués.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les personnes bloquées'**
  String get settingsBlockedUsersHint;

  /// Réglages : ligne qui ouvre la vérification du profil (photo de contrôle).
  ///
  /// In fr, this message translates to:
  /// **'Vérification du profil'**
  String get settingsProfileVerification;

  /// Réglages : sous-titre de la vérification quand le profil est vérifié.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get settingsVerified;

  /// Réglages : sous-titre de la vérification quand le profil n'est pas encore vérifié.
  ///
  /// In fr, this message translates to:
  /// **'Non vérifié'**
  String get settingsNotVerified;

  /// Réglages : titre de la section d'informations (aide, conditions, version). Affiché en petites capitales.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsSectionAbout;

  /// Réglages : ligne d'aide et de support.
  ///
  /// In fr, this message translates to:
  /// **'Aide et support'**
  String get settingsHelp;

  /// Réglages : ligne des conditions d'utilisation.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get settingsTerms;

  /// Réglages : ligne des conditions générales de vente (mazl+, Boosts).
  ///
  /// In fr, this message translates to:
  /// **'Conditions de vente'**
  String get settingsSales;

  /// Réglages : ligne de la politique de confidentialité.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get settingsPrivacyPolicy;

  /// Réglages : ligne qui montre le numéro de version de l'app (le libellé, pas le numéro).
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Bouton en bas des réglages, titre et bouton de confirmation de la feuille de déconnexion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get settingsLogOut;

  /// Feuille de déconnexion : la question posée avant de se déconnecter.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter ?'**
  String get settingsLogOutMessage;

  /// Bouton discret en bas des réglages et titre de la première feuille de suppression du compte.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get settingsDeleteAccount;

  /// Suppression du compte, première feuille : la question sur la raison du départ.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi souhaitez-vous nous quitter ?'**
  String get settingsDeleteReasonPrompt;

  /// Suppression du compte : raison « le membre a trouvé quelqu'un ».
  ///
  /// In fr, this message translates to:
  /// **'J\'ai trouvé quelqu\'un'**
  String get settingsDeleteReasonFoundSomeone;

  /// Suppression du compte : raison « le membre n'utilise plus l'app ».
  ///
  /// In fr, this message translates to:
  /// **'Je n\'utilise plus l\'application'**
  String get settingsDeleteReasonNoLongerUsing;

  /// Suppression du compte : raison « le membre veut faire une pause ».
  ///
  /// In fr, this message translates to:
  /// **'Je souhaite faire une pause'**
  String get settingsDeleteReasonBreak;

  /// Suppression du compte : raison « problèmes techniques ».
  ///
  /// In fr, this message translates to:
  /// **'Problèmes techniques'**
  String get settingsDeleteReasonTechnical;

  /// Suppression du compte : raison « le service ne convient pas ».
  ///
  /// In fr, this message translates to:
  /// **'Le service ne me convient pas'**
  String get settingsDeleteReasonService;

  /// Suppression du compte : raison « autre ».
  ///
  /// In fr, this message translates to:
  /// **'Autre raison'**
  String get settingsDeleteReasonOther;

  /// Suppression du compte, seconde feuille : titre de la confirmation finale.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation finale'**
  String get settingsDeleteFinalTitle;

  /// Suppression du compte, confirmation finale : avertissement en rouge.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get settingsDeleteIrreversible;

  /// Suppression du compte, confirmation finale : la liste de ce qui sera effacé. Les retours à la ligne et les puces « • » sont voulus.
  ///
  /// In fr, this message translates to:
  /// **'Toutes vos données seront supprimées :\n• Votre profil et vos photos\n• Vos matchs et conversations\n• Votre historique de likes\n• Vos paramètres'**
  String get settingsDeleteDataList;

  /// Suppression du compte, confirmation finale : bouton qui renonce.
  ///
  /// In fr, this message translates to:
  /// **'Garder mon compte'**
  String get settingsDeleteKeep;

  /// Message bref : la suppression du compte a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression'**
  String get settingsDeleteError;

  /// Feuille Localisation : texte grisé du champ de recherche de ville.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une ville...'**
  String get settingsCitySearchHint;

  /// Feuille Localisation : phrase d'aide sous le champ de recherche.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le nom de votre ville et sélectionnez une suggestion'**
  String get settingsCitySearchHelp;

  /// Message bref : les réglages (ville, distance, âge) ont été enregistrés.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres sauvegardés'**
  String get settingsSaved;

  /// Titre de la feuille de sortie du mode couple et bouton de la carte du mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le mode couple'**
  String get settingsCoupleLeave;

  /// Feuille de sortie du mode couple : rassurance, le mode peut être réactivé.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez le réactiver plus tard si vous le souhaitez.'**
  String get settingsCoupleLeaveMessage;

  /// Feuille de sortie du mode couple : bouton rouge qui confirme.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get settingsCoupleLeaveConfirm;

  /// Message bref : le mode couple est terminé.
  ///
  /// In fr, this message translates to:
  /// **'Mode couple quitté'**
  String get settingsCoupleLeft;

  /// Message bref : la sortie du mode couple a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de quitter le mode couple. Réessayez.'**
  String get settingsCoupleLeaveError;

  /// Message bref : l'annulation de la demande de couple a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'annuler la demande. Réessayez.'**
  String get settingsCoupleCancelRequestError;

  /// Carte du mode couple : titre quand le couple est actif.
  ///
  /// In fr, this message translates to:
  /// **'Mode couple actif'**
  String get settingsCoupleActive;

  /// Carte du mode couple, sous le titre : avec qui le membre est en couple.
  ///
  /// In fr, this message translates to:
  /// **'Avec {name}'**
  String settingsCoupleWithPartner(String name);

  /// Carte du mode couple, sous le titre, quand le prénom du partenaire est inconnu.
  ///
  /// In fr, this message translates to:
  /// **'Avec votre partenaire'**
  String get settingsCoupleWithYourPartner;

  /// Carte du mode couple : bouton qui ouvre l'espace du couple. Une seule ligne, environ 15 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Espace couple'**
  String get settingsCoupleOpenSpace;

  /// Carte du mode couple : bouton qui ouvre le calendrier. Une seule ligne, environ 12 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get settingsCoupleOpenCalendar;

  /// Carte du mode couple : le couple vient d'être formé aujourd'hui. Suit « Avec Myriam · ».
  ///
  /// In fr, this message translates to:
  /// **'Depuis aujourd\'hui'**
  String get settingsCoupleSinceToday;

  /// Carte du mode couple : depuis combien de jours le couple existe (au moins 1). Suit « Avec Myriam · ».
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, one{{days} jour} other{{days} jours}}'**
  String settingsCoupleDays(int days);

  /// Carte du mode couple : titre quand une demande est partie et que le prénom du destinataire est inconnu.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get settingsCoupleRequestSent;

  /// Carte du mode couple : titre quand une demande est partie vers une personne.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée à {name}'**
  String settingsCoupleRequestSentTo(String name);

  /// Carte du mode couple, sous le titre : la personne n'a pas encore répondu.
  ///
  /// In fr, this message translates to:
  /// **'En attente de sa réponse'**
  String get settingsCoupleWaiting;

  /// Carte du mode couple : bouton qui retire la demande envoyée. Une seule ligne.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la demande'**
  String get settingsCoupleCancelRequest;

  /// Carte du mode couple : question d'invitation à activer le mode quand aucun couple n'existe.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez trouvé l\'amour ?'**
  String get settingsCoupleInvitation;

  /// Carte du mode couple : bouton qui commence l'activation du mode couple. Environ 10 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get settingsCoupleActivate;

  /// Écran Mode Shabbat : la ligne sous les heures qui nomme le lieu pour lequel elles sont calculées. {place} est le nom de la ville du membre, ou « Paris, France » faute de ville.
  ///
  /// In fr, this message translates to:
  /// **'Basé sur {place}'**
  String settingsShabbatBasedOn(String place);

  /// Écran Mode Shabbat : nom du lieu utilisé quand la ville du membre n'est pas connue (Paris). Se glisse dans « Basé sur … ».
  ///
  /// In fr, this message translates to:
  /// **'Paris, France'**
  String get settingsShabbatDefaultPlace;

  /// Écran Mode Shabbat : remplace le paragraphe du bas quand la ville du membre n'est pas connue (profil sans ville, ou profil illisible) : les heures affichées sont celles de Paris.
  ///
  /// In fr, this message translates to:
  /// **'Les horaires sont ceux de Paris, car votre ville n\'est pas connue. Ajoutez-la dans les réglages pour des horaires exacts.'**
  String get settingsShabbatUnknownPlaceHint;

  /// Écran Mode Shabbat : paragraphe en bas de page qui dit comment les heures sont calculées (18 minutes avant le coucher du soleil, havdala à la tombée de la nuit) et où changer de lieu (la ville se règle dans les réglages). Ne promet aucune pause ni aucun statut.
  ///
  /// In fr, this message translates to:
  /// **'Allumage 18 minutes avant le coucher du soleil, havdala à la tombée de la nuit. Pour changer de lieu, modifiez votre ville dans les réglages.'**
  String get settingsShabbatExplanation;

  /// Bandeau sombre du mode Shabbat : le grand titre sur deux lignes (« Shabbat shalom. »). Le retour à la ligne est voulu.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat\nshalom.'**
  String get settingsShabbatHeroTitle;

  /// Bandeau sombre du mode Shabbat : phrase sous le titre. Mazl est le nom de l'app écrit ainsi, ne pas le traduire. Ne promet aucune pause des notifications.
  ///
  /// In fr, this message translates to:
  /// **'Mazl se repose avec vous.'**
  String get settingsShabbatHeroSubtitle;

  /// Bandeau du mode Shabbat : petit libellé au-dessus de l'heure d'allumage des bougies. Affiché en majuscules, demi-largeur d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Allumage'**
  String get settingsShabbatCandleLighting;

  /// Bandeau du mode Shabbat : petit libellé au-dessus de l'heure de la havdala (fin de Shabbat). Affiché en majuscules, demi-largeur d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Havdala'**
  String get settingsShabbatHavdalah;

  /// Écran des utilisateurs bloqués : nom affiché quand la personne n'a pas de nom.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get settingsBlockedUserFallbackName;

  /// Utilisateurs bloqués : titre de la boîte de confirmation du déblocage.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer cet utilisateur ?'**
  String get settingsBlockedUnblockTitle;

  /// Utilisateurs bloqués : texte de la confirmation de déblocage, avec le nom de la personne. Le saut de ligne double est voulu.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous débloquer {name} ?\n\nCette personne pourra à nouveau voir votre profil et vous contacter.'**
  String settingsBlockedUnblockMessage(String name);

  /// Utilisateurs bloqués : texte de la confirmation de déblocage quand la personne n'a pas de nom.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous débloquer cet utilisateur ?\n\nCette personne pourra à nouveau voir votre profil et vous contacter.'**
  String get settingsBlockedUnblockMessageUnnamed;

  /// Utilisateurs bloqués : bouton sur chaque ligne et bouton de confirmation du déblocage.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer'**
  String get settingsBlockedUnblock;

  /// Message bref : la personne nommée a été débloquée.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été débloqué'**
  String settingsBlockedUnblocked(String name);

  /// Message bref : la personne (sans nom) a été débloquée.
  ///
  /// In fr, this message translates to:
  /// **'L\'utilisateur a été débloqué'**
  String get settingsBlockedUnblockedUnnamed;

  /// Message bref : le déblocage a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du déblocage'**
  String get settingsBlockedUnblockError;

  /// Utilisateurs bloqués : titre de l'état vide.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur bloqué'**
  String get settingsBlockedEmptyTitle;

  /// Utilisateurs bloqués : explication de l'état vide, sur deux lignes centrées (le retour à la ligne est voulu).
  ///
  /// In fr, this message translates to:
  /// **'Les personnes que vous bloquez\napparaîtront ici'**
  String get settingsBlockedEmptyHint;

  /// Utilisateurs bloqués : sous-titre d'une ligne, la date du blocage.
  ///
  /// In fr, this message translates to:
  /// **'Bloqué le {date}'**
  String settingsBlockedOn(DateTime date);

  /// Réglages, « Restaurer les achats » : le magasin d'applications ne connaît aucun abonnement mazl+ pour ce compte.
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement trouvé.'**
  String get settingsRestoreNothing;

  /// Écran Mode Shabbat : bouton qui ouvre l'affichage plein écran (téléphone posé en tente). Aussi le bouton de la proposition du vendredi. Environ 20 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Lancer l\'affichage'**
  String get shabbatDisplayLaunch;

  /// Écran Mode Shabbat : phrase sous le bouton, qui dit ce que fait l'affichage (écran allumé, heure, allumage, havdala) et qu'il se lance avant Shabbat. Ne promet aucune pause ni silence des notifications.
  ///
  /// In fr, this message translates to:
  /// **'Posez le téléphone en tente : l\'écran reste allumé et affiche l\'heure, l\'allumage et la havdala. À lancer avant Shabbat, sans rien toucher ensuite.'**
  String get shabbatDisplayLaunchHint;

  /// Affichage Shabbat : le grand titre pendant Shabbat (« Shabbat shalom »). Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat shalom'**
  String get shabbatDisplayShabbatShalom;

  /// Affichage Shabbat : le mot « Shabbat » seul, titre de la veille de Shabbat et du prochain Shabbat.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat'**
  String get shabbatDisplayShabbatName;

  /// Affichage Shabbat : petit mot au-dessus du titre, le jour même de l'allumage (« Ce soir »). Majuscules, une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Ce soir'**
  String get shabbatDisplayTonight;

  /// Affichage Shabbat : petit mot au-dessus du titre quand le prochain Shabbat ou la prochaine fête n'est pas pour aujourd'hui (« À venir »). Majuscules, une ligne.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get shabbatDisplayComing;

  /// Affichage Shabbat : libellé de l'heure de début d'une fête (l'allumage qui l'ouvre). Majuscules, demi-largeur d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Entrée'**
  String get shabbatDisplayFestivalEntry;

  /// Affichage Shabbat : libellé de l'heure de fin d'une fête (la nuit qui la clôt). Majuscules, demi-largeur d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Sortie'**
  String get shabbatDisplayFestivalExit;

  /// Affichage Shabbat : libellé au-dessus du nom de la paracha de la semaine (le passage de la Torah lu ce Shabbat). Majuscules.
  ///
  /// In fr, this message translates to:
  /// **'Paracha'**
  String get shabbatDisplayParasha;

  /// Affichage Shabbat, Hanoucca : le numéro du soir dont on allume les bougies (« Soir 3 »). {night} va de 1 à 8.
  ///
  /// In fr, this message translates to:
  /// **'Soir {night}'**
  String shabbatDisplayHanukkahNight(int night);

  /// Affichage Shabbat, période de l'Omer : le jour du compte (« Jour 10 de l'Omer »). {day} va de 1 à 49.
  ///
  /// In fr, this message translates to:
  /// **'Jour {day} de l\'Omer'**
  String shabbatDisplayOmerDay(int day);

  /// Affichage Shabbat : indication discrète, en bas de l'écran, de la seule façon de quitter l'affichage (appuyer sans lâcher pendant deux secondes). Lue aussi par VoiceOver.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez deux secondes pour quitter'**
  String get shabbatDisplayExitHint;

  /// Proposition affichée le jour de l'allumage (vendredi ou veille de fête) quand l'iPhone Duo est fermé et posé en paysage : propose de lancer l'affichage Shabbat. Question courte.
  ///
  /// In fr, this message translates to:
  /// **'Poser le téléphone en tente pour ce soir ?'**
  String get shabbatDisplayProposalTitle;

  /// Proposition de l'affichage Shabbat : bouton pour la refuser jusqu'à la prochaine fois. Environ 15 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Pas maintenant'**
  String get shabbatDisplayProposalDismiss;

  /// Page Vérification : petite étiquette au-dessus du grand titre.
  ///
  /// In fr, this message translates to:
  /// **'Votre profil'**
  String get verificationProfileEyebrow;

  /// Page Vérification : grand titre de l'écran où le membre prouve que ses photos sont les siennes (niveau 1 : photo, niveau 2 : identité).
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get verificationTitle;

  /// Étiquette en capitales au-dessus du niveau « photo » de la page Vérification.
  ///
  /// In fr, this message translates to:
  /// **'Niveau 1'**
  String get verificationLevel1;

  /// Étiquette en capitales au-dessus du niveau « identité » de la page Vérification.
  ///
  /// In fr, this message translates to:
  /// **'Niveau 2'**
  String get verificationLevel2;

  /// Titre du niveau 1 : le selfie en direct est comparé aux photos du profil.
  ///
  /// In fr, this message translates to:
  /// **'Photo vérifiée'**
  String get verificationPhotoTitle;

  /// Titre du niveau 2 : l'identité est lue sur la puce du passeport ou de la carte d'identité.
  ///
  /// In fr, this message translates to:
  /// **'Identité vérifiée'**
  String get verificationIdentityTitle;

  /// Pastille posée à côté du titre d'un niveau déjà vérifié (photo ou identité). Court.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiée'**
  String get verificationVerifiedPill;

  /// Niveau 1, avant la vérification : ce qui est comparé et ce qui est gardé. Promesse validée : les images ne sont jamais conservées, seule une empreinte chiffrée l'est, supprimable à tout moment.
  ///
  /// In fr, this message translates to:
  /// **'Nous comparons votre visage à vos photos. Les images ne sont pas conservées ; seule une empreinte chiffrée l\'est, supprimable à tout moment.'**
  String get verificationConsent;

  /// Niveau 1 vérifié, quand la date de vérification est inconnue.
  ///
  /// In fr, this message translates to:
  /// **'Votre visage correspond à vos photos.'**
  String get verificationPhotoVerifiedLine;

  /// Niveau 1 vérifié : la date à laquelle la photo a été vérifiée ({date} = date courte selon la langue).
  ///
  /// In fr, this message translates to:
  /// **'Vérifiée le {date}.'**
  String verificationPhotoVerifiedOn(DateTime date);

  /// Bouton du niveau 1 vérifié : retire le badge (ouvre une confirmation).
  ///
  /// In fr, this message translates to:
  /// **'Retirer ma vérification'**
  String get verificationRemoveAction;

  /// Bouton du niveau 1 : lance le selfie en direct.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier ma photo'**
  String get verificationVerifyPhotoAction;

  /// Bouton du niveau 2 : ouvre le parcours passeport ou carte d'identité à puce.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier mon identité'**
  String get verificationVerifyIdentityAction;

  /// Sous le bouton désactivé du niveau 1 : le quota d'essais du jour est atteint ; le prochain essai a lieu aujourd'hui à {time}.
  ///
  /// In fr, this message translates to:
  /// **'Limite atteinte, nouvel essai possible à {time}.'**
  String verificationBlockedToday(DateTime time);

  /// Comme verificationBlockedToday, mais le prochain essai a lieu un autre jour : {date} = jour et mois, {time} = heure.
  ///
  /// In fr, this message translates to:
  /// **'Limite atteinte, nouvel essai possible le {date} à {time}.'**
  String verificationBlockedLater(DateTime date, DateTime time);

  /// Niveau 2 vérifié, quand la date est inconnue.
  ///
  /// In fr, this message translates to:
  /// **'Document contrôlé par sa puce.'**
  String get verificationIdentityCheckedNoDate;

  /// Niveau 2 vérifié : la date du contrôle ({date} = date courte selon la langue).
  ///
  /// In fr, this message translates to:
  /// **'Contrôlée le {date}.'**
  String verificationIdentityCheckedOn(DateTime date);

  /// Niveau 2 pas encore vérifié : ce que le membre doit présenter et à quoi sert le selfie.
  ///
  /// In fr, this message translates to:
  /// **'Passeport ou carte d\'identité, lu par sa puce. Un selfie confirme que c\'est bien vous.'**
  String get verificationIdentityPitch;

  /// Titre de la boîte de dialogue qui demande de confirmer le retrait du badge de niveau 1.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ma vérification ?'**
  String get verificationRemoveDialogTitle;

  /// Corps de la boîte de dialogue de retrait : ce qui est supprimé.
  ///
  /// In fr, this message translates to:
  /// **'Votre badge et l\'empreinte de votre visage seront supprimés.'**
  String get verificationRemoveDialogBody;

  /// Remarque après un selfie réussi : {count} photos du profil ne ressemblent pas au membre (au moins 1) et sont écartées.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Une de vos photos ne vous ressemble pas : elle ne compte pas.} other{{count} de vos photos ne vous ressemblent pas : elles ne comptent pas.}}'**
  String verificationPhotosMismatch(int count);

  /// Selfie en direct : consigne affichée en grand quand le membre doit regarder droit vers l'objectif.
  ///
  /// In fr, this message translates to:
  /// **'Regardez l\'objectif'**
  String get verificationLivenessFront;

  /// Selfie en direct : consigne en grand ; le membre tourne la tête vers SA gauche.
  ///
  /// In fr, this message translates to:
  /// **'Tournez doucement la tête vers la gauche'**
  String get verificationLivenessLeft;

  /// Selfie en direct : consigne en grand ; le membre tourne la tête vers SA droite.
  ///
  /// In fr, this message translates to:
  /// **'Tournez doucement la tête vers la droite'**
  String get verificationLivenessRight;

  /// Selfie en direct : petite aide sous la consigne, aucun visage n'est vu. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Placez votre visage dans le cercle'**
  String get verificationLivenessHintNoFace;

  /// Selfie en direct : petite aide, plusieurs personnes sont dans le cadre. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Une seule personne dans le cadre'**
  String get verificationLivenessHintMultipleFaces;

  /// Selfie en direct : petite aide, le visage est trop loin. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Rapprochez-vous un peu'**
  String get verificationLivenessHintTooSmall;

  /// Selfie en direct : petite aide, le visage n'est pas au centre du cercle. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Centrez votre visage dans le cercle'**
  String get verificationLivenessHintOffCenter;

  /// Selfie en direct : petite aide, le visage n'est pas de face. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Regardez droit devant vous'**
  String get verificationLivenessHintLookStraight;

  /// Selfie en direct : petite aide, la tête n'est pas assez tournée. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Tournez encore un peu'**
  String get verificationLivenessHintTurnMore;

  /// Selfie en direct : petite aide, la tête est trop tournée. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Pas autant, revenez un peu'**
  String get verificationLivenessHintTurnLess;

  /// Selfie en direct : petite aide, la tête est tournée du mauvais côté. Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Tournez de l\'autre côté'**
  String get verificationLivenessHintTurnOtherWay;

  /// Selfie en direct : étiquette en capitales en haut de l'écran, la pose en cours ({current}) sur le nombre de poses ({total}).
  ///
  /// In fr, this message translates to:
  /// **'Pose {current} / {total}'**
  String verificationLivenessPoseCounter(int current, int total);

  /// Selfie en direct : texte lu par les lecteurs d'écran pour les barres de progression ({done} poses prises sur {total}).
  ///
  /// In fr, this message translates to:
  /// **'Poses prises : {done} sur {total}'**
  String verificationLivenessPosesTaken(int done, int total);

  /// Selfie en direct : rappel en bas de l'écran, sous le cercle. Promesse validée : les images ne sont pas conservées.
  ///
  /// In fr, this message translates to:
  /// **'Seul dans le cadre, bien éclairé. Les images ne sont pas conservées.'**
  String get verificationLivenessPrivacy;

  /// Selfie en direct : titre de l'écran quand le temps de la session est écoulé.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée'**
  String get verificationLivenessExpiredTitle;

  /// Selfie en direct : explication quand le temps de la session est écoulé.
  ///
  /// In fr, this message translates to:
  /// **'Le temps imparti est écoulé. Vous pouvez recommencer.'**
  String get verificationLivenessExpiredBody;

  /// Selfie en direct : titre de l'écran quand l'accès à la caméra est refusé.
  ///
  /// In fr, this message translates to:
  /// **'Caméra nécessaire'**
  String get verificationCameraNeededTitle;

  /// Selfie en direct : pourquoi l'app demande la caméra frontale. MAZL est un nom de marque, ne se traduit pas.
  ///
  /// In fr, this message translates to:
  /// **'MAZL utilise la caméra frontale pour vérifier que vous êtes bien la personne de vos photos.'**
  String get verificationCameraNeededBody;

  /// Bouton quand la caméra est refusée pour de bon : ouvre les réglages du téléphone.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages'**
  String get verificationCameraOpenSettings;

  /// Bouton quand la caméra est refusée mais redemandable : relance la demande d'autorisation.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser la caméra'**
  String get verificationCameraAllow;

  /// Selfie en direct : titre de l'écran quand la caméra frontale ne démarre pas.
  ///
  /// In fr, this message translates to:
  /// **'Caméra indisponible'**
  String get verificationCameraUnavailableTitle;

  /// Selfie en direct : explication quand la caméra frontale ne démarre pas.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de démarrer la caméra frontale.'**
  String get verificationCameraUnavailableBody;

  /// Parcours passeport/carte à puce, écran d'accueil : grand titre.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre identité.'**
  String get verificationIntroTitle;

  /// Accueil du parcours identité : à quoi sert le badge « Identité vérifiée » (même texte que verificationBadgeLabel) et ce qu'il faut avoir sous la main.
  ///
  /// In fr, this message translates to:
  /// **'Le badge « Identité vérifiée » dit aux autres que vous êtes bien la personne des photos. Il faut un passeport ou une carte d\'identité biométrique, deux minutes et un peu de lumière.'**
  String get verificationIntroSubtitle;

  /// Accueil du parcours identité, étape 1 sur la liste numérotée : titre court.
  ///
  /// In fr, this message translates to:
  /// **'Photographier la page photo'**
  String get verificationIntroStep1;

  /// Accueil du parcours identité, détail de l'étape 1 : on lit la bande de lecture automatique (MRZ), les deux lignes en bas de la page photo.
  ///
  /// In fr, this message translates to:
  /// **'Pour lire les deux lignes du bas.'**
  String get verificationIntroStep1Detail;

  /// Accueil du parcours identité, étape 2 : titre court.
  ///
  /// In fr, this message translates to:
  /// **'Poser le téléphone sur la puce'**
  String get verificationIntroStep2;

  /// Accueil du parcours identité, détail de l'étape 2 : la puce est signée par l'État qui a émis le document, c'est elle qui fait foi.
  ///
  /// In fr, this message translates to:
  /// **'La puce signée par l\'État fait foi.'**
  String get verificationIntroStep2Detail;

  /// Accueil du parcours identité, étape 3 : titre court.
  ///
  /// In fr, this message translates to:
  /// **'Un selfie en mouvement'**
  String get verificationIntroStep3;

  /// Accueil du parcours identité, détail de l'étape 3.
  ///
  /// In fr, this message translates to:
  /// **'Comparé à la photo de la puce.'**
  String get verificationIntroStep3Detail;

  /// Accueil du parcours identité : promesse de confidentialité sous la liste, avec un cadenas. Traduire fidèlement, sans rien ajouter.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est conservé : nous ne gardons que le résultat.'**
  String get verificationIntroPrivacy;

  /// Accueil du parcours identité : bouton principal.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get verificationIntroStart;

  /// Étiquette en capitales en haut des écrans du parcours identité : l'étape en cours ({step}) sur le nombre d'étapes ({total}).
  ///
  /// In fr, this message translates to:
  /// **'Étape {step} / {total}'**
  String verificationStepLabel(int step, int total);

  /// Parcours identité, scan de la bande de lecture automatique (MRZ) : titre.
  ///
  /// In fr, this message translates to:
  /// **'Cadrez la page photo.'**
  String get verificationScanTitle;

  /// Scan de la page photo : conseil sous le titre. Les deux lignes du bas du document (MRZ) sont faites de chiffres, de lettres et de signes « < » ; en hébreu on nomme les lignes MRZ.
  ///
  /// In fr, this message translates to:
  /// **'Les deux lignes de « < » du bas suffisent. Évitez les reflets.'**
  String get verificationScanHint;

  /// Scan de la page photo : lien qui passe à la saisie à la main.
  ///
  /// In fr, this message translates to:
  /// **'Saisir à la main'**
  String get verificationScanManual;

  /// Scan de la page photo : description de l'aperçu de la caméra lue par les lecteurs d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de la caméra : placez les deux lignes du bas du document dans le cadre mis en évidence'**
  String get verificationScanFrameSemantics;

  /// Message « la caméra ne marche pas » : titre de l'écran de scan sans caméra, et message d'échec quand la caméra frontale ne peut pas servir au selfie.
  ///
  /// In fr, this message translates to:
  /// **'La caméra n\'est pas disponible.'**
  String get verificationCameraNotAvailable;

  /// Scan de la page photo sans caméra : explication sous le titre.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez saisir les informations de la page photo à la main.'**
  String get verificationScanUnavailableBody;

  /// Scan de la page photo sans caméra : bouton principal qui ouvre la saisie.
  ///
  /// In fr, this message translates to:
  /// **'Saisir les informations'**
  String get verificationScanEnterDetails;

  /// Parcours identité, saisie à la main : titre.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez les informations.'**
  String get verificationManualTitle;

  /// Saisie à la main : sous le titre, d'où recopier les valeurs.
  ///
  /// In fr, this message translates to:
  /// **'Recopiez-les depuis la page photo de votre document.'**
  String get verificationManualSubtitle;

  /// Libellé du champ (saisie) et de la ligne (relecture) : numéro du passeport ou de la carte.
  ///
  /// In fr, this message translates to:
  /// **'Numéro du document'**
  String get verificationFieldDocumentNumber;

  /// Libellé du champ (saisie) et de la ligne (relecture) : date de naissance du titulaire.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get verificationFieldBirthDate;

  /// Libellé du champ (saisie) et de la ligne (relecture) : date d'expiration du document.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get verificationFieldExpiryDate;

  /// Indication grisée dans un champ de date : l'ordre à taper, jour puis mois puis année, sur 8 chiffres.
  ///
  /// In fr, this message translates to:
  /// **'JJ/MM/AAAA'**
  String get verificationDateHint;

  /// Saisie à la main : lien qui revient au scan par la caméra.
  ///
  /// In fr, this message translates to:
  /// **'Scanner avec la caméra'**
  String get verificationManualUseCamera;

  /// Saisie à la main : erreur sous le champ du numéro de document quand il n'a pas 5 à 12 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Entre 5 et 12 lettres ou chiffres.'**
  String get verificationErrorDocumentNumber;

  /// Saisie à la main : erreur sous un champ de date qui n'est pas une vraie date.
  ///
  /// In fr, this message translates to:
  /// **'Date invalide.'**
  String get verificationErrorInvalidDate;

  /// Relecture des informations lues sur la page photo : titre, avant d'ouvrir la puce avec elles.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez ces informations.'**
  String get verificationReviewTitle;

  /// Relecture : bouton principal par lequel le membre confirme que les informations sont les siennes.
  ///
  /// In fr, this message translates to:
  /// **'C\'est bien moi'**
  String get verificationReviewConfirm;

  /// Lien (relecture) et bouton (échec de la puce) pour repartir de la page photo et la scanner à nouveau.
  ///
  /// In fr, this message translates to:
  /// **'Scanner à nouveau'**
  String get verificationRescan;

  /// Lecture de la puce, avant la lecture : titre.
  ///
  /// In fr, this message translates to:
  /// **'Posez votre document sur le téléphone.'**
  String get verificationNfcWaitingTitle;

  /// Lecture de la puce, avant la lecture : où poser le document. NFC se garde tel quel.
  ///
  /// In fr, this message translates to:
  /// **'Le haut du téléphone contre la couverture fermée du passeport, ou contre le dos de la carte d\'identité. Retirez la coque si besoin.'**
  String get verificationNfcPlacement;

  /// Lecture de la puce : bouton principal qui lance la lecture NFC.
  ///
  /// In fr, this message translates to:
  /// **'Lire le document'**
  String get verificationNfcRead;

  /// Lecture de la puce : description du dessin (un téléphone posé sur la couverture d'un passeport) lue par les lecteurs d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Le haut du téléphone posé contre la couverture fermée du passeport'**
  String get verificationNfcIllustration;

  /// Lecture de la puce, pendant la lecture : titre.
  ///
  /// In fr, this message translates to:
  /// **'Ne bougez plus.'**
  String get verificationNfcReadingTitle;

  /// Lecture de la puce, pendant la lecture : consigne sous le titre.
  ///
  /// In fr, this message translates to:
  /// **'Gardez le document contre le haut du téléphone jusqu\'à la fin de la lecture.'**
  String get verificationNfcReadingSubtitle;

  /// Lecture de la puce : nom de la barre de progression lu par les lecteurs d'écran.
  ///
  /// In fr, this message translates to:
  /// **'Lecture de la puce'**
  String get verificationNfcProgressLabel;

  /// Lecture de la puce : valeur de la barre de progression lue par les lecteurs d'écran ({percent} de 0 à 100).
  ///
  /// In fr, this message translates to:
  /// **'{percent} %'**
  String verificationNfcProgressValue(int percent);

  /// Lecture de la puce : première ligne de la liste d'avancement.
  ///
  /// In fr, this message translates to:
  /// **'Détection du document'**
  String get verificationNfcStepDetect;

  /// Lecture de la puce : deuxième ligne de la liste d'avancement (canal chiffré avec la puce).
  ///
  /// In fr, this message translates to:
  /// **'Connexion sécurisée'**
  String get verificationNfcStepConnect;

  /// Lecture de la puce : troisième ligne de la liste d'avancement (la photo du titulaire).
  ///
  /// In fr, this message translates to:
  /// **'Lecture de la photo'**
  String get verificationNfcStepPhoto;

  /// Lecture de la puce : quatrième ligne de la liste d'avancement (la signature de l'État).
  ///
  /// In fr, this message translates to:
  /// **'Lecture de la signature'**
  String get verificationNfcStepSignature;

  /// Lecture de la puce : phrase lue par les lecteurs d'écran pour une ligne d'avancement. {label} = l'une des quatre lignes, {state} = done (terminé), active (en cours) ou waiting (en attente).
  ///
  /// In fr, this message translates to:
  /// **'{state, select, done{{label}, terminé} active{{label}, en cours} waiting{{label}, en attente} other{{label}}}'**
  String verificationNfcStepSemantics(String label, String state);

  /// Lecture de la puce, échec « la puce n'a pas répondu » : réassurance sous le titre.
  ///
  /// In fr, this message translates to:
  /// **'Cela arrive souvent au premier essai. Rien n\'a été envoyé.'**
  String get verificationNfcSilentBody;

  /// Lecture de la puce, échec « les informations saisies ne correspondent pas à la puce » : explication sous le titre.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'a été envoyé. Relisez la page photo pour repartir sur de bonnes données.'**
  String get verificationNfcRescanBody;

  /// Lecture de la puce, échec : premier conseil de la liste numérotée.
  ///
  /// In fr, this message translates to:
  /// **'Retirez la coque du téléphone.'**
  String get verificationNfcTip1;

  /// Lecture de la puce, échec : deuxième conseil de la liste numérotée.
  ///
  /// In fr, this message translates to:
  /// **'Posez le haut du téléphone au centre de la couverture, passeport fermé.'**
  String get verificationNfcTip2;

  /// Lecture de la puce, échec : troisième conseil de la liste numérotée.
  ///
  /// In fr, this message translates to:
  /// **'Restez immobile une dizaine de secondes.'**
  String get verificationNfcTip3;

  /// Lecture de la puce, échec : lien qui repart de la page photo.
  ///
  /// In fr, this message translates to:
  /// **'Relire la page photo'**
  String get verificationNfcRereadPhotoPage;

  /// Lien qui ouvre la page web où une personne relit le document à la main (quand la puce n'est pas lisible).
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon document pour relecture'**
  String get verificationManualReviewLink;

  /// Parcours identité, la puce est lue : titre avant le selfie.
  ///
  /// In fr, this message translates to:
  /// **'Puce lue.'**
  String get verificationFaceTitle;

  /// Parcours identité, la puce est lue : ce qui reste à faire.
  ///
  /// In fr, this message translates to:
  /// **'Il reste un selfie en mouvement, comparé à la photo de la puce.'**
  String get verificationFaceSubtitle;

  /// Parcours identité, la puce est lue : bouton qui ouvre le selfie en direct.
  ///
  /// In fr, this message translates to:
  /// **'Prendre le selfie'**
  String get verificationFaceAction;

  /// Parcours identité : texte sous l'indicateur d'attente pendant l'envoi et la vérification côté serveur.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours…'**
  String get verificationSubmitSending;

  /// Parcours identité : texte sous l'indicateur d'attente avant le selfie.
  ///
  /// In fr, this message translates to:
  /// **'Préparation…'**
  String get verificationSubmitPreparing;

  /// Parcours identité réussi : très grand titre.
  ///
  /// In fr, this message translates to:
  /// **'Identité vérifiée.'**
  String get verificationDoneTitle;

  /// Parcours identité réussi : phrase sous le titre.
  ///
  /// In fr, this message translates to:
  /// **'La puce de votre document et votre selfie correspondent. Votre profil porte maintenant le badge.'**
  String get verificationDoneSubtitle;

  /// Parcours identité réussi : bouton qui termine le parcours.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get verificationDoneAction;

  /// Texte du badge tel que les autres membres le voient sur le profil (pastille).
  ///
  /// In fr, this message translates to:
  /// **'Identité vérifiée'**
  String get verificationBadgeLabel;

  /// Parcours identité réussi : légende sous l'aperçu du badge.
  ///
  /// In fr, this message translates to:
  /// **'Ce que les autres voient sur votre profil.'**
  String get verificationDoneBadgeCaption;

  /// Parcours identité réussi, tableau de ce qui est gardé : libellé de la ligne sur les photos et la puce.
  ///
  /// In fr, this message translates to:
  /// **'Photos et puce'**
  String get verificationDoneStoredLabel;

  /// Valeur de la ligne précédente. Promesse validée : la puce et les selfies ne sont jamais enregistrés.
  ///
  /// In fr, this message translates to:
  /// **'Jamais enregistrées'**
  String get verificationDoneStoredValue;

  /// Parcours identité réussi, tableau de ce qui est gardé : libellé de la ligne sur ce qui est conservé.
  ///
  /// In fr, this message translates to:
  /// **'Conservé'**
  String get verificationDoneKeptLabel;

  /// Valeur de la ligne précédente. Promesse validée : seuls le pays, la date d'expiration et une empreinte (HMAC) qui n'identifie pas la personne sont gardés.
  ///
  /// In fr, this message translates to:
  /// **'Pays, expiration, empreinte anonyme'**
  String get verificationDoneKeptValue;

  /// Parcours identité réussi, tableau de ce qui est gardé : libellé de la ligne sur le profil.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get verificationDoneProfileLabel;

  /// Valeur de la ligne précédente : la date de naissance du document est verrouillée sur le profil.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance du document'**
  String get verificationDoneProfileValue;

  /// Parcours identité pas encore ouvert dans cette version de l'app : titre de l'écran.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get verificationComingSoon;

  /// Parcours identité, échec : les données lues sur la puce sont inutilisables.
  ///
  /// In fr, this message translates to:
  /// **'Les données de la puce sont illisibles.'**
  String get verificationFailureChipDataInvalid;

  /// Parcours identité, échec : la signature de l'État sur le document n'est pas valide.
  ///
  /// In fr, this message translates to:
  /// **'La signature du document n\'a pas pu être vérifiée.'**
  String get verificationFailureChipSignatureInvalid;

  /// Parcours identité, échec : l'autorité qui a signé le document n'est pas connue.
  ///
  /// In fr, this message translates to:
  /// **'Document non reconnu.'**
  String get verificationFailureNotRecognized;

  /// Échec : le document est périmé (parcours identité et selfie).
  ///
  /// In fr, this message translates to:
  /// **'Ce document est expiré.'**
  String get verificationDocumentExpired;

  /// Parcours identité, échec : le titulaire a moins de 18 ans.
  ///
  /// In fr, this message translates to:
  /// **'Il faut avoir 18 ans pour vérifier son identité.'**
  String get verificationFailureUnderage;

  /// Échec : le document est déjà lié à un autre compte MAZL.
  ///
  /// In fr, this message translates to:
  /// **'Ce document est déjà associé à un autre compte.'**
  String get verificationDocumentAlreadyUsed;

  /// Échec : le document est refusé (exclu de l'app).
  ///
  /// In fr, this message translates to:
  /// **'Ce document ne peut pas être utilisé.'**
  String get verificationDocumentBanned;

  /// Échec : le visage du selfie ne ressemble pas à la photo lue sur la puce.
  ///
  /// In fr, this message translates to:
  /// **'Votre visage ne correspond pas à la photo du document.'**
  String get verificationDocumentFaceMismatch;

  /// Parcours identité, échec : la session de selfie a expiré.
  ///
  /// In fr, this message translates to:
  /// **'La session a expiré.'**
  String get verificationFailureSessionExpired;

  /// Parcours identité, échec : le serveur n'a pas pu lire les images du selfie.
  ///
  /// In fr, this message translates to:
  /// **'Les images n\'ont pas pu être lues.'**
  String get verificationFailureImagesUnreadable;

  /// Parcours identité, échec : aucun visage sur le selfie.
  ///
  /// In fr, this message translates to:
  /// **'Aucun visage détecté.'**
  String get verificationFailureNoFace;

  /// Parcours identité, échec : plusieurs visages sur le selfie.
  ///
  /// In fr, this message translates to:
  /// **'Un seul visage doit apparaître.'**
  String get verificationFailureMultipleFaces;

  /// Parcours identité, échec : le visage du selfie est trop petit.
  ///
  /// In fr, this message translates to:
  /// **'Rapprochez-vous de la caméra.'**
  String get verificationFailureFaceTooSmall;

  /// Parcours identité, échec : les mouvements de tête demandés n'ont pas été reconnus.
  ///
  /// In fr, this message translates to:
  /// **'Les mouvements demandés n\'ont pas été reconnus.'**
  String get verificationFailurePoseMismatch;

  /// Parcours identité, échec : les images du selfie sont presque identiques (la tête n'a pas bougé).
  ///
  /// In fr, this message translates to:
  /// **'Bougez la tête comme demandé.'**
  String get verificationFailureDuplicateFrames;

  /// Parcours identité, échec : les images du selfie ne montrent pas la même personne.
  ///
  /// In fr, this message translates to:
  /// **'Le visage a changé pendant la capture.'**
  String get verificationFailureInconsistentIdentity;

  /// Parcours identité, échec : le profil n'a aucune photo à comparer.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d\'abord une photo à votre profil.'**
  String get verificationFailureNoProfilePhoto;

  /// Parcours identité, échec : le visage du selfie ne ressemble pas à la photo de profil.
  ///
  /// In fr, this message translates to:
  /// **'Votre visage ne correspond pas à votre photo de profil.'**
  String get verificationFailureProfileMismatch;

  /// Parcours identité, échec : le quota d'essais du jour est atteint.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez atteint la limite d\'essais du jour. Revenez demain.'**
  String get verificationFailureDailyLimit;

  /// Parcours identité, échec : cause inconnue.
  ///
  /// In fr, this message translates to:
  /// **'La vérification a échoué.'**
  String get verificationFailureGeneric;

  /// Ce téléphone n'a pas de lecteur NFC : titre de l'écran, et message d'échec de la lecture. NFC se garde tel quel.
  ///
  /// In fr, this message translates to:
  /// **'Ce téléphone n\'a pas de lecteur NFC.'**
  String get verificationFailureNoNfc;

  /// Lecture de la puce, échec : le NFC est éteint dans les réglages du téléphone.
  ///
  /// In fr, this message translates to:
  /// **'Activez le NFC dans les réglages du téléphone.'**
  String get verificationFailureNfcDisabled;

  /// Lecture de la puce, échec : le document a bougé pendant la lecture.
  ///
  /// In fr, this message translates to:
  /// **'Le document a bougé. Gardez-le immobile contre le téléphone.'**
  String get verificationFailureTagLost;

  /// Lecture de la puce, échec : la puce a refusé la clé calculée à partir des informations saisies (elles sont fausses).
  ///
  /// In fr, this message translates to:
  /// **'Les informations saisies ne correspondent pas à la puce.'**
  String get verificationFailureChipMismatch;

  /// Lecture de la puce, échec : le document n'a pas de puce lisible par l'app.
  ///
  /// In fr, this message translates to:
  /// **'Ce document ne peut pas être lu.'**
  String get verificationFailureUnreadableDocument;

  /// Lecture de la puce, échec : la puce n'a rien répondu dans le temps imparti.
  ///
  /// In fr, this message translates to:
  /// **'La puce n\'a pas répondu.'**
  String get verificationFailureChipSilent;

  /// Lecture de la puce, échec sans cause connue ; sert aussi de message final dans la feuille système NFC d'iPhone.
  ///
  /// In fr, this message translates to:
  /// **'La lecture a échoué.'**
  String get verificationFailureReadFailed;

  /// Parcours identité, échec : le serveur n'a pas pu être joint.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre connexion.'**
  String get verificationFailureConnection;

  /// Parcours identité, échec : bouton qui relance la lecture de la puce.
  ///
  /// In fr, this message translates to:
  /// **'Relire le document'**
  String get verificationActionRereadDocument;

  /// Parcours identité, échec « document expiré » : bouton qui repart avec un autre document.
  ///
  /// In fr, this message translates to:
  /// **'Autre document'**
  String get verificationActionOtherDocument;

  /// Page Vérification, refus du selfie : aucun visage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun visage détecté. Mettez-vous face à la caméra, dans un endroit bien éclairé.'**
  String get verificationReasonNoFace;

  /// Page Vérification, refus du selfie : plusieurs visages.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs visages détectés. Restez seul(e) dans le cadre.'**
  String get verificationReasonMultipleFaces;

  /// Page Vérification, refus du selfie : visage trop petit.
  ///
  /// In fr, this message translates to:
  /// **'Votre visage est trop loin. Rapprochez-vous de la caméra.'**
  String get verificationReasonFaceTooSmall;

  /// Page Vérification, refus du selfie : poses non reconnues.
  ///
  /// In fr, this message translates to:
  /// **'Les poses demandées n\'ont pas été reconnues. Suivez bien les consignes.'**
  String get verificationReasonPoseMismatch;

  /// Page Vérification, refus du selfie : images trop semblables.
  ///
  /// In fr, this message translates to:
  /// **'Les images sont trop semblables. Bougez la tête comme demandé.'**
  String get verificationReasonDuplicateFrames;

  /// Page Vérification, refus du selfie : ce n'est pas la même personne sur toutes les images.
  ///
  /// In fr, this message translates to:
  /// **'Les images ne montrent pas la même personne. Recommencez seul(e).'**
  String get verificationReasonInconsistentIdentity;

  /// Page Vérification, refus du selfie : le profil n'a aucune photo exploitable.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d\'abord à votre profil une photo où votre visage est bien visible.'**
  String get verificationReasonNoProfilePhoto;

  /// Page Vérification, refus du selfie : le visage ne ressemble pas à la photo principale.
  ///
  /// In fr, this message translates to:
  /// **'Votre visage ne correspond pas à votre photo principale. Choisissez une photo récente où vous êtes bien visible.'**
  String get verificationReasonProfileMismatch;

  /// Page Vérification : le quota d'essais du jour est atteint.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez atteint la limite d\'essais pour aujourd\'hui. Revenez demain.'**
  String get verificationReasonDailyLimit;

  /// Page Vérification : la session de selfie a expiré.
  ///
  /// In fr, this message translates to:
  /// **'La session a expiré. Recommencez.'**
  String get verificationReasonSessionExpired;

  /// Page Vérification : la session de selfie est inconnue ou déjà utilisée.
  ///
  /// In fr, this message translates to:
  /// **'La session n\'est plus valide. Recommencez.'**
  String get verificationReasonSessionInvalid;

  /// Page Vérification : le serveur n'a pas pu lire les images.
  ///
  /// In fr, this message translates to:
  /// **'Les images n\'ont pas pu être lues. Recommencez.'**
  String get verificationReasonImagesUnreadable;

  /// Page Vérification : cette version de l'app est trop ancienne pour la vérification.
  ///
  /// In fr, this message translates to:
  /// **'Mettez à jour l\'application pour vérifier votre profil.'**
  String get verificationReasonAppUpdate;

  /// Refus : la puce du document n'a pas pu être authentifiée (données ou signature invalides, autorité inconnue).
  ///
  /// In fr, this message translates to:
  /// **'La puce du document n\'a pas pu être authentifiée.'**
  String get verificationReasonChipAuth;

  /// Refus : le titulaire a moins de 18 ans.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez avoir au moins 18 ans.'**
  String get verificationReasonUnderage;

  /// Page Vérification : le serveur n'a pas pu être joint (délai ou réseau).
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau et réessayez.'**
  String get verificationReasonNetwork;

  /// Page Vérification : erreur sans cause connue.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez dans un instant.'**
  String get verificationReasonGeneric;

  /// Feuille système NFC d'iPhone (affichée par iOS, pas par l'app) : invite à approcher le document. Une phrase.
  ///
  /// In fr, this message translates to:
  /// **'Approchez votre document du haut du téléphone.'**
  String get verificationNfcAlertApproach;

  /// Feuille système NFC d'iPhone : établissement du canal sécurisé avec la puce. Le membre ne doit pas bouger.
  ///
  /// In fr, this message translates to:
  /// **'Ne bouge pas. Connexion sécurisée…'**
  String get verificationNfcAlertAuthenticating;

  /// Feuille système NFC d'iPhone : lecture de la photo de la puce, avancement à 40 %.
  ///
  /// In fr, this message translates to:
  /// **'Lecture de la photo… 40 %'**
  String get verificationNfcAlertReadingPhoto;

  /// Feuille système NFC d'iPhone : lecture de la signature de la puce, avancement à 85 %.
  ///
  /// In fr, this message translates to:
  /// **'Lecture de la signature… 85 %'**
  String get verificationNfcAlertReadingSignature;

  /// Feuille système NFC d'iPhone : message de fin quand la lecture a réussi.
  ///
  /// In fr, this message translates to:
  /// **'Terminé.'**
  String get verificationNfcAlertDone;

  /// Titre de l'écran qui liste les ordinateurs connectés au compte (version web de MAZL), et libellé de la ligne qui l'ouvre dans les Paramètres.
  ///
  /// In fr, this message translates to:
  /// **'Ordinateurs connectés'**
  String get webSessionsTitle;

  /// Petit libellé en capitales en haut de l'écran des ordinateurs connectés.
  ///
  /// In fr, this message translates to:
  /// **'MAZL sur ordinateur'**
  String get webSessionsSectionLabel;

  /// Phrase d'introduction de l'écran des ordinateurs connectés. L'adresse du site web est écrite telle quelle. 7 jours est la durée maximale d'une connexion.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez MAZL sur ordinateur sur app.mazl.app. Chaque ordinateur reste connecté 7 jours au plus.'**
  String get webSessionsIntro;

  /// Bouton qui ouvre la caméra pour lire le QR code affiché sur l'ordinateur et le connecter.
  ///
  /// In fr, this message translates to:
  /// **'Connecter un ordinateur'**
  String get webSessionsConnect;

  /// Message bref (snackbar) quand un ordinateur vient d'être connecté.
  ///
  /// In fr, this message translates to:
  /// **'Ordinateur connecté.'**
  String get webSessionsConnected;

  /// Texte de l'écran des ordinateurs quand la liste n'a pas pu être chargée. Un bouton « Réessayer » suit.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos ordinateurs. Vérifiez votre connexion.'**
  String get webSessionsLoadFailed;

  /// Texte de l'écran des ordinateurs quand aucun ordinateur n'est connecté.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ordinateur n\'est connecté pour le moment.'**
  String get webSessionsEmpty;

  /// Petit libellé en capitales au-dessus de la liste des ordinateurs connectés.
  ///
  /// In fr, this message translates to:
  /// **'Ordinateurs'**
  String get webSessionsListLabel;

  /// Bouton à droite d'un ordinateur de la liste : le déconnecte du compte.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get webSessionsRevoke;

  /// Texte lu par le lecteur d'écran pour le bouton « Déconnecter » d'un ordinateur. {browser} est le nom du navigateur et du système, ex. « Chrome sur macOS ».
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter {browser}'**
  String webSessionsRevokeNamed(String browser);

  /// Message bref (snackbar) quand la déconnexion d'un ordinateur a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de déconnecter cet ordinateur. Réessayez.'**
  String get webSessionsRevokeFailed;

  /// Bouton (rouge) sous la liste : déconnecte tous les ordinateurs d'un coup.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter tous les ordinateurs'**
  String get webSessionsRevokeAll;

  /// Titre de la fenêtre de confirmation avant de déconnecter tous les ordinateurs.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter tous les ordinateurs ?'**
  String get webSessionsRevokeAllTitle;

  /// Corps de la fenêtre de confirmation avant de déconnecter tous les ordinateurs.
  ///
  /// In fr, this message translates to:
  /// **'Vous devrez vous reconnecter sur chaque ordinateur.'**
  String get webSessionsRevokeAllBody;

  /// Bouton de confirmation de la fenêtre « Déconnecter tous les ordinateurs ? ».
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter tout'**
  String get webSessionsRevokeAllConfirm;

  /// Message bref (snackbar) quand la déconnexion de tous les ordinateurs a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de déconnecter les ordinateurs. Réessayez.'**
  String get webSessionsRevokeAllFailed;

  /// Première moitié de la ligne de détail d'un ordinateur : il s'est connecté en lisant un QR code. Suivie de « · » et de la dernière activité.
  ///
  /// In fr, this message translates to:
  /// **'Connecté par QR code'**
  String get webSessionsMethodQr;

  /// Première moitié de la ligne de détail d'un ordinateur : il s'est connecté avec un compte Google.
  ///
  /// In fr, this message translates to:
  /// **'Connecté avec Google'**
  String get webSessionsMethodGoogle;

  /// Première moitié de la ligne de détail d'un ordinateur : il s'est connecté avec « Se connecter avec Apple ».
  ///
  /// In fr, this message translates to:
  /// **'Connecté avec Apple'**
  String get webSessionsMethodApple;

  /// Seconde moitié de la ligne de détail d'un ordinateur : actif il y a moins d'une minute.
  ///
  /// In fr, this message translates to:
  /// **'Actif à l\'instant'**
  String get webSessionsActiveNow;

  /// Seconde moitié de la ligne de détail d'un ordinateur : dernière activité il y a {count} minutes (de 1 à 59). « min » est l'abréviation.
  ///
  /// In fr, this message translates to:
  /// **'Actif il y a {count} min'**
  String webSessionsActiveMinutes(int count);

  /// Seconde moitié de la ligne de détail d'un ordinateur : dernière activité il y a {count} heures (de 1 à 23). « h » est l'abréviation.
  ///
  /// In fr, this message translates to:
  /// **'Actif il y a {count} h'**
  String webSessionsActiveHours(int count);

  /// Seconde moitié de la ligne de détail d'un ordinateur : dernière activité hier.
  ///
  /// In fr, this message translates to:
  /// **'Actif hier'**
  String get webSessionsActiveYesterday;

  /// Seconde moitié de la ligne de détail d'un ordinateur : dernière activité il y a {count} jours (2 ou plus). « j » est l'abréviation de jours.
  ///
  /// In fr, this message translates to:
  /// **'Actif il y a {count} j'**
  String webSessionsActiveDays(int count);

  /// Heure à laquelle un ordinateur a demandé la connexion, dans la feuille de confirmation. {hour} est l'heure (0 à 23), {minute} les minutes sur deux chiffres. En français « 14 h 05 », ailleurs « 14:05 ».
  ///
  /// In fr, this message translates to:
  /// **'{hour} h {minute}'**
  String webSessionsClockTime(String hour, String minute);

  /// Consigne affichée sur la caméra de lecture du QR code, au bas de l'écran. L'adresse du site web est écrite telle quelle.
  ///
  /// In fr, this message translates to:
  /// **'Scannez le QR code affiché sur app.mazl.app'**
  String get webSessionsScanInstruction;

  /// Texte lu par le lecteur d'écran pour la vue de la caméra qui lit le QR code.
  ///
  /// In fr, this message translates to:
  /// **'Caméra de lecture du QR code'**
  String get webSessionsScanCameraLabel;

  /// Message affiché à la place de la caméra quand l'app n'y a pas accès (autorisation refusée).
  ///
  /// In fr, this message translates to:
  /// **'La caméra n\'est pas accessible. Autorisez l\'accès à la caméra dans les réglages de votre iPhone pour scanner un code.'**
  String get webSessionsCameraUnavailable;

  /// Message sous la consigne de la caméra : le QR code lu n'est pas un code de connexion MAZL.
  ///
  /// In fr, this message translates to:
  /// **'Ce QR code n\'est pas un code MAZL.'**
  String get webSessionsScanNotMazl;

  /// Message sous la consigne de la caméra : le code lu est inconnu, expiré ou déjà utilisé.
  ///
  /// In fr, this message translates to:
  /// **'Ce code a expiré. Affichez un nouveau code sur l\'ordinateur.'**
  String get webSessionsScanExpired;

  /// Message sous la consigne de la caméra : trop de lectures de code en peu de temps.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patientez un instant avant de réessayer.'**
  String get webSessionsScanTooMany;

  /// Message sous la consigne de la caméra : la demande de connexion n'est plus valide au moment de l'approuver (déjà traitée ou expirée).
  ///
  /// In fr, this message translates to:
  /// **'Cette demande n\'est plus valide. Affichez un nouveau code sur l\'ordinateur.'**
  String get webSessionsApproveInvalid;

  /// Message sous la consigne de la caméra : le réseau est coupé ou trop lent.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau, puis réessayez.'**
  String get webSessionsConnectionProblem;

  /// Message sous la consigne de la caméra : erreur inattendue du serveur.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez dans un instant.'**
  String get webSessionsGenericProblem;

  /// Petit libellé en capitales au-dessus du titre de la feuille de confirmation d'une connexion depuis un ordinateur.
  ///
  /// In fr, this message translates to:
  /// **'Connexion à MAZL sur ordinateur'**
  String get webSessionsConfirmLabel;

  /// Titre de la feuille qui demande au membre s'il veut connecter l'ordinateur dont il vient de lire le QR code.
  ///
  /// In fr, this message translates to:
  /// **'Connecter cet ordinateur ?'**
  String get webSessionsConfirmTitle;

  /// Libellé de la ligne qui donne le navigateur de l'ordinateur à connecter (valeur : ex. « Chrome sur macOS »).
  ///
  /// In fr, this message translates to:
  /// **'Navigateur'**
  String get webSessionsConfirmBrowser;

  /// Libellé de la ligne qui donne l'adresse réseau (masquée) d'où vient la demande de connexion.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get webSessionsConfirmAddress;

  /// Libellé de la ligne qui donne l'heure à laquelle la demande de connexion a été faite (valeur : ex. « 14 h 05 »).
  ///
  /// In fr, this message translates to:
  /// **'Demande faite à'**
  String get webSessionsConfirmAskedAt;

  /// Avertissement de sécurité sous les détails de la demande de connexion : ne scanner que son propre écran, refuser si un tiers le demande (arnaque).
  ///
  /// In fr, this message translates to:
  /// **'Ne scannez que le code affiché sur votre propre ordinateur. Si quelqu\'un vous demande de scanner un code, refusez.'**
  String get webSessionsConfirmWarning;

  /// Bouton principal de la feuille de confirmation : connecte l'ordinateur.
  ///
  /// In fr, this message translates to:
  /// **'Connecter'**
  String get webSessionsConfirmApprove;

  /// Bouton secondaire de la feuille de confirmation : refuse la connexion de l'ordinateur.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get webSessionsConfirmDeny;
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
