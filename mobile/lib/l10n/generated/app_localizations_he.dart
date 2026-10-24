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
  String get profileCoupleAvailableBody => 'יש התאמה. אפשר להפעיל מצב זוג כדי לשתף פעילויות יחד.';

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
  String get profileCompatibilityUnlockBody => 'מחושב לפי אורח החיים, הכוונות והערכים.';

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
  String get profileCompatibilityIncomplete => 'כדאי להשלים את הפרופילים כדי לראות עוד פרטים';

  @override
  String get profileCompatibilityNote => 'הציון מבוסס על ההעדפות והדברים המשותפים';

  @override
  String get profileCompatibilityGotIt => 'הבנתי';

  @override
  String get profilePromptsMine => 'השאלות שלי';

  @override
  String get profilePromptsSubtitle => 'אפשר לענות על שאלות כדי להראות את האישיות שלך';

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
  String get profileIntentionMarriageDescription => 'חיפוש אחר בן/בת הזוג לחיים';

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
  String get profileDenominationModernOrthodox => 'דתי לאומי (אורתודוקסי מודרני)';

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
  String get profileSetupPhotosSubtitle => 'יש להוסיף לפחות 2 תמונות כדי להמשיך';

  @override
  String get profileSetupPhotosTip => 'פרופילים עם תמונות באיכות טובה מקבלים פי 3 יותר התאמות.';

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
  String get profileShadchanNote => 'AI Shadchan ישתמש בהעדפות אלה כדי להציע פרופילים מתאימים.';

  @override
  String get profileReportThisProfile => 'לדווח על הפרופיל';

  @override
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageSystem => 'שפת הטלפון';
}
