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
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageSystem => 'שפת הטלפון';

  @override
  String get verificationProfileEyebrow => 'הפרופיל שלך';

  @override
  String get verificationTitle => 'אימות';

  @override
  String get verificationLevel1 => 'רמה 1';

  @override
  String get verificationLevel2 => 'רמה 2';

  @override
  String get verificationPhotoTitle => 'תמונה מאומתת';

  @override
  String get verificationIdentityTitle => 'זהות מאומתת';

  @override
  String get verificationVerifiedPill => 'מאומתת';

  @override
  String get verificationConsent =>
      'אנחנו משווים את הפנים שלך לתמונות שלך. התמונות אינן נשמרות; נשמרת רק טביעת פנים מוצפנת, שאפשר למחוק בכל עת.';

  @override
  String get verificationPhotoVerifiedLine =>
      'יש התאמה בין הפנים שלך לתמונות שלך.';

  @override
  String verificationPhotoVerifiedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'אומת בתאריך $dateString.';
  }

  @override
  String get verificationRemoveAction => 'להסיר את האימות שלי';

  @override
  String get verificationVerifyPhotoAction => 'לאמת את התמונה שלי';

  @override
  String get verificationVerifyIdentityAction => 'לאמת את הזהות שלי';

  @override
  String verificationBlockedToday(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'המכסה מוצתה, אפשר לנסות שוב בשעה $timeString.';
  }

  @override
  String verificationBlockedLater(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'המכסה מוצתה, אפשר לנסות שוב ב-$dateString בשעה $timeString.';
  }

  @override
  String get verificationIdentityCheckedNoDate =>
      'המסמך נבדק באמצעות השבב שלו.';

  @override
  String verificationIdentityCheckedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'נבדק בתאריך $dateString.';
  }

  @override
  String get verificationIdentityPitch =>
      'דרכון או תעודת זהות, הנקראים באמצעות השבב שלהם. סלפי מאשר שמדובר בך באמת.';

  @override
  String get verificationRemoveDialogTitle => 'להסיר את האימות שלי?';

  @override
  String get verificationRemoveDialogBody => 'התג וטביעת הפנים שלך יימחקו.';

  @override
  String verificationPhotosMismatch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מהתמונות שלך אינן דומות לך: הן לא נספרות.',
      two: 'שתיים מהתמונות שלך אינן דומות לך: הן לא נספרות.',
      one: 'אחת מהתמונות שלך אינה דומה לך: היא לא נספרת.',
    );
    return '$_temp0';
  }

  @override
  String get verificationLivenessFront => 'להביט למצלמה';

  @override
  String get verificationLivenessLeft => 'להסב לאט את הראש שמאלה';

  @override
  String get verificationLivenessRight => 'להסב לאט את הראש ימינה';

  @override
  String get verificationLivenessHintNoFace => 'למקם את הפנים בתוך העיגול';

  @override
  String get verificationLivenessHintMultipleFaces => 'אדם אחד בלבד בפריים';

  @override
  String get verificationLivenessHintTooSmall => 'להתקרב קצת';

  @override
  String get verificationLivenessHintOffCenter => 'למרכז את הפנים בתוך העיגול';

  @override
  String get verificationLivenessHintLookStraight => 'להביט ישר קדימה';

  @override
  String get verificationLivenessHintTurnMore => 'להסב עוד קצת';

  @override
  String get verificationLivenessHintTurnLess => 'לא עד כדי כך, לחזור קצת';

  @override
  String get verificationLivenessHintTurnOtherWay => 'להסב לצד השני';

  @override
  String verificationLivenessPoseCounter(int current, int total) {
    return 'תנוחה $current מתוך $total';
  }

  @override
  String verificationLivenessPosesTaken(int done, int total) {
    return 'תנוחות שצולמו: $done מתוך $total';
  }

  @override
  String get verificationLivenessPrivacy =>
      'לבד בפריים, בתאורה טובה. התמונות אינן נשמרות.';

  @override
  String get verificationLivenessExpiredTitle => 'פג תוקף הסשן';

  @override
  String get verificationLivenessExpiredBody =>
      'הזמן שהוקצב תם. אפשר להתחיל מחדש.';

  @override
  String get verificationCameraNeededTitle => 'נדרשת מצלמה';

  @override
  String get verificationCameraNeededBody =>
      'ב-MAZL נעשה שימוש במצלמה הקדמית כדי לוודא שהתמונות שלך אכן מציגות אותך.';

  @override
  String get verificationCameraOpenSettings => 'לפתוח את ההגדרות';

  @override
  String get verificationCameraAllow => 'לאפשר גישה למצלמה';

  @override
  String get verificationCameraUnavailableTitle => 'המצלמה אינה זמינה';

  @override
  String get verificationCameraUnavailableBody =>
      'לא ניתן להפעיל את המצלמה הקדמית.';

  @override
  String get verificationIntroTitle => 'לאמת את הזהות שלך.';

  @override
  String get verificationIntroSubtitle =>
      'התג ״זהות מאומתת״ מראה לאחרים שהתמונות אכן שלך. נדרשים דרכון או תעודת זהות ביומטריים, שתי דקות וקצת אור.';

  @override
  String get verificationIntroStep1 => 'לצלם את עמוד התמונה';

  @override
  String get verificationIntroStep1Detail =>
      'כדי לקרוא את שתי שורות ה-MRZ התחתונות.';

  @override
  String get verificationIntroStep2 => 'להניח את הטלפון על השבב';

  @override
  String get verificationIntroStep2Detail =>
      'השבב החתום על ידי המדינה הוא הקובע.';

  @override
  String get verificationIntroStep3 => 'סלפי בתנועה';

  @override
  String get verificationIntroStep3Detail => 'מושווה לתמונה שבשבב.';

  @override
  String get verificationIntroPrivacy => 'דבר אינו נשמר: נשמרת רק התוצאה.';

  @override
  String get verificationIntroStart => 'להתחיל';

  @override
  String verificationStepLabel(int step, int total) {
    return 'שלב $step מתוך $total';
  }

  @override
  String get verificationScanTitle => 'לכוון את המצלמה לעמוד התמונה.';

  @override
  String get verificationScanHint =>
      'שתי שורות ה-MRZ התחתונות מספיקות. יש להימנע מהשתקפויות.';

  @override
  String get verificationScanManual => 'להזין ידנית';

  @override
  String get verificationScanFrameSemantics =>
      'תצוגה מקדימה של המצלמה: יש למקם את שתי שורות ה-MRZ התחתונות של המסמך בתוך המסגרת המסומנת';

  @override
  String get verificationCameraNotAvailable => 'המצלמה אינה זמינה.';

  @override
  String get verificationScanUnavailableBody =>
      'אפשר להזין ידנית את הפרטים מעמוד התמונה.';

  @override
  String get verificationScanEnterDetails => 'להזין את הפרטים';

  @override
  String get verificationManualTitle => 'להזין את הפרטים.';

  @override
  String get verificationManualSubtitle => 'יש להעתיק אותם מעמוד התמונה במסמך.';

  @override
  String get verificationFieldDocumentNumber => 'מספר המסמך';

  @override
  String get verificationFieldBirthDate => 'תאריך לידה';

  @override
  String get verificationFieldExpiryDate => 'תאריך תפוגה';

  @override
  String get verificationDateHint => 'DD/MM/YYYY';

  @override
  String get verificationManualUseCamera => 'לסרוק במצלמה';

  @override
  String get verificationErrorDocumentNumber => 'בין 5 ל-12 אותיות או ספרות.';

  @override
  String get verificationErrorInvalidDate => 'תאריך לא תקין.';

  @override
  String get verificationReviewTitle => 'לבדוק את הפרטים.';

  @override
  String get verificationReviewConfirm => 'זה אני';

  @override
  String get verificationRescan => 'לסרוק שוב';

  @override
  String get verificationNfcWaitingTitle => 'להניח את המסמך על הטלפון.';

  @override
  String get verificationNfcPlacement =>
      'החלק העליון של הטלפון צמוד לכריכה הסגורה של הדרכון, או לגב תעודת הזהות. אם צריך, יש להסיר את המגן מהטלפון.';

  @override
  String get verificationNfcRead => 'לקרוא את המסמך';

  @override
  String get verificationNfcIllustration =>
      'החלק העליון של הטלפון מונח על הכריכה הסגורה של הדרכון';

  @override
  String get verificationNfcReadingTitle => 'אין לזוז.';

  @override
  String get verificationNfcReadingSubtitle =>
      'יש להשאיר את המסמך צמוד לחלק העליון של הטלפון עד תום הקריאה.';

  @override
  String get verificationNfcProgressLabel => 'קריאת השבב';

  @override
  String verificationNfcProgressValue(int percent) {
    return '$percent%';
  }

  @override
  String get verificationNfcStepDetect => 'זיהוי המסמך';

  @override
  String get verificationNfcStepConnect => 'חיבור מאובטח';

  @override
  String get verificationNfcStepPhoto => 'קריאת התמונה';

  @override
  String get verificationNfcStepSignature => 'קריאת החתימה';

  @override
  String verificationNfcStepSemantics(String label, String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'done': '$label, הושלם',
      'active': '$label, בתהליך',
      'waiting': '$label, ממתין',
      'other': '$label',
    });
    return '$_temp0';
  }

  @override
  String get verificationNfcSilentBody =>
      'זה קורה לעיתים קרובות בניסיון הראשון. דבר לא נשלח.';

  @override
  String get verificationNfcRescanBody =>
      'דבר לא נשלח. יש לקרוא שוב את עמוד התמונה כדי להתחיל מחדש עם נתונים נכונים.';

  @override
  String get verificationNfcTip1 => 'להסיר את המגן מהטלפון.';

  @override
  String get verificationNfcTip2 =>
      'להניח את החלק העליון של הטלפון במרכז הכריכה, כשהדרכון סגור.';

  @override
  String get verificationNfcTip3 => 'להישאר ללא תנועה כעשר שניות.';

  @override
  String get verificationNfcRereadPhotoPage => 'לקרוא שוב את עמוד התמונה';

  @override
  String get verificationManualReviewLink => 'לשלוח את המסמך שלי לבדיקה ידנית';

  @override
  String get verificationFaceTitle => 'השבב נקרא.';

  @override
  String get verificationFaceSubtitle =>
      'נשאר סלפי בתנועה, שיושווה לתמונה שבשבב.';

  @override
  String get verificationFaceAction => 'לצלם את הסלפי';

  @override
  String get verificationSubmitSending => 'מתבצע אימות…';

  @override
  String get verificationSubmitPreparing => 'מתבצעת הכנה…';

  @override
  String get verificationDoneTitle => 'הזהות אומתה.';

  @override
  String get verificationDoneSubtitle =>
      'השבב במסמך שלך והסלפי תואמים. בפרופיל שלך מופיע עכשיו התג.';

  @override
  String get verificationDoneAction => 'סיום';

  @override
  String get verificationBadgeLabel => 'זהות מאומתת';

  @override
  String get verificationDoneBadgeCaption => 'מה שאחרים רואים בפרופיל שלך.';

  @override
  String get verificationDoneStoredLabel => 'תמונות ושבב';

  @override
  String get verificationDoneStoredValue => 'לעולם לא נשמרים';

  @override
  String get verificationDoneKeptLabel => 'נשמר';

  @override
  String get verificationDoneKeptValue => 'מדינה, תפוגה, טביעה אנונימית';

  @override
  String get verificationDoneProfileLabel => 'פרופיל';

  @override
  String get verificationDoneProfileValue => 'תאריך הלידה מהמסמך';

  @override
  String get verificationComingSoon => 'בקרוב';

  @override
  String get verificationFailureChipDataInvalid => 'נתוני השבב אינם קריאים.';

  @override
  String get verificationFailureChipSignatureInvalid =>
      'לא ניתן היה לאמת את חתימת המסמך.';

  @override
  String get verificationFailureNotRecognized => 'המסמך לא זוהה.';

  @override
  String get verificationDocumentExpired => 'תוקף המסמך פג.';

  @override
  String get verificationFailureUnderage => 'נדרש גיל 18 כדי לאמת זהות.';

  @override
  String get verificationDocumentAlreadyUsed =>
      'המסמך הזה כבר משויך לחשבון אחר.';

  @override
  String get verificationDocumentBanned => 'אי אפשר להשתמש במסמך הזה.';

  @override
  String get verificationDocumentFaceMismatch =>
      'אין התאמה בין הפנים שלך לתמונה שבמסמך.';

  @override
  String get verificationFailureSessionExpired => 'פג תוקף הסשן.';

  @override
  String get verificationFailureImagesUnreadable =>
      'לא ניתן היה לקרוא את התמונות.';

  @override
  String get verificationFailureNoFace => 'לא זוהו פנים.';

  @override
  String get verificationFailureMultipleFaces =>
      'יש לוודא שרק אדם אחד מופיע בפריים.';

  @override
  String get verificationFailureFaceTooSmall => 'להתקרב למצלמה.';

  @override
  String get verificationFailurePoseMismatch => 'התנועות שנדרשו לא זוהו.';

  @override
  String get verificationFailureDuplicateFrames => 'להזיז את הראש כפי שהתבקש.';

  @override
  String get verificationFailureInconsistentIdentity =>
      'הפנים השתנו במהלך הצילום.';

  @override
  String get verificationFailureNoProfilePhoto =>
      'קודם כול יש להוסיף תמונה לפרופיל.';

  @override
  String get verificationFailureProfileMismatch =>
      'אין התאמה בין הפנים שלך לתמונת הפרופיל.';

  @override
  String get verificationFailureDailyLimit =>
      'מכסת הניסיונות להיום מוצתה. אפשר לחזור מחר.';

  @override
  String get verificationFailureGeneric => 'האימות נכשל.';

  @override
  String get verificationFailureNoNfc => 'בטלפון הזה אין קורא NFC.';

  @override
  String get verificationFailureNfcDisabled => 'יש להפעיל NFC בהגדרות הטלפון.';

  @override
  String get verificationFailureTagLost =>
      'המסמך זז. יש להחזיק אותו ללא תנועה צמוד לטלפון.';

  @override
  String get verificationFailureChipMismatch =>
      'הפרטים שהוזנו אינם תואמים לשבב.';

  @override
  String get verificationFailureUnreadableDocument =>
      'אי אפשר לקרוא את המסמך הזה.';

  @override
  String get verificationFailureChipSilent => 'השבב לא הגיב.';

  @override
  String get verificationFailureReadFailed => 'הקריאה נכשלה.';

  @override
  String get verificationFailureConnection =>
      'אין אפשרות להתחבר. יש לבדוק את החיבור.';

  @override
  String get verificationActionRereadDocument => 'לקרוא שוב את המסמך';

  @override
  String get verificationActionOtherDocument => 'מסמך אחר';

  @override
  String get verificationReasonNoFace =>
      'לא זוהו פנים. יש לעמוד מול המצלמה במקום מואר.';

  @override
  String get verificationReasonMultipleFaces =>
      'זוהו כמה פנים. יש להישאר לבד בפריים.';

  @override
  String get verificationReasonFaceTooSmall =>
      'המצלמה רחוקה מדי מהפנים. יש להתקרב אליה.';

  @override
  String get verificationReasonPoseMismatch =>
      'התנוחות שנדרשו לא זוהו. יש לפעול בדיוק לפי ההוראות.';

  @override
  String get verificationReasonDuplicateFrames =>
      'התמונות דומות מדי. יש להזיז את הראש כפי שהתבקש.';

  @override
  String get verificationReasonInconsistentIdentity =>
      'התמונות אינן מציגות את אותו אדם. יש להתחיל מחדש כשאף אחד אחר לא נמצא בפריים.';

  @override
  String get verificationReasonNoProfilePhoto =>
      'קודם כול יש להוסיף לפרופיל תמונה שבה רואים את הפנים בבירור.';

  @override
  String get verificationReasonProfileMismatch =>
      'אין התאמה בין הפנים שלך לתמונה הראשית. יש לבחור תמונה עדכנית שבה רואים אותך בבירור.';

  @override
  String get verificationReasonDailyLimit =>
      'מכסת הניסיונות להיום מוצתה. אפשר לחזור מחר.';

  @override
  String get verificationReasonSessionExpired =>
      'פג תוקף הסשן. יש להתחיל מחדש.';

  @override
  String get verificationReasonSessionInvalid =>
      'הסשן אינו תקף עוד. יש להתחיל מחדש.';

  @override
  String get verificationReasonImagesUnreadable =>
      'לא ניתן היה לקרוא את התמונות. יש להתחיל מחדש.';

  @override
  String get verificationReasonAppUpdate =>
      'יש לעדכן את האפליקציה כדי לאמת את הפרופיל.';

  @override
  String get verificationReasonChipAuth => 'לא ניתן היה לאמת את השבב שבמסמך.';

  @override
  String get verificationReasonUnderage => 'נדרש גיל 18 לפחות.';

  @override
  String get verificationReasonNetwork =>
      'אין אפשרות להתחבר. יש לבדוק את הרשת ולנסות שוב.';

  @override
  String get verificationReasonGeneric =>
      'אירעה שגיאה. אפשר לנסות שוב בעוד רגע.';

  @override
  String get verificationNfcAlertApproach =>
      'יש לקרב את המסמך לחלק העליון של הטלפון.';

  @override
  String get verificationNfcAlertAuthenticating =>
      'אין לזוז. מתבצע חיבור מאובטח…';

  @override
  String get verificationNfcAlertReadingPhoto => 'קריאת התמונה… 40%';

  @override
  String get verificationNfcAlertReadingSignature => 'קריאת החתימה… 85%';

  @override
  String get verificationNfcAlertDone => 'הסתיים.';
}
