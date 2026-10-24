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
  String get likesTitle => 'Likes';

  @override
  String likesSection(String count) {
    return 'They liked you · $count';
  }

  @override
  String likesWaiting(int count, String label) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$label people are waiting for your reply.',
      one: '$label person is waiting for your reply.',
    );
    return '$_temp0';
  }

  @override
  String get likesSeeWhoWithPlus => 'See who liked you with mazl+';

  @override
  String likesMatchWith(String name) {
    return 'It\'s a match with $name';
  }

  @override
  String get likesMessageAction => 'Message';

  @override
  String likesYouLiked(String name) {
    return 'You liked $name';
  }

  @override
  String get likesEmptyTitle => 'No likes yet';

  @override
  String get likesEmptyBody =>
      'Keep discovering profiles and complete yours to get more likes.';

  @override
  String get likesEmptyAction => 'Discover profiles';

  @override
  String get likesPremiumBody =>
      'See who liked you and match right away with the people you like.';

  @override
  String get likesPremiumOffers => 'See plans';

  @override
  String likesCardOpen(String title) {
    return 'View $title\'s like';
  }

  @override
  String likesCardPass(String name) {
    return 'Pass on $name';
  }

  @override
  String likesCardLike(String name) {
    return 'Like $name';
  }

  @override
  String get likesLockedLabel => 'Hidden profile';

  @override
  String get likesLockedHint => 'Available with mazl+';

  @override
  String likesDistance(int km) {
    return '$km km';
  }

  @override
  String get matchingDiscoverDailyPicks => 'Daily picks';

  @override
  String get matchingFilters => 'Filters';

  @override
  String get matchingDiscoverEmptyTitle => 'You\'ve seen everyone.';

  @override
  String get matchingDiscoverEmptyBody =>
      'Come back later or widen your filters to see new profiles.';

  @override
  String get matchingDiscoverOpenFilters => 'Open filters';

  @override
  String get matchingDiscoverRefresh => 'Refresh';

  @override
  String get matchingDiscoverUndo => 'Undo';

  @override
  String get matchingDiscoverSuperLike => 'Super like';

  @override
  String get matchingDiscoverBoost => 'Boost';

  @override
  String matchingDiscoverBoostOn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return 'Boost is on. You\'re at the top of the stack for $_temp0.';
  }

  @override
  String get matchingDiscoverBoostFailed => 'Couldn\'t turn on Boost';

  @override
  String get matchingCardPass => 'Pass';

  @override
  String get matchingCardLike => 'Like';

  @override
  String get matchingCardViewProfile => 'View profile';

  @override
  String get matchingCardAnonymous => 'Anonymous';

  @override
  String matchingCardDistance(int km) {
    return '$km km away';
  }

  @override
  String get matchingCardVerified => 'Verified';

  @override
  String matchingAvatarNewMatch(String name) {
    return 'New match, $name';
  }

  @override
  String matchingAvatarMatch(String name) {
    return 'Match, $name';
  }

  @override
  String get matchingMatchTitle => 'It\'s a match!';

  @override
  String matchingMatchLineNamed(String name) {
    return 'You and $name liked each other.';
  }

  @override
  String get matchingMatchLineAnonymous => 'You liked each other.';

  @override
  String get matchingMatchSendMessage => 'Send a message';

  @override
  String get matchingMatchKeepDiscovering => 'Keep discovering';

  @override
  String matchingSeeMoreWithPlus(int count) {
    return 'See $count more with mazl+';
  }

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

  @override
  String get visitorsTitle => 'Who visited my profile';

  @override
  String visitorsTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visits',
      one: '$count visit',
    );
    return '$_temp0';
  }

  @override
  String visitorsThisWeek(int count) {
    return '$count this week';
  }

  @override
  String get visitorsBannerTitle => 'See who visited you';

  @override
  String get visitorsBannerBody => 'Upgrade to mazl+ to see the profiles';

  @override
  String get visitorsEmptyTitle => 'No visitors yet';

  @override
  String get visitorsEmptyBody =>
      'Complete your profile and use a Boost to attract more visitors.';

  @override
  String get visitorsEmptyAction => 'Turn on a Boost';

  @override
  String get visitorsLockedTitle => 'Only with mazl+';

  @override
  String get visitorsLockedBody =>
      'Upgrade to mazl+ to see who visited your profile and get in touch with them directly.';

  @override
  String get visitorsLockedAction => 'Discover mazl+';

  @override
  String get visitorsNew => 'NEW';

  @override
  String visitorsAgoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String visitorsAgoHours(int count) {
    return '${count}h ago';
  }

  @override
  String visitorsAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
    );
    return '$_temp0';
  }

  @override
  String visitorsAgoWeeks(int count) {
    return '$count wk ago';
  }
}
