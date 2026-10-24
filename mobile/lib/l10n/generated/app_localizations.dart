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

  /// Message bref quand aimer un profil crée un match. {name} est le prénom.
  ///
  /// In fr, this message translates to:
  /// **'Match avec {name}'**
  String likesMatchWith(String name);

  /// Bouton du message bref « Match avec … » : ouvre la messagerie.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get likesMessageAction;

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

  /// Info-bulle du petit bouton rond de la carte qui annule le dernier balayage (fonction mazl+).
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get matchingDiscoverUndo;

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

  /// Titre de la barre d'en-tête de l'écran des visiteurs du profil.
  ///
  /// In fr, this message translates to:
  /// **'Qui a visité mon profil'**
  String get visitorsTitle;

  /// Grand chiffre de l'en-tête violet : le nombre total de visites. {count} est un entier.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} visite} other{{count} visites}}'**
  String visitorsTotal(int count);

  /// Sous le total des visites : combien datent des 7 derniers jours. {count} est un entier.
  ///
  /// In fr, this message translates to:
  /// **'{count} cette semaine'**
  String visitorsThisWeek(int count);

  /// Titre de la bannière qui propose mazl+ à un compte gratuit.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez qui vous a visité'**
  String get visitorsBannerTitle;

  /// Sous le titre de la bannière mazl+ : une ligne courte (12 px). « mazl+ » est un nom de marque.
  ///
  /// In fr, this message translates to:
  /// **'Passez à mazl+ pour voir les profils'**
  String get visitorsBannerBody;

  /// Titre de l'écran des visiteurs quand personne n'a encore visité le profil.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de visiteurs'**
  String get visitorsEmptyTitle;

  /// Texte sous le titre de l'écran des visiteurs vide : conseil pour attirer des visiteurs. « Boost » est le nom d'une fonction.
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre profil et utilisez un Boost pour attirer plus de visiteurs.'**
  String get visitorsEmptyBody;

  /// Bouton de l'écran des visiteurs vide : ouvre l'écran du Boost.
  ///
  /// In fr, this message translates to:
  /// **'Activer un Boost'**
  String get visitorsEmptyAction;

  /// Titre de la feuille qui s'ouvre quand un compte gratuit touche une visite verrouillée. « mazl+ » est un nom de marque.
  ///
  /// In fr, this message translates to:
  /// **'Réservé à mazl+'**
  String get visitorsLockedTitle;

  /// Texte de la feuille « Réservé à mazl+ ».
  ///
  /// In fr, this message translates to:
  /// **'Passez à mazl+ pour découvrir qui a visité votre profil et les contacter directement.'**
  String get visitorsLockedBody;

  /// Bouton principal de la feuille « Réservé à mazl+ » : ouvre l'abonnement.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir mazl+'**
  String get visitorsLockedAction;

  /// Pastille sur la photo d'une visite de moins de 24 heures. 10 px de haut, une seule ligne courte.
  ///
  /// In fr, this message translates to:
  /// **'NEW'**
  String get visitorsNew;

  /// Il y a moins d'une heure, sous le prénom d'un visiteur. {count} est un entier de minutes (« min » abrégé).
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} min'**
  String visitorsAgoMinutes(int count);

  /// Il y a moins d'un jour, sous le prénom d'un visiteur. {count} est un entier d'heures (« h » abrégé).
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count}h'**
  String visitorsAgoHours(int count);

  /// Il y a 2 à 6 jours, sous le prénom d'un visiteur. {count} est un entier de jours.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Il y a {count} jour} other{Il y a {count} jours}}'**
  String visitorsAgoDays(int count);

  /// Il y a une semaine ou plus, sous le prénom d'un visiteur. {count} est un entier de semaines (« sem. » abrégé).
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} sem.'**
  String visitorsAgoWeeks(int count);
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
