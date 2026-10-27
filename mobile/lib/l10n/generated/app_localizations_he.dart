// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get authLoginEyebrow => 'היכרויות · הקהילה היהודית';

  @override
  String get authLoginTagline => 'היכרויות רציניות בין אנשים עם ערכים משותפים.';

  @override
  String get authLoginApple => 'המשך עם Apple';

  @override
  String get authLoginGoogle => 'המשך עם Google';

  @override
  String get authLoginDev => 'התחברות מדומה (פיתוח)';

  @override
  String authLegal(String terms, String privacy) {
    return 'המשך מהווה הסכמה $terms ו$privacy.';
  }

  @override
  String get authLegalTermsLink => 'לתנאי השימוש';

  @override
  String get authLegalPrivacyLink => 'למדיניות הפרטיות';

  @override
  String get authErrorGeneric => 'אירעה שגיאה. יש לנסות שוב.';

  @override
  String get authErrorCancelled => 'ההתחברות בוטלה.';

  @override
  String get authErrorUnsupported => 'שיטת ההתחברות הזו אינה זמינה במכשיר הזה.';

  @override
  String authErrorAccountDisabled(String contact) {
    return 'החשבון שלך הושבת. כתבו לנו אל $contact.';
  }

  @override
  String get authRouteErrorTitle => 'העמוד לא נמצא';

  @override
  String get authRouteErrorBody => 'אירעה שגיאה';

  @override
  String get authRouteErrorHome => 'חזרה לדף הבית';

  @override
  String get authLoginReviewLink => 'התחברות עם שם משתמש';

  @override
  String get authReviewTitle => 'התחברות עם שם משתמש';

  @override
  String get authReviewIntro => 'יש להזין את שם המשתמש והסיסמה שנמסרו.';

  @override
  String get authReviewUsernameLabel => 'שם משתמש';

  @override
  String get authReviewPasswordLabel => 'סיסמה';

  @override
  String get authReviewShowPassword => 'הצגת הסיסמה';

  @override
  String get authReviewHidePassword => 'הסתרת הסיסמה';

  @override
  String get authReviewSubmit => 'התחברות';

  @override
  String get authErrorInvalidCredentials => 'שם המשתמש או הסיסמה שגויים.';

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
  String get chatListTitle => 'הודעות';

  @override
  String get chatListSearchHint => 'חיפוש';

  @override
  String get chatListLoadErrorTitle => 'לא ניתן לטעון';

  @override
  String get chatListLoadErrorBody => 'יש לבדוק את החיבור ולנסות שוב.';

  @override
  String get chatListEmptyTitle => 'עדיין אין שיחות';

  @override
  String get chatListEmptyBody =>
      'השיחות שלך יופיעו כאן מיד אחרי ההתאמה הראשונה.';

  @override
  String get chatListEmptyAction => 'לגלות';

  @override
  String chatListNoResults(String query) {
    return 'אין תוצאות עבור “$query”.';
  }

  @override
  String get chatListUnknownMember => 'משתמש';

  @override
  String get chatNewMatch => 'התאמה חדשה';

  @override
  String chatListUnreadLabel(String name) {
    return '$name, הודעה שלא נקראה';
  }

  @override
  String get chatPhotoLabel => 'תמונה';

  @override
  String get chatVoiceLabel => 'הודעה קולית';

  @override
  String get chatRemovedLabel => 'ההודעה הוסרה';

  @override
  String get chatOtherFallbackName => 'ההתאמה';

  @override
  String get chatAuthorYou => 'את/ה';

  @override
  String get chatHeaderLoading => 'בטעינה…';

  @override
  String get chatHeaderTyping => 'הקלדה…';

  @override
  String get chatHeaderOptions => 'אפשרויות';

  @override
  String get chatOptionsViewProfile => 'לצפות בפרופיל';

  @override
  String get chatOptionsMute => 'להשתיק התראות';

  @override
  String get chatOptionsBlock => 'לחסום';

  @override
  String get chatMutedConfirmation => 'ההתראות של השיחה הזו הושתקו';

  @override
  String get chatBlockFallbackName => 'משתמש זה';

  @override
  String get chatLoading => 'טעינת השיחה';

  @override
  String get chatEmptyTitle => 'לומר שלום.';

  @override
  String get chatEmptyBody => 'שליחת ההודעה הראשונה שוברת את הקרח.';

  @override
  String chatMatchStart(String date) {
    return 'התאמה · $date';
  }

  @override
  String chatNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count הודעות חדשות',
      two: 'שתי הודעות חדשות',
      one: 'הודעה חדשה אחת',
    );
    return '$_temp0';
  }

  @override
  String get chatTypingSemantics => 'מתבצעת הקלדה';

  @override
  String chatSeenAt(String time) {
    return 'נקראה ב־$time';
  }

  @override
  String get chatFailedRetry => 'השליחה נכשלה · לנסות שוב';

  @override
  String get chatMenuReply => 'תשובה';

  @override
  String get chatMenuCopy => 'העתקה';

  @override
  String get chatMenuUnsend => 'הסרה';

  @override
  String get chatMenuClose => 'סגירת התפריט';

  @override
  String get chatCopied => 'ההודעה הועתקה';

  @override
  String get chatReportThanks => 'תודה, אנחנו בודקים את ההודעה.';

  @override
  String get chatReactionsTitle => 'תגובות';

  @override
  String get chatReportTitle => 'דיווח על ההודעה';

  @override
  String get chatReportReasonScam => 'הונאה או בקשת כסף';

  @override
  String get chatReportReasonHarassment => 'הטרדה או התבטאויות לא הולמות';

  @override
  String get chatReportReasonInappropriate => 'תוכן לא הולם';

  @override
  String get chatReportReasonOther => 'אחר';

  @override
  String get chatScamAdviceTitle => 'הגנה מפני הונאות';

  @override
  String get chatScamAdviceMoney =>
      'אין לשלוח לעולם כסף, כרטיסי מתנה או מטבעות קריפטוגרפיים.';

  @override
  String get chatScamAdviceApps =>
      'יש להיזהר ממי שמבקש במהירות לעבור ל־WhatsApp, ל־Telegram או ל־Signal.';

  @override
  String get chatScamAdviceVideo => 'מומלץ לקיים שיחת וידאו לפני שמתקדמים.';

  @override
  String get chatScamAdviceReport =>
      'במקרה של ספק, יש לדווח על השיחה: אנחנו בודקים אותה.';

  @override
  String get chatScamTitle => 'לנהוג בזהירות';

  @override
  String get chatScamBody => 'אין להעביר כסף לאדם שלא פגשתם.';

  @override
  String get chatScamLearnMore => 'למידע נוסף';

  @override
  String get chatPhotoReveal => 'לצפות בתמונה';

  @override
  String get chatVoicePlayFailed => 'לא ניתן להשמיע';

  @override
  String get chatVoicePlay => 'השמעת ההודעה הקולית';

  @override
  String get chatVoicePause => 'השהיה';

  @override
  String get chatComposerHint => 'הודעה';

  @override
  String get chatComposerAttach => 'צירוף תמונות';

  @override
  String get chatComposerSend => 'שליחה';

  @override
  String get chatComposerSendVoice => 'שליחת ההודעה הקולית';

  @override
  String get chatComposerPhotoError =>
      'לא ניתן להוסיף את התמונה. יש לבדוק את ההרשאות.';

  @override
  String get chatComposerMicDenied =>
      'יש לאשר גישה למיקרופון בהגדרות כדי לשלוח הודעה קולית.';

  @override
  String get chatComposerRecordError => 'לא ניתן להקליט כרגע. יש לנסות שוב.';

  @override
  String get chatComposerHoldLonger =>
      'יש להחזיק את המיקרופון זמן רב יותר כדי להקליט.';

  @override
  String get chatComposerHoldHint =>
      'יש להחזיק את המיקרופון כדי להקליט הודעה קולית.';

  @override
  String get chatMicSemantics => 'החזקה להקלטת הודעה קולית';

  @override
  String get chatAttachPhotos => 'תמונות';

  @override
  String get chatAttachPhotosLimit => 'עד 10 בכל פעם';

  @override
  String get chatAttachCamera => 'מצלמה';

  @override
  String get chatRecordingCancel => 'ביטול ההקלטה';

  @override
  String get chatRecordingRelease => 'יש לשחרר כדי לבטל';

  @override
  String get chatRecordingSlide => '‹ החלקה לביטול';

  @override
  String get chatReplyCancel => 'ביטול התשובה';

  @override
  String chatReplyToOther(String name) {
    return 'תשובה אל $name';
  }

  @override
  String get chatReplyToMine => 'תשובה להודעה שלך';

  @override
  String get chatErrorSessionExpired => 'פג תוקף ההתחברות, יש להתחבר מחדש.';

  @override
  String get chatErrorCannotUnsend => 'לא ניתן עוד להסיר את ההודעה.';

  @override
  String get chatErrorConversationGone => 'השיחה כבר אינה זמינה.';

  @override
  String get chatErrorBlocked => 'לא ניתן עוד לכתוב בשיחה הזו.';

  @override
  String get chatErrorTooLarge => 'הקובץ גדול מדי.';

  @override
  String get chatErrorRateLimited => 'יותר מדי שליחות, יש להמתין רגע.';

  @override
  String get chatErrorServer => 'השרת אינו זמין, יש לנסות שוב.';

  @override
  String get chatErrorFileRejected => 'הקובץ נדחה, יש לנסות קובץ אחר.';

  @override
  String get chatErrorMessageRejected => 'ההודעה נדחתה.';

  @override
  String get chatErrorTimeout => 'תם הזמן, יש לבדוק את החיבור.';

  @override
  String get chatErrorNetwork => 'אין חיבור לאינטרנט.';

  @override
  String get chatErrorUnknown => 'אירעה שגיאה.';

  @override
  String get chatErrorTooManyPhotos => 'עד עשר תמונות בכל הודעה.';

  @override
  String get chatErrorNotYetSent => 'ההודעה עדיין לא נשלחה.';

  @override
  String get chatErrorMessageGone => 'ההודעה כבר לא קיימת.';

  @override
  String get chatErrorNotAuthor => 'ניתן להסיר הודעה רק על ידי מי ששלח אותה.';

  @override
  String get chatErrorReactionUnavailable => 'התגובה אינה זמינה.';

  @override
  String get chatErrorSendUnavailable => 'לא ניתן לשלוח כרגע.';

  @override
  String get chatErrorLoadFailed => 'לא ניתן לטעון את השיחה.';

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
  String linkOpenError(String target) {
    return 'לא ניתן לפתוח את $target כרגע.';
  }

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
  String get coupleSpaceSetupExplain =>
      'יש לבחור התאמה. ברגע שהבקשה תאושר, שני הצדדים עוברים למצב זוגי.';

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
  String get duoTutorialWelcomeTitle => 'MAZL בנוי בשביל ה־Duo';

  @override
  String get duoTutorialWelcomeBody =>
      'כשהמכשיר סגור, הלשוניות מסתדרות בעמודה, ממש מתחת לאגודל. אפשר לבצע את המחוות בטלפון, במקביל אלינו.';

  @override
  String get duoTutorialOpenTitle => 'לפתוח אותו';

  @override
  String get duoTutorialOpenBody =>
      'לפרוש את האייפון עד הסוף. השיחות מופיעות לצד הרשימה.';

  @override
  String get duoTutorialBookTitle => 'לקפל אותו כמו ספר';

  @override
  String get duoTutorialBookBody =>
      'לפתוח אותו עד החצי. הקפל הופך לקו בין שתי עמודות: הרשימה בצד אחד, הפרטים בצד השני.';

  @override
  String get duoTutorialTableTitle => 'להניח אותו על השולחן';

  @override
  String get duoTutorialTableBody =>
      'להחזיק אותו כמו מחשב נייד. התמונה נשארת למעלה והכפתורים למטה, מתחת לאגודל.';

  @override
  String get duoTutorialReadyTitle => 'יוצאים לדרך';

  @override
  String get duoTutorialReadyBody =>
      'כל התנוחות מוכרות. את המדריך אפשר לראות שוב בכל עת בהגדרות.';

  @override
  String get duoTutorialSkip => 'דילוג';

  @override
  String get duoTutorialNext => 'הבא';

  @override
  String get duoTutorialStart => 'להתחיל';

  @override
  String get duoTutorialDone => 'בוצע';

  @override
  String duoTutorialProgress(int current, int total) {
    return 'שלב $current מתוך $total';
  }

  @override
  String get duoTutorialSettingsTitle => 'MAZL ב־iPhone Duo';

  @override
  String get duoTutorialSettingsSubtitle => 'לצפות שוב במדריך';

  @override
  String get eventsTitle => 'אירועים';

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
  String get eventsNoOthers => 'אין אירועים נוספים כרגע. כדאי לחזור בקרוב.';

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
      other: '‎$count / $max מקומות',
      one: '‎$count / $max מקום',
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
  String get eventsComingSoon => 'בקרוב';

  @override
  String get eventsNotifyMe => 'עדכנו אותי';

  @override
  String get eventsNotifyRequested => 'נעדכן אותך';

  @override
  String get eventsNotifyRequestedDone => 'נעדכן אותך כשההרשמה תיפתח.';

  @override
  String get eventsNotifyCancelled => 'ההתראה בוטלה';

  @override
  String get eventsNotifyError => 'לא הצלחנו לשמור את הבקשה. נסו שוב.';

  @override
  String get genreLookingForRequired => 'יש לבחור את מי מחפשים';

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
  String get layoutPaneChatTitle => 'לבחור שיחה';

  @override
  String get layoutPaneChatMessage => 'היא נפתחת כאן, לצד הרשימה.';

  @override
  String get layoutPaneProfileTitle => 'לבחור התאמה';

  @override
  String get layoutPaneProfileMessage => 'הפרופיל מוצג כאן, לצד הרשימה.';

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
  String get matchingPicksSeenAll => 'כל הבחירות של היום נצפו.';

  @override
  String matchingPicksNextIn(int hours, int minutes) {
    return 'הבחירות הבאות בעוד $hours שע׳ ו-$minutes דק׳';
  }

  @override
  String matchingPicksUpdatedIn(int hours, int minutes) {
    return 'העדכון הבא בעוד $hours שע׳ ו-$minutes דק׳';
  }

  @override
  String matchingPicksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count פרופילים נבחרו בשבילך',
      two: 'שני פרופילים נבחרו בשבילך',
      one: 'פרופיל אחד נבחר בשבילך',
    );
    return '$_temp0';
  }

  @override
  String get matchingPicksDiscoverMore => 'לגלות עוד פרופילים';

  @override
  String get matchingPicksBadge => 'בחירה';

  @override
  String get matchingFiltersReset => 'איפוס';

  @override
  String get matchingFiltersAge => 'טווח גילאים';

  @override
  String matchingFiltersYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שנה',
      two: 'שנתיים',
      one: 'שנה',
    );
    return '$_temp0';
  }

  @override
  String get matchingFiltersDistance => 'מרחק מרבי';

  @override
  String matchingFiltersKm(int count) {
    return '$count ק״מ';
  }

  @override
  String get matchingFiltersDenomination => 'זרם דתי';

  @override
  String get matchingFiltersKashrut => 'כשרות';

  @override
  String get matchingFiltersShabbatSection => 'שבת';

  @override
  String get matchingFiltersChoiceHint =>
      'אפשר לבחור כמה אפשרויות. פרופילים שלא ענו על השאלה הזו לא יוצגו.';

  @override
  String get matchingFiltersOptions => 'אפשרויות';

  @override
  String get matchingFiltersVerifiedTitle => 'פרופילים מאומתים בלבד';

  @override
  String get matchingFiltersVerifiedHint => 'להציג פרופילים מאומתים בלבד';

  @override
  String get matchingFiltersPhotoTitle => 'עם תמונה בלבד';

  @override
  String get matchingFiltersPhotoHint => 'להסתיר פרופילים ללא תמונה';

  @override
  String get matchingFiltersUpsellTitle => 'פתיחת כל המסננים';

  @override
  String get matchingFiltersUpsellBody => 'המעבר ל-mazl+‎ מאפשר חיפוש מדויק';

  @override
  String get matchingFiltersApply => 'החלת המסננים';

  @override
  String get matchingFiltersSaved => 'המסננים נשמרו';

  @override
  String get matchingFiltersSaveFailed => 'אירעה שגיאה בשמירה';

  @override
  String get matchingFiltersAdvanced => 'מסננים מתקדמים';

  @override
  String get matchingFiltersLoadFailed =>
      'לא ניתן היה לטעון את המסננים המתקדמים.';

  @override
  String get matchingFiltersConsentNeeded =>
      'קריטריונים אלה מחייבים הסכמה לעיבוד אורח החיים הדתי. הם לא נשמרו.';

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
  String get onboardingStart => 'להתחיל';

  @override
  String onboardingStep(String current, String total) {
    return '‎$current / $total';
  }

  @override
  String onboardingPageOf(int current, int total) {
    return 'עמוד $current מתוך $total';
  }

  @override
  String get onboardingPage1Title => 'ברוכים הבאים ל־MAZL';

  @override
  String get onboardingPage1Body =>
      'אפליקציית ההיכרויות שנוצרה עבור הקהילה היהודית.';

  @override
  String get onboardingPage2Title => 'למצוא את המזל שלך';

  @override
  String get onboardingPage2Body =>
      'פרופילים שמתאימים לערכים ולאורח החיים הדתי שלך.';

  @override
  String get onboardingPage3Title => 'מצב זוגיות';

  @override
  String get onboardingPage3Body =>
      'אחרי שמוצאים אהבה, MAZL ממשיכה ללוות: למצוא אהבה ולשמור עליה.';

  @override
  String get onboardingPage3Feature1 => 'זיכרונות ותאריכים חשובים';

  @override
  String get onboardingPage3Feature2 => 'רשימת משאלות לשניים';

  @override
  String get onboardingPage3Feature3 => 'לוח שנה יהודי משותף';

  @override
  String get onboardingPage3Feature4 => 'פעילויות והצעות';

  @override
  String get onboardingPage4Title => 'מצב שבת';

  @override
  String get onboardingPage4Body =>
      'זמני הדלקת נרות והבדלה לעיר שלכם, ומסך מנוחה.';

  @override
  String get onboardingPage5Title => 'הצעות היום';

  @override
  String get onboardingPage5Body =>
      'בכל יום מחכה לכם ב״גילוי״ מבחר קצר של פרופילים.';

  @override
  String get packsSuperLikesLabel => 'סופר לייקים';

  @override
  String get packsSuperLikesTitle => 'נגמרו הסופר לייקים.';

  @override
  String get packsSuperLikesSubtitle =>
      'אפשר להוסיף עוד. סופר לייקים שנרכשו לא פגים לעולם.';

  @override
  String get packsBoostsLabel => 'בוסטים';

  @override
  String get packsBoostsTitle => 'נגמרו הבוסטים.';

  @override
  String packsBoostsSubtitle(int minutes) {
    return 'אפשר להבליט את הפרופיל למשך $minutes דקות. בוסט שנרכש לא פג לעולם.';
  }

  @override
  String packsPackSuperLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Super Likes',
      one: '$count Super Like',
    );
    return '$_temp0';
  }

  @override
  String packsPackBoosts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Boosts',
      one: '$count Boost',
    );
    return '$_temp0';
  }

  @override
  String packsPackSemantics(String quantity, String price) {
    return 'לרכוש $quantity תמורת $price';
  }

  @override
  String get packsLoading => 'טוען הצעות';

  @override
  String get packsStoreUnavailable =>
      'החנות אינה זמינה כרגע. אפשר לנסות שוב בעוד רגע.';

  @override
  String get packsPending =>
      'הרכישה ממתינה לאישור. היתרה תתעדכן מיד לאחר האישור.';

  @override
  String get packsBoostAlreadyActive => 'בוסט כבר פעיל.';

  @override
  String get packsErrorExhausted => 'אין כרגע מה להשתמש בו.';

  @override
  String get plusFeatureUnlimitedLikesTitle => 'לייקים ללא הגבלה';

  @override
  String get plusFeatureUnlimitedLikesDescription =>
      'אפשר לתת לייקים בלי הגבלה יומית.';

  @override
  String get plusFeatureSeeWhoLikesYouTitle => 'לראות מי אהב אותך';

  @override
  String get plusFeatureSeeWhoLikesYouDescription =>
      'אפשר לראות מי אהב אותך עוד לפני שנפגשים.';

  @override
  String get plusFeatureSuperLikesTitle => 'סופר לייקים';

  @override
  String get plusFeatureSuperLikesDescription =>
      'אפשר לבלוט עם 5 סופר לייקים ביום.';

  @override
  String get plusFeatureBoostTitle => 'בוסט';

  @override
  String get plusFeatureBoostDescription =>
      'אפשר להיות בראש הערימה למשך 30 דקות.';

  @override
  String get plusFeatureReadReceiptsTitle => 'אישורי קריאה';

  @override
  String get plusFeatureReadReceiptsDescription =>
      'אפשר לדעת מתי ההודעות נקראו.';

  @override
  String get plusFeatureAdvancedFiltersTitle => 'מסננים מתקדמים';

  @override
  String get plusFeatureAdvancedFiltersDescription =>
      'אפשר לסנן לפי מנהגים, קהילה ועוד.';

  @override
  String get plusFeaturePrioritySupportTitle => 'תמיכה בעדיפות';

  @override
  String get plusFeaturePrioritySupportDescription =>
      'אפשר לקבל מענה מהיר מהצוות שלנו.';

  @override
  String get plusReservedLabel => 'בלעדי ל-mazl+‎';

  @override
  String get plusDiscover => 'לגלות את mazl+‎';

  @override
  String get plusNotNow => 'לא עכשיו';

  @override
  String plusDailyLimitLabel(int limit) {
    return 'מגבלה יומית · ‎$limit / $limit';
  }

  @override
  String get plusDailyLimitTitle => 'הלייקים להיום נגמרו.';

  @override
  String get plusDailyLimitBody =>
      'הם חוזרים בחצות. אפשר גם להמשיך בלי לספור ולראות מי כבר אהב אותך.';

  @override
  String get plusDailyLimitNext => 'הלייקים הבאים בעוד';

  @override
  String get plusDailyLimitWait => 'להמתין עד חצות';

  @override
  String get plusOfferTagline => 'להכיר בלי לספור.';

  @override
  String get plusPerkUnlimitedLikesDetail => 'בלי המגבלה של 10 ביום.';

  @override
  String get plusPerkSeeWhoDetail => 'עוד לפני שנפגשים.';

  @override
  String get plusPerkSuperLikesTitle => '5 סופר לייקים ביום';

  @override
  String get plusPerkSuperLikesDetail => 'במקום אחד בלבד.';

  @override
  String get plusPerkBoostTitle => 'בוסט אחד ביום';

  @override
  String get plusPerkBoostDetail => 'בראש הערימה למשך 30 דקות.';

  @override
  String get plusPerkFiltersDetail => 'מנהגים, קהילה ועוד.';

  @override
  String get plusYourPlan => 'המסלול שלך';

  @override
  String plusMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months חודשים',
      two: 'חודשיים',
      one: 'חודש אחד',
    );
    return '$_temp0';
  }

  @override
  String plusPerMonth(String price) {
    return '$price לחודש';
  }

  @override
  String plusPlanSavings(int percent) {
    return '‎-$percent%';
  }

  @override
  String plusPlanSemantics(String duration, String price, String perMonth) {
    return '$duration, $price, $perMonth';
  }

  @override
  String plusPlanSemanticsSaving(
    String duration,
    String price,
    String perMonth,
    String saving,
  ) {
    return '$duration, $price, $perMonth, חיסכון של $saving';
  }

  @override
  String plusContinuePrice(String price) {
    return 'להמשיך · $price';
  }

  @override
  String get plusAndroidSoon => 'בקרוב באנדרואיד';

  @override
  String get plusRestore => 'שחזור';

  @override
  String get plusTerms => 'תנאי שימוש';

  @override
  String get plusPrivacy => 'פרטיות';

  @override
  String get plusLegalAppStore =>
      'חידוש אוטומטי, אפשר לבטל בכל עת בהגדרות של App Store.';

  @override
  String get plusLegalGooglePlay =>
      'חידוש אוטומטי, אפשר לבטל בכל עת בהגדרות של Google Play.';

  @override
  String get plusPendingApproval =>
      'הרכישה ממתינה לאישור. המנוי יופעל מיד לאחר האישור.';

  @override
  String get plusOfferRestored => 'המנוי שוחזר';

  @override
  String get plusOfferNothingFound => 'לא נמצא מנוי';

  @override
  String get plusPlansSoon => 'המנויים יהיו זמינים בקרוב.';

  @override
  String get plusErrorPurchaseInProgress => 'כבר מתבצעת רכישה.';

  @override
  String get plusErrorOwnedByAnotherAccount =>
      'הרכישה הזו ב-App Store כבר משויכת לחשבון mazl אחר.';

  @override
  String get plusErrorInvalidTransaction =>
      'לא ניתן היה לאמת את הרכישה מול App Store. היא תיבדק שוב בהפעלה הבאה.';

  @override
  String get plusErrorInvalidBody =>
      'לא ניתן היה להעביר את הרכישה כראוי. אפשר לנסות שוב בעוד רגע.';

  @override
  String get plusErrorSignInAgain =>
      'יש להתחבר שוב ל-mazl כדי להשלים את הרכישה.';

  @override
  String get plusErrorOffline => 'אין חיבור. הרכישה נשמרת ותאומת בהקדם האפשרי.';

  @override
  String get plusErrorGeneric => 'הרכישה לא הושלמה. אפשר לנסות שוב בעוד רגע.';

  @override
  String get plusErrorInactive => 'המנוי אינו פעיל.';

  @override
  String get plusErrorRestoreFailed => 'השחזור נכשל. אפשר לנסות שוב בעוד רגע.';

  @override
  String get plusActiveSubscription => 'מנוי פעיל';

  @override
  String plusActiveSubscriptionPlan(String plan) {
    return 'מנוי פעיל · $plan';
  }

  @override
  String get plusWelcomeTitle => 'ברוכים הבאים ל-mazl+‎.';

  @override
  String get plusWelcomeSubtitle => 'הכול פתוח. מאיפה מתחילים?';

  @override
  String plusWelcomeLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count אנשים אהבו אותך',
      two: 'שני אנשים אהבו אותך',
      one: 'אדם אחד אהב אותך',
    );
    return '$_temp0';
  }

  @override
  String get plusWelcomeLikesDetail => 'לראות אותם עכשיו';

  @override
  String get plusWelcomeBoostTitle => 'להפעיל את הבוסט';

  @override
  String get plusWelcomeBoostDetail => 'בראש הערימה למשך 30 דקות';

  @override
  String get plusWelcomeFiltersTitle => 'לדייק את המסננים';

  @override
  String get plusWelcomeFiltersDetail => 'מנהגים, קהילה ועוד';

  @override
  String plusTitleDetail(String title, String detail) {
    return '$title. $detail';
  }

  @override
  String get plusSubscriptionTitle => 'מנוי';

  @override
  String get plusStatusActive => 'פעיל';

  @override
  String get plusStatusCancelled => 'בוטל';

  @override
  String get plusFactPlan => 'מסלול';

  @override
  String get plusFactRenewal => 'חידוש';

  @override
  String get plusFactExpiration => 'תפוגה';

  @override
  String plusPlanAndPrice(String duration, String price) {
    return '$duration · $price';
  }

  @override
  String plusSuperLikesOf(int left, int max) {
    return '$left מתוך $max';
  }

  @override
  String get plusBoostAvailable => 'זמין';

  @override
  String get plusBoostUsed => 'נוצל היום';

  @override
  String get plusLikesLabel => 'לייקים';

  @override
  String get plusLikesUnlimited => 'ללא הגבלה';

  @override
  String get plusManageAppStore => 'לניהול ב-App Store';

  @override
  String get plusManageGooglePlay => 'לניהול ב-Google Play';

  @override
  String get plusManageFailed => 'לא ניתן לפתוח את ניהול המנוי.';

  @override
  String get plusRestorePurchases => 'לשחזר את הרכישות';

  @override
  String get plusNoActiveSubscription => 'אין מנוי פעיל.';

  @override
  String get plusPurchasesRestored => 'הרכישות שוחזרו.';

  @override
  String get plusNothingToRestore => 'לא נמצא מנוי.';

  @override
  String get plusSettingsPitch => 'לייקים ללא הגבלה, לראות מי אהב אותך, בוסט';

  @override
  String get plusUpgradeTo => 'לשדרג ל-mazl+‎';

  @override
  String plusSettingsSemanticsActive(String detail) {
    return 'mazl+‎. $detail';
  }

  @override
  String plusSettingsSemanticsUpgrade(String detail) {
    return 'לשדרג ל-mazl+‎. $detail';
  }

  @override
  String get privacyGateUnverifiable =>
      'לא ניתן לאמת את ההסכמה. יש לבדוק את החיבור.';

  @override
  String get privacyGateAsk => 'כדי למלא את אורח החיים הדתי, יש לתת הסכמה';

  @override
  String get privacyGive => 'לתת הסכמה';

  @override
  String get privacyLockedHint => 'זמין לאחר מתן הסכמה לנתוני אורח החיים הדתי.';

  @override
  String get privacySheetLabel => 'מידע רגיש · סעיף 9 ב-GDPR';

  @override
  String get privacySheetTitle => 'אורח החיים הדתי שלך, בהסכמתך';

  @override
  String get privacySheetBody =>
      'המידע הזה עוזר להציע פרופילים תואמים. זה מידע רגיש, שמעובד רק בהסכמה מפורשת, נפרדת מתנאי השימוש. אפשר לסרב ועדיין להשתמש ב-MAZL.';

  @override
  String get privacySheetCheckbox => 'קראתי את הטקסט ואני נותן/ת הסכמה מפורשת.';

  @override
  String get privacySheetAccept => 'אני מסכים/ה';

  @override
  String get privacySheetDecline => 'להמשיך בלי';

  @override
  String get privacySheetErrorOutdated =>
      'הטקסט עודכן. יש לסגור את החלון ולפתוח אותו מחדש.';

  @override
  String get privacySheetErrorSave =>
      'לא ניתן היה לשמור את הבחירה. יש לנסות שוב.';

  @override
  String get privacySettingsTitle => 'נתוני אורח החיים הדתי';

  @override
  String get privacySettingsGrantedShort => 'ניתנה הסכמה';

  @override
  String get privacySettingsDeniedShort => 'לא ניתנה הסכמה';

  @override
  String get privacySettingsGrantedTitle => 'ההסכמה ניתנה';

  @override
  String get privacySettingsNotGrantedTitle => 'ההסכמה לא ניתנה';

  @override
  String get privacySettingsWithdraw => 'לבטל את ההסכמה';

  @override
  String get privacySettingsWithdrawTitle => 'לבטל את ההסכמה?';

  @override
  String get privacySettingsWithdrawBody =>
      'הזרם, הכשרות, שמירת השבת והכוונה יימחקו מהפרופיל.';

  @override
  String get privacySettingsWithdrawFailed =>
      'לא ניתן היה לבטל את ההסכמה. יש לנסות שוב.';

  @override
  String get privacySettingsLoadFailed =>
      'לא ניתן לטעון את ההסכמה. יש לבדוק את החיבור.';

  @override
  String get analyticsSheetLabel => 'מדידת שימוש';

  @override
  String get analyticsSheetTitle => 'עזרו לשפר את MAZL';

  @override
  String get analyticsSheetBody =>
      'MAZL סופרת את המסכים שבהם ביקרתם ואת השלבים העיקריים (הרשמה, רכישה) כדי להשתפר. אף פעם לא את תוכן ההודעות, התמונות או אורח החיים הדתי שלכם. המזהה שלכם מוצפן בכינוי, ושום דבר לא משותף עם צדדים שלישיים. אפשר לסרב: MAZL תעבוד בדיוק אותו דבר.';

  @override
  String get analyticsSheetAccept => 'אישור';

  @override
  String get analyticsSheetDecline => 'סירוב';

  @override
  String get analyticsSheetErrorOutdated =>
      'הטקסט עודכן. יש לסגור את החלון ולפתוח אותו מחדש.';

  @override
  String get analyticsSheetErrorSave =>
      'לא ניתן היה לשמור את הבחירה. יש לנסות שוב.';

  @override
  String get analyticsSettingsTitle => 'מדידת שימוש';

  @override
  String get analyticsSettingsGrantedShort => 'פעילה';

  @override
  String get analyticsSettingsDeniedShort => 'כבויה';

  @override
  String get analyticsSettingsGrantedTitle => 'מדידת השימוש פעילה';

  @override
  String get analyticsSettingsNotGrantedTitle => 'מדידת השימוש כבויה';

  @override
  String get analyticsSettingsAccept => 'לאשר מדידת שימוש';

  @override
  String get analyticsSettingsWithdraw => 'לבטל את ההסכמה שלי';

  @override
  String get analyticsSettingsLoadFailed =>
      'לא ניתן לקרוא את הבחירה. יש לבדוק את החיבור.';

  @override
  String get analyticsSettingsSaveFailed =>
      'לא ניתן היה לשמור את הבחירה. יש לנסות שוב.';

  @override
  String get profileMyProfile => 'הפרופיל שלי';

  @override
  String get profileEdit => 'עריכה';

  @override
  String get profileSettings => 'הגדרות';

  @override
  String get profileMoreOptions => 'אפשרויות נוספות';

  @override
  String get profileDecline => 'לדחות';

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
  String get profileCompatibilityUnlock => 'לפתוח עם mazl+‎';

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
  String get profileSetupPreferencesNote =>
      'ההעדפות האלה מעצבות את הפרופילים שמופיעים ב״גילוי״. אפשר לשנות אותן בכל עת.';

  @override
  String get profileReportThisProfile => 'לדווח על הפרופיל';

  @override
  String get profileChoiceNotSent => 'הבחירה לא נשלחה. יש לנסות שוב.';

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
  String get settingsShabbatAutoPause => 'זמני שבת';

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
  String get settingsSales => 'תנאי מכירה';

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
  String settingsShabbatBasedOn(String place) {
    return 'מבוסס על $place';
  }

  @override
  String get settingsShabbatDefaultPlace => 'פריז, צרפת';

  @override
  String get settingsShabbatUnknownPlaceHint =>
      'השעות הן של פריז, כי העיר שלכם אינה ידועה. הוסיפו אותה בהגדרות לשעות מדויקות.';

  @override
  String get settingsShabbatExplanation =>
      'הדלקת נרות 18 דקות לפני השקיעה, והבדלה עם צאת הכוכבים. כדי לשנות מקום, עדכנו את העיר בהגדרות.';

  @override
  String get settingsShabbatHeroTitle => 'שבת\nשלום.';

  @override
  String get settingsShabbatHeroSubtitle => 'Mazl נח איתכם.';

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

  @override
  String get settingsRestoreNothing => 'לא נמצא מינוי.';

  @override
  String storefrontCampaignUntil(String date) {
    return 'עד $date';
  }

  @override
  String storefrontDiscountBadge(int percent) {
    return 'מבצע ‎-$percent%';
  }

  @override
  String get storefrontCampaignDefaultCta => 'למימוש ההצעה';

  @override
  String storefrontPlanSemanticsHighlight(String plan, String highlight) {
    return '$plan. $highlight';
  }

  @override
  String get settingsFestiveIconTitle => 'סמל החגים';

  @override
  String get settingsFestiveIconSubtitle =>
      'סמל האפליקציה מתחלף סביב החגים. ‏iOS מציגה התראה בכל החלפה.';

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

  @override
  String get webSessionsTitle => 'מחשבים מחוברים';

  @override
  String get webSessionsSectionLabel => 'MAZL במחשב';

  @override
  String get webSessionsIntro =>
      'אפשר להשתמש ב-MAZL במחשב בכתובת app.mazl.app. כל מחשב נשאר מחובר 7 ימים לכל היותר.';

  @override
  String get webSessionsConnect => 'לחבר מחשב';

  @override
  String get webSessionsConnected => 'המחשב חובר.';

  @override
  String get webSessionsLoadFailed =>
      'לא ניתן לטעון את רשימת המחשבים. יש לבדוק את החיבור.';

  @override
  String get webSessionsEmpty => 'אין כרגע מחשב מחובר.';

  @override
  String get webSessionsListLabel => 'מחשבים';

  @override
  String get webSessionsRevoke => 'לנתק';

  @override
  String webSessionsRevokeNamed(String browser) {
    return 'לנתק את $browser';
  }

  @override
  String get webSessionsRevokeFailed =>
      'לא ניתן היה לנתק את המחשב. יש לנסות שוב.';

  @override
  String get webSessionsRevokeAll => 'לנתק את כל המחשבים';

  @override
  String get webSessionsRevokeAllTitle => 'לנתק את כל המחשבים?';

  @override
  String get webSessionsRevokeAllBody => 'יהיה צורך להתחבר מחדש בכל מחשב.';

  @override
  String get webSessionsRevokeAllConfirm => 'לנתק הכול';

  @override
  String get webSessionsRevokeAllFailed =>
      'לא ניתן היה לנתק את המחשבים. יש לנסות שוב.';

  @override
  String get webSessionsMethodQr => 'חובר באמצעות קוד QR';

  @override
  String get webSessionsMethodGoogle => 'חובר באמצעות Google';

  @override
  String get webSessionsMethodApple => 'חובר באמצעות Apple';

  @override
  String get webSessionsActiveNow => 'פעילות ממש עכשיו';

  @override
  String webSessionsActiveMinutes(int count) {
    return 'פעילות לפני $count דק׳';
  }

  @override
  String webSessionsActiveHours(int count) {
    return 'פעילות לפני $count שע׳';
  }

  @override
  String get webSessionsActiveYesterday => 'פעילות אתמול';

  @override
  String webSessionsActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'פעילות לפני $count ימים',
      two: 'פעילות לפני יומיים',
    );
    return '$_temp0';
  }

  @override
  String webSessionsClockTime(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get webSessionsScanInstruction =>
      'יש לסרוק את קוד ה-QR המוצג ב-app.mazl.app';

  @override
  String get webSessionsScanCameraLabel => 'מצלמה לסריקת קוד QR';

  @override
  String get webSessionsCameraUnavailable =>
      'אין גישה למצלמה. יש לאפשר גישה למצלמה בהגדרות האייפון כדי לסרוק קוד.';

  @override
  String get webSessionsScanNotMazl => 'קוד ה-QR הזה אינו קוד של MAZL.';

  @override
  String get webSessionsScanExpired => 'הקוד פג תוקף. יש להציג קוד חדש במחשב.';

  @override
  String get webSessionsScanTooMany =>
      'יותר מדי ניסיונות. יש להמתין רגע לפני ניסיון נוסף.';

  @override
  String get webSessionsApproveInvalid =>
      'הבקשה כבר אינה תקפה. יש להציג קוד חדש במחשב.';

  @override
  String get webSessionsConnectionProblem =>
      'לא ניתן להתחבר. יש לבדוק את הרשת ולנסות שוב.';

  @override
  String get webSessionsGenericProblem => 'אירעה שגיאה. יש לנסות שוב בעוד רגע.';

  @override
  String get webSessionsConfirmLabel => 'התחברות ל-MAZL במחשב';

  @override
  String get webSessionsConfirmTitle => 'לחבר את המחשב הזה?';

  @override
  String get webSessionsConfirmBrowser => 'דפדפן';

  @override
  String get webSessionsConfirmAddress => 'כתובת';

  @override
  String get webSessionsConfirmAskedAt => 'הבקשה נשלחה בשעה';

  @override
  String get webSessionsConfirmWarning =>
      'יש לסרוק רק את הקוד שמוצג במחשב שלך. אם מישהו מבקש לסרוק קוד, יש לסרב.';

  @override
  String get webSessionsConfirmApprove => 'לחבר';

  @override
  String get webSessionsConfirmDeny => 'לסרב';
}
