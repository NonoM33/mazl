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
