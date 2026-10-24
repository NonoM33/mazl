// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get errorTimeout => 'Timed out. Check your connection.';

  @override
  String get errorNetwork => 'No connection. Check your network and try again.';

  @override
  String get errorServer => 'The server is unavailable. Try again in a moment.';

  @override
  String get errorSessionExpired => 'Session expired. Please sign in again.';

  @override
  String get errorForbidden => 'You\'re not allowed to do this.';

  @override
  String get errorNotFound => 'Not found: this item no longer exists.';

  @override
  String get errorConflict => 'This action is no longer possible.';

  @override
  String get errorTooLarge => 'File too large.';

  @override
  String get errorRateLimited => 'Too many attempts. Please wait a moment.';

  @override
  String get errorInvalid => 'Request refused. Check what you entered.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonSee => 'View';

  @override
  String get commonShare => 'Share';

  @override
  String get commonReport => 'Report';

  @override
  String get commonOk => 'OK';

  @override
  String get commonLater => 'Later';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonNotSpecified => 'Not specified';

  @override
  String get commonLoadError => 'Couldn’t load';

  @override
  String get safetyBlock => 'Block';

  @override
  String get safetyBlockSubtitle =>
      'This person won\'t be able to see you or contact you';

  @override
  String get safetyReportSubtitle => 'Report inappropriate behavior';

  @override
  String get safetyBlockConfirmTitle => 'Block this person?';

  @override
  String safetyBlockConfirmIntro(String name) {
    return 'If you block $name:';
  }

  @override
  String get safetyBlockEffectHidden =>
      'This person won\'t be able to see your profile anymore';

  @override
  String get safetyBlockEffectNotSeen => 'You won\'t see their profile anymore';

  @override
  String get safetyBlockEffectChats => 'Your conversations will be deleted';

  @override
  String get safetyBlockEffectNotNotified => 'This person won\'t be notified';

  @override
  String safetyBlocked(String name) {
    return '$name has been blocked';
  }

  @override
  String get safetyBlockFailed => 'Something went wrong while blocking';

  @override
  String get safetyReportTitle => 'Report a problem';

  @override
  String safetyReportWhy(String name) {
    return 'Why are you reporting $name?';
  }

  @override
  String get safetyReportDetailsHint => 'More details (optional)';

  @override
  String get safetyReportAlsoBlock => 'Also block this person';

  @override
  String get safetyReportAlsoBlockHint => 'You won\'t see this profile anymore';

  @override
  String get safetyReportSend => 'Send report';

  @override
  String get safetyReportThanks =>
      'Thanks for your report. Our team will take a look.';

  @override
  String get safetyReportFailed =>
      'Something went wrong while sending the report';

  @override
  String get safetyCategoryFakeProfile => 'Fake profile';

  @override
  String get safetyCategoryFakeProfileHint => 'Stolen photos, false identity';

  @override
  String get safetyCategoryInappropriatePhotos => 'Inappropriate photos';

  @override
  String get safetyCategoryInappropriatePhotosHint =>
      'Sexual, violent or shocking content';

  @override
  String get safetyCategoryHarassment => 'Harassment';

  @override
  String get safetyCategoryHarassmentHint => 'Pushy messages, threats, insults';

  @override
  String get safetyCategorySpam => 'Spam / Scam';

  @override
  String get safetyCategorySpamHint =>
      'Ads, requests for money, suspicious links';

  @override
  String get safetyCategoryUnderage => 'Underage';

  @override
  String get safetyCategoryUnderageHint => 'This person seems to be under 18';

  @override
  String get safetyCategoryOfflineBehavior => 'Behavior outside the app';

  @override
  String get safetyCategoryOfflineBehaviorHint =>
      'Inappropriate behavior during a meeting';

  @override
  String get safetyCategoryOther => 'Other';

  @override
  String get safetyCategoryOtherHint => 'Another reason (please explain)';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Phone language';
}
