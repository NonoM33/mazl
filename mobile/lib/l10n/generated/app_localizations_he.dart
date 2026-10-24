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
}
