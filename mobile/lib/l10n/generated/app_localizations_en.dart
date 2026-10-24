// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get chatHeaderOnline => 'Online';

  @override
  String get chatHeaderVideoCall => 'Video call';

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
  String get icebreakerWidgetTitle => 'Need inspiration?';

  @override
  String get icebreakerWidgetSubtitle =>
      'Here are a few ideas to break the ice';

  @override
  String get icebreakerTopicFallback => 'that';

  @override
  String icebreakerPromptLoved(String promptText, String followUp) {
    return 'I loved your answer to \"$promptText\". $followUp';
  }

  @override
  String icebreakerPromptSmiled(String promptText) {
    return 'Your answer about \"$promptText\" made me smile. Can you tell me more?';
  }

  @override
  String icebreakerPromptCurious(String answer, String topic) {
    return 'I\'m curious why you answered \"$answer\" to the question about $topic';
  }

  @override
  String get icebreakerFollowUpIntrigued => 'I\'m intrigued.';

  @override
  String get icebreakerFollowUpKnowMore => 'I\'d love to know more.';

  @override
  String get icebreakerFollowUpTellMe => 'Will you tell me about it?';

  @override
  String get icebreakerFollowUpInteresting => 'That sounds interesting.';

  @override
  String get icebreakerBioTravelRecent =>
      'Where have you travelled recently? I\'d love to hear your stories.';

  @override
  String get icebreakerBioTravelDream => 'What\'s your next dream destination?';

  @override
  String get icebreakerBioMusicGenre =>
      'What kind of music are you listening to lately?';

  @override
  String get icebreakerBioMusicConcert => 'Been to a good concert lately?';

  @override
  String get icebreakerBioCookingNow => 'What are you cooking these days?';

  @override
  String get icebreakerBioCookingSignature => 'What\'s your signature dish?';

  @override
  String get icebreakerBioSportWhich => 'Which sport do you play?';

  @override
  String get icebreakerBioSportWatchOrPlay =>
      'Do you prefer watching or playing?';

  @override
  String get icebreakerBioReadingNow => 'What are you reading right now?';

  @override
  String get icebreakerBioReadingLastBook =>
      'What\'s the last book that really stuck with you?';

  @override
  String get icebreakerBioCinemaRecent => 'Seen any good movies lately?';

  @override
  String get icebreakerBioCinemaOrSeries => 'Do you prefer movies or series?';

  @override
  String get icebreakerBioHikingTrails =>
      'Do you know any nice trails around here?';

  @override
  String get icebreakerBioHikingBest => 'What\'s your best hike ever?';

  @override
  String get icebreakerBioPhotoSubjects => 'What do you mostly take photos of?';

  @override
  String get icebreakerBioPhotoCamera => 'What camera do you use?';

  @override
  String get icebreakerOrthodoxSynagogue =>
      'Do you have a favourite synagogue nearby?';

  @override
  String get icebreakerOrthodoxShabbat => 'How do you usually spend Shabbat?';

  @override
  String get icebreakerOrthodoxKosherRestaurant =>
      'Do you have a favourite kosher restaurant?';

  @override
  String get icebreakerTraditionalTraditions =>
      'Which Jewish traditions matter most to you?';

  @override
  String get icebreakerTraditionalShabbat =>
      'How do you usually celebrate Shabbat?';

  @override
  String get icebreakerTraditionalHoliday =>
      'Do you have a favourite Jewish holiday?';

  @override
  String get icebreakerSecularCulture =>
      'What\'s your relationship with Jewish culture?';

  @override
  String get icebreakerSecularFamilyTraditions =>
      'Are there family traditions you keep?';

  @override
  String get icebreakerSecularHolidays => 'Which holidays do you celebrate?';

  @override
  String get icebreakerDefaultHoliday =>
      'What\'s your favourite Jewish holiday?';

  @override
  String get icebreakerDefaultFamilyTraditions =>
      'Do you have any special family traditions?';

  @override
  String get icebreakerDefaultPracticingFamily =>
      'Did you grow up in a practising family?';

  @override
  String icebreakerLocationKnowWell(String location) {
    return 'Do you know $location well? What would you recommend?';
  }

  @override
  String icebreakerLocationFavoriteSpot(String location) {
    return 'What\'s your favourite spot in $location?';
  }

  @override
  String icebreakerLocationOriginallyFrom(String location) {
    return 'Are you originally from $location or did you move there?';
  }

  @override
  String icebreakerLocationRestaurant(String location) {
    return 'Is there a good restaurant you would recommend in $location?';
  }

  @override
  String get icebreakerGenericDinnerGuest =>
      'If you could have dinner with anyone, living or dead, who would it be?';

  @override
  String get icebreakerGenericPerfectDay =>
      'What\'s your idea of a perfect day?';

  @override
  String get icebreakerGenericHiddenTalent =>
      'Do you have a hidden talent few people know about?';

  @override
  String get icebreakerGenericSpontaneous =>
      'What\'s the most spontaneous thing you\'ve ever done?';

  @override
  String get icebreakerGenericSeaOrMountain =>
      'Do you prefer holidays by the sea or in the mountains?';

  @override
  String get icebreakerGenericLottery =>
      'If you won the lottery tomorrow, what would you do first?';

  @override
  String get icebreakerGenericGuiltyPleasure => 'What\'s your guilty pleasure?';

  @override
  String get icebreakerGenericDream =>
      'Is there a dream you haven\'t fulfilled yet?';

  @override
  String get icebreakerGenericBestAdvice =>
      'What\'s the best advice you\'ve ever been given?';

  @override
  String get icebreakerGenericBreakfastOrDinner =>
      'Do you prefer breakfast or dinner out?';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Phone language';
}
