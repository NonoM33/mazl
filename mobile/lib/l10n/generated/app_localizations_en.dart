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
  String get profileMatchLabel => 'Match';

  @override
  String get profileMatchTitle => 'It\'s a match.';

  @override
  String profileMatchBody(String name) {
    return 'You can now chat with $name.';
  }

  @override
  String get profileMatchBodyUnnamed => 'You can now chat with this person.';

  @override
  String get profileSendMessage => 'Send a message';

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
  String get profileCoupleElsewhereBody => 'You\'re already in couple mode with someone else.';

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
  String get profileCoupleAvailableBody => 'You matched. Turn on couple mode to share activities together.';

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
  String get profileCompatibilityUnavailable => 'Compatibility isn\'t available right now.';

  @override
  String profileCompatibilityUnlockTitle(String name) {
    return 'Find out your compatibility score with $name.';
  }

  @override
  String get profileCompatibilityUnlockBody => 'Based on your practices, intentions and values.';

  @override
  String get profileCompatibilityUnlock => 'Unlock with mazl+';

  @override
  String get profileFactorIntentions => 'Intentions';

  @override
  String get profileFactorAge => 'Age';

  @override
  String get profileFactorDistance => 'Distance';

  @override
  String get profileVerdictSameIntention => 'You\'re looking for the same thing';

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
  String profileCompatibilityCriteria(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count criteria analyzed',
      one: '1 criterion analyzed',
    );
    return '$_temp0';
  }

  @override
  String get profileCompatibilityScoreTitle => 'Compatibility score';

  @override
  String profileCompatibilityWith(String name) {
    return 'With $name';
  }

  @override
  String get profileCompatibilityDetails => 'Details';

  @override
  String get profileCompatibilityIncomplete => 'Complete your profiles to see more details';

  @override
  String get profileCompatibilityNote => 'The score is based on your preferences and what you have in common';

  @override
  String get profileCompatibilityGotIt => 'Got it';

  @override
  String get profilePromptsMine => 'My prompts';

  @override
  String get profilePromptsSubtitle => 'Answer questions to show your personality';

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
  String get profilePromptsGetToKnowMe => 'Get to know me';

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
  String get profileIntentionMarriageDescription => 'I\'m looking for my future spouse';

  @override
  String get profileIntentionSeriousDescription => 'I\'m looking for something lasting';

  @override
  String get profileIntentionOpenDescription => 'We\'ll see where it goes';

  @override
  String get profileIntentionFriendsFirstDescription => 'Let\'s start by getting to know each other';

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
  String get profileSetupAboutYouSubtitle => 'This information will be visible on your profile';

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
  String get profileSetupPhotosTip => 'Profiles with good-quality photos get 3x more matches.';

  @override
  String get profileSetupPracticeTitle => 'Your practice';

  @override
  String get profileSetupPracticeSubtitle => 'Help us find someone who suits you';

  @override
  String get profileSetupLookingTitle => 'What you\'re looking for';

  @override
  String get profileSetupLookingSubtitle => 'Help us show you the right profiles';

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
  String get profileShadchanNote => 'Our AI Shadchan will use these preferences to suggest compatible profiles.';

  @override
  String get profileReportThisProfile => 'Report this profile';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Phone language';
}
