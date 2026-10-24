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
  String get coupleFeedDashboardSettingsTooltip => 'Settings';

  @override
  String get coupleFeedDashboardMe => 'Me';

  @override
  String get coupleFeedDashboardPartnerFallback => 'Partner';

  @override
  String coupleFeedDashboardDaysTogether(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days together',
      one: '1 day together',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedDashboardDailyQuestion => 'Question of the day';

  @override
  String get coupleFeedDashboardAnswer => 'Answer';

  @override
  String get coupleFeedDashboardAnswerHint => 'Your answer…';

  @override
  String get coupleFeedDashboardSend => 'Send';

  @override
  String get coupleFeedDashboardAnswerSent =>
      'Answer sent. Your partner will be notified.';

  @override
  String get coupleFeedDashboardActivities => 'Activities for two';

  @override
  String get coupleFeedDashboardMilestones => 'Our milestones';

  @override
  String get coupleFeedDashboardSeeAll => 'See all';

  @override
  String get coupleFeedDashboardEvents => 'Events for couples';

  @override
  String get coupleFeedDashboardJewishCalendar => 'Jewish calendar';

  @override
  String get coupleFeedStoriesTitle => 'Couples\' stories';

  @override
  String get coupleFeedDashboardSeeAllStories => 'See all';

  @override
  String get coupleFeedDashboardEventSampleTitle => 'Kosher cooking class';

  @override
  String get coupleFeedDashboardEventSampleWhen =>
      'Sunday, January 20 - 3:00 PM';

  @override
  String get coupleFeedDashboardEventSampleTag => 'Couples';

  @override
  String get coupleFeedDashboardAllEvents => 'See all events';

  @override
  String get coupleFeedDashboardParasha => 'Shabbat Beshalach';

  @override
  String get coupleFeedDashboardShabbatTimes =>
      'Starts: 5:23 PM - Ends: 6:34 PM';

  @override
  String get coupleFeedDashboardShabbatDinner => 'Dinner';

  @override
  String get coupleFeedDashboardShabbatPrayer => 'Prayer';

  @override
  String get coupleFeedDashboardShabbatRest => 'Rest';

  @override
  String get coupleFeedStoryShareTitle => 'Share your story';

  @override
  String get coupleFeedDashboardShareStoryLine =>
      'Inspire the MAZL community with your story';

  @override
  String get coupleFeedDashboardSeeStories => 'See stories';

  @override
  String get coupleFeedMilestoneFirstWeekTitle => 'First week';

  @override
  String get coupleFeedMilestoneFirstWeekLine => '7 days together';

  @override
  String get coupleFeedMilestoneFirstMonthTitle => 'First month';

  @override
  String get coupleFeedMilestoneFirstMonthLine => '30 days of love';

  @override
  String get coupleFeedMilestoneThreeMonthsTitle => 'Three months';

  @override
  String get coupleFeedMilestoneThreeMonthsLine => '3 months of happiness';

  @override
  String get coupleFeedMilestoneSixMonthsTitle => 'Half a year';

  @override
  String get coupleFeedMilestoneSixMonthsLine => '6 months hand in hand';

  @override
  String get coupleFeedMilestoneFirstYearTitle => 'First year';

  @override
  String get coupleFeedMilestoneFirstYearLine => '365 days of MAZL';

  @override
  String get coupleFeedQuestion1 =>
      'What is your favorite moment of the week together?';

  @override
  String get coupleFeedQuestion1Category => 'Connection';

  @override
  String get coupleFeedQuestion2 =>
      'If you could travel anywhere, where would you go?';

  @override
  String get coupleFeedQuestion2Category => 'Dreams';

  @override
  String get coupleFeedQuestion3 => 'What made you smile today?';

  @override
  String get coupleFeedQuestion3Category => 'Everyday life';

  @override
  String get coupleFeedQuestion4 =>
      'How would you like to celebrate your next Shabbat?';

  @override
  String get coupleFeedQuestion4Category => 'Judaism';

  @override
  String get coupleFeedQuestion4Option1 => 'Romantic dinner at home';

  @override
  String get coupleFeedQuestion4Option2 => 'Invitation to friends\' home';

  @override
  String get coupleFeedQuestion4Option3 => 'Kosher restaurant';

  @override
  String get coupleFeedQuestion4Option4 => 'Community Shabbaton';

  @override
  String get coupleFeedQuestion5 =>
      'Which personality trait do you admire most in your partner?';

  @override
  String get coupleFeedQuestion5Category => 'Appreciation';

  @override
  String get coupleFeedIdeaShabbatCookingTitle => 'Shabbat cooking';

  @override
  String get coupleFeedIdeaShabbatCookingCategory => 'Home';

  @override
  String get coupleFeedIdeaTorahTitle => 'Torah study';

  @override
  String get coupleFeedIdeaDateNightTitle => 'Date night';

  @override
  String get coupleFeedIdeaDateNightCategory => 'Romance';

  @override
  String get coupleFeedIdeaSportTitle => 'Sports together';

  @override
  String get coupleFeedIdeaChesedTitle => 'Chesed together';

  @override
  String get coupleFeedIdeaChesedCategory => 'Community';

  @override
  String get coupleFeedIdeaTravelCategory => 'Adventure';

  @override
  String get coupleFeedCategoryWellness => 'Wellness';

  @override
  String get coupleFeedCategoryGastronomy => 'Gastronomy';

  @override
  String get coupleFeedFilterGastronomy => 'Food';

  @override
  String get coupleFeedCategoryCulture => 'Culture';

  @override
  String get coupleFeedCategorySport => 'Sports';

  @override
  String get coupleFeedCategoryTravel => 'Travel';

  @override
  String get coupleFeedCategorySpiritual => 'Spiritual';

  @override
  String get coupleFeedCategoryDiy => 'DIY';

  @override
  String get coupleFeedCategoryRomantic => 'Romantic';

  @override
  String get coupleFeedFilterAll => 'All';

  @override
  String get coupleFeedEventCategoryDinner => 'Dinner';

  @override
  String get coupleFeedEventCategoryTasting => 'Tasting';

  @override
  String get coupleFeedEventCategoryParty => 'Party';

  @override
  String get coupleFeedEventCategoryWorkshop => 'Workshop';

  @override
  String get coupleFeedEventCategoryBrunch => 'Brunch';

  @override
  String get coupleFeedEventCategorySpiritual => 'Spiritual';

  @override
  String get coupleFeedEventCategoryTravel => 'Weekend';

  @override
  String get coupleFeedEventCategoryConcert => 'Concert';

  @override
  String get coupleFeedEventCategoryGame => 'Games';

  @override
  String get coupleFeedEventCategoryOther => 'Event';

  @override
  String get coupleFeedPriceFree => 'Free';

  @override
  String coupleFeedEventPricePerCouple(String price) {
    return '$price per couple';
  }

  @override
  String coupleFeedDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String coupleFeedDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String coupleFeedDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String coupleFeedRatingWithReviews(String rating, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$rating ($countString reviews)',
      one: '$rating (1 review)',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedKosher => 'Kosher';

  @override
  String get coupleFeedFeatured => 'Featured';

  @override
  String get coupleFeedPartnerMazl => 'MAZL partner';

  @override
  String coupleFeedPartnerDiscountMazl(int percent) {
    return '$percent% off · MAZL partner';
  }

  @override
  String coupleFeedPartnerDiscount(int percent) {
    return '$percent% off · Partner';
  }

  @override
  String get coupleFeedActivitiesTitle => 'Activities';

  @override
  String get coupleFeedSavedTitle => 'Saved activities';

  @override
  String get coupleFeedActivitiesEmptyTitle => 'No activities right now';

  @override
  String get coupleFeedActivitiesEmptyLine => 'New ideas are coming soon.';

  @override
  String get coupleFeedRefresh => 'Refresh';

  @override
  String get coupleFeedSeeDetail => 'See details';

  @override
  String coupleFeedActivitySavedSnack(String title) {
    return '$title saved';
  }

  @override
  String coupleFeedActivitySaveCardError(String title) {
    return 'Couldn\'t save “$title”. Try again.';
  }

  @override
  String coupleFeedActivityPassCardError(String title) {
    return 'Couldn\'t skip “$title”. Try again.';
  }

  @override
  String get coupleFeedActivityNotFoundTitle => 'Activity not found';

  @override
  String get coupleFeedActivityNotFoundLine => 'It\'s no longer offered.';

  @override
  String get coupleFeedActivityRemoveError =>
      'Couldn\'t remove this activity. Try again.';

  @override
  String get coupleFeedActivitySaveError =>
      'Couldn\'t save this activity. Try again.';

  @override
  String get coupleFeedActivitySavedConfirm => 'Activity saved';

  @override
  String coupleFeedCodeCopied(String code) {
    return 'Code $code copied';
  }

  @override
  String get coupleFeedRemoveFromSaved => 'Remove from saved activities';

  @override
  String coupleFeedActivityShareText(String title) {
    return 'A date idea for us: \"$title\" (via MAZL)';
  }

  @override
  String get coupleFeedPromoCodeLabel => 'MAZL promo code';

  @override
  String get coupleFeedCopyCode => 'Copy code';

  @override
  String get coupleFeedDescription => 'Description';

  @override
  String get coupleFeedTags => 'Tags';

  @override
  String get coupleFeedAddress => 'Address';

  @override
  String get coupleFeedContact => 'Contact';

  @override
  String get coupleFeedCall => 'Call';

  @override
  String get coupleFeedWebsite => 'Website';

  @override
  String get coupleFeedFromPrice => 'From';

  @override
  String get coupleFeedBook => 'Book';

  @override
  String get coupleFeedSavedRemoveTitle => 'Remove from the list?';

  @override
  String coupleFeedSavedRemoveBody(String title) {
    return 'Do you want to remove \"$title\" from your saved activities?';
  }

  @override
  String get coupleFeedSavedRemoved => 'Activity removed';

  @override
  String coupleFeedSavedRemoveError(String title) {
    return 'Couldn\'t remove “$title”. Try again.';
  }

  @override
  String get coupleFeedSavedEmptyTitle => 'No saved activities';

  @override
  String get coupleFeedSavedEmptyLine => 'Swipe a card up to keep it.';

  @override
  String get coupleFeedSavedEmptyAction => 'Discover activities';

  @override
  String get coupleFeedEventsTitle => 'Events';

  @override
  String get coupleFeedEventsUpcoming => 'Upcoming';

  @override
  String coupleFeedEventsRegisteredTab(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Registered ($countString)';
  }

  @override
  String get coupleFeedEventsEmptyAll => 'No events available';

  @override
  String get coupleFeedEventsEmptyRegistered =>
      'You\'re not registered for any events';

  @override
  String get coupleFeedEventsDiscover => 'Discover events';

  @override
  String coupleFeedEventRegisteredSnack(String title) {
    return 'Registered for \"$title\"';
  }

  @override
  String coupleFeedEventRegisteredSnackDetail(String title) {
    return 'Registered for “$title”';
  }

  @override
  String get coupleFeedEventRegisterError => 'Couldn\'t register. Try again.';

  @override
  String get coupleFeedEventCancelError =>
      'Couldn\'t cancel your registration. Try again.';

  @override
  String get coupleFeedEventCancelTitle => 'Cancel your registration?';

  @override
  String coupleFeedEventCancelBody(String title) {
    return 'Do you really want to cancel your registration for \"$title\"?';
  }

  @override
  String get coupleFeedEventCancelNo => 'No';

  @override
  String get coupleFeedEventCancelYes => 'Yes, cancel';

  @override
  String get coupleFeedEventCancelled => 'Registration cancelled';

  @override
  String get coupleFeedEventFull => 'Full';

  @override
  String coupleFeedEventSpots(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString spots',
      one: '1 spot',
    );
    return '$_temp0';
  }

  @override
  String coupleFeedEventSpotsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString spots left',
      one: '1 spot left',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedEventRegister => 'Register';

  @override
  String get coupleFeedEventCancelMine => 'Cancel my registration';

  @override
  String get coupleFeedEventNotFoundTitle => 'Event not found';

  @override
  String get coupleFeedEventNotFoundLine => 'It\'s no longer offered.';

  @override
  String get coupleFeedEventFactPlace => 'Venue';

  @override
  String get coupleFeedEventFactDressCode => 'Dress code';

  @override
  String get coupleFeedEventFactOrganizer => 'Organized by';

  @override
  String get coupleFeedEventIncluded => 'What\'s included';

  @override
  String get coupleFeedLoadFailedTitle => 'Couldn\'t load';

  @override
  String get coupleFeedFailureNetwork => 'Can\'t reach the server. Try again.';

  @override
  String get coupleFeedFailureMalformed =>
      'Unexpected response from the server.';

  @override
  String get coupleFeedFailureNotInCouple => 'Couple mode isn\'t active.';

  @override
  String get coupleFeedFailureNotFound => 'Not found.';

  @override
  String get coupleFeedFailureFull => 'This event is full.';

  @override
  String get coupleFeedFailureServer =>
      'The server couldn\'t respond. Try again.';

  @override
  String get coupleFeedStoriesEmptyTitle => 'No couples\' stories yet';

  @override
  String get coupleFeedStoriesEmptyLine =>
      'The first MAZL love stories will be shared soon.';

  @override
  String coupleFeedStoryShareText(String name1, String name2, String excerpt) {
    return '$name1 and $name2 met on MAZL. Their story: $excerpt...';
  }

  @override
  String coupleFeedStoryStatusSince(String status, String date) {
    return '$status · since $date';
  }

  @override
  String get coupleFeedStatusDating => 'In a relationship';

  @override
  String get coupleFeedStatusEngaged => 'Engaged';

  @override
  String get coupleFeedStatusMarried => 'Married';

  @override
  String get coupleFeedStoryShareLine =>
      'Inspire the MAZL community by sharing your story.';

  @override
  String get coupleFeedStoryStatusLabel => 'Your status';

  @override
  String get coupleFeedStoryTextLabel => 'Your story (min. 100 characters)';

  @override
  String get coupleFeedStoryTextHint =>
      'How did you meet? What did you like about each other?…';

  @override
  String get coupleFeedStoryPhotosLabel => 'Photos (optional)';

  @override
  String get coupleFeedStoryPhotosHint => 'Add photos of the two of you';

  @override
  String get coupleFeedStorySubmit => 'Submit our story';

  @override
  String get coupleFeedStoryTooShort =>
      'Your story must be at least 100 characters long';

  @override
  String get coupleFeedStoryThanks =>
      'Thank you. Your story will be published after review.';

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
