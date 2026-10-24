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
  String get coupleSpaceStatusSingle => 'Single';

  @override
  String get coupleSpaceStatusDating => 'Dating';

  @override
  String get coupleSpaceStatusInRelationship => 'In a relationship';

  @override
  String get coupleSpaceStatusEngaged => 'Engaged';

  @override
  String get coupleSpaceStatusMarried => 'Married';

  @override
  String coupleSpaceDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '$count week',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '$count month',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '$count year',
    );
    return '$_temp0';
  }

  @override
  String get coupleSpaceAnniversaryTag => 'Happy MAZL anniversary';

  @override
  String coupleSpaceAnniversaryDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days together',
      one: 'day together',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceAnniversaryWith(String name) {
    return 'with $name';
  }

  @override
  String coupleSpaceAnniversaryNext(String milestone, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return 'Next: $milestone in $_temp0';
  }

  @override
  String get coupleSpaceAnniversaryHappy => 'Happy anniversary';

  @override
  String coupleSpaceAnniversaryDaysWith(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0 with $name';
  }

  @override
  String get coupleSpaceAnniversaryThanks => 'Thanks';

  @override
  String coupleSpaceAnniversaryShare(int count, String milestone) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return 'We\'re celebrating $_temp0 together on MAZL. $milestone';
  }

  @override
  String get coupleSpaceMilestonesTitle => 'Your milestones';

  @override
  String coupleSpaceMilestoneIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return 'in $_temp0';
  }

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
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Phone language';
}
