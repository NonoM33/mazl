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
