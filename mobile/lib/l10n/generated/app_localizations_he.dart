// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get boostTitle => 'בוסט';

  @override
  String get boostHeadlineActive => 'הבוסט פעיל';

  @override
  String get boostHeadlineIdle => 'להעלות את הפרופיל עם בוסט';

  @override
  String get boostTagline => 'פי 10 יותר אנשים יראו את הפרופיל.';

  @override
  String boostMinutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'נותרו $minutes דקות',
      two: 'נותרו שתי דקות',
      one: 'נותרה דקה אחת',
    );
    return '$_temp0';
  }

  @override
  String get boostDuringTitle => 'במהלך הבוסט הזה';

  @override
  String get boostViews => 'צפיות';

  @override
  String get boostLikes => 'לייקים';

  @override
  String get boostBenefitsTitle => 'היתרונות של הבוסט';

  @override
  String get boostBenefitFirst => 'הפרופיל יופיע ראשון בהצעות';

  @override
  String boostBenefitVisibility(int minutes) {
    return 'פי 10 יותר חשיפה למשך $minutes דקות';
  }

  @override
  String get boostBenefitMatches => 'יותר סיכוי ליצור מאץ\'';

  @override
  String get boostBenefitStats => 'סטטיסטיקות בזמן אמת במהלך הבוסט';

  @override
  String get boostActivate => 'להפעיל את הבוסט';

  @override
  String boostRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'נותרו $count בוסטים',
      two: 'נותרו שני בוסטים',
      one: 'נותר בוסט אחד',
    );
    return '$_temp0';
  }

  @override
  String get boostActivated => 'הבוסט הופעל. הפרופיל שלך מוצג עכשיו בראש.';

  @override
  String get boostActivateFailed => 'אירעה שגיאה בהפעלה';

  @override
  String get boostUpsellTitle => 'בוסטים ללא הגבלה';

  @override
  String get boostUpsellBody => 'אפשר להשתמש בבוסט ללא הגבלה עם mazl+‎';

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
  String get matchingMatchesTitle => 'מאצ\'ים';

  @override
  String get matchingMatchesWhoLikedYou => 'מי אהב אותך';

  @override
  String matchingMatchesNewSection(int count) {
    return 'חדשים · $count';
  }

  @override
  String matchingMatchesConversationsSection(int count) {
    return 'שיחות · $count';
  }

  @override
  String get matchingMatchesLoadFailed => 'לא ניתן לטעון את המאצ\'ים';

  @override
  String get matchingMatchesEmptyTitle => 'עדיין אין מאצ\'ים';

  @override
  String get matchingMatchesEmptyBody => 'כדאי להמשיך לגלות פרופילים.';

  @override
  String get matchingMatchesUnknownName => 'ללא שם';

  @override
  String get matchingMatchesWriteHint => 'אפשר לכתוב הודעה';

  @override
  String matchingMatchesViewProfileOf(String name) {
    return 'לצפייה בפרופיל של $name';
  }

  @override
  String matchingMatchesSeeMore(int count) {
    return 'לראות עוד $count';
  }

  @override
  String matchingMatchedDaysAgo(int count) {
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
  String matchingMatchedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count שבועות',
      two: 'לפני שבועיים',
      one: 'לפני שבוע',
    );
    return '$_temp0';
  }

  @override
  String matchingMatchedMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count חודשים',
      two: 'לפני חודשיים',
      one: 'לפני חודש',
    );
    return '$_temp0';
  }

  @override
  String get matchingCouplePromoTitle => 'קרה מאץ\'?';

  @override
  String get matchingCouplePromoDismiss => 'הסתרה';

  @override
  String get matchingCouplePromoBody =>
      'שאלות יומיות, אבני דרך, לוח שנה יהודי משותף: בונים את הקשר עם mazl.';

  @override
  String get matchingCouplePromoAction => 'להפעיל מצב זוגי';

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
  String get shadchanTitle => 'השדכן הדיגיטלי';

  @override
  String get shadchanHeaderTitle => 'שידוכים אישיים בשבילך';

  @override
  String get shadchanHeaderBody =>
      'הבינה המלאכותית שלנו בוחנת את ההעדפות שלך כדי להציע פרופילים תואמים מאוד';

  @override
  String get shadchanTodayTitle => 'הצעות להיום';

  @override
  String shadchanNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count חדשות',
      one: '$count חדשה',
    );
    return '$_temp0';
  }

  @override
  String get shadchanEmptyTitle => 'כל ההצעות נבדקו.';

  @override
  String get shadchanEmptyBody => 'כדאי לחזור מחר להצעות שידוך חדשות.';

  @override
  String get shadchanEmptyAction => 'לגלות עוד פרופילים';

  @override
  String shadchanPassed(String name) {
    return 'ההצעה של $name הוסרה';
  }

  @override
  String shadchanLiked(String name) {
    return 'ההצעה של $name נוספה ללייקים שלך';
  }

  @override
  String get shadchanHowTitle => 'איך זה עובד?';

  @override
  String get shadchanHowStepAnalyze =>
      'הבינה המלאכותית שלנו בוחנת את הפרופיל וההעדפות שלך';

  @override
  String get shadchanHowStepCompare => 'היא משווה אותם לפרופילים תואמים';

  @override
  String get shadchanHowStepDaily => 'מדי יום מתקבלות הצעות מותאמות אישית';

  @override
  String get shadchanWhy => 'למה ההצעה הזו?';

  @override
  String get shadchanMatchBadge => 'מאץ\'';

  @override
  String get shadchanReasonSamePractice => 'אותה רמת שמירת מצוות';

  @override
  String get shadchanReasonInterests => 'תחומי עניין משותפים: טיולים, בישול';

  @override
  String get shadchanReasonGoals => 'מטרות דומות';

  @override
  String get shadchanReasonFamily => 'ערכי משפחה תואמים';

  @override
  String get shadchanReasonMusic => 'תשוקה משותפת למוזיקה';

  @override
  String get shadchanReasonLocation => 'אזורי מגורים תואמים';

  @override
  String get shadchanReasonReligion => 'אורח חיים דתי דומה';

  @override
  String get shadchanReasonProfession => 'תחומי עיסוק קרובים';

  @override
  String get shadchanReasonCouple => 'תפיסה זהה של זוגיות';

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
