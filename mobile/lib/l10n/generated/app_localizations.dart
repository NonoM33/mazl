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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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
    Locale('ru')
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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr', 'he', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'he': return AppLocalizationsHe();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
