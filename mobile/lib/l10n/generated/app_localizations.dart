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
