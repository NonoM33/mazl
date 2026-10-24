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

  /// Connexion : bouton texte qui ouvre l'écran de connexion par e-mail.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser mon e-mail'**
  String get authLoginEmail;

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

  /// Connexion par e-mail : l'adresse ou le mot de passe est faux.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect'**
  String get authErrorInvalidCredentials;

  /// Connexion avec Apple ou Google : le membre a fermé la fenêtre de connexion.
  ///
  /// In fr, this message translates to:
  /// **'Connexion annulée.'**
  String get authErrorCancelled;

  /// Inscription : un compte existe déjà avec cette adresse e-mail.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse e-mail est déjà utilisée.'**
  String get authErrorEmailTaken;

  /// Connexion avec Apple : proposée sur iPhone et Mac seulement.
  ///
  /// In fr, this message translates to:
  /// **'Cette méthode de connexion n\'est pas disponible sur cet appareil.'**
  String get authErrorUnsupported;

  /// Connexion par e-mail : échec dont la cause n'est pas connue.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion'**
  String get authErrorLoginFailed;

  /// Inscription par e-mail : échec dont la cause n'est pas connue.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'inscription'**
  String get authErrorRegisterFailed;

  /// Inscription : le membre n'a pas coché la case des conditions d'utilisation.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez accepter les conditions d\'utilisation'**
  String get authErrorTermsRequired;

  /// Connexion par e-mail : grand titre en mode connexion.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get authEmailTitleLogin;

  /// Connexion par e-mail : grand titre en mode inscription.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get authEmailTitleRegister;

  /// Connexion par e-mail : phrase sous le titre en mode connexion.
  ///
  /// In fr, this message translates to:
  /// **'Ravi de vous revoir'**
  String get authEmailSubtitleLogin;

  /// Connexion par e-mail : phrase sous le titre en mode inscription.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte MAZL'**
  String get authEmailSubtitleRegister;

  /// Inscription : titre du champ du prénom.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get authFieldName;

  /// Connexion : titre du champ de l'adresse e-mail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authFieldEmail;

  /// Connexion : titre du champ du mot de passe.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authFieldPassword;

  /// Inscription : titre du champ qui redemande le mot de passe.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authFieldPasswordConfirm;

  /// Inscription : force du mot de passe, niveau le plus bas (à côté de la barre).
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get authStrengthWeak;

  /// Inscription : force du mot de passe, deuxième niveau.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get authStrengthFair;

  /// Inscription : force du mot de passe, troisième niveau.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get authStrengthGood;

  /// Inscription : force du mot de passe, niveau le plus haut.
  ///
  /// In fr, this message translates to:
  /// **'Excellent'**
  String get authStrengthExcellent;

  /// Inscription : phrase à côté de la case à cocher des conditions (12 px, sur deux lignes au plus).
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte les Conditions d\'utilisation et la Politique de confidentialité'**
  String get authTermsCheckbox;

  /// Connexion par e-mail : lien qui ouvre la réinitialisation du mot de passe.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authForgotLink;

  /// Connexion par e-mail : bouton principal en mode connexion.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSubmitLogin;

  /// Connexion par e-mail : bouton principal en mode inscription.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get authSubmitRegister;

  /// Connexion par e-mail : question en bas du formulaire en mode connexion.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get authToggleNoAccount;

  /// Connexion par e-mail : question en bas du formulaire en mode inscription.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get authToggleHaveAccount;

  /// Connexion par e-mail : bouton texte qui passe en mode inscription.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authToggleCreate;

  /// Connexion par e-mail : bouton texte qui repasse en mode connexion.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authToggleSignIn;

  /// Formulaire e-mail : champ vide.
  ///
  /// In fr, this message translates to:
  /// **'Email requis'**
  String get authValidationEmailRequired;

  /// Formulaire e-mail : adresse mal formée.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get authValidationEmailInvalid;

  /// Formulaire e-mail : mot de passe vide.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get authValidationPasswordRequired;

  /// Formulaire e-mail : mot de passe trop court (8 caractères).
  ///
  /// In fr, this message translates to:
  /// **'Minimum 8 caractères'**
  String get authValidationPasswordMin;

  /// Inscription : le mot de passe n'a pas de majuscule.
  ///
  /// In fr, this message translates to:
  /// **'Au moins une majuscule'**
  String get authValidationPasswordUpper;

  /// Inscription : le mot de passe n'a pas de chiffre.
  ///
  /// In fr, this message translates to:
  /// **'Au moins un chiffre'**
  String get authValidationPasswordDigit;

  /// Inscription : les deux mots de passe saisis diffèrent.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get authValidationPasswordMismatch;

  /// Inscription : prénom vide.
  ///
  /// In fr, this message translates to:
  /// **'Prénom requis'**
  String get authValidationNameRequired;

  /// Inscription : prénom trop court (2 caractères).
  ///
  /// In fr, this message translates to:
  /// **'Minimum 2 caractères'**
  String get authValidationNameMin;

  /// Inscription : titre de la boîte de dialogue après la création du compte.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre email'**
  String get authVerifyTitle;

  /// Inscription : première ligne de la boîte de dialogue ; l'adresse du membre est affichée juste en dessous.
  ///
  /// In fr, this message translates to:
  /// **'Un email de vérification a été envoyé à :'**
  String get authVerifySent;

  /// Inscription : consigne de la boîte de dialogue.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur le lien dans l\'email pour activer votre compte.'**
  String get authVerifyInstruction;

  /// Inscription : bouton qui ferme la boîte de dialogue.
  ///
  /// In fr, this message translates to:
  /// **'OK, je vais vérifier'**
  String get authVerifyOk;

  /// Mot de passe oublié : titre de la boîte de dialogue.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get authForgotTitle;

  /// Mot de passe oublié : consigne au-dessus du champ e-mail.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email pour recevoir un lien de réinitialisation.'**
  String get authForgotInstruction;

  /// Mot de passe oublié : confirmation après l'envoi du lien.
  ///
  /// In fr, this message translates to:
  /// **'Email de réinitialisation envoyé'**
  String get authForgotSent;

  /// Mot de passe oublié : bouton qui envoie le lien.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get authForgotSend;

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

  /// Info-bulle du bouton rond (engrenage) en haut à droite du tableau de bord du couple.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get coupleFeedDashboardSettingsTooltip;

  /// Nom affiché sous l'avatar du membre, dans l'en-tête du tableau de bord du couple. Très court.
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get coupleFeedDashboardMe;

  /// Nom affiché sous l'avatar du partenaire quand son prénom est inconnu. Très court.
  ///
  /// In fr, this message translates to:
  /// **'Partenaire'**
  String get coupleFeedDashboardPartnerFallback;

  /// Titre de l'en-tête du couple : le nombre de jours depuis le début de la relation. Une ligne, sous les deux avatars.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 jours ensemble} one{{count} jour ensemble} other{{count} jours ensemble}}'**
  String coupleFeedDashboardDaysTogether(int count);

  /// Petit titre de la carte de la question du jour, à gauche de la catégorie de la question. Majuscules ajoutées par le design.
  ///
  /// In fr, this message translates to:
  /// **'Question du jour'**
  String get coupleFeedDashboardDailyQuestion;

  /// Bouton plein de la carte de la question du jour : ouvre la feuille pour répondre.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get coupleFeedDashboardAnswer;

  /// Texte d'aide dans le champ où le membre écrit sa réponse à la question du jour.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse…'**
  String get coupleFeedDashboardAnswerHint;

  /// Bouton qui envoie la réponse écrite à la question du jour.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get coupleFeedDashboardSend;

  /// Message vert affiché en bas de l'écran une fois la réponse à la question du jour envoyée. Une à deux lignes.
  ///
  /// In fr, this message translates to:
  /// **'Réponse envoyée. Votre partenaire sera notifié(e).'**
  String get coupleFeedDashboardAnswerSent;

  /// Titre de section (petites majuscules) au-dessus de la bande d'idées d'activités à deux.
  ///
  /// In fr, this message translates to:
  /// **'Activités en couple'**
  String get coupleFeedDashboardActivities;

  /// Titre de section au-dessus des étapes du couple (première semaine, premier mois...).
  ///
  /// In fr, this message translates to:
  /// **'Nos étapes'**
  String get coupleFeedDashboardMilestones;

  /// Bouton texte à droite du titre « Nos étapes ». Court.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get coupleFeedDashboardSeeAll;

  /// Titre de section au-dessus de la carte d'événement pour couples.
  ///
  /// In fr, this message translates to:
  /// **'Événements en couple'**
  String get coupleFeedDashboardEvents;

  /// Titre de section au-dessus de la carte du calendrier juif (Shabbat de la semaine).
  ///
  /// In fr, this message translates to:
  /// **'Calendrier juif'**
  String get coupleFeedDashboardJewishCalendar;

  /// Titre de l'écran des histoires de couples et titre de section du tableau de bord du couple.
  ///
  /// In fr, this message translates to:
  /// **'Histoires de couples'**
  String get coupleFeedStoriesTitle;

  /// Bouton texte à droite du titre « Histoires de couples » : ouvre la liste des histoires. Court.
  ///
  /// In fr, this message translates to:
  /// **'Voir toutes'**
  String get coupleFeedDashboardSeeAllStories;

  /// Titre de l'événement d'exemple dans la carte « Événements en couple » du tableau de bord (contenu fixe, pas celui du serveur).
  ///
  /// In fr, this message translates to:
  /// **'Cours de cuisine casher'**
  String get coupleFeedDashboardEventSampleTitle;

  /// Jour et heure de l'événement d'exemple de la carte « Événements en couple » (contenu fixe).
  ///
  /// In fr, this message translates to:
  /// **'Dimanche 20 janvier - 15h00'**
  String get coupleFeedDashboardEventSampleWhen;

  /// Petite pastille à droite de l'événement d'exemple : il s'adresse aux couples. Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Couples'**
  String get coupleFeedDashboardEventSampleTag;

  /// Bouton contour de la carte « Événements en couple » : ouvre tous les événements.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les événements'**
  String get coupleFeedDashboardAllEvents;

  /// Nom du Shabbat de la semaine dans la carte du calendrier juif (contenu fixe). Nom propre de la section de la Torah.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat Beshalach'**
  String get coupleFeedDashboardParasha;

  /// Heures d'entrée et de sortie du Shabbat dans la carte du calendrier juif (contenu fixe). Une ligne.
  ///
  /// In fr, this message translates to:
  /// **'Entrée : 17h23 - Sortie : 18h34'**
  String get coupleFeedDashboardShabbatTimes;

  /// Légende sous une icône ronde : idée de dîner de Shabbat. Un mot, 12 px de large environ par lettre.
  ///
  /// In fr, this message translates to:
  /// **'Dîner'**
  String get coupleFeedDashboardShabbatDinner;

  /// Légende sous une icône ronde : idée de prière de Shabbat. Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Prière'**
  String get coupleFeedDashboardShabbatPrayer;

  /// Légende sous une icône ronde : idée de repos de Shabbat. Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Repos'**
  String get coupleFeedDashboardShabbatRest;

  /// Titre de la carte du tableau de bord et de la feuille qui invitent le couple à partager son histoire.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre histoire'**
  String get coupleFeedStoryShareTitle;

  /// Phrase sous le titre de la carte « Partagez votre histoire » du tableau de bord.
  ///
  /// In fr, this message translates to:
  /// **'Inspirez la communauté MAZL avec votre histoire'**
  String get coupleFeedDashboardShareStoryLine;

  /// Bouton contour de la carte « Partagez votre histoire » : ouvre la liste des histoires. Moitié de la largeur de l'écran.
  ///
  /// In fr, this message translates to:
  /// **'Voir les histoires'**
  String get coupleFeedDashboardSeeStories;

  /// Étape du couple : première semaine (titre).
  ///
  /// In fr, this message translates to:
  /// **'Première semaine'**
  String get coupleFeedMilestoneFirstWeekTitle;

  /// Étape du couple : première semaine (légende).
  ///
  /// In fr, this message translates to:
  /// **'7 jours ensemble'**
  String get coupleFeedMilestoneFirstWeekLine;

  /// Étape du couple : premier mois (titre).
  ///
  /// In fr, this message translates to:
  /// **'Premier mois'**
  String get coupleFeedMilestoneFirstMonthTitle;

  /// Étape du couple : premier mois (légende).
  ///
  /// In fr, this message translates to:
  /// **'30 jours d\'amour'**
  String get coupleFeedMilestoneFirstMonthLine;

  /// Étape du couple : trois mois (titre).
  ///
  /// In fr, this message translates to:
  /// **'Trimestre'**
  String get coupleFeedMilestoneThreeMonthsTitle;

  /// Étape du couple : trois mois (légende).
  ///
  /// In fr, this message translates to:
  /// **'3 mois de bonheur'**
  String get coupleFeedMilestoneThreeMonthsLine;

  /// Étape du couple : six mois (titre).
  ///
  /// In fr, this message translates to:
  /// **'Mi-année'**
  String get coupleFeedMilestoneSixMonthsTitle;

  /// Étape du couple : six mois (légende).
  ///
  /// In fr, this message translates to:
  /// **'6 mois main dans la main'**
  String get coupleFeedMilestoneSixMonthsLine;

  /// Étape du couple : un an (titre).
  ///
  /// In fr, this message translates to:
  /// **'Première année'**
  String get coupleFeedMilestoneFirstYearTitle;

  /// Étape du couple : un an (légende). « Mazl » est écrit ainsi dans le texte d'origine.
  ///
  /// In fr, this message translates to:
  /// **'365 jours de Mazl'**
  String get coupleFeedMilestoneFirstYearLine;

  /// Question du jour n° 1, posée à un membre du couple.
  ///
  /// In fr, this message translates to:
  /// **'Quel est votre moment préféré de la semaine ensemble ?'**
  String get coupleFeedQuestion1;

  /// Catégorie de la question du jour n° 1, dans une pastille. Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get coupleFeedQuestion1Category;

  /// Question du jour n° 2.
  ///
  /// In fr, this message translates to:
  /// **'Si vous pouviez voyager n\'importe où, où iriez-vous ?'**
  String get coupleFeedQuestion2;

  /// Catégorie de la question du jour n° 2. Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Rêves'**
  String get coupleFeedQuestion2Category;

  /// Question du jour n° 3.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce qui vous a fait sourire aujourd\'hui ?'**
  String get coupleFeedQuestion3;

  /// Catégorie de la question du jour n° 3. Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Quotidien'**
  String get coupleFeedQuestion3Category;

  /// Question du jour n° 4, sur le Shabbat, avec quatre réponses au choix.
  ///
  /// In fr, this message translates to:
  /// **'Comment aimeriez-vous célébrer votre prochain Shabbat ?'**
  String get coupleFeedQuestion4;

  /// Catégorie de la question du jour n° 4. Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Judaïsme'**
  String get coupleFeedQuestion4Category;

  /// Réponse au choix n° 1 de la question sur le Shabbat, bouton pleine largeur.
  ///
  /// In fr, this message translates to:
  /// **'Dîner romantique à la maison'**
  String get coupleFeedQuestion4Option1;

  /// Réponse au choix n° 2 de la question sur le Shabbat, bouton pleine largeur.
  ///
  /// In fr, this message translates to:
  /// **'Invitation chez des amis'**
  String get coupleFeedQuestion4Option2;

  /// Réponse au choix n° 3 de la question sur le Shabbat, bouton pleine largeur.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant casher'**
  String get coupleFeedQuestion4Option3;

  /// Réponse au choix n° 4 de la question sur le Shabbat : un Shabbaton est un week-end communautaire.
  ///
  /// In fr, this message translates to:
  /// **'Shabbaton communautaire'**
  String get coupleFeedQuestion4Option4;

  /// Question du jour n° 5.
  ///
  /// In fr, this message translates to:
  /// **'Quel trait de caractère admirez-vous le plus chez votre partenaire ?'**
  String get coupleFeedQuestion5;

  /// Catégorie de la question du jour n° 5. Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Appréciation'**
  String get coupleFeedQuestion5Category;

  /// Idée d'activité à deux de la bande du tableau de bord : cuisiner pour Shabbat. Carte étroite (deux lignes).
  ///
  /// In fr, this message translates to:
  /// **'Cuisine Shabbat'**
  String get coupleFeedIdeaShabbatCookingTitle;

  /// Étiquette de l'idée « Cuisine Shabbat ». Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Maison'**
  String get coupleFeedIdeaShabbatCookingCategory;

  /// Idée d'activité à deux : étudier la Torah ensemble. Carte étroite.
  ///
  /// In fr, this message translates to:
  /// **'Étude Torah'**
  String get coupleFeedIdeaTorahTitle;

  /// Idée d'activité à deux : une soirée en tête-à-tête. Carte étroite.
  ///
  /// In fr, this message translates to:
  /// **'Date night'**
  String get coupleFeedIdeaDateNightTitle;

  /// Étiquette de l'idée « Date night ». Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Romance'**
  String get coupleFeedIdeaDateNightCategory;

  /// Idée d'activité à deux : faire du sport ensemble. Carte étroite.
  ///
  /// In fr, this message translates to:
  /// **'Sport ensemble'**
  String get coupleFeedIdeaSportTitle;

  /// Idée d'activité à deux : une action de bienfaisance (hesed) en couple. Carte étroite.
  ///
  /// In fr, this message translates to:
  /// **'Hesed ensemble'**
  String get coupleFeedIdeaChesedTitle;

  /// Étiquette de l'idée « Hesed ensemble ». Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get coupleFeedIdeaChesedCategory;

  /// Étiquette de l'idée « Voyage ». Un mot.
  ///
  /// In fr, this message translates to:
  /// **'Aventure'**
  String get coupleFeedIdeaTravelCategory;

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

  /// Titre de l'état vide des histoires de couples.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'histoires de couples'**
  String get coupleFeedStoriesEmptyTitle;

  /// Phrase sous le titre de l'état vide des histoires.
  ///
  /// In fr, this message translates to:
  /// **'Les premières histoires d\'amour MAZL seront bientôt partagées.'**
  String get coupleFeedStoriesEmptyLine;

  /// Texte envoyé par le partage d'une histoire de couple ; {name1} et {name2} sont les prénoms, {excerpt} le début de l'histoire.
  ///
  /// In fr, this message translates to:
  /// **'{name1} et {name2} se sont rencontrés sur MAZL. Leur histoire : {excerpt}...'**
  String coupleFeedStoryShareText(String name1, String name2, String excerpt);

  /// Sous les noms du couple : son statut et le mois où ils se sont rencontrés. {status} est un des trois statuts, {date} un mois et une année.
  ///
  /// In fr, this message translates to:
  /// **'{status} · depuis {date}'**
  String coupleFeedStoryStatusSince(String status, String date);

  /// Statut d'un couple : ensemble, sans engagement particulier.
  ///
  /// In fr, this message translates to:
  /// **'En couple'**
  String get coupleFeedStatusDating;

  /// Statut d'un couple : fiancés.
  ///
  /// In fr, this message translates to:
  /// **'Fiancés'**
  String get coupleFeedStatusEngaged;

  /// Statut d'un couple : mariés.
  ///
  /// In fr, this message translates to:
  /// **'Mariés'**
  String get coupleFeedStatusMarried;

  /// Phrase sous le titre de la feuille « Partagez votre histoire ».
  ///
  /// In fr, this message translates to:
  /// **'Inspirez la communauté MAZL en partageant votre histoire.'**
  String get coupleFeedStoryShareLine;

  /// Titre de section (petites majuscules) au-dessus des trois puces de statut.
  ///
  /// In fr, this message translates to:
  /// **'Votre statut'**
  String get coupleFeedStoryStatusLabel;

  /// Titre de section au-dessus du champ de l'histoire ; le minimum de 100 caractères est imposé.
  ///
  /// In fr, this message translates to:
  /// **'Votre histoire (min. 100 caractères)'**
  String get coupleFeedStoryTextLabel;

  /// Texte d'aide du champ de l'histoire : deux questions pour donner des idées au couple.
  ///
  /// In fr, this message translates to:
  /// **'Comment vous êtes-vous rencontrés ? Qu\'est-ce qui vous a plu chez l\'autre ?…'**
  String get coupleFeedStoryTextHint;

  /// Titre de section au-dessus de la zone d'ajout de photos.
  ///
  /// In fr, this message translates to:
  /// **'Photos (optionnel)'**
  String get coupleFeedStoryPhotosLabel;

  /// Texte de la zone d'ajout de photos de couple, sous une icône d'appareil photo.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des photos de couple'**
  String get coupleFeedStoryPhotosHint;

  /// Bouton plein qui envoie l'histoire du couple pour validation.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre notre histoire'**
  String get coupleFeedStorySubmit;

  /// Message en bas d'écran : l'histoire fait moins de 100 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Votre histoire doit faire au moins 100 caractères'**
  String get coupleFeedStoryTooShort;

  /// Message vert après l'envoi de l'histoire : elle sera relue avant d'être publiée.
  ///
  /// In fr, this message translates to:
  /// **'Merci. Votre histoire sera publiée après validation.'**
  String get coupleFeedStoryThanks;

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

  /// Titre de la section des badges débloqués par le couple.
  ///
  /// In fr, this message translates to:
  /// **'Nos badges'**
  String get coupleSpaceBadgesTitle;

  /// État vide de la section des badges : titre.
  ///
  /// In fr, this message translates to:
  /// **'Aucun badge pour l\'instant'**
  String get coupleSpaceBadgesEmptyTitle;

  /// État vide de la section des badges : comment en débloquer.
  ///
  /// In fr, this message translates to:
  /// **'Faites des activités ensemble pour débloquer des badges.'**
  String get coupleSpaceBadgesEmptyHint;

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

  /// Statut de relation du membre : sans partenaire.
  ///
  /// In fr, this message translates to:
  /// **'Célibataire'**
  String get coupleSpaceStatusSingle;

  /// Statut de relation du membre : en train de faire connaissance.
  ///
  /// In fr, this message translates to:
  /// **'En train de dater'**
  String get coupleSpaceStatusDating;

  /// Statut de relation du membre : en couple.
  ///
  /// In fr, this message translates to:
  /// **'En couple'**
  String get coupleSpaceStatusInRelationship;

  /// Statut de relation du membre : fiancé ou fiancée.
  ///
  /// In fr, this message translates to:
  /// **'Fiancé(e)'**
  String get coupleSpaceStatusEngaged;

  /// Statut de relation du membre : marié ou mariée.
  ///
  /// In fr, this message translates to:
  /// **'Marié(e)'**
  String get coupleSpaceStatusMarried;

  /// Durée en jours (repli quand un jalon n'est ni une semaine, ni un mois, ni une année pleine).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} jour} other{{count} jours}}'**
  String coupleSpaceDurationDays(int count);

  /// Nom d'un jalon du couple qui vaut un nombre entier de semaines (ex. « 1 semaine »).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} semaine} other{{count} semaines}}'**
  String coupleSpaceDurationWeeks(int count);

  /// Nom d'un jalon du couple qui vaut un nombre entier de mois (ex. « 3 mois »).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} mois} other{{count} mois}}'**
  String coupleSpaceDurationMonths(int count);

  /// Nom d'un jalon du couple qui vaut un nombre entier d'années (ex. « 1 an »).
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} an} other{{count} ans}}'**
  String coupleSpaceDurationYears(int count);

  /// Pastille en haut de la carte d'anniversaire, le jour où le couple fête son anniversaire sur l'app. « MAZL » est le nom de l'app.
  ///
  /// In fr, this message translates to:
  /// **'Joyeux anniversaire MAZL'**
  String get coupleSpaceAnniversaryTag;

  /// Sous le grand nombre de jours de la carte d'anniversaire : le nombre est affiché au-dessus, ce texte donne l'unité.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{jour ensemble} other{jours ensemble}}'**
  String coupleSpaceAnniversaryDaysLabel(int count);

  /// Carte d'anniversaire : avec qui le couple est ensemble, {name} est le partenaire.
  ///
  /// In fr, this message translates to:
  /// **'avec {name}'**
  String coupleSpaceAnniversaryWith(String name);

  /// Carte d'anniversaire : le prochain jalon ({milestone}, déjà nommé, ex. « 3 mois ») arrive dans {count} jours.
  ///
  /// In fr, this message translates to:
  /// **'Prochain : {milestone} dans {count, plural, one{{count} jour} other{{count} jours}}'**
  String coupleSpaceAnniversaryNext(String milestone, int count);

  /// Titre de la fenêtre de célébration d'un anniversaire de couple.
  ///
  /// In fr, this message translates to:
  /// **'Joyeux anniversaire'**
  String get coupleSpaceAnniversaryHappy;

  /// Fenêtre de célébration : combien de jours le couple a passé ensemble, avec {name} le partenaire.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} jour} other{{count} jours}} avec {name}'**
  String coupleSpaceAnniversaryDaysWith(int count, String name);

  /// Bouton qui ferme la fenêtre de célébration d'un anniversaire.
  ///
  /// In fr, this message translates to:
  /// **'Merci'**
  String get coupleSpaceAnniversaryThanks;

  /// Texte partagé (WhatsApp, etc.) par le couple pour son anniversaire. {milestone} est le jalon atteint, déjà nommé, ou vide ; il termine la phrase. « MAZL » est le nom de l'app.
  ///
  /// In fr, this message translates to:
  /// **'Nous fêtons {count, plural, one{{count} jour} other{{count} jours}} ensemble sur MAZL. {milestone}'**
  String coupleSpaceAnniversaryShare(int count, String milestone);

  /// Titre de la liste des jalons du couple (7 jours, 1 mois, 1 an…). « milestones » est un anglicisme courant en français.
  ///
  /// In fr, this message translates to:
  /// **'Vos milestones'**
  String get coupleSpaceMilestonesTitle;

  /// Sous un jalon pas encore atteint : il arrive dans {count} jours.
  ///
  /// In fr, this message translates to:
  /// **'dans {count, plural, one{{count} jour} other{{count} jours}}'**
  String coupleSpaceMilestoneIn(int count);

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

  /// Liste des événements : info-bulle du bouton calendrier de la barre du haut.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get eventsCalendarTooltip;

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
  /// **'Questions quotidiennes'**
  String get onboardingPage3Feature1;

  /// Présentation, page 3 : deuxième ligne de la liste.
  ///
  /// In fr, this message translates to:
  /// **'Milestones de couple'**
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
  /// **'Une pause automatique pendant Shabbat et les fêtes, sans rien à régler.'**
  String get onboardingPage4Body;

  /// Présentation, page 5 : titre. Nom de la fonction d'entremetteuse par intelligence artificielle.
  ///
  /// In fr, this message translates to:
  /// **'AI Shadchan'**
  String get onboardingPage5Title;

  /// Présentation, page 5 : texte.
  ///
  /// In fr, this message translates to:
  /// **'Notre intelligence artificielle vous aide à trouver la bonne personne.'**
  String get onboardingPage5Body;

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

  /// Étiquette en capitales au-dessus du titre de la fenêtre qui annonce un match.
  ///
  /// In fr, this message translates to:
  /// **'Match'**
  String get profileMatchLabel;

  /// Grand titre de la fenêtre qui annonce que deux membres se sont aimés. Environ 15 caractères, peut passer sur deux lignes.
  ///
  /// In fr, this message translates to:
  /// **'C\'est un match.'**
  String get profileMatchTitle;

  /// Fenêtre de match : invite à écrire à la personne. {name} est son prénom.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez maintenant discuter avec {name}.'**
  String profileMatchBody(String name);

  /// Fenêtre de match, quand le prénom manque : invite à écrire à la personne.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez maintenant discuter avec cette personne.'**
  String get profileMatchBodyUnnamed;

  /// Bouton plein de la fenêtre de match : ouvre la conversation.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un message'**
  String get profileSendMessage;

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

  /// Carte de score : nombre de critères pris en compte. Une ligne, petit corps.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 critère analysé} other{{count} critères analysés}}'**
  String profileCompatibilityCriteria(int count);

  /// Titre de la feuille de détail du score quand le palier n'est pas « très compatible ».
  ///
  /// In fr, this message translates to:
  /// **'Score de compatibilité'**
  String get profileCompatibilityScoreTitle;

  /// Feuille de détail du score : sous le titre, avec qui. {name} est le prénom de la personne.
  ///
  /// In fr, this message translates to:
  /// **'Avec {name}'**
  String profileCompatibilityWith(String name);

  /// Feuille de détail du score : titre de la liste des critères.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get profileCompatibilityDetails;

  /// Feuille de détail du score : message quand aucun critère n'est disponible.
  ///
  /// In fr, this message translates to:
  /// **'Complétez vos profils pour voir plus de détails'**
  String get profileCompatibilityIncomplete;

  /// Feuille de détail du score : note explicative en petit corps.
  ///
  /// In fr, this message translates to:
  /// **'Le score est basé sur vos préférences et points communs'**
  String get profileCompatibilityNote;

  /// Feuille de détail du score : bouton qui la ferme.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get profileCompatibilityGotIt;

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

  /// Titre au-dessus des questions et réponses d'un membre sur son profil.
  ///
  /// In fr, this message translates to:
  /// **'Apprenez à me connaître'**
  String get profilePromptsGetToKnowMe;

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

  /// Inscription, étape 4 : encadré en bas, petit corps. « AI Shadchan » est le nom de la fonction, à ne pas traduire.
  ///
  /// In fr, this message translates to:
  /// **'Notre AI Shadchan utilisera ces préférences pour vous proposer des profils compatibles.'**
  String get profileShadchanNote;

  /// Bouton texte en bas du profil d'un autre membre : ouvre la fenêtre de blocage et de signalement.
  ///
  /// In fr, this message translates to:
  /// **'Signaler ce profil'**
  String get profileReportThisProfile;

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

  /// Réglages : sous-titre de la ligne Mode Shabbat (les notifications se mettent en pause toutes seules).
  ///
  /// In fr, this message translates to:
  /// **'Pause automatique'**
  String get settingsShabbatAutoPause;

  /// Réglages : interrupteur qui prévient avant les fêtes juives.
  ///
  /// In fr, this message translates to:
  /// **'Alertes fêtes'**
  String get settingsHolidayAlerts;

  /// Réglages : sous-titre de l'interrupteur Alertes fêtes.
  ///
  /// In fr, this message translates to:
  /// **'Notifications avant les fêtes'**
  String get settingsHolidayAlertsHint;

  /// Réglages : titre de la section des notifications. Affiché en petites capitales.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// Réglages : interrupteur des notifications de nouveaux matchs.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux matchs'**
  String get settingsNotifMatches;

  /// Réglages : interrupteur des notifications de messages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get settingsNotifMessages;

  /// Réglages : interrupteur des notifications de Super Likes.
  ///
  /// In fr, this message translates to:
  /// **'Super Likes'**
  String get settingsNotifSuperLikes;

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

  /// Écran Mode Shabbat : la ville sur laquelle se basent les horaires, affichée sous les heures et dans la ligne de lieu.
  ///
  /// In fr, this message translates to:
  /// **'Basé sur Paris, France'**
  String get settingsShabbatCity;

  /// Écran Mode Shabbat : titre de la liste des réglages sous le bandeau sombre. Affiché en petites capitales.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsShabbatSettingsHeader;

  /// Écran Mode Shabbat : interrupteur principal.
  ///
  /// In fr, this message translates to:
  /// **'Activer le mode Shabbat'**
  String get settingsShabbatEnable;

  /// Écran Mode Shabbat : sous-titre de l'interrupteur principal.
  ///
  /// In fr, this message translates to:
  /// **'Pause automatique des notifications pendant Shabbat'**
  String get settingsShabbatEnableHint;

  /// Écran Mode Shabbat : interrupteur qui étend la pause aux fêtes.
  ///
  /// In fr, this message translates to:
  /// **'Inclure les fêtes'**
  String get settingsShabbatIncludeHolidays;

  /// Écran Mode Shabbat : sous-titre de l'interrupteur des fêtes. Yom Tov désigne un jour de fête.
  ///
  /// In fr, this message translates to:
  /// **'Pause aussi pendant Yom Tov'**
  String get settingsShabbatIncludeHolidaysHint;

  /// Écran Mode Shabbat : curseur du délai de pause avant l'heure d'allumage des bougies.
  ///
  /// In fr, this message translates to:
  /// **'Marge avant l\'allumage'**
  String get settingsShabbatBuffer;

  /// Une durée courte en minutes, par exemple « 18 min ». Valeur du curseur de marge.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String settingsMinutesShort(int minutes);

  /// Lue par le lecteur d'écran pour le curseur de marge (phrase entière, pas d'abréviation).
  ///
  /// In fr, this message translates to:
  /// **'{minutes, plural, =0{0 minutes} one{{minutes} minute} other{{minutes} minutes}}'**
  String settingsMinutesSpoken(int minutes);

  /// Écran Mode Shabbat : bouton qui changera la ville. Environ 10 caractères.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get settingsShabbatEdit;

  /// Écran Mode Shabbat : paragraphe en bas de page qui explique ce que fait la pause. Le nom entre guillemets est celui du statut (comme « Mode Shabbat » des réglages).
  ///
  /// In fr, this message translates to:
  /// **'Les notifications sont mises en pause et les messages attendent. Vous recevrez tout après la fin de Shabbat, et votre statut affichera « Mode Shabbat ».'**
  String get settingsShabbatExplanation;

  /// Bandeau sombre du mode Shabbat : le grand titre sur deux lignes (« Shabbat shalom. »). Le retour à la ligne est voulu.
  ///
  /// In fr, this message translates to:
  /// **'Shabbat\nshalom.'**
  String get settingsShabbatHeroTitle;

  /// Bandeau sombre du mode Shabbat : phrase sous le titre. Mazl est le nom de l'app écrit ainsi, ne pas le traduire.
  ///
  /// In fr, this message translates to:
  /// **'Mazl se repose avec vous. Vos messages vous attendront à la havdala.'**
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

  /// Appel vidéo : texte sous le prénom pendant l'appel.
  ///
  /// In fr, this message translates to:
  /// **'Appel en cours...'**
  String get videoCallInProgress;

  /// Appel vidéo : bouton qui bascule entre caméra avant et arrière (12 px sous l'icône).
  ///
  /// In fr, this message translates to:
  /// **'Flip'**
  String get videoCallFlip;

  /// Appel vidéo : bouton qui coupe ou remet la caméra.
  ///
  /// In fr, this message translates to:
  /// **'Caméra'**
  String get videoCallCamera;

  /// Appel vidéo : bouton qui coupe ou remet le micro.
  ///
  /// In fr, this message translates to:
  /// **'Micro'**
  String get videoCallMic;

  /// Appel vidéo : bouton rouge qui raccroche.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get videoCallEnd;
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
