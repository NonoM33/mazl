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
