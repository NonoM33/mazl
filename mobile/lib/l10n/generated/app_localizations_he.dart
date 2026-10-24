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
  String get coupleFeedDashboardSettingsTooltip => 'הגדרות';

  @override
  String get coupleFeedDashboardMe => 'אני';

  @override
  String get coupleFeedDashboardPartnerFallback => 'בן או בת הזוג';

  @override
  String coupleFeedDashboardDaysTogether(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ימים יחד',
      two: 'יומיים יחד',
      one: 'יום אחד יחד',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedDashboardDailyQuestion => 'שאלת היום';

  @override
  String get coupleFeedDashboardAnswer => 'לענות';

  @override
  String get coupleFeedDashboardAnswerHint => 'לכתוב תשובה…';

  @override
  String get coupleFeedDashboardSend => 'לשלוח';

  @override
  String get coupleFeedDashboardAnswerSent =>
      'התשובה נשלחה. בן או בת הזוג יקבלו הודעה.';

  @override
  String get coupleFeedDashboardActivities => 'פעילויות לזוג';

  @override
  String get coupleFeedDashboardMilestones => 'אבני הדרך שלנו';

  @override
  String get coupleFeedDashboardSeeAll => 'לכל הפריטים';

  @override
  String get coupleFeedDashboardEvents => 'אירועים לזוגות';

  @override
  String get coupleFeedDashboardJewishCalendar => 'לוח השנה העברי';

  @override
  String get coupleFeedStoriesTitle => 'סיפורי זוגות';

  @override
  String get coupleFeedDashboardSeeAllStories => 'לכל הסיפורים';

  @override
  String get coupleFeedDashboardEventSampleTitle => 'שיעור בישול כשר';

  @override
  String get coupleFeedDashboardEventSampleWhen =>
      'יום ראשון, 20 בינואר - 15:00';

  @override
  String get coupleFeedDashboardEventSampleTag => 'זוגות';

  @override
  String get coupleFeedDashboardAllEvents => 'לכל האירועים';

  @override
  String get coupleFeedDashboardParasha => 'שבת בשלח';

  @override
  String get coupleFeedDashboardShabbatTimes => 'כניסה: 17:23 - יציאה: 18:34';

  @override
  String get coupleFeedDashboardShabbatDinner => 'סעודה';

  @override
  String get coupleFeedDashboardShabbatPrayer => 'תפילה';

  @override
  String get coupleFeedDashboardShabbatRest => 'מנוחה';

  @override
  String get coupleFeedStoryShareTitle => 'לשתף את סיפור הזוגיות';

  @override
  String get coupleFeedDashboardShareStoryLine =>
      'לעורר השראה בקהילת MAZL עם סיפור הזוגיות';

  @override
  String get coupleFeedDashboardSeeStories => 'לצפות בסיפורים';

  @override
  String get coupleFeedMilestoneFirstWeekTitle => 'שבוע ראשון';

  @override
  String get coupleFeedMilestoneFirstWeekLine => '7 ימים יחד';

  @override
  String get coupleFeedMilestoneFirstMonthTitle => 'חודש ראשון';

  @override
  String get coupleFeedMilestoneFirstMonthLine => '30 ימים של אהבה';

  @override
  String get coupleFeedMilestoneThreeMonthsTitle => 'שלושה חודשים';

  @override
  String get coupleFeedMilestoneThreeMonthsLine => '3 חודשים של אושר';

  @override
  String get coupleFeedMilestoneSixMonthsTitle => 'חצי שנה';

  @override
  String get coupleFeedMilestoneSixMonthsLine => '6 חודשים יד ביד';

  @override
  String get coupleFeedMilestoneFirstYearTitle => 'שנה ראשונה';

  @override
  String get coupleFeedMilestoneFirstYearLine => '365 ימים של MAZL';

  @override
  String get coupleFeedQuestion1 => 'מהו הרגע האהוב בשבוע המשותף?';

  @override
  String get coupleFeedQuestion1Category => 'חיבור';

  @override
  String get coupleFeedQuestion2 =>
      'אם אפשר היה לנסוע לכל מקום, לאן היו נוסעים?';

  @override
  String get coupleFeedQuestion2Category => 'חלומות';

  @override
  String get coupleFeedQuestion3 => 'מה הביא חיוך היום?';

  @override
  String get coupleFeedQuestion3Category => 'יומיום';

  @override
  String get coupleFeedQuestion4 => 'איך היו רוצים לחגוג את השבת הקרובה?';

  @override
  String get coupleFeedQuestion4Category => 'יהדות';

  @override
  String get coupleFeedQuestion4Option1 => 'ארוחה רומנטית בבית';

  @override
  String get coupleFeedQuestion4Option2 => 'הזמנה אצל חברים';

  @override
  String get coupleFeedQuestion4Option3 => 'מסעדה כשרה';

  @override
  String get coupleFeedQuestion4Option4 => 'שבתון קהילתי';

  @override
  String get coupleFeedQuestion5 => 'איזו תכונה הכי מעריכים אצל בן או בת הזוג?';

  @override
  String get coupleFeedQuestion5Category => 'הערכה';

  @override
  String get coupleFeedIdeaShabbatCookingTitle => 'בישול לשבת';

  @override
  String get coupleFeedIdeaShabbatCookingCategory => 'בית';

  @override
  String get coupleFeedIdeaTorahTitle => 'לימוד תורה';

  @override
  String get coupleFeedIdeaDateNightTitle => 'ערב זוגי';

  @override
  String get coupleFeedIdeaDateNightCategory => 'רומנטיקה';

  @override
  String get coupleFeedIdeaSportTitle => 'ספורט ביחד';

  @override
  String get coupleFeedIdeaChesedTitle => 'חסד ביחד';

  @override
  String get coupleFeedIdeaChesedCategory => 'קהילה';

  @override
  String get coupleFeedIdeaTravelCategory => 'הרפתקה';

  @override
  String get coupleFeedCategoryWellness => 'רווחה';

  @override
  String get coupleFeedCategoryGastronomy => 'גסטרונומיה';

  @override
  String get coupleFeedFilterGastronomy => 'אוכל';

  @override
  String get coupleFeedCategoryCulture => 'תרבות';

  @override
  String get coupleFeedCategorySport => 'ספורט';

  @override
  String get coupleFeedCategoryTravel => 'טיולים';

  @override
  String get coupleFeedCategorySpiritual => 'רוחניות';

  @override
  String get coupleFeedCategoryDiy => 'יצירה עצמית';

  @override
  String get coupleFeedCategoryRomantic => 'רומנטי';

  @override
  String get coupleFeedFilterAll => 'הכול';

  @override
  String get coupleFeedEventCategoryDinner => 'ארוחת ערב';

  @override
  String get coupleFeedEventCategoryTasting => 'טעימות';

  @override
  String get coupleFeedEventCategoryParty => 'מסיבה';

  @override
  String get coupleFeedEventCategoryWorkshop => 'סדנה';

  @override
  String get coupleFeedEventCategoryBrunch => 'בראנץ\'';

  @override
  String get coupleFeedEventCategorySpiritual => 'רוחניות';

  @override
  String get coupleFeedEventCategoryTravel => 'סוף שבוע';

  @override
  String get coupleFeedEventCategoryConcert => 'קונצרט';

  @override
  String get coupleFeedEventCategoryGame => 'משחקים';

  @override
  String get coupleFeedEventCategoryOther => 'אירוע';

  @override
  String get coupleFeedPriceFree => 'חינם';

  @override
  String coupleFeedEventPricePerCouple(String price) {
    return '$price לזוג';
  }

  @override
  String coupleFeedDurationMinutes(int minutes) {
    return '$minutes דק׳';
  }

  @override
  String coupleFeedDurationHours(int hours) {
    return '$hours שע׳';
  }

  @override
  String coupleFeedDurationHoursMinutes(int hours, int minutes) {
    return '$hours שע׳ $minutes דק׳';
  }

  @override
  String coupleFeedRatingWithReviews(String rating, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$rating ($countString ביקורות)',
      two: '$rating (2 ביקורות)',
      one: '$rating (ביקורת אחת)',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedKosher => 'כשר';

  @override
  String get coupleFeedFeatured => 'מומלץ';

  @override
  String get coupleFeedPartnerMazl => 'שותף MAZL';

  @override
  String coupleFeedPartnerDiscountMazl(int percent) {
    return 'הנחה של $percent% · שותף MAZL';
  }

  @override
  String coupleFeedPartnerDiscount(int percent) {
    return 'הנחה של $percent% · שותף';
  }

  @override
  String get coupleFeedActivitiesTitle => 'פעילויות';

  @override
  String get coupleFeedSavedTitle => 'פעילויות שמורות';

  @override
  String get coupleFeedActivitiesEmptyTitle => 'אין פעילויות כרגע';

  @override
  String get coupleFeedActivitiesEmptyLine => 'רעיונות חדשים בדרך.';

  @override
  String get coupleFeedRefresh => 'לרענן';

  @override
  String get coupleFeedSeeDetail => 'לצפות בפרטים';

  @override
  String coupleFeedActivitySavedSnack(String title) {
    return '$title נשמר';
  }

  @override
  String coupleFeedActivitySaveCardError(String title) {
    return 'השמירה של ״$title״ נכשלה. אפשר לנסות שוב.';
  }

  @override
  String coupleFeedActivityPassCardError(String title) {
    return 'הדילוג על ״$title״ נכשל. אפשר לנסות שוב.';
  }

  @override
  String get coupleFeedActivityNotFoundTitle => 'הפעילות לא נמצאה';

  @override
  String get coupleFeedActivityNotFoundLine => 'הפעילות כבר לא מוצעת.';

  @override
  String get coupleFeedActivityRemoveError =>
      'הסרת הפעילות נכשלה. אפשר לנסות שוב.';

  @override
  String get coupleFeedActivitySaveError =>
      'שמירת הפעילות נכשלה. אפשר לנסות שוב.';

  @override
  String get coupleFeedActivitySavedConfirm => 'הפעילות נשמרה';

  @override
  String coupleFeedCodeCopied(String code) {
    return 'הקוד $code הועתק';
  }

  @override
  String get coupleFeedRemoveFromSaved => 'להסיר מהפעילויות השמורות';

  @override
  String coupleFeedActivityShareText(String title) {
    return 'רעיון לדייט בשבילנו: \"$title\" (דרך MAZL)';
  }

  @override
  String get coupleFeedPromoCodeLabel => 'קוד קופון MAZL';

  @override
  String get coupleFeedCopyCode => 'להעתיק את הקוד';

  @override
  String get coupleFeedDescription => 'תיאור';

  @override
  String get coupleFeedTags => 'תגיות';

  @override
  String get coupleFeedAddress => 'כתובת';

  @override
  String get coupleFeedContact => 'יצירת קשר';

  @override
  String get coupleFeedCall => 'להתקשר';

  @override
  String get coupleFeedWebsite => 'אתר';

  @override
  String get coupleFeedFromPrice => 'החל מ-';

  @override
  String get coupleFeedBook => 'להזמין';

  @override
  String get coupleFeedSavedRemoveTitle => 'להסיר מהרשימה?';

  @override
  String coupleFeedSavedRemoveBody(String title) {
    return 'להסיר את \"$title\" מהפעילויות השמורות?';
  }

  @override
  String get coupleFeedSavedRemoved => 'הפעילות הוסרה';

  @override
  String coupleFeedSavedRemoveError(String title) {
    return 'הסרת ״$title״ נכשלה. אפשר לנסות שוב.';
  }

  @override
  String get coupleFeedSavedEmptyTitle => 'אין פעילויות שמורות';

  @override
  String get coupleFeedSavedEmptyLine =>
      'מחליקים כרטיס כלפי מעלה כדי לשמור אותו.';

  @override
  String get coupleFeedSavedEmptyAction => 'לגלות פעילויות';

  @override
  String get coupleFeedEventsTitle => 'אירועים';

  @override
  String get coupleFeedEventsUpcoming => 'בקרוב';

  @override
  String coupleFeedEventsRegisteredTab(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'רשומים ($countString)';
  }

  @override
  String get coupleFeedEventsEmptyAll => 'אין אירועים זמינים';

  @override
  String get coupleFeedEventsEmptyRegistered => 'אין הרשמה לאף אירוע';

  @override
  String get coupleFeedEventsDiscover => 'לגלות אירועים';

  @override
  String coupleFeedEventRegisteredSnack(String title) {
    return 'ההרשמה ל-\"$title\" הושלמה';
  }

  @override
  String coupleFeedEventRegisteredSnackDetail(String title) {
    return 'ההרשמה ל-״$title״ הושלמה';
  }

  @override
  String get coupleFeedEventRegisterError => 'ההרשמה נכשלה. אפשר לנסות שוב.';

  @override
  String get coupleFeedEventCancelError => 'ביטול ההרשמה נכשל. אפשר לנסות שוב.';

  @override
  String get coupleFeedEventCancelTitle => 'לבטל את ההרשמה?';

  @override
  String coupleFeedEventCancelBody(String title) {
    return 'לבטל את ההרשמה ל-\"$title\"?';
  }

  @override
  String get coupleFeedEventCancelNo => 'לא';

  @override
  String get coupleFeedEventCancelYes => 'כן, לבטל';

  @override
  String get coupleFeedEventCancelled => 'ההרשמה בוטלה';

  @override
  String get coupleFeedEventFull => 'מלא';

  @override
  String coupleFeedEventSpots(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString מקומות',
      two: '2 מקומות',
      one: 'מקום אחד',
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
      other: 'נותרו $countString מקומות',
      two: 'נותרו 2 מקומות',
      one: 'נותר מקום אחד',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedEventRegister => 'להירשם';

  @override
  String get coupleFeedEventCancelMine => 'לבטל את ההרשמה';

  @override
  String get coupleFeedEventNotFoundTitle => 'האירוע לא נמצא';

  @override
  String get coupleFeedEventNotFoundLine => 'האירוע כבר לא מוצע.';

  @override
  String get coupleFeedEventFactPlace => 'מקום';

  @override
  String get coupleFeedEventFactDressCode => 'קוד לבוש';

  @override
  String get coupleFeedEventFactOrganizer => 'מאורגן על ידי';

  @override
  String get coupleFeedEventIncluded => 'מה כלול';

  @override
  String get coupleFeedLoadFailedTitle => 'הטעינה נכשלה';

  @override
  String get coupleFeedStoriesEmptyTitle => 'עדיין אין סיפורי זוגות';

  @override
  String get coupleFeedStoriesEmptyLine =>
      'סיפורי האהבה הראשונים של MAZL ישותפו בקרוב.';

  @override
  String coupleFeedStoryShareText(String name1, String name2, String excerpt) {
    return '$name1 ו$name2 הכירו ב-MAZL. הסיפור שלהם: $excerpt...';
  }

  @override
  String coupleFeedStoryStatusSince(String status, String date) {
    return '$status · מאז $date';
  }

  @override
  String get coupleFeedStatusDating => 'בזוגיות';

  @override
  String get coupleFeedStatusEngaged => 'באירוסין';

  @override
  String get coupleFeedStatusMarried => 'בנישואין';

  @override
  String get coupleFeedStoryShareLine =>
      'לעורר השראה בקהילת MAZL באמצעות שיתוף סיפור הזוגיות.';

  @override
  String get coupleFeedStoryStatusLabel => 'מצב הזוגיות';

  @override
  String get coupleFeedStoryTextLabel => 'סיפור הזוגיות (לפחות 100 תווים)';

  @override
  String get coupleFeedStoryTextHint => 'איך התחיל הכול? מה משך בצד השני?…';

  @override
  String get coupleFeedStoryPhotosLabel => 'תמונות (לא חובה)';

  @override
  String get coupleFeedStoryPhotosHint => 'להוסיף תמונות של הזוג';

  @override
  String get coupleFeedStorySubmit => 'לשלוח את סיפור הזוגיות';

  @override
  String get coupleFeedStoryTooShort => 'הסיפור צריך להכיל לפחות 100 תווים';

  @override
  String get coupleFeedStoryThanks => 'תודה. הסיפור יפורסם לאחר אישור.';

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
  String get eventsTitle => 'אירועים';

  @override
  String get eventsCalendarTooltip => 'לוח שנה';

  @override
  String get eventsFilterAll => 'הכול';

  @override
  String get eventsFilterHolidays => 'חגים';

  @override
  String get eventsTypeShabbat => 'שבת';

  @override
  String get eventsTypeShabbatDinner => 'ארוחת שבת';

  @override
  String get eventsTypeSpeedDating => 'ספיד דייטינג';

  @override
  String get eventsTypeHoliday => 'חג';

  @override
  String get eventsTypeLecture => 'שיעור';

  @override
  String get eventsTypeSocial => 'חברתי';

  @override
  String get eventsTypeOther => 'אירוע';

  @override
  String get eventsLoading => 'טוען...';

  @override
  String get eventsLoadError => 'לא ניתן לטעון את האירועים';

  @override
  String get eventsEmptyTitle => 'אין אירועים';

  @override
  String get eventsEmptyHint => 'כדאי לחזור בקרוב\nכדי לגלות אירועים חדשים.';

  @override
  String get eventsTomorrow => 'מחר';

  @override
  String eventsInDays(int days) {
    return 'בעוד $days ימים';
  }

  @override
  String eventsDateAtTime(String date, String time) {
    return '$date בשעה $time';
  }

  @override
  String get eventsFree => 'חינם';

  @override
  String eventsAttendeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count משתתפים',
      two: 'שני משתתפים',
      one: 'משתתף אחד',
    );
    return '$_temp0';
  }

  @override
  String get eventsAlmostFull => 'כמעט מלא';

  @override
  String get eventsFull => 'מלא';

  @override
  String get eventsNotFound => 'האירוע לא נמצא';

  @override
  String get eventsInfoDate => 'תאריך';

  @override
  String get eventsInfoTime => 'שעה';

  @override
  String get eventsInfoPlace => 'מקום';

  @override
  String get eventsInfoParticipants => 'משתתפים';

  @override
  String get eventsInfoPrice => 'מחיר';

  @override
  String get eventsDescription => 'תיאור';

  @override
  String eventsCapacity(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$count / $max מקומות',
      one: '$count / $max מקום',
    );
    return '$_temp0';
  }

  @override
  String eventsRegisteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'נרשמו $count',
      two: 'נרשמו שניים',
      one: 'נרשם אחד',
    );
    return '$_temp0';
  }

  @override
  String eventsPricePerPerson(String price) {
    return '$price לאדם';
  }

  @override
  String get eventsRsvpConfirmedBanner => 'ההרשמה לאירוע אושרה';

  @override
  String get eventsRsvpCancel => 'ביטול ההרשמה';

  @override
  String eventsRsvpJoinPaid(String price) {
    return 'הרשמה - $price';
  }

  @override
  String get eventsRsvpJoinFree => 'הרשמה בחינם';

  @override
  String get eventsRsvpCancelled => 'ההרשמה בוטלה';

  @override
  String get eventsRsvpDone => 'ההרשמה אושרה';

  @override
  String eventsShareMessage(String title) {
    return 'הצטרפו אליי ל\"$title\" ב-MAZL';
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
  String get navigationDiscover => 'גילוי';

  @override
  String get navigationMatches => 'התאמות';

  @override
  String get navigationMessages => 'הודעות';

  @override
  String get navigationEvents => 'אירועים';

  @override
  String get navigationProfile => 'פרופיל';

  @override
  String get navigationShowTabs => 'הצגת הלשוניות';

  @override
  String get profileMyProfile => 'הפרופיל שלי';

  @override
  String get profileEdit => 'עריכה';

  @override
  String get profileSettings => 'הגדרות';

  @override
  String get profileMoreOptions => 'אפשרויות נוספות';

  @override
  String get profilePass => 'לדלג';

  @override
  String profileLikeName(String name) {
    return 'אהבתי את $name';
  }

  @override
  String get profileThisPerson => 'אדם זה';

  @override
  String get profileFallbackName => 'משתמש/ת';

  @override
  String get profileFallbackReportName => 'המשתמש/ת';

  @override
  String get profileDefaultLocation => 'צרפת';

  @override
  String get profileDistanceUnderOneKm => 'במרחק של פחות מ-1 ק״מ';

  @override
  String profileDistanceKm(int km) {
    return 'במרחק $km ק״מ';
  }

  @override
  String get profileGenderMale => 'גבר';

  @override
  String get profileGenderFemale => 'אישה';

  @override
  String get profileFactPractice => 'רמת דתיות';

  @override
  String get profileFactKashrut => 'כשרות';

  @override
  String get profileShabbat => 'שבת';

  @override
  String get profileFactGender => 'מגדר';

  @override
  String get profileEssentials => 'עיקרי הדברים';

  @override
  String get profileInAFewWords => 'במילים ספורות';

  @override
  String get profileAbout => 'אודות';

  @override
  String get profileLookingFor => 'החיפוש שלי';

  @override
  String get profileAddPhotos => 'להוסיף תמונות';

  @override
  String get profileVerified => 'פרופיל מאומת';

  @override
  String get profileVerifiedPlus => 'פרופיל מאומת+';

  @override
  String get profileVerifyMyProfile => 'לאמת את הפרופיל';

  @override
  String profileVerificationStatus(String status) {
    return 'מצב אימות: $status';
  }

  @override
  String get profilePhotoPrevious => 'התמונה הקודמת';

  @override
  String get profilePhotoNext => 'התמונה הבאה';

  @override
  String profilePhotoCounter(int current, int total) {
    return 'תמונה $current מתוך $total';
  }

  @override
  String get profileMatchLabel => 'התאמה';

  @override
  String get profileMatchTitle => 'יש התאמה.';

  @override
  String profileMatchBody(String name) {
    return 'אפשר להתחיל לשוחח עם $name.';
  }

  @override
  String get profileMatchBodyUnnamed => 'אפשר להתחיל לשוחח עם אדם זה.';

  @override
  String get profileSendMessage => 'לשלוח הודעה';

  @override
  String profileCompletionEyebrow(int done, int total) {
    return 'פרופיל · $done/$total';
  }

  @override
  String get profileCompletionTitle => 'להשלים את הפרופיל';

  @override
  String profileCompletionRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שלבים נותרו',
      two: 'שני שלבים נותרו',
      one: 'שלב אחד נותר',
    );
    return '$_temp0';
  }

  @override
  String get profileCompletionAction => 'להשלים עכשיו';

  @override
  String get profileStepPhotosDone => 'תמונות נוספו';

  @override
  String get profileStepPhotosTodo => 'להוסיף לפחות 2 תמונות';

  @override
  String get profileStepBioDone => 'הביוגרפיה הושלמה';

  @override
  String get profileStepBioTodo => 'לתאר את עצמך בכמה שורות';

  @override
  String get profileStepCityDone => 'העיר צוינה';

  @override
  String get profileStepCityTodo => 'לציין את העיר שלך';

  @override
  String get profileStepVerifiedDone => 'הפרופיל אומת';

  @override
  String get profileStepVerifiedTodo => 'לאמת את הפרופיל';

  @override
  String get profileCoupleMode => 'מצב זוג';

  @override
  String get profileCoupleInCoupleTitle => 'בזוגיות';

  @override
  String profileCoupleInCoupleBody(String name) {
    return 'מצב זוג פעיל עם $name.';
  }

  @override
  String get profileCoupleElsewhereTitle => 'כבר במצב זוג';

  @override
  String get profileCoupleElsewhereBody => 'כבר פעיל מצב זוג עם מישהו אחר.';

  @override
  String get profileCoupleReceivedTitle => 'התקבלה בקשה';

  @override
  String profileCoupleReceivedBody(String name) {
    return '$name רוצה להפעיל איתך מצב זוג.';
  }

  @override
  String get profileCoupleRespond => 'להשיב';

  @override
  String get profileCouplePendingTitle => 'הבקשה נשלחה';

  @override
  String profileCouplePendingBody(String name) {
    return 'עדיין אין תשובה מ-$name.';
  }

  @override
  String get profileCoupleCancelRequest => 'לבטל את הבקשה';

  @override
  String get profileCoupleAvailableTitle => 'מעבר למצב זוג';

  @override
  String get profileCoupleAvailableBody =>
      'יש התאמה. אפשר להפעיל מצב זוג כדי לשתף פעילויות יחד.';

  @override
  String profileCoupleActivate(String name) {
    return 'להפעיל עם $name';
  }

  @override
  String profileCoupleRequestSent(String name) {
    return 'הבקשה נשלחה אל $name.';
  }

  @override
  String get profileCompatibility => 'התאמה';

  @override
  String get profileCompatibilityVeryHigh => 'התאמה גבוהה מאוד';

  @override
  String get profileCompatibilityHigh => 'התאמה טובה';

  @override
  String get profileCompatibilityAverage => 'התאמה בינונית';

  @override
  String get profileCompatibilityLow => 'התאמה נמוכה';

  @override
  String get profileCompatibilityBasis => 'מחושבת לפי שני הפרופילים.';

  @override
  String get profileCompatibilityUnavailable => 'ההתאמה אינה זמינה כרגע.';

  @override
  String profileCompatibilityUnlockTitle(String name) {
    return 'אפשר לגלות את ציון ההתאמה עם $name.';
  }

  @override
  String get profileCompatibilityUnlockBody =>
      'מחושב לפי אורח החיים, הכוונות והערכים.';

  @override
  String get profileCompatibilityUnlock => 'לפתוח עם mazl+';

  @override
  String get profileFactorIntentions => 'כוונות';

  @override
  String get profileFactorAge => 'גיל';

  @override
  String get profileFactorDistance => 'מרחק';

  @override
  String get profileVerdictSameIntention => 'מחפשים את אותו הדבר';

  @override
  String get profileVerdictDifferentIntention => 'כוונות שונות';

  @override
  String get profileVerdictSameDenomination => 'אותו זרם';

  @override
  String get profileVerdictSimilarPractice => 'רמת דתיות דומה';

  @override
  String get profileVerdictDifferentPractice => 'רמת דתיות שונה';

  @override
  String get profileVerdictVeryCloseAge => 'גילאים קרובים מאוד';

  @override
  String get profileVerdictCloseAge => 'גילאים קרובים';

  @override
  String get profileVerdictModerateAgeGap => 'הפרש גילאים בינוני';

  @override
  String get profileVerdictLargeAgeGap => 'הפרש גילאים גדול';

  @override
  String get profileVerdictVeryNear => 'קרוב מאוד (פחות מ-10 ק״מ)';

  @override
  String get profileVerdictNear => 'קרוב (פחות מ-25 ק״מ)';

  @override
  String get profileVerdictModerateDistance => 'מרחק בינוני';

  @override
  String get profileVerdictFar => 'די רחוק';

  @override
  String profileCompatibilityCriteria(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קריטריונים נבדקו',
      two: 'שני קריטריונים נבדקו',
      one: 'קריטריון אחד נבדק',
    );
    return '$_temp0';
  }

  @override
  String get profileCompatibilityScoreTitle => 'ציון התאמה';

  @override
  String profileCompatibilityWith(String name) {
    return 'עם $name';
  }

  @override
  String get profileCompatibilityDetails => 'פרטים';

  @override
  String get profileCompatibilityIncomplete =>
      'כדאי להשלים את הפרופילים כדי לראות עוד פרטים';

  @override
  String get profileCompatibilityNote =>
      'הציון מבוסס על ההעדפות והדברים המשותפים';

  @override
  String get profileCompatibilityGotIt => 'הבנתי';

  @override
  String get profilePromptsMine => 'השאלות שלי';

  @override
  String get profilePromptsSubtitle =>
      'אפשר לענות על שאלות כדי להראות את האישיות שלך';

  @override
  String profilePromptsMaxReached(int max) {
    return 'הושג המקסימום: $max שאלות';
  }

  @override
  String get profilePromptsAllUsed => 'כל השאלות כבר בשימוש';

  @override
  String get profilePromptAdd => 'להוסיף שאלה';

  @override
  String get profilePromptChoose => 'לבחור שאלה';

  @override
  String get profilePromptYourAnswer => 'התשובה שלך…';

  @override
  String get profilePromptDeleteTitle => 'למחוק את השאלה?';

  @override
  String get profileIrreversibleSentence => 'לא ניתן לבטל פעולה זו.';

  @override
  String get profileIrreversible => 'לא ניתן לבטל פעולה זו';

  @override
  String get profilePromptDeleted => 'השאלה נמחקה';

  @override
  String get profilePromptsGetToKnowMe => 'להכיר אותי';

  @override
  String get profilePromptCategoryPersonality => 'אישיות';

  @override
  String get profilePromptCategoryLifestyle => 'אורח חיים';

  @override
  String get profilePromptCategoryJewish => 'יהדות';

  @override
  String get profilePromptCategoryConversation => 'שיחה';

  @override
  String get profileOther => 'אחר';

  @override
  String get profilePromptPerfectSunday => 'יום ראשון המושלם שלי...';

  @override
  String get profilePromptFunFact => 'עובדה מפתיעה עליי...';

  @override
  String get profilePromptLifeGoal => 'אחת המטרות שלי בחיים...';

  @override
  String get profilePromptPetPeeve => 'מה שהכי מעצבן אותי...';

  @override
  String get profilePromptProudOf => 'אני גאה ב...';

  @override
  String get profilePromptLookingFor => 'החיפוש שלי: מישהו ש...';

  @override
  String get profilePromptIdealVacation => 'החופשה האידיאלית שלי...';

  @override
  String get profilePromptFavoriteFood => 'המנה האהובה עליי...';

  @override
  String get profilePromptHiddenTalent => 'הכישרון הנסתר שלי...';

  @override
  String get profilePromptBingeWatching => 'עכשיו אני צופה ב...';

  @override
  String get profilePromptShabbatIdeal => 'השבת האידיאלית שלי...';

  @override
  String get profilePromptFamilyTradition => 'מסורת משפחתית יקרה ללבי...';

  @override
  String get profilePromptFavoriteHoliday => 'החג היהודי האהוב עליי...';

  @override
  String get profilePromptFridayNight => 'ערב שבת אצלי בבית...';

  @override
  String get profilePromptIsraelMemory => 'הזיכרון הכי טוב שלי מישראל...';

  @override
  String get profilePromptJewishValue => 'ערך יהודי שמנחה אותי...';

  @override
  String get profilePromptDebateMe => 'בואו נתווכח על…';

  @override
  String get profilePromptTeachMe => 'תלמדו אותי משהו על…';

  @override
  String get profilePromptTogetherWeCould => 'ביחד אפשר...';

  @override
  String get profilePromptFirstDate => 'הדייט הראשון המושלם...';

  @override
  String get profileIntentionHint => 'אפשר להראות לאחרים מה מחפשים';

  @override
  String get profileIntentionMarriage => 'נישואין';

  @override
  String get profileIntentionSerious => 'זוגיות רצינית';

  @override
  String get profileIntentionOpen => 'פתיחות לכל אפשרות';

  @override
  String get profileIntentionOpenSelector => 'פתיחות לכל אפשרות';

  @override
  String get profileIntentionFriendsFirst => 'קודם כול חברות';

  @override
  String get profileIntentionUndecided => 'עדיין לא ברור לי';

  @override
  String get profileIntentionMarriageDescription =>
      'חיפוש אחר בן/בת הזוג לחיים';

  @override
  String get profileIntentionSeriousDescription => 'חיפוש אחר קשר ארוך טווח';

  @override
  String get profileIntentionOpenDescription => 'נראה לאן זה מוביל';

  @override
  String get profileIntentionFriendsFirstDescription => 'נתחיל מהיכרות';

  @override
  String get profileDenomination => 'זרם';

  @override
  String get profileDenominationSecular => 'חילוני';

  @override
  String get profileDenominationTraditional => 'מסורתי';

  @override
  String get profileDenominationMasorti => 'קונסרבטיבי (מסורטי)';

  @override
  String get profileDenominationLiberal => 'רפורמי (ליברלי)';

  @override
  String get profileDenominationModernOrthodox =>
      'דתי לאומי (אורתודוקסי מודרני)';

  @override
  String get profileDenominationOrthodox => 'אורתודוקסי (חרדי)';

  @override
  String get profileDenominationChabad => 'חב״ד';

  @override
  String get profileFieldKashrut => 'כשרות';

  @override
  String get profileKashrutNone => 'לא';

  @override
  String get profileKashrutHome => 'כשר בבית';

  @override
  String get profileKashrutStrict => 'כשרות מחמירה';

  @override
  String get profileKashrutGlatt => 'גלאט כשר';

  @override
  String get profileKashrutOptionHome => 'בבית';

  @override
  String get profileKashrutOptionStrict => 'מחמירה';

  @override
  String get profileKashrutOptionGlatt => 'גלאט';

  @override
  String get profileShabbatNotObservant => 'ללא שמירת שבת';

  @override
  String get profileShabbatPartial => 'שמירת שבת חלקית';

  @override
  String get profileShabbatObserved => 'שמירת שבת';

  @override
  String get profileShabbatStrict => 'שמירת שבת קפדנית';

  @override
  String get profileShabbatFamily => 'שבת משפחתית';

  @override
  String get profileShabbatOptionPartial => 'שמירה חלקית';

  @override
  String get profileShabbatOptionObservant => 'שמירה';

  @override
  String get profileShabbatOptionStrict => 'שמירה קפדנית';

  @override
  String get profileSynagogue => 'בית כנסת';

  @override
  String get profileSynagogueDaily => 'מדי יום';

  @override
  String get profileSynagogueWeekly => 'כל שבוע';

  @override
  String get profileSynagogueHolidays => 'בחגים';

  @override
  String get profileSynagogueRarely => 'לעיתים רחוקות';

  @override
  String get profileEditTitle => 'עריכת פרופיל';

  @override
  String get profilePhotos => 'תמונות';

  @override
  String get profilePhotosHint => 'לחיצה ארוכה להגדרה כתמונה ראשית';

  @override
  String get profileBioHint => 'לספר על עצמך…';

  @override
  String get profileBasicInfo => 'פרטים בסיסיים';

  @override
  String get profileFirstName => 'שם פרטי';

  @override
  String get profileCity => 'עיר';

  @override
  String get profilePracticeTitle => 'אורח החיים הדתי שלי';

  @override
  String get profilePrimaryPhoto => 'ראשית';

  @override
  String get profileEnterFirstName => 'להזין שם פרטי';

  @override
  String get profileEnterCity => 'להזין עיר';

  @override
  String get profileUpdated => 'הפרופיל עודכן';

  @override
  String get profilePhotoAdded => 'התמונה נוספה';

  @override
  String get profileUploadUnavailable => 'ההעלאה אינה זמינה כרגע';

  @override
  String get profileDeletePhotoTitle => 'למחוק את התמונה?';

  @override
  String get profilePhotoDeleted => 'התמונה נמחקה';

  @override
  String get profileServiceUnavailable => 'השירות אינו זמין זמנית';

  @override
  String get profilePrimaryUpdated => 'התמונה הראשית עודכנה';

  @override
  String profileSetupStep(int step, int total) {
    return 'שלב $step/$total';
  }

  @override
  String get profileSetupNext => 'הבא';

  @override
  String get profileSetupFinish => 'סיום';

  @override
  String get profileSetupNameRequired => 'יש להזין שם פרטי כדי להמשיך';

  @override
  String get profileSetupBirthdateRequired => 'יש להזין תאריך לידה';

  @override
  String get profileSetupGenderRequired => 'יש לבחור מגדר';

  @override
  String get profileBirthdate => 'תאריך לידה';

  @override
  String get profileBirthdateHint => 'DD.MM.YYYY';

  @override
  String get profileSetupAboutYouTitle => 'קצת עליך';

  @override
  String get profileSetupAboutYouSubtitle => 'פרטים אלה יוצגו בפרופיל';

  @override
  String get profileFirstNameHint => 'איך קוראים לך?';

  @override
  String get profileIAm => 'אני';

  @override
  String get profileAMan => 'גבר';

  @override
  String get profileAWoman => 'אישה';

  @override
  String get profileCityHint => 'איפה גרים?';

  @override
  String get profileSetupPhotosTitle => 'להוסיף תמונות';

  @override
  String get profileSetupPhotosSubtitle =>
      'יש להוסיף לפחות 2 תמונות כדי להמשיך';

  @override
  String get profileSetupPhotosTip =>
      'פרופילים עם תמונות באיכות טובה מקבלים פי 3 יותר התאמות.';

  @override
  String get profileSetupPracticeTitle => 'אורח החיים הדתי שלך';

  @override
  String get profileSetupPracticeSubtitle => 'כך נוכל למצוא מישהו שמתאים לך';

  @override
  String get profileSetupLookingTitle => 'החיפוש שלך';

  @override
  String get profileSetupLookingSubtitle => 'כך נוכל להציג פרופילים מתאימים';

  @override
  String get profileILookFor => 'החיפוש שלי';

  @override
  String get profileAgeRange => 'טווח גילאים';

  @override
  String get profileMaxDistance => 'מרחק מרבי';

  @override
  String profileDistanceSliderLabel(int km) {
    return '$km ק״מ';
  }

  @override
  String get profileGoal => 'מטרה';

  @override
  String get profileShadchanNote =>
      'AI Shadchan ישתמש בהעדפות אלה כדי להציע פרופילים מתאימים.';

  @override
  String get profileReportThisProfile => 'לדווח על הפרופיל';

  @override
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageSystem => 'שפת הטלפון';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get settingsSectionAccount => 'חשבון';

  @override
  String get settingsEditProfile => 'עריכת פרופיל';

  @override
  String get settingsEmail => 'אימייל';

  @override
  String get settingsNotSignedIn => 'לא בוצעה התחברות';

  @override
  String get settingsDefaultUserName => 'משתמש/ת';

  @override
  String get settingsSectionDiscovery => 'גילוי';

  @override
  String get settingsLocation => 'מיקום';

  @override
  String get settingsLocationNotSet => 'לא הוגדר';

  @override
  String get settingsMaxDistance => 'מרחק מרבי';

  @override
  String settingsDistanceKm(int distance) {
    final intl.NumberFormat distanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String distanceString = distanceNumberFormat.format(distance);

    return '$distanceString ק״מ';
  }

  @override
  String get settingsAgeRange => 'טווח גילאים';

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

    return '$minString - $maxString שנים';
  }

  @override
  String get settingsSectionJewish => 'הגדרות יהודיות';

  @override
  String get settingsShabbatMode => 'מצב שבת';

  @override
  String get settingsShabbatAutoPause => 'השהיה אוטומטית';

  @override
  String get settingsHolidayAlerts => 'התראות חגים';

  @override
  String get settingsHolidayAlertsHint => 'התראות לפני החגים';

  @override
  String get settingsSectionNotifications => 'התראות';

  @override
  String get settingsNotifMatches => 'התאמות חדשות';

  @override
  String get settingsNotifMessages => 'הודעות';

  @override
  String get settingsNotifSuperLikes => 'סופר לייקים';

  @override
  String get settingsSectionCouple => 'מצב זוגי';

  @override
  String get settingsSectionSubscription => 'מנוי';

  @override
  String get settingsRestorePurchases => 'שחזור רכישות';

  @override
  String get settingsRestoreSuccess => 'הרכישות שוחזרו בהצלחה.';

  @override
  String get settingsRestoreError => 'שחזור הרכישות נכשל. אפשר לנסות שוב.';

  @override
  String settingsSubscriptionRenewsOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'מתחדש ב-$dateString';
  }

  @override
  String settingsSubscriptionEndsOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'עד $dateString';
  }

  @override
  String get settingsSectionPrivacy => 'פרטיות ואבטחה';

  @override
  String get settingsBlockedUsers => 'משתמשים חסומים';

  @override
  String get settingsBlockedUsersHint => 'ניהול האנשים החסומים';

  @override
  String get settingsProfileVerification => 'אימות פרופיל';

  @override
  String get settingsVerified => 'מאומת';

  @override
  String get settingsNotVerified => 'לא מאומת';

  @override
  String get settingsSectionAbout => 'אודות';

  @override
  String get settingsHelp => 'עזרה ותמיכה';

  @override
  String get settingsTerms => 'תנאי שימוש';

  @override
  String get settingsPrivacyPolicy => 'מדיניות פרטיות';

  @override
  String get settingsVersion => 'גרסה';

  @override
  String get settingsLogOut => 'התנתקות';

  @override
  String get settingsLogOutMessage => 'להתנתק מהחשבון?';

  @override
  String get settingsDeleteAccount => 'מחיקת החשבון שלי';

  @override
  String get settingsDeleteReasonPrompt => 'מה הסיבה לעזיבה?';

  @override
  String get settingsDeleteReasonFoundSomeone => 'מצאתי מישהו/י';

  @override
  String get settingsDeleteReasonNoLongerUsing =>
      'אני כבר לא משתמש/ת באפליקציה';

  @override
  String get settingsDeleteReasonBreak => 'אני רוצה לקחת הפסקה';

  @override
  String get settingsDeleteReasonTechnical => 'בעיות טכניות';

  @override
  String get settingsDeleteReasonService => 'השירות לא מתאים לי';

  @override
  String get settingsDeleteReasonOther => 'סיבה אחרת';

  @override
  String get settingsDeleteFinalTitle => 'אישור סופי';

  @override
  String get settingsDeleteIrreversible => 'לא ניתן לבטל פעולה זו.';

  @override
  String get settingsDeleteDataList =>
      'כל הנתונים יימחקו:\n• הפרופיל והתמונות\n• ההתאמות והשיחות\n• היסטוריית הלייקים\n• ההגדרות';

  @override
  String get settingsDeleteKeep => 'להשאיר את החשבון';

  @override
  String get settingsDeleteError => 'מחיקת החשבון נכשלה';

  @override
  String get settingsCitySearchHint => 'חיפוש עיר...';

  @override
  String get settingsCitySearchHelp => 'יש להקליד את שם העיר ולבחור הצעה';

  @override
  String get settingsSaved => 'ההגדרות נשמרו';

  @override
  String get settingsCoupleLeave => 'יציאה ממצב זוגי';

  @override
  String get settingsCoupleLeaveMessage => 'אפשר להפעיל אותו מחדש בהמשך.';

  @override
  String get settingsCoupleLeaveConfirm => 'יציאה';

  @override
  String get settingsCoupleLeft => 'המצב הזוגי הופסק';

  @override
  String get settingsCoupleLeaveError =>
      'לא ניתן לצאת ממצב זוגי. אפשר לנסות שוב.';

  @override
  String get settingsCoupleCancelRequestError =>
      'לא ניתן לבטל את הבקשה. אפשר לנסות שוב.';

  @override
  String get settingsCoupleActive => 'מצב זוגי פעיל';

  @override
  String settingsCoupleWithPartner(String name) {
    return 'עם $name';
  }

  @override
  String get settingsCoupleWithYourPartner => 'עם בן/בת הזוג';

  @override
  String get settingsCoupleOpenSpace => 'מרחב זוגי';

  @override
  String get settingsCoupleOpenCalendar => 'לוח שנה';

  @override
  String get settingsCoupleSinceToday => 'מהיום';

  @override
  String settingsCoupleDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ימים',
      two: 'יומיים',
      one: 'יום אחד',
    );
    return '$_temp0';
  }

  @override
  String get settingsCoupleRequestSent => 'הבקשה נשלחה';

  @override
  String settingsCoupleRequestSentTo(String name) {
    return 'הבקשה נשלחה אל $name';
  }

  @override
  String get settingsCoupleWaiting => 'בהמתנה לתשובה';

  @override
  String get settingsCoupleCancelRequest => 'ביטול הבקשה';

  @override
  String get settingsCoupleInvitation => 'נמצאה אהבה?';

  @override
  String get settingsCoupleActivate => 'הפעלה';

  @override
  String get settingsShabbatCity => 'מבוסס על פריז, צרפת';

  @override
  String get settingsShabbatSettingsHeader => 'הגדרות';

  @override
  String get settingsShabbatEnable => 'הפעלת מצב שבת';

  @override
  String get settingsShabbatEnableHint => 'ההתראות מושהות אוטומטית בשבת';

  @override
  String get settingsShabbatIncludeHolidays => 'לכלול חגים';

  @override
  String get settingsShabbatIncludeHolidaysHint => 'השהיה גם ביום טוב';

  @override
  String get settingsShabbatBuffer => 'מרווח לפני הדלקת נרות';

  @override
  String settingsMinutesShort(int minutes) {
    return '$minutes דק׳';
  }

  @override
  String settingsMinutesSpoken(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes דקות',
      two: 'שתי דקות',
      one: 'דקה אחת',
    );
    return '$_temp0';
  }

  @override
  String get settingsShabbatEdit => 'עריכה';

  @override
  String get settingsShabbatExplanation =>
      'ההתראות מושהות וההודעות ממתינות. הכול יגיע בתום השבת, והסטטוס יציג “מצב שבת”.';

  @override
  String get settingsShabbatHeroTitle => 'שבת\nשלום.';

  @override
  String get settingsShabbatHeroSubtitle =>
      'Mazl נח איתכם. ההודעות ימתינו להבדלה.';

  @override
  String get settingsShabbatCandleLighting => 'הדלקת נרות';

  @override
  String get settingsShabbatHavdalah => 'הבדלה';

  @override
  String get settingsBlockedUserFallbackName => 'משתמש/ת';

  @override
  String get settingsBlockedUnblockTitle => 'לבטל את חסימת המשתמש?';

  @override
  String settingsBlockedUnblockMessage(String name) {
    return 'לבטל את החסימה של $name?\n\nאדם זה יוכל שוב לראות את הפרופיל וליצור קשר.';
  }

  @override
  String get settingsBlockedUnblockMessageUnnamed =>
      'לבטל את החסימה של משתמש זה?\n\nאדם זה יוכל שוב לראות את הפרופיל וליצור קשר.';

  @override
  String get settingsBlockedUnblock => 'ביטול חסימה';

  @override
  String settingsBlockedUnblocked(String name) {
    return 'החסימה של $name בוטלה';
  }

  @override
  String get settingsBlockedUnblockedUnnamed => 'החסימה בוטלה';

  @override
  String get settingsBlockedUnblockError => 'ביטול החסימה נכשל';

  @override
  String get settingsBlockedEmptyTitle => 'אין משתמשים חסומים';

  @override
  String get settingsBlockedEmptyHint => 'אנשים שנחסמו\nיופיעו כאן';

  @override
  String settingsBlockedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'תאריך החסימה: $dateString';
  }
}
