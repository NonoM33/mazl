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

  /// Phrase d'erreur : pas de connexion au serveur.
  ///
  /// In fr, this message translates to:
  /// **'Serveur injoignable. Réessayez.'**
  String get coupleFeedFailureNetwork;

  /// Phrase d'erreur : le serveur a répondu quelque chose d'inattendu.
  ///
  /// In fr, this message translates to:
  /// **'Réponse inattendue du serveur.'**
  String get coupleFeedFailureMalformed;

  /// Phrase d'erreur : le membre n'est pas en mode couple.
  ///
  /// In fr, this message translates to:
  /// **'Le mode couple n\'est pas actif.'**
  String get coupleFeedFailureNotInCouple;

  /// Phrase d'erreur : l'élément demandé n'existe pas.
  ///
  /// In fr, this message translates to:
  /// **'Introuvable.'**
  String get coupleFeedFailureNotFound;

  /// Phrase d'erreur : l'événement est complet.
  ///
  /// In fr, this message translates to:
  /// **'Cet événement est complet.'**
  String get coupleFeedFailureFull;

  /// Phrase d'erreur : le serveur a échoué.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur n\'a pas pu répondre. Réessayez.'**
  String get coupleFeedFailureServer;

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
