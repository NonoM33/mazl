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
  String get coupleFeedFailureNetwork => 'לא ניתן להתחבר לשרת. אפשר לנסות שוב.';

  @override
  String get coupleFeedFailureMalformed => 'התקבלה תשובה לא צפויה מהשרת.';

  @override
  String get coupleFeedFailureNotInCouple => 'מצב זוג אינו פעיל.';

  @override
  String get coupleFeedFailureNotFound => 'לא נמצא.';

  @override
  String get coupleFeedFailureFull => 'האירוע מלא.';

  @override
  String get coupleFeedFailureServer => 'השרת לא הצליח להגיב. אפשר לנסות שוב.';

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
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageSystem => 'שפת הטלפון';
}
