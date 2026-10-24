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
