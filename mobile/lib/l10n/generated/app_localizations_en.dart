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
  String get eventsTitle => 'Events';

  @override
  String get eventsCalendarTooltip => 'Calendar';

  @override
  String get eventsFilterAll => 'All';

  @override
  String get eventsFilterHolidays => 'Holidays';

  @override
  String get eventsTypeShabbat => 'Shabbat';

  @override
  String get eventsTypeShabbatDinner => 'Shabbat dinner';

  @override
  String get eventsTypeSpeedDating => 'Speed dating';

  @override
  String get eventsTypeHoliday => 'Holiday';

  @override
  String get eventsTypeLecture => 'Class';

  @override
  String get eventsTypeSocial => 'Social';

  @override
  String get eventsTypeOther => 'Event';

  @override
  String get eventsLoading => 'Loading...';

  @override
  String get eventsLoadError => 'Couldn\'t load events';

  @override
  String get eventsEmptyTitle => 'No events';

  @override
  String get eventsEmptyHint => 'Come back soon to discover\nnew events.';

  @override
  String get eventsTomorrow => 'Tomorrow';

  @override
  String eventsInDays(int days) {
    return 'In ${days}d';
  }

  @override
  String eventsDateAtTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get eventsFree => 'Free';

  @override
  String eventsAttendeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants',
      one: '1 participant',
    );
    return '$_temp0';
  }

  @override
  String get eventsAlmostFull => 'Almost full';

  @override
  String get eventsFull => 'Full';

  @override
  String get eventsNotFound => 'Event not found';

  @override
  String get eventsInfoDate => 'Date';

  @override
  String get eventsInfoTime => 'Time';

  @override
  String get eventsInfoPlace => 'Place';

  @override
  String get eventsInfoParticipants => 'Participants';

  @override
  String get eventsInfoPrice => 'Price';

  @override
  String get eventsDescription => 'Description';

  @override
  String eventsCapacity(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$count / $max spots',
      one: '$count / $max spot',
    );
    return '$_temp0';
  }

  @override
  String eventsRegisteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people registered',
      one: '1 person registered',
    );
    return '$_temp0';
  }

  @override
  String eventsPricePerPerson(String price) {
    return '$price per person';
  }

  @override
  String get eventsRsvpConfirmedBanner => 'You\'re registered for this event';

  @override
  String get eventsRsvpCancel => 'Cancel my registration';

  @override
  String eventsRsvpJoinPaid(String price) {
    return 'Register - $price';
  }

  @override
  String get eventsRsvpJoinFree => 'Register for free';

  @override
  String get eventsRsvpCancelled => 'Registration cancelled';

  @override
  String get eventsRsvpDone => 'Registration confirmed';

  @override
  String eventsShareMessage(String title) {
    return 'Join me at \"$title\" on MAZL';
  }

  @override
  String get navigationDiscover => 'Discover';

  @override
  String get navigationMatches => 'Matches';

  @override
  String get navigationMessages => 'Messages';

  @override
  String get navigationEvents => 'Events';

  @override
  String get navigationProfile => 'Profile';

  @override
  String get navigationShowTabs => 'Show tabs';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Phone language';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsEditProfile => 'Edit profile';

  @override
  String get settingsEmail => 'Email';

  @override
  String get settingsNotSignedIn => 'Not signed in';

  @override
  String get settingsDefaultUserName => 'User';

  @override
  String get settingsSectionDiscovery => 'Discovery';

  @override
  String get settingsLocation => 'Location';

  @override
  String get settingsLocationNotSet => 'Not set';

  @override
  String get settingsMaxDistance => 'Maximum distance';

  @override
  String settingsDistanceKm(int distance) {
    final intl.NumberFormat distanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String distanceString = distanceNumberFormat.format(distance);

    return '$distanceString km';
  }

  @override
  String get settingsAgeRange => 'Age range';

  @override
  String settingsAgeRangeValue(int min, int max) {
    final intl.NumberFormat minNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String minString = minNumberFormat.format(min);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$minString - $maxString years';
  }

  @override
  String get settingsSectionJewish => 'Jewish settings';

  @override
  String get settingsShabbatMode => 'Shabbat mode';

  @override
  String get settingsShabbatAutoPause => 'Automatic pause';

  @override
  String get settingsHolidayAlerts => 'Holiday alerts';

  @override
  String get settingsHolidayAlertsHint => 'Notifications ahead of holidays';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsNotifMatches => 'New matches';

  @override
  String get settingsNotifMessages => 'Messages';

  @override
  String get settingsNotifSuperLikes => 'Super Likes';

  @override
  String get settingsSectionCouple => 'Couple mode';

  @override
  String get settingsSectionSubscription => 'Subscription';

  @override
  String get settingsRestorePurchases => 'Restore purchases';

  @override
  String get settingsRestoreSuccess => 'Purchases restored.';

  @override
  String get settingsRestoreError =>
      'Purchases could not be restored. Try again.';

  @override
  String settingsSubscriptionRenewsOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'renews on $dateString';
  }

  @override
  String settingsSubscriptionEndsOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'until $dateString';
  }

  @override
  String get settingsSectionPrivacy => 'Privacy and safety';

  @override
  String get settingsBlockedUsers => 'Blocked users';

  @override
  String get settingsBlockedUsersHint => 'Manage blocked people';

  @override
  String get settingsProfileVerification => 'Profile verification';

  @override
  String get settingsVerified => 'Verified';

  @override
  String get settingsNotVerified => 'Not verified';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsHelp => 'Help and support';

  @override
  String get settingsTerms => 'Terms of use';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLogOut => 'Log out';

  @override
  String get settingsLogOutMessage => 'Do you really want to log out?';

  @override
  String get settingsDeleteAccount => 'Delete my account';

  @override
  String get settingsDeleteReasonPrompt => 'Why do you want to leave us?';

  @override
  String get settingsDeleteReasonFoundSomeone => 'I found someone';

  @override
  String get settingsDeleteReasonNoLongerUsing => 'I no longer use the app';

  @override
  String get settingsDeleteReasonBreak => 'I want to take a break';

  @override
  String get settingsDeleteReasonTechnical => 'Technical problems';

  @override
  String get settingsDeleteReasonService => 'The service isn\'t right for me';

  @override
  String get settingsDeleteReasonOther => 'Other reason';

  @override
  String get settingsDeleteFinalTitle => 'Final confirmation';

  @override
  String get settingsDeleteIrreversible => 'This action cannot be undone.';

  @override
  String get settingsDeleteDataList =>
      'All your data will be deleted:\n• Your profile and photos\n• Your matches and conversations\n• Your like history\n• Your settings';

  @override
  String get settingsDeleteKeep => 'Keep my account';

  @override
  String get settingsDeleteError => 'Couldn\'t delete the account';

  @override
  String get settingsCitySearchHint => 'Search for a city...';

  @override
  String get settingsCitySearchHelp =>
      'Type your city name and pick a suggestion';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsCoupleLeave => 'Leave couple mode';

  @override
  String get settingsCoupleLeaveMessage =>
      'You can turn it back on later if you wish.';

  @override
  String get settingsCoupleLeaveConfirm => 'Leave';

  @override
  String get settingsCoupleLeft => 'Couple mode left';

  @override
  String get settingsCoupleLeaveError =>
      'Couldn\'t leave couple mode. Try again.';

  @override
  String get settingsCoupleCancelRequestError =>
      'Couldn\'t cancel the request. Try again.';

  @override
  String get settingsCoupleActive => 'Couple mode on';

  @override
  String settingsCoupleWithPartner(String name) {
    return 'With $name';
  }

  @override
  String get settingsCoupleWithYourPartner => 'With your partner';

  @override
  String get settingsCoupleOpenSpace => 'Couple space';

  @override
  String get settingsCoupleOpenCalendar => 'Calendar';

  @override
  String get settingsCoupleSinceToday => 'Since today';

  @override
  String settingsCoupleDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get settingsCoupleRequestSent => 'Request sent';

  @override
  String settingsCoupleRequestSentTo(String name) {
    return 'Request sent to $name';
  }

  @override
  String get settingsCoupleWaiting => 'Waiting for their answer';

  @override
  String get settingsCoupleCancelRequest => 'Cancel request';

  @override
  String get settingsCoupleInvitation => 'Found love?';

  @override
  String get settingsCoupleActivate => 'Turn on';

  @override
  String get settingsShabbatCity => 'Based on Paris, France';

  @override
  String get settingsShabbatSettingsHeader => 'Settings';

  @override
  String get settingsShabbatEnable => 'Turn on Shabbat mode';

  @override
  String get settingsShabbatEnableHint =>
      'Notifications pause automatically during Shabbat';

  @override
  String get settingsShabbatIncludeHolidays => 'Include holidays';

  @override
  String get settingsShabbatIncludeHolidaysHint => 'Also pause during Yom Tov';

  @override
  String get settingsShabbatBuffer => 'Margin before candle lighting';

  @override
  String settingsMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String settingsMinutesSpoken(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get settingsShabbatEdit => 'Edit';

  @override
  String get settingsShabbatExplanation =>
      'Notifications are paused and messages wait for you. You\'ll get everything after Shabbat ends, and your status will show “Shabbat mode”.';

  @override
  String get settingsShabbatHeroTitle => 'Shabbat\nshalom.';

  @override
  String get settingsShabbatHeroSubtitle =>
      'Mazl is resting with you. Your messages will wait for you at Havdalah.';

  @override
  String get settingsShabbatCandleLighting => 'Candle lighting';

  @override
  String get settingsShabbatHavdalah => 'Havdalah';

  @override
  String get settingsBlockedUserFallbackName => 'User';

  @override
  String get settingsBlockedUnblockTitle => 'Unblock this user?';

  @override
  String settingsBlockedUnblockMessage(String name) {
    return 'Do you want to unblock $name?\n\nThis person will be able to see your profile and contact you again.';
  }

  @override
  String get settingsBlockedUnblockMessageUnnamed =>
      'Do you want to unblock this user?\n\nThis person will be able to see your profile and contact you again.';

  @override
  String get settingsBlockedUnblock => 'Unblock';

  @override
  String settingsBlockedUnblocked(String name) {
    return '$name was unblocked';
  }

  @override
  String get settingsBlockedUnblockedUnnamed => 'The user was unblocked';

  @override
  String get settingsBlockedUnblockError => 'Couldn\'t unblock this user';

  @override
  String get settingsBlockedEmptyTitle => 'No blocked users';

  @override
  String get settingsBlockedEmptyHint => 'People you block\nwill appear here';

  @override
  String settingsBlockedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Blocked on $dateString';
  }
}
