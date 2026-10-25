// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get authLoginEyebrow => 'Dating · Jewish community';

  @override
  String get authLoginTagline =>
      'Serious dating between people who share your values.';

  @override
  String get authLoginApple => 'Continue with Apple';

  @override
  String get authLoginGoogle => 'Continue with Google';

  @override
  String get authLoginDev => 'Fake sign-in (dev)';

  @override
  String authLegal(String terms, String privacy) {
    return 'By continuing, you agree to the $terms and the $privacy.';
  }

  @override
  String get authLegalTermsLink => 'Terms';

  @override
  String get authLegalPrivacyLink => 'Privacy Policy';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get authErrorCancelled => 'Sign-in cancelled.';

  @override
  String get authErrorUnsupported =>
      'This sign-in method isn\'t available on this device.';

  @override
  String authErrorAccountDisabled(String contact) {
    return 'Your account is disabled. Write to us at $contact.';
  }

  @override
  String get authRouteErrorTitle => 'Page not found';

  @override
  String get authRouteErrorBody => 'Something went wrong';

  @override
  String get authRouteErrorHome => 'Back to home';

  @override
  String get boostTitle => 'Boost';

  @override
  String get boostHeadlineActive => 'Boost is on';

  @override
  String get boostHeadlineIdle => 'Boost your profile';

  @override
  String get boostTagline => 'Get seen by 10x more people.';

  @override
  String boostMinutesLeft(int minutes) {
    return '$minutes min left';
  }

  @override
  String get boostDuringTitle => 'During this Boost';

  @override
  String get boostViews => 'Views';

  @override
  String get boostLikes => 'Likes';

  @override
  String get boostBenefitsTitle => 'What Boost gives you';

  @override
  String get boostBenefitFirst => 'Show up first in suggestions';

  @override
  String boostBenefitVisibility(int minutes) {
    return '10x more visibility for $minutes min';
  }

  @override
  String get boostBenefitMatches => 'More chances to match';

  @override
  String get boostBenefitStats => 'Live stats while Boost is on';

  @override
  String get boostActivate => 'Turn on Boost';

  @override
  String boostRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Boosts left',
      one: '$count Boost left',
    );
    return '$_temp0';
  }

  @override
  String get boostActivated =>
      'Boost is on. Your profile is now front and center.';

  @override
  String get boostActivateFailed =>
      'Something went wrong while turning on Boost';

  @override
  String get boostUpsellTitle => 'Unlimited Boosts';

  @override
  String get boostUpsellBody => 'Boost as much as you like with mazl+';

  @override
  String get chatListTitle => 'Messages';

  @override
  String get chatListSearchHint => 'Search';

  @override
  String get chatListLoadErrorTitle => 'Can\'t load your messages';

  @override
  String get chatListLoadErrorBody => 'Check your connection, then try again.';

  @override
  String get chatListEmptyTitle => 'No conversations yet';

  @override
  String get chatListEmptyBody =>
      'Your conversations will appear here as soon as you get your first match.';

  @override
  String get chatListEmptyAction => 'Discover';

  @override
  String chatListNoResults(String query) {
    return 'No results for “$query”.';
  }

  @override
  String get chatListUnknownMember => 'User';

  @override
  String get chatNewMatch => 'New match';

  @override
  String chatListUnreadLabel(String name) {
    return '$name, unread message';
  }

  @override
  String get chatPhotoLabel => 'Photo';

  @override
  String get chatVoiceLabel => 'Voice message';

  @override
  String get chatRemovedLabel => 'Message removed';

  @override
  String get chatOtherFallbackName => 'Your match';

  @override
  String get chatAuthorYou => 'You';

  @override
  String get chatHeaderLoading => 'Loading…';

  @override
  String get chatHeaderTyping => 'typing…';

  @override
  String get chatHeaderOptions => 'Options';

  @override
  String get chatOptionsViewProfile => 'View profile';

  @override
  String get chatOptionsMute => 'Mute notifications';

  @override
  String get chatOptionsBlock => 'Block';

  @override
  String get chatMutedConfirmation =>
      'Notifications muted for this conversation';

  @override
  String get chatBlockFallbackName => 'This user';

  @override
  String get chatLoading => 'Loading the conversation';

  @override
  String get chatEmptyTitle => 'Say hello.';

  @override
  String get chatEmptyBody => 'Send the first message to break the ice.';

  @override
  String chatMatchStart(String date) {
    return 'Match · $date';
  }

  @override
  String chatNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new messages',
      one: '1 new message',
    );
    return '$_temp0';
  }

  @override
  String get chatTypingSemantics => 'Your match is typing';

  @override
  String chatSeenAt(String time) {
    return 'Seen at $time';
  }

  @override
  String get chatFailedRetry => 'Failed · Try again';

  @override
  String get chatMenuReply => 'Reply';

  @override
  String get chatMenuCopy => 'Copy';

  @override
  String get chatMenuUnsend => 'Unsend';

  @override
  String get chatMenuClose => 'Close menu';

  @override
  String get chatCopied => 'Message copied';

  @override
  String get chatReportThanks => 'Thanks, we\'re reviewing this message.';

  @override
  String get chatReactionsTitle => 'Reactions';

  @override
  String get chatReportTitle => 'Report this message';

  @override
  String get chatReportReasonScam => 'Scam or request for money';

  @override
  String get chatReportReasonHarassment =>
      'Harassment or inappropriate remarks';

  @override
  String get chatReportReasonInappropriate => 'Inappropriate content';

  @override
  String get chatReportReasonOther => 'Other';

  @override
  String get chatScamAdviceTitle => 'Protect yourself from scams';

  @override
  String get chatScamAdviceMoney =>
      'Never send money, gift cards or cryptocurrency.';

  @override
  String get chatScamAdviceApps =>
      'Be wary of anyone who quickly asks to move to WhatsApp, Telegram or Signal.';

  @override
  String get chatScamAdviceVideo =>
      'Have a video call before getting involved.';

  @override
  String get chatScamAdviceReport =>
      'If in doubt, report the conversation: we review it.';

  @override
  String get chatScamTitle => 'Stay cautious';

  @override
  String get chatScamBody =>
      'Never transfer money to someone you haven\'t met.';

  @override
  String get chatScamLearnMore => 'Learn more';

  @override
  String get chatPhotoReveal => 'View photo';

  @override
  String get chatVoicePlayFailed => 'Can\'t play this message';

  @override
  String get chatVoicePlay => 'Play voice message';

  @override
  String get chatVoicePause => 'Pause';

  @override
  String get chatComposerHint => 'Message';

  @override
  String get chatComposerAttach => 'Attach photos';

  @override
  String get chatComposerSend => 'Send';

  @override
  String get chatComposerSendVoice => 'Send voice message';

  @override
  String get chatComposerPhotoError =>
      'Couldn\'t add the photo. Check the permissions.';

  @override
  String get chatComposerMicDenied =>
      'Allow microphone access in Settings to send a voice message.';

  @override
  String get chatComposerRecordError => 'Can\'t record right now. Try again.';

  @override
  String get chatComposerHoldLonger => 'Hold the microphone longer to record.';

  @override
  String get chatComposerHoldHint =>
      'Hold the microphone to record a voice message.';

  @override
  String get chatMicSemantics => 'Hold to record a voice message';

  @override
  String get chatAttachPhotos => 'Photos';

  @override
  String get chatAttachPhotosLimit => 'Up to 10 at a time';

  @override
  String get chatAttachCamera => 'Camera';

  @override
  String get chatRecordingCancel => 'Cancel recording';

  @override
  String get chatRecordingRelease => 'Release to cancel';

  @override
  String get chatRecordingSlide => '‹ Slide to cancel';

  @override
  String get chatReplyCancel => 'Cancel reply';

  @override
  String chatReplyToOther(String name) {
    return 'Reply to $name';
  }

  @override
  String get chatReplyToMine => 'Reply to your message';

  @override
  String get chatErrorSessionExpired =>
      'Session expired, please sign in again.';

  @override
  String get chatErrorCannotUnsend => 'This message can no longer be unsent.';

  @override
  String get chatErrorConversationGone =>
      'This conversation is no longer available.';

  @override
  String get chatErrorBlocked =>
      'You can no longer write in this conversation.';

  @override
  String get chatErrorTooLarge => 'File too large.';

  @override
  String get chatErrorRateLimited => 'Too many messages, please wait a moment.';

  @override
  String get chatErrorServer => 'The server is unavailable, try again.';

  @override
  String get chatErrorFileRejected => 'File rejected, try another one.';

  @override
  String get chatErrorMessageRejected => 'Message rejected.';

  @override
  String get chatErrorTimeout => 'Timed out, check your connection.';

  @override
  String get chatErrorNetwork => 'No internet connection.';

  @override
  String get chatErrorUnknown => 'Something went wrong.';

  @override
  String get chatErrorTooManyPhotos => 'Ten photos at most per message.';

  @override
  String get chatErrorNotYetSent => 'This message hasn\'t been sent yet.';

  @override
  String get chatErrorMessageGone => 'This message no longer exists.';

  @override
  String get chatErrorNotAuthor => 'Only the author can unsend a message.';

  @override
  String get chatErrorReactionUnavailable => 'Reaction unavailable.';

  @override
  String get chatErrorSendUnavailable => 'Can\'t send right now.';

  @override
  String get chatErrorLoadFailed => 'Couldn\'t load the conversation.';

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
  String linkOpenError(String target) {
    return 'Couldn\'t open $target right now.';
  }

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
  String get coupleSpaceTabActivities => 'Activities';

  @override
  String get coupleSpaceTabCalendar => 'Calendar';

  @override
  String get coupleSpaceTabEvents => 'Events';

  @override
  String get coupleSpaceTabSpace => 'Our space';

  @override
  String get coupleSpaceTitle => 'Our space';

  @override
  String get coupleSpaceSettingsTooltip => 'Settings';

  @override
  String get coupleSpaceYou => 'You';

  @override
  String get coupleSpacePartnerFallback => 'Your other half';

  @override
  String coupleSpaceTogetherSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return 'Together for $_temp0';
  }

  @override
  String get coupleSpaceStoryBegins => 'Your story begins';

  @override
  String get coupleSpaceStatSavedActivities => 'Saved\nactivities';

  @override
  String get coupleSpaceStatUpcomingEvents => 'Upcoming\nevents';

  @override
  String get coupleSpaceStatMemories => 'Memories\ncreated';

  @override
  String get coupleSpaceQuickActions => 'Quick actions';

  @override
  String get coupleSpaceQuickAddMemory => 'Add a\nmemory';

  @override
  String get coupleSpaceQuickAddBucket => 'Add to the\nbucket list';

  @override
  String get coupleSpaceQuickAddDate => 'Add a\ndate';

  @override
  String get coupleSpaceMemoriesTitle => 'Our memories';

  @override
  String get coupleSpaceMemoriesEmptyTitle => 'No memories yet';

  @override
  String get coupleSpaceMemoriesEmptyHint =>
      'Add your first memories together.';

  @override
  String get coupleSpaceBucketTitle => 'Bucket list';

  @override
  String coupleSpaceBucketProgress(int done, int total) {
    return 'Bucket list · $done/$total';
  }

  @override
  String get coupleSpaceBucketEmptyTitle => 'Your bucket list is empty';

  @override
  String get coupleSpaceBucketEmptyHint => 'Add experiences to live together.';

  @override
  String get coupleSpaceDatesTitle => 'Important dates';

  @override
  String get coupleSpaceSeeAll => 'See all';

  @override
  String get coupleSpaceDatesEmptyTitle => 'No important dates';

  @override
  String get coupleSpaceDatesEmptyHint =>
      'Add your anniversaries, holidays and more.';

  @override
  String get coupleSpaceBadgesTitle => 'Our badges';

  @override
  String get coupleSpaceBadgesEmptyTitle => 'No badges yet';

  @override
  String get coupleSpaceBadgesEmptyHint =>
      'Do activities together to unlock badges.';

  @override
  String get coupleSpaceGoalDone => 'Goal achieved';

  @override
  String get coupleSpaceGoalFailed =>
      'Couldn\'t mark this goal as done. Please try again.';

  @override
  String coupleSpaceRefreshFailed(String reason) {
    return 'Couldn\'t refresh. $reason';
  }

  @override
  String get coupleSpaceLoadFailedTitle => 'Couldn\'t load';

  @override
  String get coupleSpaceSheetAdd => 'Add';

  @override
  String get coupleSpaceAddMemoryTitle => 'Add a memory';

  @override
  String get coupleSpaceFieldTitle => 'Title';

  @override
  String get coupleSpaceFieldDescription => 'Description';

  @override
  String get coupleSpaceAddBucketTitle => 'Add to the bucket list';

  @override
  String get coupleSpaceBucketFieldLabel => 'What do you want to do together?';

  @override
  String get coupleSpaceBucketFieldHint => 'e.g. See the northern lights';

  @override
  String get coupleSpaceAddDateTitle => 'Add an important date';

  @override
  String get coupleSpaceDateFieldHint => 'e.g. Our anniversary';

  @override
  String get coupleSpaceFieldDate => 'Date';

  @override
  String coupleSpaceAddFailed(String reason) {
    return 'Couldn\'t add it. $reason';
  }

  @override
  String get coupleSpaceSetupTitle => 'Couple mode';

  @override
  String get coupleSpaceSetupWho => 'Who with?';

  @override
  String get coupleSpaceSetupSend => 'Send request';

  @override
  String get coupleSpaceSetupNoMatches => 'No matches yet.';

  @override
  String get coupleSpaceSetupMatchesError => 'Couldn\'t load your matches.';

  @override
  String get coupleSpaceSetupSentTitle => 'Request sent';

  @override
  String coupleSpaceSetupSentBody(String name) {
    return '$name needs to accept. We\'ll let you know as soon as they answer.';
  }

  @override
  String get coupleSpaceSetupSentBodyAnonymous =>
      'This person needs to accept. We\'ll let you know as soon as they answer.';

  @override
  String get coupleSpaceSetupGotIt => 'Got it';

  @override
  String get coupleSpaceSetupCancelRequest => 'Cancel request';

  @override
  String get coupleSpaceMazelTovTitle => 'Mazel tov';

  @override
  String coupleSpaceMazelTovCongrats(String name) {
    return 'Congratulations to you and $name';
  }

  @override
  String get coupleSpaceMazelTovWelcome =>
      'MAZL is with you on this new chapter.';

  @override
  String get coupleSpaceMazelTovStart => 'Start our adventure';

  @override
  String coupleSpaceRequestTitle(String name) {
    return '$name would like to turn on couple mode with you';
  }

  @override
  String get coupleSpaceRequestTitleAnonymous =>
      'This person would like to turn on couple mode with you';

  @override
  String get coupleSpaceRequestAccept => 'Accept';

  @override
  String get coupleSpaceRequestDecline => 'No, thanks';

  @override
  String coupleSpaceFlowDeclinedNamed(String name) {
    return '$name didn\'t follow up on your request.';
  }

  @override
  String get coupleSpaceFlowDeclined => 'Your request didn\'t go through.';

  @override
  String get coupleSpaceFlowEnded => 'Couple mode has ended.';

  @override
  String get coupleSpaceArchiveMessage =>
      'I found love on Mazl. I\'m no longer available. Good luck with your search.';

  @override
  String get coupleSpaceFailNotMatched =>
      'Couple mode can only be turned on with a match.';

  @override
  String get coupleSpaceFailAlreadyInCouple =>
      'One of you is already in couple mode.';

  @override
  String get coupleSpaceFailRequestPending =>
      'A request is already pending with this person.';

  @override
  String get coupleSpaceFailRequestGone => 'This request is no longer pending.';

  @override
  String get coupleSpaceFailUnavailable => 'This person isn\'t available.';

  @override
  String get coupleSpaceFailSelf => 'You can\'t send a request to yourself.';

  @override
  String get coupleSpaceFailNotInCouple => 'Couple mode isn\'t active.';

  @override
  String get coupleSpaceFailCannotLeave =>
      'Couple mode can\'t be left right now.';

  @override
  String get coupleSpaceFailUnknown =>
      'Something went wrong. Please try again in a moment.';

  @override
  String get coupleSpaceFailEventFull => 'This event is full.';

  @override
  String get coupleSpaceFailServer =>
      'The server couldn\'t answer. Please try again.';

  @override
  String get coupleSpaceFailUnexpected =>
      'Unexpected response from the server.';

  @override
  String get coupleSpaceCalendarTitle => 'Calendar';

  @override
  String get coupleSpaceCalendarShabbatIdeas => 'Ideas for this Shabbat';

  @override
  String get coupleSpaceCalendarUpcoming => 'Upcoming holidays';

  @override
  String get coupleSpaceCalendarPrevMonth => 'Previous month';

  @override
  String get coupleSpaceCalendarNextMonth => 'Next month';

  @override
  String get coupleSpaceCalendarOngoing => 'Ongoing';

  @override
  String coupleSpaceCalendarCountdown(int count) {
    return 'In ${count}d';
  }

  @override
  String get coupleSpaceCalendarIdeas => 'Couple ideas';

  @override
  String coupleSpaceCalendarRangeSameMonth(
    String startDay,
    String endDay,
    String month,
  ) {
    return '$month $startDay – $endDay';
  }

  @override
  String coupleSpaceCalendarRangeOtherMonth(String start, String end) {
    return '$start – $end';
  }

  @override
  String get eventsTitle => 'Events';

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
  String get genreLookingForRequired => 'Select who you are looking for';

  @override
  String get jewishCalendarShabbatTitle => 'This Shabbat';

  @override
  String jewishCalendarParashat(String name) {
    return 'Parashat $name';
  }

  @override
  String jewishCalendarParshaPair(String first, String second) {
    return '$first – $second';
  }

  @override
  String get jewishCalendarCandleLighting => 'Candle lighting';

  @override
  String get jewishCalendarHavdalah => 'Havdalah';

  @override
  String get jewishCalendarCategoryPreparation => 'Preparation';

  @override
  String get jewishCalendarCategorySpiritual => 'Spiritual';

  @override
  String get jewishCalendarCategoryRelaxation => 'Relaxation';

  @override
  String get jewishCalendarActivityShabbatDinnerTitle =>
      'Prepare dinner together';

  @override
  String get jewishCalendarActivityShabbatDinnerBody =>
      'Make the challah and the festive meal';

  @override
  String get jewishCalendarActivityShabbatCandlesTitle => 'Light the candles';

  @override
  String get jewishCalendarActivityShabbatCandlesBody =>
      'A shared moment of spirituality';

  @override
  String get jewishCalendarActivityShabbatWalkTitle => 'Shabbat walk';

  @override
  String get jewishCalendarActivityShabbatWalkBody =>
      'A quiet stroll after the meal';

  @override
  String get jewishCalendarActivityShabbatParashaTitle => 'Study the parasha';

  @override
  String get jewishCalendarActivityShabbatParashaBody =>
      'Learn the weekly portion together';

  @override
  String get jewishCalendarActivityPesachSederTitle => 'Prepare the Seder';

  @override
  String get jewishCalendarActivityPesachSederBody => 'Set the table together';

  @override
  String get jewishCalendarActivityPesachCleaningTitle =>
      'Do the Passover cleaning';

  @override
  String get jewishCalendarActivityPesachCleaningBody =>
      'Spring cleaning as a team';

  @override
  String get jewishCalendarHolidayRoshHashanaName => 'Rosh Hashanah';

  @override
  String get jewishCalendarHolidayRoshHashanaDescription => 'Jewish New Year';

  @override
  String get jewishCalendarHolidayYomKippurName => 'Yom Kippur';

  @override
  String get jewishCalendarHolidayYomKippurDescription => 'Day of Atonement';

  @override
  String get jewishCalendarHolidaySukkotName => 'Sukkot';

  @override
  String get jewishCalendarHolidaySukkotDescription => 'Festival of Booths';

  @override
  String get jewishCalendarHolidaySheminiAtzeretName => 'Shemini Atzeret';

  @override
  String get jewishCalendarHolidaySheminiAtzeretDescription =>
      'Eighth day of assembly';

  @override
  String get jewishCalendarHolidaySimchatTorahName => 'Simchat Torah';

  @override
  String get jewishCalendarHolidaySimchatTorahDescription =>
      'Rejoicing in the Torah';

  @override
  String get jewishCalendarHolidayHanukkahName => 'Hanukkah';

  @override
  String get jewishCalendarHolidayHanukkahDescription => 'Festival of Lights';

  @override
  String get jewishCalendarHolidayTuBishvatName => 'Tu BiShvat';

  @override
  String get jewishCalendarHolidayTuBishvatDescription =>
      'New Year of the Trees';

  @override
  String get jewishCalendarHolidayPurimName => 'Purim';

  @override
  String get jewishCalendarHolidayPurimDescription => 'Festival of Lots';

  @override
  String get jewishCalendarHolidayPesachName => 'Passover';

  @override
  String get jewishCalendarHolidayPesachDescription => 'Festival of Freedom';

  @override
  String get jewishCalendarHolidayYomHashoahName => 'Yom HaShoah';

  @override
  String get jewishCalendarHolidayYomHashoahDescription =>
      'Holocaust Remembrance Day';

  @override
  String get jewishCalendarHolidayYomHazikaronName => 'Yom HaZikaron';

  @override
  String get jewishCalendarHolidayYomHazikaronDescription =>
      'Memorial Day for fallen soldiers';

  @override
  String get jewishCalendarHolidayYomHaatzmautName => 'Yom HaAtzmaut';

  @override
  String get jewishCalendarHolidayYomHaatzmautDescription =>
      'Israel Independence Day';

  @override
  String get jewishCalendarHolidayYomYerushalayimName => 'Yom Yerushalayim';

  @override
  String get jewishCalendarHolidayYomYerushalayimDescription =>
      'Jerusalem Reunification Day';

  @override
  String get jewishCalendarHolidayLagBaomerName => 'Lag BaOmer';

  @override
  String get jewishCalendarHolidayLagBaomerDescription =>
      '33rd day of the Omer';

  @override
  String get jewishCalendarHolidayShavuotName => 'Shavuot';

  @override
  String get jewishCalendarHolidayShavuotDescription => 'Giving of the Torah';

  @override
  String get jewishCalendarIdeaFestiveDinner => 'Festive dinner';

  @override
  String get jewishCalendarIdeaTashlich => 'Tashlich together';

  @override
  String get jewishCalendarIdeaMutualForgiveness =>
      'Ask each other for forgiveness';

  @override
  String get jewishCalendarIdeaBuildSukkah => 'Build the sukkah together';

  @override
  String get jewishCalendarIdeaInviteFriends => 'Invite friends';

  @override
  String get jewishCalendarIdeaPrayerForRain => 'Prayer for rain';

  @override
  String get jewishCalendarIdeaDanceWithTorah => 'Dance with the Torah';

  @override
  String get jewishCalendarIdeaLightCandlesTogether =>
      'Light the candles together';

  @override
  String get jewishCalendarIdeaHomemadeSufganiyot => 'Homemade sufganiyot';

  @override
  String get jewishCalendarIdeaCoupleCostumes => 'Couple costumes';

  @override
  String get jewishCalendarIdeaMishloachManot => 'Mishloach manot together';

  @override
  String get jewishCalendarIdeaRomanticSeder => 'Romantic Seder';

  @override
  String get jewishCalendarIdeaTripToIsrael => 'Trip to Israel';

  @override
  String get jewishCalendarIdeaIsraeliBarbecue => 'Israeli barbecue';

  @override
  String get jewishCalendarIdeaConcertOrParty => 'Concert or party';

  @override
  String get jewishCalendarIdeaCampfire => 'Bonfire';

  @override
  String get jewishCalendarIdeaPicnic => 'Picnic';

  @override
  String get jewishCalendarIdeaHomemadeCheesecake => 'Homemade cheesecake';

  @override
  String get jewishCalendarIdeaStudyNight => 'Night of study';

  @override
  String get jewishCalendarParshaBereshis => 'Bereshit';

  @override
  String get jewishCalendarParshaNoach => 'Noach';

  @override
  String get jewishCalendarParshaLechLecha => 'Lech-Lecha';

  @override
  String get jewishCalendarParshaVayera => 'Vayera';

  @override
  String get jewishCalendarParshaChayeiSara => 'Chayei Sara';

  @override
  String get jewishCalendarParshaToldos => 'Toldot';

  @override
  String get jewishCalendarParshaVayetzei => 'Vayetzei';

  @override
  String get jewishCalendarParshaVayishlach => 'Vayishlach';

  @override
  String get jewishCalendarParshaVayeshev => 'Vayeshev';

  @override
  String get jewishCalendarParshaMiketz => 'Miketz';

  @override
  String get jewishCalendarParshaVayigash => 'Vayigash';

  @override
  String get jewishCalendarParshaVayechi => 'Vayechi';

  @override
  String get jewishCalendarParshaShemos => 'Shemot';

  @override
  String get jewishCalendarParshaVaera => 'Vaera';

  @override
  String get jewishCalendarParshaBo => 'Bo';

  @override
  String get jewishCalendarParshaBeshalach => 'Beshalach';

  @override
  String get jewishCalendarParshaYisro => 'Yitro';

  @override
  String get jewishCalendarParshaMishpatim => 'Mishpatim';

  @override
  String get jewishCalendarParshaTerumah => 'Terumah';

  @override
  String get jewishCalendarParshaTetzaveh => 'Tetzaveh';

  @override
  String get jewishCalendarParshaKiSisa => 'Ki Tisa';

  @override
  String get jewishCalendarParshaVayakhel => 'Vayakhel';

  @override
  String get jewishCalendarParshaPekudei => 'Pekudei';

  @override
  String get jewishCalendarParshaVayikra => 'Vayikra';

  @override
  String get jewishCalendarParshaTzav => 'Tzav';

  @override
  String get jewishCalendarParshaShmini => 'Shemini';

  @override
  String get jewishCalendarParshaTazria => 'Tazria';

  @override
  String get jewishCalendarParshaMetzora => 'Metzora';

  @override
  String get jewishCalendarParshaAchreiMos => 'Acharei Mot';

  @override
  String get jewishCalendarParshaKedoshim => 'Kedoshim';

  @override
  String get jewishCalendarParshaEmor => 'Emor';

  @override
  String get jewishCalendarParshaBehar => 'Behar';

  @override
  String get jewishCalendarParshaBechukosai => 'Bechukotai';

  @override
  String get jewishCalendarParshaBamidbar => 'Bamidbar';

  @override
  String get jewishCalendarParshaNasso => 'Naso';

  @override
  String get jewishCalendarParshaBehaaloscha => 'Beha\'alotcha';

  @override
  String get jewishCalendarParshaShlach => 'Shelach';

  @override
  String get jewishCalendarParshaKorach => 'Korach';

  @override
  String get jewishCalendarParshaChukas => 'Chukat';

  @override
  String get jewishCalendarParshaBalak => 'Balak';

  @override
  String get jewishCalendarParshaPinchas => 'Pinchas';

  @override
  String get jewishCalendarParshaMatos => 'Matot';

  @override
  String get jewishCalendarParshaMasei => 'Masei';

  @override
  String get jewishCalendarParshaDevarim => 'Devarim';

  @override
  String get jewishCalendarParshaVaeschanan => 'Va\'etchanan';

  @override
  String get jewishCalendarParshaEikev => 'Eikev';

  @override
  String get jewishCalendarParshaReeh => 'Re\'eh';

  @override
  String get jewishCalendarParshaShoftim => 'Shoftim';

  @override
  String get jewishCalendarParshaKiSeitzei => 'Ki Teitzei';

  @override
  String get jewishCalendarParshaKiSavo => 'Ki Tavo';

  @override
  String get jewishCalendarParshaNitzavim => 'Nitzavim';

  @override
  String get jewishCalendarParshaVayeilech => 'Vayelech';

  @override
  String get jewishCalendarParshaHaazinu => 'Haazinu';

  @override
  String get jewishCalendarParshaVzosHaberacha => 'Vezot Haberakhah';

  @override
  String get layoutPaneChatTitle => 'Pick a conversation';

  @override
  String get layoutPaneChatMessage => 'It opens here, next to the list.';

  @override
  String get layoutPaneProfileTitle => 'Pick a match';

  @override
  String get layoutPaneProfileMessage =>
      'Their profile shows here, next to the list.';

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
  String get matchingMatchesTitle => 'Matches';

  @override
  String get matchingMatchesWhoLikedYou => 'Who liked you';

  @override
  String matchingMatchesNewSection(int count) {
    return 'New · $count';
  }

  @override
  String matchingMatchesConversationsSection(int count) {
    return 'Conversations · $count';
  }

  @override
  String get matchingMatchesLoadFailed => 'Couldn\'t load your matches';

  @override
  String get matchingMatchesEmptyTitle => 'No matches yet';

  @override
  String get matchingMatchesEmptyBody => 'Keep discovering profiles.';

  @override
  String get matchingMatchesUnknownName => 'Unknown';

  @override
  String get matchingMatchesWriteHint => 'Say hello';

  @override
  String matchingMatchesViewProfileOf(String name) {
    return 'View $name\'s profile';
  }

  @override
  String matchingMatchesSeeMore(int count) {
    return 'See $count more';
  }

  @override
  String matchingMatchedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '$count day ago',
    );
    return '$_temp0';
  }

  @override
  String matchingMatchedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '$count week ago',
    );
    return '$_temp0';
  }

  @override
  String matchingMatchedMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '$count month ago',
    );
    return '$_temp0';
  }

  @override
  String get matchingCouplePromoTitle => 'Did you two match?';

  @override
  String get matchingCouplePromoDismiss => 'Dismiss';

  @override
  String get matchingCouplePromoBody =>
      'Daily questions, milestones, a shared Jewish calendar: build your relationship with mazl.';

  @override
  String get matchingCouplePromoAction => 'Turn on couple mode';

  @override
  String get matchingPicksSeenAll => 'You\'ve seen all your picks.';

  @override
  String matchingPicksNextIn(int hours, int minutes) {
    return 'Next picks in ${hours}h ${minutes}m';
  }

  @override
  String matchingPicksUpdatedIn(int hours, int minutes) {
    return 'Refreshes in ${hours}h ${minutes}m';
  }

  @override
  String matchingPicksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profiles picked for you',
      one: '$count profile picked for you',
    );
    return '$_temp0';
  }

  @override
  String get matchingPicksDiscoverMore => 'Discover more profiles';

  @override
  String get matchingPicksBadge => 'Pick';

  @override
  String get matchingFiltersReset => 'Reset';

  @override
  String get matchingFiltersAge => 'Age range';

  @override
  String matchingFiltersYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '$count year',
    );
    return '$_temp0';
  }

  @override
  String get matchingFiltersDistance => 'Maximum distance';

  @override
  String matchingFiltersKm(int count) {
    return '$count km';
  }

  @override
  String get matchingFiltersDenomination => 'Religious movement';

  @override
  String get matchingFiltersKashrut => 'Kashrut';

  @override
  String get matchingFiltersShabbatSection => 'Shabbat';

  @override
  String get matchingFiltersChoiceHint =>
      'You can pick several. Profiles that haven\'t answered are not shown.';

  @override
  String get matchingFiltersOptions => 'Options';

  @override
  String get matchingFiltersVerifiedTitle => 'Verified profiles only';

  @override
  String get matchingFiltersVerifiedHint => 'Only show verified profiles';

  @override
  String get matchingFiltersPhotoTitle => 'With photo only';

  @override
  String get matchingFiltersPhotoHint => 'Hide profiles without a photo';

  @override
  String get matchingFiltersUpsellTitle => 'Unlock every filter';

  @override
  String get matchingFiltersUpsellBody =>
      'Upgrade to mazl+ for precise searches';

  @override
  String get matchingFiltersApply => 'Apply filters';

  @override
  String get matchingFiltersSaved => 'Filters saved';

  @override
  String get matchingFiltersSaveFailed => 'Something went wrong while saving';

  @override
  String get matchingFiltersAdvanced => 'Advanced filters';

  @override
  String get matchingFiltersLoadFailed =>
      'Your advanced filters couldn\'t be loaded.';

  @override
  String get matchingFiltersConsentNeeded =>
      'These criteria need your consent to process your religious practice. They weren\'t saved.';

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
  String get onboardingStart => 'Get started';

  @override
  String onboardingStep(String current, String total) {
    return '$current / $total';
  }

  @override
  String onboardingPageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get onboardingPage1Title => 'Welcome to MAZL';

  @override
  String get onboardingPage1Body =>
      'The dating app designed for the Jewish community.';

  @override
  String get onboardingPage2Title => 'Find your mazal';

  @override
  String get onboardingPage2Body =>
      'Discover profiles that match your values and your level of observance.';

  @override
  String get onboardingPage3Title => 'Couple mode';

  @override
  String get onboardingPage3Body =>
      'Once you\'ve found love, MAZL stays with you: find love, and keep it.';

  @override
  String get onboardingPage3Feature1 => 'Memories and important dates';

  @override
  String get onboardingPage3Feature2 => 'A bucket list for two';

  @override
  String get onboardingPage3Feature3 => 'Shared Jewish calendar';

  @override
  String get onboardingPage3Feature4 => 'Activities and suggestions';

  @override
  String get onboardingPage4Title => 'Shabbat mode';

  @override
  String get onboardingPage4Body =>
      'Candle-lighting and Havdalah times for your city, and a rest screen.';

  @override
  String get onboardingPage5Title => 'Daily picks';

  @override
  String get onboardingPage5Body =>
      'Every day, a short selection of profiles is waiting for you in Discover.';

  @override
  String get packsSuperLikesLabel => 'Super Likes';

  @override
  String get packsSuperLikesTitle => 'You’re out of Super Likes.';

  @override
  String get packsSuperLikesSubtitle =>
      'Get more. The ones you buy never expire.';

  @override
  String get packsBoostsLabel => 'Boosts';

  @override
  String get packsBoostsTitle => 'You’re out of Boosts.';

  @override
  String packsBoostsSubtitle(int minutes) {
    return 'Put your profile first for $minutes min. A Boost you buy never expires.';
  }

  @override
  String packsPackSuperLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Super Likes',
      one: '$count Super Like',
    );
    return '$_temp0';
  }

  @override
  String packsPackBoosts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Boosts',
      one: '$count Boost',
    );
    return '$_temp0';
  }

  @override
  String packsPackSemantics(String quantity, String price) {
    return 'Buy $quantity for $price';
  }

  @override
  String get packsLoading => 'Loading offers';

  @override
  String get packsStoreUnavailable =>
      'The store isn’t available right now. Try again in a moment.';

  @override
  String get packsPending =>
      'Purchase pending approval. Your balance will update as soon as it is approved.';

  @override
  String get packsBoostAlreadyActive => 'A Boost is already running.';

  @override
  String get packsErrorExhausted => 'You have none left to use right now.';

  @override
  String get plusFeatureUnlimitedLikesTitle => 'Unlimited likes';

  @override
  String get plusFeatureUnlimitedLikesDescription =>
      'Like as much as you want, with no daily limit.';

  @override
  String get plusFeatureSeeWhoLikesYouTitle => 'See who liked you';

  @override
  String get plusFeatureSeeWhoLikesYouDescription =>
      'See who liked you before you even cross paths.';

  @override
  String get plusFeatureSuperLikesTitle => 'Super Likes';

  @override
  String get plusFeatureSuperLikesDescription =>
      'Stand out with 5 Super Likes a day.';

  @override
  String get plusFeatureBoostTitle => 'Boost';

  @override
  String get plusFeatureBoostDescription =>
      'Be at the top of the stack for 30 minutes.';

  @override
  String get plusFeatureReadReceiptsTitle => 'Read receipts';

  @override
  String get plusFeatureReadReceiptsDescription =>
      'Know when your messages have been read.';

  @override
  String get plusFeatureAdvancedFiltersTitle => 'Advanced filters';

  @override
  String get plusFeatureAdvancedFiltersDescription =>
      'Filter by practice, community and more.';

  @override
  String get plusFeaturePrioritySupportTitle => 'Priority support';

  @override
  String get plusFeaturePrioritySupportDescription =>
      'Get a quick answer from our team.';

  @override
  String get plusReservedLabel => 'Reserved for mazl+';

  @override
  String get plusDiscover => 'Discover mazl+';

  @override
  String get plusNotNow => 'Not now';

  @override
  String plusDailyLimitLabel(int limit) {
    return 'Daily limit · $limit / $limit';
  }

  @override
  String get plusDailyLimitTitle => 'Your likes for today are gone.';

  @override
  String get plusDailyLimitBody =>
      'They come back at midnight. Or keep going without counting, and see who already liked you.';

  @override
  String get plusDailyLimitNext => 'Next likes in';

  @override
  String get plusDailyLimitWait => 'Wait until midnight';

  @override
  String get plusOfferTagline => 'Meet without counting.';

  @override
  String get plusPerkUnlimitedLikesDetail => 'No more 10 a day.';

  @override
  String get plusPerkSeeWhoDetail => 'Before you even cross paths.';

  @override
  String get plusPerkSuperLikesTitle => '5 Super Likes a day';

  @override
  String get plusPerkSuperLikesDetail => 'Instead of just one.';

  @override
  String get plusPerkBoostTitle => 'One Boost a day';

  @override
  String get plusPerkBoostDetail => 'At the top of the stack for 30 minutes.';

  @override
  String get plusPerkFiltersDetail => 'Practice, community, and more.';

  @override
  String get plusYourPlan => 'Your plan';

  @override
  String plusMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String plusPerMonth(String price) {
    return '$price per month';
  }

  @override
  String plusPlanSavings(int percent) {
    return '-$percent%';
  }

  @override
  String plusPlanSemantics(String duration, String price, String perMonth) {
    return '$duration, $price, $perMonth';
  }

  @override
  String plusPlanSemanticsSaving(
    String duration,
    String price,
    String perMonth,
    String saving,
  ) {
    return '$duration, $price, $perMonth, saves $saving';
  }

  @override
  String plusContinuePrice(String price) {
    return 'Continue · $price';
  }

  @override
  String get plusAndroidSoon => 'Coming soon on Android';

  @override
  String get plusRestore => 'Restore';

  @override
  String get plusTerms => 'Terms';

  @override
  String get plusPrivacy => 'Privacy';

  @override
  String get plusLegalAppStore =>
      'Renews automatically. Cancel anytime in the App Store settings.';

  @override
  String get plusLegalGooglePlay =>
      'Renews automatically. Cancel anytime in the Google Play settings.';

  @override
  String get plusPendingApproval =>
      'Purchase pending approval. Your subscription will activate as soon as it is approved.';

  @override
  String get plusOfferRestored => 'Subscription restored';

  @override
  String get plusOfferNothingFound => 'No subscription found';

  @override
  String get plusPlansSoon => 'Subscriptions will be available soon.';

  @override
  String get plusErrorPurchaseInProgress =>
      'A purchase is already in progress.';

  @override
  String get plusErrorOwnedByAnotherAccount =>
      'This App Store purchase is already linked to another mazl account.';

  @override
  String get plusErrorInvalidTransaction =>
      'We couldn\'t validate this purchase with the App Store. It will be checked again at the next launch.';

  @override
  String get plusErrorInvalidBody =>
      'Your purchase couldn\'t be sent correctly. Try again in a moment.';

  @override
  String get plusErrorSignInAgain =>
      'Sign in to mazl again to finish your purchase.';

  @override
  String get plusErrorOffline =>
      'Can\'t connect. Your purchase is kept and will be validated as soon as possible.';

  @override
  String get plusErrorGeneric =>
      'The purchase couldn\'t be completed. Try again in a moment.';

  @override
  String get plusErrorInactive => 'Your subscription isn\'t active.';

  @override
  String get plusErrorRestoreFailed =>
      'Restoring failed. Try again in a moment.';

  @override
  String get plusActiveSubscription => 'Active subscription';

  @override
  String plusActiveSubscriptionPlan(String plan) {
    return 'Active subscription · $plan';
  }

  @override
  String get plusWelcomeTitle => 'Welcome to mazl+.';

  @override
  String get plusWelcomeSubtitle =>
      'Everything is unlocked. Where do you want to start?';

  @override
  String plusWelcomeLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people liked you',
      one: '1 person liked you',
    );
    return '$_temp0';
  }

  @override
  String get plusWelcomeLikesDetail => 'See them now';

  @override
  String get plusWelcomeBoostTitle => 'Start your Boost';

  @override
  String get plusWelcomeBoostDetail => 'At the top of the stack for 30 minutes';

  @override
  String get plusWelcomeFiltersTitle => 'Fine-tune your filters';

  @override
  String get plusWelcomeFiltersDetail => 'Practice, community, and more';

  @override
  String plusTitleDetail(String title, String detail) {
    return '$title. $detail';
  }

  @override
  String get plusSubscriptionTitle => 'Subscription';

  @override
  String get plusStatusActive => 'Active';

  @override
  String get plusStatusCancelled => 'Cancelled';

  @override
  String get plusFactPlan => 'Plan';

  @override
  String get plusFactRenewal => 'Renewal';

  @override
  String get plusFactExpiration => 'Expiration';

  @override
  String plusPlanAndPrice(String duration, String price) {
    return '$duration · $price';
  }

  @override
  String plusSuperLikesOf(int left, int max) {
    return '$left of $max';
  }

  @override
  String get plusBoostAvailable => 'Available';

  @override
  String get plusBoostUsed => 'Used today';

  @override
  String get plusLikesLabel => 'Likes';

  @override
  String get plusLikesUnlimited => 'Unlimited';

  @override
  String get plusManageAppStore => 'Manage in the App Store';

  @override
  String get plusManageGooglePlay => 'Manage in Google Play';

  @override
  String get plusManageFailed => 'Couldn\'t open subscription management.';

  @override
  String get plusRestorePurchases => 'Restore my purchases';

  @override
  String get plusNoActiveSubscription => 'No active subscription.';

  @override
  String get plusPurchasesRestored => 'Purchases restored.';

  @override
  String get plusNothingToRestore => 'No subscription found.';

  @override
  String get plusSettingsPitch => 'Unlimited likes, see who liked you, Boost';

  @override
  String get plusUpgradeTo => 'Upgrade to mazl+';

  @override
  String plusSettingsSemanticsActive(String detail) {
    return 'mazl+. $detail';
  }

  @override
  String plusSettingsSemanticsUpgrade(String detail) {
    return 'Upgrade to mazl+. $detail';
  }

  @override
  String get privacyGateUnverifiable =>
      'We couldn\'t check your consent. Check your connection.';

  @override
  String get privacyGateAsk => 'To share your practice, give your consent';

  @override
  String get privacyGive => 'Give my consent';

  @override
  String get privacyLockedHint =>
      'Available once you\'ve given your consent for religious practice data.';

  @override
  String get privacySheetLabel => 'Sensitive data · GDPR article 9';

  @override
  String get privacySheetTitle => 'Your religious practice, with your consent';

  @override
  String get privacySheetBody =>
      'This information helps suggest compatible profiles. It is sensitive data, processed only with your explicit consent, separate from the terms of use. You can decline and still use MAZL.';

  @override
  String get privacySheetCheckbox =>
      'I\'ve read this text and I give my explicit consent.';

  @override
  String get privacySheetAccept => 'I agree';

  @override
  String get privacySheetDecline => 'Continue without';

  @override
  String get privacySheetErrorOutdated =>
      'The text has been updated. Close this window and open it again.';

  @override
  String get privacySheetErrorSave =>
      'Your choice couldn\'t be saved. Please try again.';

  @override
  String get privacySettingsTitle => 'Religious practice data';

  @override
  String get privacySettingsGrantedShort => 'Granted';

  @override
  String get privacySettingsDeniedShort => 'Not granted';

  @override
  String get privacySettingsGrantedTitle => 'Consent given';

  @override
  String get privacySettingsNotGrantedTitle => 'Consent not given';

  @override
  String get privacySettingsWithdraw => 'Withdraw my consent';

  @override
  String get privacySettingsWithdrawTitle => 'Withdraw your consent?';

  @override
  String get privacySettingsWithdrawBody =>
      'Your denomination, kashrut, Shabbat observance and intention will be erased from your profile.';

  @override
  String get privacySettingsWithdrawFailed =>
      'We couldn\'t withdraw your consent. Please try again.';

  @override
  String get privacySettingsLoadFailed =>
      'We couldn\'t load your consent. Check your connection.';

  @override
  String get profileMyProfile => 'My profile';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileMoreOptions => 'More options';

  @override
  String get profilePass => 'Pass';

  @override
  String profileLikeName(String name) {
    return 'Like $name';
  }

  @override
  String get profileThisPerson => 'this person';

  @override
  String get profileFallbackName => 'User';

  @override
  String get profileFallbackReportName => 'This user';

  @override
  String get profileDefaultLocation => 'France';

  @override
  String get profileDistanceUnderOneKm => 'under 1 km away';

  @override
  String profileDistanceKm(int km) {
    return '$km km away';
  }

  @override
  String get profileGenderMale => 'Man';

  @override
  String get profileGenderFemale => 'Woman';

  @override
  String get profileFactPractice => 'Practice';

  @override
  String get profileFactKashrut => 'Kashrut';

  @override
  String get profileShabbat => 'Shabbat';

  @override
  String get profileFactGender => 'Gender';

  @override
  String get profileEssentials => 'The essentials';

  @override
  String get profileInAFewWords => 'In a few words';

  @override
  String get profileAbout => 'About';

  @override
  String get profileLookingFor => 'What I\'m looking for';

  @override
  String get profileAddPhotos => 'Add photos';

  @override
  String get profileVerified => 'Verified';

  @override
  String get profileVerifiedPlus => 'Verified+';

  @override
  String get profileVerifyMyProfile => 'Verify my profile';

  @override
  String profileVerificationStatus(String status) {
    return 'Verification status: $status';
  }

  @override
  String get profilePhotoPrevious => 'Previous photo';

  @override
  String get profilePhotoNext => 'Next photo';

  @override
  String profilePhotoCounter(int current, int total) {
    return 'Photo $current of $total';
  }

  @override
  String profileCompletionEyebrow(int done, int total) {
    return 'Profile · $done/$total';
  }

  @override
  String get profileCompletionTitle => 'Complete your profile';

  @override
  String profileCompletionRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps left',
      one: '$count step left',
    );
    return '$_temp0';
  }

  @override
  String get profileCompletionAction => 'Complete it now';

  @override
  String get profileStepPhotosDone => 'Photos added';

  @override
  String get profileStepPhotosTodo => 'Add at least 2 photos';

  @override
  String get profileStepBioDone => 'Bio completed';

  @override
  String get profileStepBioTodo => 'Describe yourself in a few lines';

  @override
  String get profileStepCityDone => 'City added';

  @override
  String get profileStepCityTodo => 'Enter your city';

  @override
  String get profileStepVerifiedDone => 'Profile verified';

  @override
  String get profileStepVerifiedTodo => 'Get your profile verified';

  @override
  String get profileCoupleMode => 'Couple mode';

  @override
  String get profileCoupleInCoupleTitle => 'In a couple';

  @override
  String profileCoupleInCoupleBody(String name) {
    return 'You\'re in couple mode with $name.';
  }

  @override
  String get profileCoupleElsewhereTitle => 'Already in couple mode';

  @override
  String get profileCoupleElsewhereBody =>
      'You\'re already in couple mode with someone else.';

  @override
  String get profileCoupleReceivedTitle => 'Request received';

  @override
  String profileCoupleReceivedBody(String name) {
    return '$name would like to turn on couple mode with you.';
  }

  @override
  String get profileCoupleRespond => 'Reply';

  @override
  String get profileCouplePendingTitle => 'Request sent';

  @override
  String profileCouplePendingBody(String name) {
    return '$name hasn\'t replied yet.';
  }

  @override
  String get profileCoupleCancelRequest => 'Cancel request';

  @override
  String get profileCoupleAvailableTitle => 'Switch to couple mode';

  @override
  String get profileCoupleAvailableBody =>
      'You matched. Turn on couple mode to share activities together.';

  @override
  String profileCoupleActivate(String name) {
    return 'Turn on with $name';
  }

  @override
  String profileCoupleRequestSent(String name) {
    return 'Request sent to $name.';
  }

  @override
  String get profileCompatibility => 'Compatibility';

  @override
  String get profileCompatibilityVeryHigh => 'Very compatible';

  @override
  String get profileCompatibilityHigh => 'Compatible';

  @override
  String get profileCompatibilityAverage => 'Average compatibility';

  @override
  String get profileCompatibilityLow => 'Not very compatible';

  @override
  String get profileCompatibilityBasis => 'Based on both of your profiles.';

  @override
  String get profileCompatibilityUnavailable =>
      'Compatibility isn\'t available right now.';

  @override
  String profileCompatibilityUnlockTitle(String name) {
    return 'Find out your compatibility score with $name.';
  }

  @override
  String get profileCompatibilityUnlockBody =>
      'Based on your practices, intentions and values.';

  @override
  String get profileCompatibilityUnlock => 'Unlock with mazl+';

  @override
  String get profileFactorIntentions => 'Intentions';

  @override
  String get profileFactorAge => 'Age';

  @override
  String get profileFactorDistance => 'Distance';

  @override
  String get profileVerdictSameIntention =>
      'You\'re looking for the same thing';

  @override
  String get profileVerdictDifferentIntention => 'Different intentions';

  @override
  String get profileVerdictSameDenomination => 'Same denomination';

  @override
  String get profileVerdictSimilarPractice => 'Similar practice';

  @override
  String get profileVerdictDifferentPractice => 'Different practice';

  @override
  String get profileVerdictVeryCloseAge => 'Very close in age';

  @override
  String get profileVerdictCloseAge => 'Close in age';

  @override
  String get profileVerdictModerateAgeGap => 'Moderate age gap';

  @override
  String get profileVerdictLargeAgeGap => 'Large age gap';

  @override
  String get profileVerdictVeryNear => 'Very close (< 10 km)';

  @override
  String get profileVerdictNear => 'Close (< 25 km)';

  @override
  String get profileVerdictModerateDistance => 'Moderate distance';

  @override
  String get profileVerdictFar => 'Fairly far';

  @override
  String get profilePromptsMine => 'My prompts';

  @override
  String get profilePromptsSubtitle =>
      'Answer questions to show your personality';

  @override
  String profilePromptsMaxReached(int max) {
    return 'Maximum of $max prompts reached';
  }

  @override
  String get profilePromptsAllUsed => 'All prompts are already used';

  @override
  String get profilePromptAdd => 'Add a prompt';

  @override
  String get profilePromptChoose => 'Choose a prompt';

  @override
  String get profilePromptYourAnswer => 'Your answer…';

  @override
  String get profilePromptDeleteTitle => 'Delete this prompt?';

  @override
  String get profileIrreversibleSentence => 'This can\'t be undone.';

  @override
  String get profileIrreversible => 'This can\'t be undone';

  @override
  String get profilePromptDeleted => 'Prompt deleted';

  @override
  String get profilePromptCategoryPersonality => 'Personality';

  @override
  String get profilePromptCategoryLifestyle => 'Lifestyle';

  @override
  String get profilePromptCategoryJewish => 'Judaism';

  @override
  String get profilePromptCategoryConversation => 'Conversation';

  @override
  String get profileOther => 'Other';

  @override
  String get profilePromptPerfectSunday => 'My perfect Sunday...';

  @override
  String get profilePromptFunFact => 'A surprising fact about me...';

  @override
  String get profilePromptLifeGoal => 'One of my goals in life...';

  @override
  String get profilePromptPetPeeve => 'What annoys me the most...';

  @override
  String get profilePromptProudOf => 'I\'m proud of...';

  @override
  String get profilePromptLookingFor => 'I\'m looking for someone who...';

  @override
  String get profilePromptIdealVacation => 'My ideal vacation...';

  @override
  String get profilePromptFavoriteFood => 'My favorite dish...';

  @override
  String get profilePromptHiddenTalent => 'My hidden talent...';

  @override
  String get profilePromptBingeWatching => 'Right now I\'m watching...';

  @override
  String get profilePromptShabbatIdeal => 'My ideal Shabbat...';

  @override
  String get profilePromptFamilyTradition => 'A family tradition I love...';

  @override
  String get profilePromptFavoriteHoliday => 'My favorite Jewish holiday...';

  @override
  String get profilePromptFridayNight => 'Friday night at my place...';

  @override
  String get profilePromptIsraelMemory => 'My best memory in Israel...';

  @override
  String get profilePromptJewishValue => 'A Jewish value that guides me...';

  @override
  String get profilePromptDebateMe => 'Debate me on…';

  @override
  String get profilePromptTeachMe => 'Teach me something about…';

  @override
  String get profilePromptTogetherWeCould => 'Together we could...';

  @override
  String get profilePromptFirstDate => 'Ideal first date...';

  @override
  String get profileIntentionHint => 'Show others what you\'re looking for';

  @override
  String get profileIntentionMarriage => 'Marriage';

  @override
  String get profileIntentionSerious => 'Serious relationship';

  @override
  String get profileIntentionOpen => 'Open to anything';

  @override
  String get profileIntentionOpenSelector => 'Open to anything';

  @override
  String get profileIntentionFriendsFirst => 'Friendship first';

  @override
  String get profileIntentionUndecided => 'I don\'t know yet';

  @override
  String get profileIntentionMarriageDescription =>
      'I\'m looking for my future spouse';

  @override
  String get profileIntentionSeriousDescription =>
      'I\'m looking for something lasting';

  @override
  String get profileIntentionOpenDescription => 'We\'ll see where it goes';

  @override
  String get profileIntentionFriendsFirstDescription =>
      'Let\'s start by getting to know each other';

  @override
  String get profileDenomination => 'Denomination';

  @override
  String get profileDenominationSecular => 'Secular';

  @override
  String get profileDenominationTraditional => 'Traditional';

  @override
  String get profileDenominationMasorti => 'Masorti';

  @override
  String get profileDenominationLiberal => 'Liberal (Reform)';

  @override
  String get profileDenominationModernOrthodox => 'Modern Orthodox';

  @override
  String get profileDenominationOrthodox => 'Orthodox';

  @override
  String get profileDenominationChabad => 'Chabad';

  @override
  String get profileFieldKashrut => 'Kashrut';

  @override
  String get profileKashrutNone => 'No';

  @override
  String get profileKashrutHome => 'Kosher at home';

  @override
  String get profileKashrutStrict => 'Strictly kosher';

  @override
  String get profileKashrutGlatt => 'Glatt kosher';

  @override
  String get profileKashrutOptionHome => 'At home';

  @override
  String get profileKashrutOptionStrict => 'Strict';

  @override
  String get profileKashrutOptionGlatt => 'Glatt';

  @override
  String get profileShabbatNotObservant => 'Not observant';

  @override
  String get profileShabbatPartial => 'Partial Shabbat';

  @override
  String get profileShabbatObserved => 'Shabbat observed';

  @override
  String get profileShabbatStrict => 'Strict Shabbat';

  @override
  String get profileShabbatFamily => 'Family Shabbat';

  @override
  String get profileShabbatOptionPartial => 'Partially';

  @override
  String get profileShabbatOptionObservant => 'Observant';

  @override
  String get profileShabbatOptionStrict => 'Very observant';

  @override
  String get profileSynagogue => 'Synagogue';

  @override
  String get profileSynagogueDaily => 'Daily';

  @override
  String get profileSynagogueWeekly => 'Every week';

  @override
  String get profileSynagogueHolidays => 'On holidays';

  @override
  String get profileSynagogueRarely => 'Rarely';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profilePhotos => 'Photos';

  @override
  String get profilePhotosHint => 'Press and hold to set as main photo';

  @override
  String get profileBioHint => 'Tell us about yourself…';

  @override
  String get profileBasicInfo => 'Basic information';

  @override
  String get profileFirstName => 'First name';

  @override
  String get profileCity => 'City';

  @override
  String get profilePracticeTitle => 'My practice';

  @override
  String get profilePrimaryPhoto => 'Main';

  @override
  String get profileEnterFirstName => 'Enter your first name';

  @override
  String get profileEnterCity => 'Enter your city';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profilePhotoAdded => 'Photo added';

  @override
  String get profileUploadUnavailable => 'Upload isn\'t available right now';

  @override
  String get profileDeletePhotoTitle => 'Delete this photo?';

  @override
  String get profilePhotoDeleted => 'Photo deleted';

  @override
  String get profileServiceUnavailable => 'Service temporarily unavailable';

  @override
  String get profilePrimaryUpdated => 'Main photo updated';

  @override
  String profileSetupStep(int step, int total) {
    return 'Step $step/$total';
  }

  @override
  String get profileSetupNext => 'Next';

  @override
  String get profileSetupFinish => 'Finish';

  @override
  String get profileSetupNameRequired => 'Enter your first name to continue';

  @override
  String get profileSetupBirthdateRequired => 'Enter your date of birth';

  @override
  String get profileSetupGenderRequired => 'Select your gender';

  @override
  String get profileBirthdate => 'Date of birth';

  @override
  String get profileBirthdateHint => 'MM/DD/YYYY';

  @override
  String get profileSetupAboutYouTitle => 'Tell us about you';

  @override
  String get profileSetupAboutYouSubtitle =>
      'This information will be visible on your profile';

  @override
  String get profileFirstNameHint => 'What\'s your name?';

  @override
  String get profileIAm => 'I am';

  @override
  String get profileAMan => 'A man';

  @override
  String get profileAWoman => 'A woman';

  @override
  String get profileCityHint => 'Where do you live?';

  @override
  String get profileSetupPhotosTitle => 'Add photos';

  @override
  String get profileSetupPhotosSubtitle => 'Add at least 2 photos to continue';

  @override
  String get profileSetupPhotosTip =>
      'Profiles with good-quality photos get 3x more matches.';

  @override
  String get profileSetupPracticeTitle => 'Your practice';

  @override
  String get profileSetupPracticeSubtitle =>
      'Help us find someone who suits you';

  @override
  String get profileSetupLookingTitle => 'What you\'re looking for';

  @override
  String get profileSetupLookingSubtitle =>
      'Help us show you the right profiles';

  @override
  String get profileILookFor => 'I\'m looking for';

  @override
  String get profileAgeRange => 'Age range';

  @override
  String get profileMaxDistance => 'Maximum distance';

  @override
  String profileDistanceSliderLabel(int km) {
    return '$km km';
  }

  @override
  String get profileGoal => 'Goal';

  @override
  String get profileSetupPreferencesNote =>
      'These preferences shape your Discover feed. You can change them at any time.';

  @override
  String get profileReportThisProfile => 'Report this profile';

  @override
  String get profileChoiceNotSent =>
      'Your choice wasn\'t sent. Please try again.';

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
  String get settingsShabbatAutoPause => 'Shabbat times';

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
  String get settingsSales => 'Terms of sale';

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
  String settingsShabbatBasedOn(String place) {
    return 'Based on $place';
  }

  @override
  String get settingsShabbatDefaultPlace => 'Paris, France';

  @override
  String get settingsShabbatUnknownPlaceHint =>
      'The times are Paris\'s, because your city is not known. Add it in the settings for exact times.';

  @override
  String get settingsShabbatExplanation =>
      'Candle lighting is 18 minutes before sunset, Havdalah at nightfall. To change the place, update your city in the settings.';

  @override
  String get settingsShabbatHeroTitle => 'Shabbat\nshalom.';

  @override
  String get settingsShabbatHeroSubtitle => 'Mazl is resting with you.';

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

  @override
  String get settingsRestoreNothing => 'No subscription found.';

  @override
  String get verificationProfileEyebrow => 'Your profile';

  @override
  String get verificationTitle => 'Verification';

  @override
  String get verificationLevel1 => 'Level 1';

  @override
  String get verificationLevel2 => 'Level 2';

  @override
  String get verificationPhotoTitle => 'Photo verified';

  @override
  String get verificationIdentityTitle => 'Identity verified';

  @override
  String get verificationVerifiedPill => 'Verified';

  @override
  String get verificationConsent =>
      'We compare your face with your photos. The images are not kept; only an encrypted fingerprint is, and it can be deleted at any time.';

  @override
  String get verificationPhotoVerifiedLine => 'Your face matches your photos.';

  @override
  String verificationPhotoVerifiedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Verified on $dateString.';
  }

  @override
  String get verificationRemoveAction => 'Remove my verification';

  @override
  String get verificationVerifyPhotoAction => 'Verify my photo';

  @override
  String get verificationVerifyIdentityAction => 'Verify my identity';

  @override
  String verificationBlockedToday(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Limit reached, you can try again at $timeString.';
  }

  @override
  String verificationBlockedLater(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Limit reached, you can try again on $dateString at $timeString.';
  }

  @override
  String get verificationIdentityCheckedNoDate =>
      'Document checked through its chip.';

  @override
  String verificationIdentityCheckedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Checked on $dateString.';
  }

  @override
  String get verificationIdentityPitch =>
      'Passport or ID card, read through its chip. A selfie confirms it is really you.';

  @override
  String get verificationRemoveDialogTitle => 'Remove my verification?';

  @override
  String get verificationRemoveDialogBody =>
      'Your badge and your face print will be deleted.';

  @override
  String verificationPhotosMismatch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of your photos do not look like you: they do not count.',
      one: 'One of your photos does not look like you: it does not count.',
    );
    return '$_temp0';
  }

  @override
  String get verificationLivenessFront => 'Look at the camera';

  @override
  String get verificationLivenessLeft => 'Slowly turn your head to the left';

  @override
  String get verificationLivenessRight => 'Slowly turn your head to the right';

  @override
  String get verificationLivenessHintNoFace =>
      'Put your face inside the circle';

  @override
  String get verificationLivenessHintMultipleFaces =>
      'Only one person in the frame';

  @override
  String get verificationLivenessHintTooSmall => 'Move a little closer';

  @override
  String get verificationLivenessHintOffCenter =>
      'Center your face in the circle';

  @override
  String get verificationLivenessHintLookStraight => 'Look straight ahead';

  @override
  String get verificationLivenessHintTurnMore => 'Turn a little more';

  @override
  String get verificationLivenessHintTurnLess =>
      'Not that far, come back a little';

  @override
  String get verificationLivenessHintTurnOtherWay => 'Turn the other way';

  @override
  String verificationLivenessPoseCounter(int current, int total) {
    return 'Pose $current / $total';
  }

  @override
  String verificationLivenessPosesTaken(int done, int total) {
    return 'Poses captured: $done of $total';
  }

  @override
  String get verificationLivenessPrivacy =>
      'Alone in the frame, well lit. The images are not kept.';

  @override
  String get verificationLivenessExpiredTitle => 'Session expired';

  @override
  String get verificationLivenessExpiredBody =>
      'The allotted time has run out. You can start again.';

  @override
  String get verificationCameraNeededTitle => 'Camera needed';

  @override
  String get verificationCameraNeededBody =>
      'MAZL uses the front camera to check that you are the person in your photos.';

  @override
  String get verificationCameraOpenSettings => 'Open settings';

  @override
  String get verificationCameraAllow => 'Allow camera access';

  @override
  String get verificationCameraUnavailableTitle => 'Camera unavailable';

  @override
  String get verificationCameraUnavailableBody =>
      'The front camera could not be started.';

  @override
  String get verificationIntroTitle => 'Verify your identity.';

  @override
  String get verificationIntroSubtitle =>
      'The “Identity verified” badge tells others that you really are the person in the photos. You need a biometric passport or ID card, two minutes and a bit of light.';

  @override
  String get verificationIntroStep1 => 'Photograph the photo page';

  @override
  String get verificationIntroStep1Detail => 'To read the two bottom lines.';

  @override
  String get verificationIntroStep2 => 'Place the phone on the chip';

  @override
  String get verificationIntroStep2Detail =>
      'The chip, signed by the state, is what counts.';

  @override
  String get verificationIntroStep3 => 'A moving selfie';

  @override
  String get verificationIntroStep3Detail =>
      'Compared with the photo on the chip.';

  @override
  String get verificationIntroPrivacy =>
      'Nothing is kept: we only keep the result.';

  @override
  String get verificationIntroStart => 'Start';

  @override
  String verificationStepLabel(int step, int total) {
    return 'Step $step / $total';
  }

  @override
  String get verificationScanTitle => 'Frame the photo page.';

  @override
  String get verificationScanHint =>
      'The two lines of “<” at the bottom are enough. Avoid glare.';

  @override
  String get verificationScanManual => 'Enter by hand';

  @override
  String get verificationScanFrameSemantics =>
      'Camera preview: place the two bottom lines of the document inside the highlighted frame';

  @override
  String get verificationCameraNotAvailable => 'The camera is not available.';

  @override
  String get verificationScanUnavailableBody =>
      'You can enter the details from the photo page by hand.';

  @override
  String get verificationScanEnterDetails => 'Enter the details';

  @override
  String get verificationManualTitle => 'Enter the details.';

  @override
  String get verificationManualSubtitle =>
      'Copy them from the photo page of your document.';

  @override
  String get verificationFieldDocumentNumber => 'Document number';

  @override
  String get verificationFieldBirthDate => 'Date of birth';

  @override
  String get verificationFieldExpiryDate => 'Expiry date';

  @override
  String get verificationDateHint => 'DD/MM/YYYY';

  @override
  String get verificationManualUseCamera => 'Scan with the camera';

  @override
  String get verificationErrorDocumentNumber =>
      'Between 5 and 12 letters or digits.';

  @override
  String get verificationErrorInvalidDate => 'Invalid date.';

  @override
  String get verificationReviewTitle => 'Check these details.';

  @override
  String get verificationReviewConfirm => 'That\'s me';

  @override
  String get verificationRescan => 'Scan again';

  @override
  String get verificationNfcWaitingTitle => 'Place your document on the phone.';

  @override
  String get verificationNfcPlacement =>
      'The top of the phone against the closed cover of the passport, or against the back of the ID card. Remove the case if needed.';

  @override
  String get verificationNfcRead => 'Read the document';

  @override
  String get verificationNfcIllustration =>
      'The top of the phone resting against the closed cover of the passport';

  @override
  String get verificationNfcReadingTitle => 'Don\'t move.';

  @override
  String get verificationNfcReadingSubtitle =>
      'Keep the document against the top of the phone until the reading is finished.';

  @override
  String get verificationNfcProgressLabel => 'Reading the chip';

  @override
  String verificationNfcProgressValue(int percent) {
    return '$percent%';
  }

  @override
  String get verificationNfcStepDetect => 'Detecting the document';

  @override
  String get verificationNfcStepConnect => 'Secure connection';

  @override
  String get verificationNfcStepPhoto => 'Reading the photo';

  @override
  String get verificationNfcStepSignature => 'Reading the signature';

  @override
  String verificationNfcStepSemantics(String label, String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'done': '$label, done',
      'active': '$label, in progress',
      'waiting': '$label, waiting',
      'other': '$label',
    });
    return '$_temp0';
  }

  @override
  String get verificationNfcSilentBody =>
      'This often happens on the first try. Nothing was sent.';

  @override
  String get verificationNfcRescanBody =>
      'Nothing was sent. Read the photo page again to start over with correct data.';

  @override
  String get verificationNfcTip1 => 'Take the case off your phone.';

  @override
  String get verificationNfcTip2 =>
      'Put the top of the phone in the middle of the cover, passport closed.';

  @override
  String get verificationNfcTip3 => 'Stay still for about ten seconds.';

  @override
  String get verificationNfcRereadPhotoPage => 'Read the photo page again';

  @override
  String get verificationManualReviewLink =>
      'Send my document for manual review';

  @override
  String get verificationFaceTitle => 'Chip read.';

  @override
  String get verificationFaceSubtitle =>
      'One moving selfie left, compared with the photo on the chip.';

  @override
  String get verificationFaceAction => 'Take the selfie';

  @override
  String get verificationSubmitSending => 'Verification in progress…';

  @override
  String get verificationSubmitPreparing => 'Getting ready…';

  @override
  String get verificationDoneTitle => 'Identity verified.';

  @override
  String get verificationDoneSubtitle =>
      'The chip in your document and your selfie match. Your profile now carries the badge.';

  @override
  String get verificationDoneAction => 'Done';

  @override
  String get verificationBadgeLabel => 'Identity verified';

  @override
  String get verificationDoneBadgeCaption => 'What others see on your profile.';

  @override
  String get verificationDoneStoredLabel => 'Photos and chip';

  @override
  String get verificationDoneStoredValue => 'Never stored';

  @override
  String get verificationDoneKeptLabel => 'Kept';

  @override
  String get verificationDoneKeptValue =>
      'Country, expiry, anonymous fingerprint';

  @override
  String get verificationDoneProfileLabel => 'Profile';

  @override
  String get verificationDoneProfileValue => 'Date of birth from the document';

  @override
  String get verificationComingSoon => 'Coming soon';

  @override
  String get verificationFailureChipDataInvalid =>
      'The chip data is unreadable.';

  @override
  String get verificationFailureChipSignatureInvalid =>
      'The document\'s signature could not be verified.';

  @override
  String get verificationFailureNotRecognized => 'Document not recognized.';

  @override
  String get verificationDocumentExpired => 'This document has expired.';

  @override
  String get verificationFailureUnderage =>
      'You must be 18 to verify your identity.';

  @override
  String get verificationDocumentAlreadyUsed =>
      'This document is already linked to another account.';

  @override
  String get verificationDocumentBanned => 'This document cannot be used.';

  @override
  String get verificationDocumentFaceMismatch =>
      'Your face does not match the photo in the document.';

  @override
  String get verificationFailureSessionExpired => 'The session has expired.';

  @override
  String get verificationFailureImagesUnreadable =>
      'The images could not be read.';

  @override
  String get verificationFailureNoFace => 'No face detected.';

  @override
  String get verificationFailureMultipleFaces => 'Only one face should appear.';

  @override
  String get verificationFailureFaceTooSmall => 'Move closer to the camera.';

  @override
  String get verificationFailurePoseMismatch =>
      'The requested movements were not recognized.';

  @override
  String get verificationFailureDuplicateFrames =>
      'Move your head as requested.';

  @override
  String get verificationFailureInconsistentIdentity =>
      'The face changed during the capture.';

  @override
  String get verificationFailureNoProfilePhoto =>
      'First add a photo to your profile.';

  @override
  String get verificationFailureProfileMismatch =>
      'Your face does not match your profile photo.';

  @override
  String get verificationFailureDailyLimit =>
      'You have reached today\'s limit of attempts. Come back tomorrow.';

  @override
  String get verificationFailureGeneric => 'The verification failed.';

  @override
  String get verificationFailureNoNfc => 'This phone has no NFC reader.';

  @override
  String get verificationFailureNfcDisabled =>
      'Turn on NFC in the phone settings.';

  @override
  String get verificationFailureTagLost =>
      'The document moved. Hold it still against the phone.';

  @override
  String get verificationFailureChipMismatch =>
      'The details entered do not match the chip.';

  @override
  String get verificationFailureUnreadableDocument =>
      'This document cannot be read.';

  @override
  String get verificationFailureChipSilent => 'The chip did not respond.';

  @override
  String get verificationFailureReadFailed => 'The reading failed.';

  @override
  String get verificationFailureConnection =>
      'Can\'t connect. Check your connection.';

  @override
  String get verificationActionRereadDocument => 'Read the document again';

  @override
  String get verificationActionOtherDocument => 'Another document';

  @override
  String get verificationReasonNoFace =>
      'No face detected. Face the camera in a well-lit place.';

  @override
  String get verificationReasonMultipleFaces =>
      'Several faces detected. Stay alone in the frame.';

  @override
  String get verificationReasonFaceTooSmall =>
      'Your face is too far away. Move closer to the camera.';

  @override
  String get verificationReasonPoseMismatch =>
      'The requested poses were not recognized. Follow the instructions carefully.';

  @override
  String get verificationReasonDuplicateFrames =>
      'The images are too similar. Move your head as requested.';

  @override
  String get verificationReasonInconsistentIdentity =>
      'The images do not show the same person. Start again on your own.';

  @override
  String get verificationReasonNoProfilePhoto =>
      'First add to your profile a photo where your face is clearly visible.';

  @override
  String get verificationReasonProfileMismatch =>
      'Your face does not match your main photo. Choose a recent photo where you are clearly visible.';

  @override
  String get verificationReasonDailyLimit =>
      'You have reached the limit of attempts for today. Come back tomorrow.';

  @override
  String get verificationReasonSessionExpired =>
      'The session has expired. Start again.';

  @override
  String get verificationReasonSessionInvalid =>
      'The session is no longer valid. Start again.';

  @override
  String get verificationReasonImagesUnreadable =>
      'The images could not be read. Start again.';

  @override
  String get verificationReasonAppUpdate =>
      'Update the app to verify your profile.';

  @override
  String get verificationReasonChipAuth =>
      'The document\'s chip could not be authenticated.';

  @override
  String get verificationReasonUnderage => 'You must be at least 18.';

  @override
  String get verificationReasonNetwork =>
      'Can\'t connect. Check your network and try again.';

  @override
  String get verificationReasonGeneric =>
      'Something went wrong. Try again in a moment.';

  @override
  String get verificationNfcAlertApproach =>
      'Bring your document close to the top of the phone.';

  @override
  String get verificationNfcAlertAuthenticating =>
      'Don\'t move. Secure connection…';

  @override
  String get verificationNfcAlertReadingPhoto => 'Reading the photo… 40%';

  @override
  String get verificationNfcAlertReadingSignature =>
      'Reading the signature… 85%';

  @override
  String get verificationNfcAlertDone => 'Done.';

  @override
  String get webSessionsTitle => 'Connected computers';

  @override
  String get webSessionsSectionLabel => 'MAZL on computer';

  @override
  String get webSessionsIntro =>
      'Use MAZL on a computer at app.mazl.app. Each computer stays connected for 7 days at most.';

  @override
  String get webSessionsConnect => 'Connect a computer';

  @override
  String get webSessionsConnected => 'Computer connected.';

  @override
  String get webSessionsLoadFailed =>
      'We couldn\'t load your computers. Check your connection.';

  @override
  String get webSessionsEmpty => 'No computer is connected right now.';

  @override
  String get webSessionsListLabel => 'Computers';

  @override
  String get webSessionsRevoke => 'Disconnect';

  @override
  String webSessionsRevokeNamed(String browser) {
    return 'Disconnect $browser';
  }

  @override
  String get webSessionsRevokeFailed =>
      'We couldn\'t disconnect this computer. Please try again.';

  @override
  String get webSessionsRevokeAll => 'Disconnect all computers';

  @override
  String get webSessionsRevokeAllTitle => 'Disconnect all computers?';

  @override
  String get webSessionsRevokeAllBody =>
      'You\'ll have to sign in again on each computer.';

  @override
  String get webSessionsRevokeAllConfirm => 'Disconnect all';

  @override
  String get webSessionsRevokeAllFailed =>
      'We couldn\'t disconnect the computers. Please try again.';

  @override
  String get webSessionsMethodQr => 'Connected by QR code';

  @override
  String get webSessionsMethodGoogle => 'Connected with Google';

  @override
  String get webSessionsMethodApple => 'Connected with Apple';

  @override
  String get webSessionsActiveNow => 'Active just now';

  @override
  String webSessionsActiveMinutes(int count) {
    return 'Active $count min ago';
  }

  @override
  String webSessionsActiveHours(int count) {
    return 'Active $count h ago';
  }

  @override
  String get webSessionsActiveYesterday => 'Active yesterday';

  @override
  String webSessionsActiveDays(int count) {
    return 'Active $count d ago';
  }

  @override
  String webSessionsClockTime(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get webSessionsScanInstruction =>
      'Scan the QR code shown on app.mazl.app';

  @override
  String get webSessionsScanCameraLabel => 'QR code scanning camera';

  @override
  String get webSessionsCameraUnavailable =>
      'The camera isn\'t accessible. Allow camera access in your iPhone settings to scan a code.';

  @override
  String get webSessionsScanNotMazl => 'This QR code isn\'t a MAZL code.';

  @override
  String get webSessionsScanExpired =>
      'This code has expired. Show a new code on the computer.';

  @override
  String get webSessionsScanTooMany =>
      'Too many attempts. Wait a moment before trying again.';

  @override
  String get webSessionsApproveInvalid =>
      'This request is no longer valid. Show a new code on the computer.';

  @override
  String get webSessionsConnectionProblem =>
      'Couldn\'t connect. Check your network, then try again.';

  @override
  String get webSessionsGenericProblem =>
      'Something went wrong. Please try again in a moment.';

  @override
  String get webSessionsConfirmLabel => 'Signing in to MAZL on a computer';

  @override
  String get webSessionsConfirmTitle => 'Connect this computer?';

  @override
  String get webSessionsConfirmBrowser => 'Browser';

  @override
  String get webSessionsConfirmAddress => 'Address';

  @override
  String get webSessionsConfirmAskedAt => 'Requested at';

  @override
  String get webSessionsConfirmWarning =>
      'Only scan the code shown on your own computer. If someone asks you to scan a code, decline.';

  @override
  String get webSessionsConfirmApprove => 'Connect';

  @override
  String get webSessionsConfirmDeny => 'Decline';
}
