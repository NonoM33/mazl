// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get commonCancel => 'ביטול';

  @override
  String get commonContinue => 'המשך';

  @override
  String get commonRetry => 'לנסות שוב';

  @override
  String get commonClose => 'סגירה';

  @override
  String get commonBack => 'חזרה';

  @override
  String get errorTimeout => 'הזמן הקצוב חלף. יש לבדוק את החיבור.';

  @override
  String get errorNetwork => 'אין חיבור. יש לבדוק את הרשת ולנסות שוב.';

  @override
  String get errorServer => 'השרת אינו זמין. אפשר לנסות שוב בעוד רגע.';

  @override
  String get errorSessionExpired => 'פג תוקף החיבור. יש להתחבר מחדש.';

  @override
  String get errorForbidden => 'פעולה זו אינה מורשית.';

  @override
  String get errorNotFound => 'לא נמצא: הפריט כבר לא קיים.';

  @override
  String get errorConflict => 'פעולה זו כבר אינה אפשרית.';

  @override
  String get errorTooLarge => 'הקובץ גדול מדי.';

  @override
  String get errorRateLimited => 'יותר מדי ניסיונות. כדאי להמתין רגע.';

  @override
  String get errorInvalid => 'הבקשה נדחתה. יש לבדוק את הפרטים שהוזנו.';

  @override
  String get errorUnknown => 'משהו השתבש. אפשר לנסות שוב.';

  @override
  String get commonSave => 'שמירה';

  @override
  String get commonDelete => 'מחיקה';

  @override
  String get commonRemove => 'הסרה';

  @override
  String get commonSkip => 'דילוג';

  @override
  String get commonSee => 'הצגה';

  @override
  String get commonShare => 'שיתוף';

  @override
  String get commonReport => 'דיווח';

  @override
  String get commonOk => 'אישור';

  @override
  String get commonLater => 'אחר כך';

  @override
  String get commonToday => 'היום';

  @override
  String get commonYesterday => 'אתמול';

  @override
  String get commonNotSpecified => 'לא צוין';

  @override
  String get commonLoadError => 'שגיאה בטעינה';

  @override
  String get coupleSpaceTabActivities => 'פעילויות';

  @override
  String get coupleSpaceTabCalendar => 'לוח שנה';

  @override
  String get coupleSpaceTabEvents => 'אירועים';

  @override
  String get coupleSpaceTabSpace => 'המרחב שלנו';

  @override
  String get coupleSpaceTitle => 'המרחב שלנו';

  @override
  String get coupleSpaceSettingsTooltip => 'הגדרות';

  @override
  String get coupleSpaceYou => 'אני';

  @override
  String get coupleSpacePartnerFallback => 'החצי השני';

  @override
  String coupleSpaceTogetherSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים',
      two: 'יומיים',
      one: 'יום אחד',
    );
    return 'יחד כבר $_temp0';
  }

  @override
  String get coupleSpaceStoryBegins => 'הסיפור שלכם מתחיל';

  @override
  String get coupleSpaceStatSavedActivities => 'פעילויות\nשמורות';

  @override
  String get coupleSpaceStatUpcomingEvents => 'אירועים\nקרובים';

  @override
  String get coupleSpaceStatMemories => 'זיכרונות\nשנוצרו';

  @override
  String get coupleSpaceQuickActions => 'פעולות מהירות';

  @override
  String get coupleSpaceQuickAddMemory => 'הוספת\nזיכרון';

  @override
  String get coupleSpaceQuickAddBucket => 'הוספה לרשימת\nהמשאלות';

  @override
  String get coupleSpaceQuickAddDate => 'הוספת\nתאריך';

  @override
  String get coupleSpaceMemoriesTitle => 'הזיכרונות שלנו';

  @override
  String get coupleSpaceMemoriesEmptyTitle => 'עדיין אין זיכרונות';

  @override
  String get coupleSpaceMemoriesEmptyHint =>
      'אפשר להוסיף את הזיכרונות הראשונים שלכם יחד.';

  @override
  String get coupleSpaceBucketTitle => 'רשימת משאלות';

  @override
  String coupleSpaceBucketProgress(int done, int total) {
    return 'רשימת משאלות · $done/$total';
  }

  @override
  String get coupleSpaceBucketEmptyTitle => 'רשימת המשאלות ריקה';

  @override
  String get coupleSpaceBucketEmptyHint => 'אפשר להוסיף חוויות לעשות יחד.';

  @override
  String get coupleSpaceDatesTitle => 'תאריכים חשובים';

  @override
  String get coupleSpaceSeeAll => 'להציג הכול';

  @override
  String get coupleSpaceDatesEmptyTitle => 'אין תאריכים חשובים';

  @override
  String get coupleSpaceDatesEmptyHint => 'אפשר להוסיף ימי שנה, חגים ועוד.';

  @override
  String get coupleSpaceBadgesTitle => 'התגים שלנו';

  @override
  String get coupleSpaceBadgesEmptyTitle => 'עדיין אין תגים';

  @override
  String get coupleSpaceBadgesEmptyHint => 'פעילויות משותפות פותחות תגים.';

  @override
  String get coupleSpaceGoalDone => 'היעד הושג';

  @override
  String get coupleSpaceGoalFailed =>
      'לא ניתן לסמן את היעד כהושג. אפשר לנסות שוב.';

  @override
  String coupleSpaceRefreshFailed(String reason) {
    return 'לא ניתן לרענן. $reason';
  }

  @override
  String get coupleSpaceLoadFailedTitle => 'לא ניתן לטעון';

  @override
  String get coupleSpaceSheetAdd => 'להוסיף';

  @override
  String get coupleSpaceAddMemoryTitle => 'להוסיף זיכרון';

  @override
  String get coupleSpaceFieldTitle => 'כותרת';

  @override
  String get coupleSpaceFieldDescription => 'תיאור';

  @override
  String get coupleSpaceAddBucketTitle => 'להוסיף לרשימת המשאלות';

  @override
  String get coupleSpaceBucketFieldLabel => 'מה רוצים לעשות יחד?';

  @override
  String get coupleSpaceBucketFieldHint => 'למשל: לראות את זוהר הצפון';

  @override
  String get coupleSpaceAddDateTitle => 'להוסיף תאריך חשוב';

  @override
  String get coupleSpaceDateFieldHint => 'למשל: יום השנה שלנו';

  @override
  String get coupleSpaceFieldDate => 'תאריך';

  @override
  String coupleSpaceAddFailed(String reason) {
    return 'לא ניתן להוסיף. $reason';
  }

  @override
  String get coupleSpaceSetupTitle => 'מצב זוגי';

  @override
  String get coupleSpaceSetupWho => 'עם מי?';

  @override
  String get coupleSpaceSetupSend => 'לשלוח את הבקשה';

  @override
  String get coupleSpaceSetupNoMatches => 'עדיין אין התאמות.';

  @override
  String get coupleSpaceSetupMatchesError => 'לא ניתן לטעון את ההתאמות.';

  @override
  String get coupleSpaceSetupSentTitle => 'הבקשה נשלחה';

  @override
  String coupleSpaceSetupSentBody(String name) {
    return 'הבקשה ממתינה לאישור של $name. נעדכן ברגע שתהיה תשובה.';
  }

  @override
  String get coupleSpaceSetupSentBodyAnonymous =>
      'הבקשה ממתינה לאישור של האדם הזה. נעדכן ברגע שתהיה תשובה.';

  @override
  String get coupleSpaceSetupGotIt => 'הבנתי';

  @override
  String get coupleSpaceSetupCancelRequest => 'לבטל את הבקשה';

  @override
  String get coupleSpaceMazelTovTitle => 'מזל טוב';

  @override
  String coupleSpaceMazelTovCongrats(String name) {
    return 'ברכות לך ול־$name';
  }

  @override
  String get coupleSpaceMazelTovWelcome => 'MAZL מלווה אתכם בשלב החדש הזה.';

  @override
  String get coupleSpaceMazelTovStart => 'מתחילים את ההרפתקה שלנו';

  @override
  String coupleSpaceRequestTitle(String name) {
    return 'התקבלה בקשה מ־$name להפעלת מצב זוגי';
  }

  @override
  String get coupleSpaceRequestTitleAnonymous =>
      'התקבלה בקשה להפעלת מצב זוגי מהאדם הזה';

  @override
  String get coupleSpaceRequestAccept => 'לאשר';

  @override
  String get coupleSpaceRequestDecline => 'לא, תודה';

  @override
  String coupleSpaceFlowDeclinedNamed(String name) {
    return 'הבקשה שלך אל $name לא אושרה.';
  }

  @override
  String get coupleSpaceFlowDeclined => 'הבקשה שלך לא יצאה לפועל.';

  @override
  String get coupleSpaceFlowEnded => 'מצב זוגי הסתיים.';

  @override
  String get coupleSpaceArchiveMessage =>
      'מצאתי אהבה ב־Mazl, ואני כבר לא בחיפוש. בהצלחה!';

  @override
  String get coupleSpaceFailNotMatched => 'מצב זוגי אפשר להפעיל רק עם התאמה.';

  @override
  String get coupleSpaceFailAlreadyInCouple => 'אחד מכם כבר במצב זוגי.';

  @override
  String get coupleSpaceFailRequestPending => 'כבר יש בקשה ממתינה עם האדם הזה.';

  @override
  String get coupleSpaceFailRequestGone => 'הבקשה הזו כבר לא ממתינה.';

  @override
  String get coupleSpaceFailUnavailable => 'אי אפשר לפנות לאדם הזה כרגע.';

  @override
  String get coupleSpaceFailSelf => 'אי אפשר לשלוח בקשה לעצמך.';

  @override
  String get coupleSpaceFailNotInCouple => 'מצב זוגי אינו פעיל.';

  @override
  String get coupleSpaceFailCannotLeave => 'לא ניתן לצאת ממצב זוגי כרגע.';

  @override
  String get coupleSpaceFailUnknown => 'משהו השתבש. אפשר לנסות שוב בעוד רגע.';

  @override
  String get coupleSpaceFailEventFull => 'האירוע מלא.';

  @override
  String get coupleSpaceFailServer => 'השרת לא הצליח להשיב. אפשר לנסות שוב.';

  @override
  String get coupleSpaceFailUnexpected => 'התקבלה תשובה לא צפויה מהשרת.';

  @override
  String get coupleSpaceStatusSingle => 'לא בזוגיות';

  @override
  String get coupleSpaceStatusDating => 'בתקופת היכרות';

  @override
  String get coupleSpaceStatusInRelationship => 'בזוגיות';

  @override
  String get coupleSpaceStatusEngaged => 'בתקופת אירוסין';

  @override
  String get coupleSpaceStatusMarried => 'בנישואין';

  @override
  String coupleSpaceDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים',
      two: 'יומיים',
      one: 'יום אחד',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שבועות',
      two: 'שבועיים',
      one: 'שבוע אחד',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count חודשים',
      two: 'חודשיים',
      one: 'חודש אחד',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שנים',
      two: 'שנתיים',
      one: 'שנה אחת',
    );
    return '$_temp0';
  }

  @override
  String get coupleSpaceAnniversaryTag => 'יום שנה שמח ב־MAZL';

  @override
  String coupleSpaceAnniversaryDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ימים יחד',
      one: 'יום יחד',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceAnniversaryWith(String name) {
    return 'עם $name';
  }

  @override
  String coupleSpaceAnniversaryNext(String milestone, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים',
      two: 'יומיים',
      one: 'יום אחד',
    );
    return 'הבא: $milestone בעוד $_temp0';
  }

  @override
  String get coupleSpaceAnniversaryHappy => 'יום שנה שמח';

  @override
  String coupleSpaceAnniversaryDaysWith(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים',
      two: 'יומיים',
      one: 'יום אחד',
    );
    return '$_temp0 עם $name';
  }

  @override
  String get coupleSpaceAnniversaryThanks => 'תודה';

  @override
  String coupleSpaceAnniversaryShare(int count, String milestone) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים',
      two: 'יומיים',
      one: 'יום אחד',
    );
    return 'חוגגים $_temp0 יחד ב־MAZL. $milestone';
  }

  @override
  String get coupleSpaceMilestonesTitle => 'אבני הדרך שלכם';

  @override
  String coupleSpaceMilestoneIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ימים',
      two: 'יומיים',
      one: 'יום אחד',
    );
    return 'בעוד $_temp0';
  }

  @override
  String get coupleSpaceCalendarTitle => 'לוח שנה';

  @override
  String get coupleSpaceCalendarShabbatIdeas => 'רעיונות לשבת הזו';

  @override
  String get coupleSpaceCalendarUpcoming => 'החגים הקרובים';

  @override
  String get coupleSpaceCalendarPrevMonth => 'החודש הקודם';

  @override
  String get coupleSpaceCalendarNextMonth => 'החודש הבא';

  @override
  String get coupleSpaceCalendarOngoing => 'מתקיים עכשיו';

  @override
  String coupleSpaceCalendarCountdown(int count) {
    return 'בעוד $count ימים';
  }

  @override
  String get coupleSpaceCalendarIdeas => 'רעיונות לזוג';

  @override
  String coupleSpaceCalendarRangeSameMonth(
    String startDay,
    String endDay,
    String month,
  ) {
    return '$startDay – $endDay $month';
  }

  @override
  String coupleSpaceCalendarRangeOtherMonth(String start, String end) {
    return '$start – $end';
  }

  @override
  String get jewishCalendarShabbatTitle => 'השבת הזו';

  @override
  String jewishCalendarParashat(String name) {
    return 'פרשת $name';
  }

  @override
  String jewishCalendarParshaPair(String first, String second) {
    return '$first־$second';
  }

  @override
  String get jewishCalendarCandleLighting => 'הדלקת נרות';

  @override
  String get jewishCalendarHavdalah => 'הבדלה';

  @override
  String get jewishCalendarCategoryPreparation => 'הכנות';

  @override
  String get jewishCalendarCategorySpiritual => 'רוחניות';

  @override
  String get jewishCalendarCategoryRelaxation => 'רגיעה';

  @override
  String get jewishCalendarActivityShabbatDinnerTitle => 'להכין את הסעודה ביחד';

  @override
  String get jewishCalendarActivityShabbatDinnerBody =>
      'לאפות חלה ולבשל את סעודת החג';

  @override
  String get jewishCalendarActivityShabbatCandlesTitle => 'להדליק נרות';

  @override
  String get jewishCalendarActivityShabbatCandlesBody => 'רגע רוחני משותף';

  @override
  String get jewishCalendarActivityShabbatWalkTitle => 'טיול שבת';

  @override
  String get jewishCalendarActivityShabbatWalkBody => 'טיול רגוע אחרי הסעודה';

  @override
  String get jewishCalendarActivityShabbatParashaTitle => 'לימוד פרשת השבוע';

  @override
  String get jewishCalendarActivityShabbatParashaBody =>
      'ללמוד ביחד את פרשת השבוע';

  @override
  String get jewishCalendarActivityPesachSederTitle => 'להכין את הסדר';

  @override
  String get jewishCalendarActivityPesachSederBody => 'לערוך את השולחן ביחד';

  @override
  String get jewishCalendarActivityPesachCleaningTitle => 'ניקיונות לפסח';

  @override
  String get jewishCalendarActivityPesachCleaningBody => 'ניקיון אביב כצוות';

  @override
  String get jewishCalendarHolidayRoshHashanaName => 'ראש השנה';

  @override
  String get jewishCalendarHolidayRoshHashanaDescription =>
      'השנה החדשה היהודית';

  @override
  String get jewishCalendarHolidayYomKippurName => 'יום כיפור';

  @override
  String get jewishCalendarHolidayYomKippurDescription => 'יום הסליחה והכפרה';

  @override
  String get jewishCalendarHolidaySukkotName => 'סוכות';

  @override
  String get jewishCalendarHolidaySukkotDescription => 'חג הסוכות';

  @override
  String get jewishCalendarHolidaySheminiAtzeretName => 'שמיני עצרת';

  @override
  String get jewishCalendarHolidaySheminiAtzeretDescription =>
      'היום השמיני של העצרת';

  @override
  String get jewishCalendarHolidaySimchatTorahName => 'שמחת תורה';

  @override
  String get jewishCalendarHolidaySimchatTorahDescription => 'השמחה בתורה';

  @override
  String get jewishCalendarHolidayHanukkahName => 'חנוכה';

  @override
  String get jewishCalendarHolidayHanukkahDescription => 'חג האורים';

  @override
  String get jewishCalendarHolidayTuBishvatName => 'ט״ו בשבט';

  @override
  String get jewishCalendarHolidayTuBishvatDescription => 'ראש השנה לאילנות';

  @override
  String get jewishCalendarHolidayPurimName => 'פורים';

  @override
  String get jewishCalendarHolidayPurimDescription => 'חג הגורלות';

  @override
  String get jewishCalendarHolidayPesachName => 'פסח';

  @override
  String get jewishCalendarHolidayPesachDescription => 'חג החירות';

  @override
  String get jewishCalendarHolidayYomHashoahName => 'יום השואה';

  @override
  String get jewishCalendarHolidayYomHashoahDescription =>
      'יום הזיכרון לשואה ולגבורה';

  @override
  String get jewishCalendarHolidayYomHazikaronName => 'יום הזיכרון';

  @override
  String get jewishCalendarHolidayYomHazikaronDescription =>
      'יום הזיכרון לחללי צה״ל';

  @override
  String get jewishCalendarHolidayYomHaatzmautName => 'יום העצמאות';

  @override
  String get jewishCalendarHolidayYomHaatzmautDescription =>
      'יום העצמאות של ישראל';

  @override
  String get jewishCalendarHolidayYomYerushalayimName => 'יום ירושלים';

  @override
  String get jewishCalendarHolidayYomYerushalayimDescription =>
      'יום איחוד ירושלים';

  @override
  String get jewishCalendarHolidayLagBaomerName => 'ל״ג בעומר';

  @override
  String get jewishCalendarHolidayLagBaomerDescription => 'היום ה־33 בעומר';

  @override
  String get jewishCalendarHolidayShavuotName => 'שבועות';

  @override
  String get jewishCalendarHolidayShavuotDescription => 'מתן תורה';

  @override
  String get jewishCalendarIdeaFestiveDinner => 'סעודת חג';

  @override
  String get jewishCalendarIdeaTashlich => 'תשליך ביחד';

  @override
  String get jewishCalendarIdeaMutualForgiveness => 'לבקש סליחה הדדית';

  @override
  String get jewishCalendarIdeaBuildSukkah => 'לבנות סוכה ביחד';

  @override
  String get jewishCalendarIdeaInviteFriends => 'להזמין חברים';

  @override
  String get jewishCalendarIdeaPrayerForRain => 'תפילת גשם';

  @override
  String get jewishCalendarIdeaDanceWithTorah => 'לרקוד עם ספר התורה';

  @override
  String get jewishCalendarIdeaLightCandlesTogether => 'להדליק נרות ביחד';

  @override
  String get jewishCalendarIdeaHomemadeSufganiyot => 'סופגניות ביתיות';

  @override
  String get jewishCalendarIdeaCoupleCostumes => 'תחפושות זוגיות';

  @override
  String get jewishCalendarIdeaMishloachManot => 'משלוח מנות ביחד';

  @override
  String get jewishCalendarIdeaRomanticSeder => 'סדר רומנטי';

  @override
  String get jewishCalendarIdeaTripToIsrael => 'טיול בישראל';

  @override
  String get jewishCalendarIdeaIsraeliBarbecue => 'על האש ישראלי';

  @override
  String get jewishCalendarIdeaConcertOrParty => 'הופעה או מסיבה';

  @override
  String get jewishCalendarIdeaCampfire => 'מדורה';

  @override
  String get jewishCalendarIdeaPicnic => 'פיקניק';

  @override
  String get jewishCalendarIdeaHomemadeCheesecake => 'עוגת גבינה ביתית';

  @override
  String get jewishCalendarIdeaStudyNight => 'ליל לימוד';

  @override
  String get jewishCalendarParshaBereshis => 'בראשית';

  @override
  String get jewishCalendarParshaNoach => 'נח';

  @override
  String get jewishCalendarParshaLechLecha => 'לך לך';

  @override
  String get jewishCalendarParshaVayera => 'וירא';

  @override
  String get jewishCalendarParshaChayeiSara => 'חיי שרה';

  @override
  String get jewishCalendarParshaToldos => 'תולדות';

  @override
  String get jewishCalendarParshaVayetzei => 'ויצא';

  @override
  String get jewishCalendarParshaVayishlach => 'וישלח';

  @override
  String get jewishCalendarParshaVayeshev => 'וישב';

  @override
  String get jewishCalendarParshaMiketz => 'מקץ';

  @override
  String get jewishCalendarParshaVayigash => 'ויגש';

  @override
  String get jewishCalendarParshaVayechi => 'ויחי';

  @override
  String get jewishCalendarParshaShemos => 'שמות';

  @override
  String get jewishCalendarParshaVaera => 'וארא';

  @override
  String get jewishCalendarParshaBo => 'בא';

  @override
  String get jewishCalendarParshaBeshalach => 'בשלח';

  @override
  String get jewishCalendarParshaYisro => 'יתרו';

  @override
  String get jewishCalendarParshaMishpatim => 'משפטים';

  @override
  String get jewishCalendarParshaTerumah => 'תרומה';

  @override
  String get jewishCalendarParshaTetzaveh => 'תצוה';

  @override
  String get jewishCalendarParshaKiSisa => 'כי תשא';

  @override
  String get jewishCalendarParshaVayakhel => 'ויקהל';

  @override
  String get jewishCalendarParshaPekudei => 'פקודי';

  @override
  String get jewishCalendarParshaVayikra => 'ויקרא';

  @override
  String get jewishCalendarParshaTzav => 'צו';

  @override
  String get jewishCalendarParshaShmini => 'שמיני';

  @override
  String get jewishCalendarParshaTazria => 'תזריע';

  @override
  String get jewishCalendarParshaMetzora => 'מצורע';

  @override
  String get jewishCalendarParshaAchreiMos => 'אחרי מות';

  @override
  String get jewishCalendarParshaKedoshim => 'קדושים';

  @override
  String get jewishCalendarParshaEmor => 'אמור';

  @override
  String get jewishCalendarParshaBehar => 'בהר';

  @override
  String get jewishCalendarParshaBechukosai => 'בחוקותי';

  @override
  String get jewishCalendarParshaBamidbar => 'במדבר';

  @override
  String get jewishCalendarParshaNasso => 'נשא';

  @override
  String get jewishCalendarParshaBehaaloscha => 'בהעלותך';

  @override
  String get jewishCalendarParshaShlach => 'שלח';

  @override
  String get jewishCalendarParshaKorach => 'קרח';

  @override
  String get jewishCalendarParshaChukas => 'חוקת';

  @override
  String get jewishCalendarParshaBalak => 'בלק';

  @override
  String get jewishCalendarParshaPinchas => 'פינחס';

  @override
  String get jewishCalendarParshaMatos => 'מטות';

  @override
  String get jewishCalendarParshaMasei => 'מסעי';

  @override
  String get jewishCalendarParshaDevarim => 'דברים';

  @override
  String get jewishCalendarParshaVaeschanan => 'ואתחנן';

  @override
  String get jewishCalendarParshaEikev => 'עקב';

  @override
  String get jewishCalendarParshaReeh => 'ראה';

  @override
  String get jewishCalendarParshaShoftim => 'שופטים';

  @override
  String get jewishCalendarParshaKiSeitzei => 'כי תצא';

  @override
  String get jewishCalendarParshaKiSavo => 'כי תבוא';

  @override
  String get jewishCalendarParshaNitzavim => 'נצבים';

  @override
  String get jewishCalendarParshaVayeilech => 'וילך';

  @override
  String get jewishCalendarParshaHaazinu => 'האזינו';

  @override
  String get jewishCalendarParshaVzosHaberacha => 'וזאת הברכה';

  @override
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageSystem => 'שפת הטלפון';
}
