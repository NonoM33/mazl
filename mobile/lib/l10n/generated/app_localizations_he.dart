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
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageSystem => 'שפת הטלפון';

  @override
  String get settingsShabbatMode => 'מצב שבת';

  @override
  String get settingsShabbatAutoPause => 'השהיה אוטומטית';

  @override
  String get settingsBlockedUsers => 'משתמשים חסומים';

  @override
  String get settingsBlockedUsersHint => 'ניהול האנשים החסומים';

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
