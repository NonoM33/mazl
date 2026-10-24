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
  String get likesTitle => 'לייקים';

  @override
  String likesSection(String count) {
    return 'אהבו אותך · $count';
  }

  @override
  String likesWaiting(int count, String label) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$label אנשים ממתינים לתשובה שלך.',
      two: 'שני אנשים ממתינים לתשובה שלך.',
      one: 'אדם אחד ממתין לתשובה שלך.',
    );
    return '$_temp0';
  }

  @override
  String get likesSeeWhoWithPlus => 'לראות מי אהב אותך עם mazl+‎';

  @override
  String likesMatchWith(String name) {
    return 'יש מאץ\' עם $name';
  }

  @override
  String get likesMessageAction => 'הודעה';

  @override
  String likesYouLiked(String name) {
    return 'נשלח לייק ל-$name';
  }

  @override
  String get likesEmptyTitle => 'עדיין אין לייקים';

  @override
  String get likesEmptyBody =>
      'כדאי להמשיך לגלות פרופילים ולהשלים את הפרופיל כדי לקבל יותר לייקים.';

  @override
  String get likesEmptyAction => 'לגלות פרופילים';

  @override
  String get likesPremiumBody =>
      'אפשר לגלות מי אהב אותך וליצור מאץ\' מיד עם מי שמוצא חן בעיניך.';

  @override
  String get likesPremiumOffers => 'לצפייה במסלולים';

  @override
  String likesCardOpen(String title) {
    return 'לצפייה בלייק של $title';
  }

  @override
  String likesCardPass(String name) {
    return 'לדלג על $name';
  }

  @override
  String likesCardLike(String name) {
    return 'לתת לייק ל-$name';
  }

  @override
  String get likesLockedLabel => 'פרופיל מוסתר';

  @override
  String get likesLockedHint => 'זמין עם mazl+‎';

  @override
  String likesDistance(int km) {
    return '$km ק״מ';
  }

  @override
  String get matchingDiscoverDailyPicks => 'הבחירות של היום';

  @override
  String get matchingFilters => 'מסננים';

  @override
  String get matchingDiscoverEmptyTitle => 'כל הפרופילים נצפו.';

  @override
  String get matchingDiscoverEmptyBody =>
      'כדאי לחזור מאוחר יותר או להרחיב את המסננים כדי לראות פרופילים חדשים.';

  @override
  String get matchingDiscoverOpenFilters => 'פתיחת המסננים';

  @override
  String get matchingDiscoverRefresh => 'רענון';

  @override
  String get matchingDiscoverUndo => 'ביטול';

  @override
  String get matchingDiscoverSuperLike => 'סופר לייק';

  @override
  String get matchingDiscoverBoost => 'בוסט';

  @override
  String matchingDiscoverBoostOn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes דקות',
      two: 'שתי דקות',
      one: 'דקה אחת',
    );
    return 'הבוסט הופעל. הפרופיל שלך בראש הערימה למשך $_temp0.';
  }

  @override
  String get matchingDiscoverBoostFailed => 'לא ניתן להפעיל את הבוסט';

  @override
  String get matchingCardPass => 'לדלג';

  @override
  String get matchingCardLike => 'לייק';

  @override
  String get matchingCardViewProfile => 'לצפייה בפרופיל';

  @override
  String get matchingCardAnonymous => 'ללא שם';

  @override
  String matchingCardDistance(int km) {
    return 'במרחק $km ק״מ';
  }

  @override
  String get matchingCardVerified => 'פרופיל מאומת';

  @override
  String matchingAvatarNewMatch(String name) {
    return 'מאץ\' חדש, $name';
  }

  @override
  String matchingAvatarMatch(String name) {
    return 'מאץ\', $name';
  }

  @override
  String get matchingMatchTitle => 'יש מאץ\'!';

  @override
  String matchingMatchLineNamed(String name) {
    return 'יש חיבור הדדי עם $name.';
  }

  @override
  String get matchingMatchLineAnonymous => 'יש חיבור הדדי.';

  @override
  String get matchingMatchSendMessage => 'לשלוח הודעה';

  @override
  String get matchingMatchKeepDiscovering => 'להמשיך לגלות';

  @override
  String matchingSeeMoreWithPlus(int count) {
    return 'לראות עוד $count עם mazl+‎';
  }

  @override
  String get safetyBlock => 'לחסום';

  @override
  String get safetyBlockSubtitle =>
      'לאדם הזה לא תהיה אפשרות לראות את הפרופיל שלך או ליצור איתך קשר';

  @override
  String get safetyReportSubtitle => 'דיווח על התנהגות לא הולמת';

  @override
  String get safetyBlockConfirmTitle => 'לחסום את הפרופיל הזה?';

  @override
  String safetyBlockConfirmIntro(String name) {
    return 'בחסימת $name:';
  }

  @override
  String get safetyBlockEffectHidden => 'הפרופיל שלך לא יוצג יותר לאדם הזה';

  @override
  String get safetyBlockEffectNotSeen => 'הפרופיל הזה לא יוצג לך יותר';

  @override
  String get safetyBlockEffectChats => 'השיחות יימחקו';

  @override
  String get safetyBlockEffectNotNotified => 'האדם הזה לא יקבל התראה';

  @override
  String safetyBlocked(String name) {
    return '$name נחסם';
  }

  @override
  String get safetyBlockFailed => 'אירעה שגיאה בחסימה';

  @override
  String get safetyReportTitle => 'דיווח על בעיה';

  @override
  String safetyReportWhy(String name) {
    return 'מה הסיבה לדיווח על $name?';
  }

  @override
  String get safetyReportDetailsHint => 'פרטים נוספים (לא חובה)';

  @override
  String get safetyReportAlsoBlock => 'לחסום גם את הפרופיל הזה';

  @override
  String get safetyReportAlsoBlockHint => 'הפרופיל הזה לא יוצג לך יותר';

  @override
  String get safetyReportSend => 'שליחת הדיווח';

  @override
  String get safetyReportThanks => 'תודה על הדיווח. הצוות שלנו יבדוק אותו.';

  @override
  String get safetyReportFailed => 'אירעה שגיאה בשליחת הדיווח';

  @override
  String get safetyCategoryFakeProfile => 'פרופיל מזויף';

  @override
  String get safetyCategoryFakeProfileHint => 'תמונות גנובות, זהות בדויה';

  @override
  String get safetyCategoryInappropriatePhotos => 'תמונות לא הולמות';

  @override
  String get safetyCategoryInappropriatePhotosHint =>
      'תוכן מיני, אלים או מזעזע';

  @override
  String get safetyCategoryHarassment => 'הטרדה';

  @override
  String get safetyCategoryHarassmentHint => 'הודעות לוחצות, איומים, עלבונות';

  @override
  String get safetyCategorySpam => 'ספאם / הונאה';

  @override
  String get safetyCategorySpamHint => 'פרסומות, בקשות כסף, קישורים חשודים';

  @override
  String get safetyCategoryUnderage => 'מתחת לגיל 18';

  @override
  String get safetyCategoryUnderageHint => 'נראה שהגיל הוא מתחת ל-18';

  @override
  String get safetyCategoryOfflineBehavior => 'התנהגות מחוץ לאפליקציה';

  @override
  String get safetyCategoryOfflineBehaviorHint =>
      'התנהגות לא הולמת במהלך פגישה';

  @override
  String get safetyCategoryOther => 'אחר';

  @override
  String get safetyCategoryOtherHint => 'סיבה אחרת (נא לפרט)';

  @override
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageSystem => 'שפת הטלפון';

  @override
  String get visitorsTitle => 'מי ביקר בפרופיל שלי';

  @override
  String visitorsTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ביקורים',
      two: 'שני ביקורים',
      one: 'ביקור אחד',
    );
    return '$_temp0';
  }

  @override
  String visitorsThisWeek(int count) {
    return '$count השבוע';
  }

  @override
  String get visitorsBannerTitle => 'אפשר לגלות מי ביקר אצלך';

  @override
  String get visitorsBannerBody => 'המעבר ל-mazl+‎ מאפשר לראות את הפרופילים';

  @override
  String get visitorsEmptyTitle => 'עדיין אין מבקרים';

  @override
  String get visitorsEmptyBody =>
      'כדאי להשלים את הפרופיל ולהשתמש בבוסט כדי למשוך יותר מבקרים.';

  @override
  String get visitorsEmptyAction => 'להפעיל בוסט';

  @override
  String get visitorsLockedTitle => 'בלעדי ל-mazl+‎';

  @override
  String get visitorsLockedBody =>
      'המעבר ל-mazl+‎ מאפשר לגלות מי ביקר בפרופיל שלך וליצור קשר ישירות.';

  @override
  String get visitorsLockedAction => 'להכיר את mazl+‎';

  @override
  String get visitorsNew => 'חדש';

  @override
  String visitorsAgoMinutes(int count) {
    return 'לפני $count דק׳';
  }

  @override
  String visitorsAgoHours(int count) {
    return 'לפני $count שע׳';
  }

  @override
  String visitorsAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count ימים',
      two: 'לפני יומיים',
      one: 'לפני יום',
    );
    return '$_temp0';
  }

  @override
  String visitorsAgoWeeks(int count) {
    return 'לפני $count שב׳';
  }
}
