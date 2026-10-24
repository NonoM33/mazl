// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

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
  String get chatHeaderOnline => 'מחובר/ת';

  @override
  String get chatHeaderVideoCall => 'שיחת וידאו';

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
  String get icebreakerWidgetTitle => 'קצת השראה?';

  @override
  String get icebreakerWidgetSubtitle => 'כמה רעיונות לשבירת הקרח';

  @override
  String get icebreakerTopicFallback => 'זה';

  @override
  String icebreakerPromptLoved(String promptText, String followUp) {
    return 'אהבתי את התשובה ל־\"$promptText\". $followUp';
  }

  @override
  String icebreakerPromptSmiled(String promptText) {
    return 'התשובה על \"$promptText\" הנעימה לי. אפשר לשמוע עוד?';
  }

  @override
  String icebreakerPromptCurious(String answer, String topic) {
    return 'מעניין אותי למה ענית \"$answer\" בשאלה על $topic';
  }

  @override
  String get icebreakerFollowUpIntrigued => 'זה מסקרן אותי.';

  @override
  String get icebreakerFollowUpKnowMore => 'אשמח לשמוע עוד.';

  @override
  String get icebreakerFollowUpTellMe => 'מה הסיפור?';

  @override
  String get icebreakerFollowUpInteresting => 'זה נשמע מעניין.';

  @override
  String get icebreakerBioTravelRecent =>
      'לאן טיילת לאחרונה? אשמח לשמוע סיפורים.';

  @override
  String get icebreakerBioTravelDream => 'מהו היעד החלומי הבא שלך?';

  @override
  String get icebreakerBioMusicGenre => 'איזו מוזיקה מתנגנת אצלך בזמן האחרון?';

  @override
  String get icebreakerBioMusicConcert => 'היית לאחרונה בהופעה טובה?';

  @override
  String get icebreakerBioCookingNow => 'מה מבשלים אצלך לאחרונה?';

  @override
  String get icebreakerBioCookingSignature => 'מהי המנה המיוחדת שלך?';

  @override
  String get icebreakerBioSportWhich => 'איזה ספורט קרוב ללבך?';

  @override
  String get icebreakerBioSportWatchOrPlay => 'מה עדיף: לצפות או לשחק?';

  @override
  String get icebreakerBioReadingNow => 'מה בקריאה אצלך כרגע?';

  @override
  String get icebreakerBioReadingLastBook =>
      'מהו הספר האחרון שהשאיר עליך רושם?';

  @override
  String get icebreakerBioCinemaRecent => 'ראית לאחרונה סרט טוב?';

  @override
  String get icebreakerBioCinemaOrSeries => 'מה עדיף: קולנוע או סדרות?';

  @override
  String get icebreakerBioHikingTrails => 'יש שבילי הליכה יפים באזור?';

  @override
  String get icebreakerBioHikingBest => 'מהו הטיול הרגלי היפה ביותר שלך?';

  @override
  String get icebreakerBioPhotoSubjects => 'מה הנושא האהוב עליך בצילום?';

  @override
  String get icebreakerBioPhotoCamera => 'באיזה מכשיר צילום משתמשים אצלך?';

  @override
  String get icebreakerOrthodoxSynagogue => 'יש בית כנסת מועדף באזור?';

  @override
  String get icebreakerOrthodoxShabbat => 'איך בדרך כלל עוברת עליך שבת?';

  @override
  String get icebreakerOrthodoxKosherRestaurant => 'יש מסעדה כשרה מועדפת?';

  @override
  String get icebreakerTraditionalTraditions =>
      'אילו מסורות יהודיות הכי חשובות לך?';

  @override
  String get icebreakerTraditionalShabbat =>
      'איך מציינים אצלך את השבת בדרך כלל?';

  @override
  String get icebreakerTraditionalHoliday => 'יש חג יהודי אהוב?';

  @override
  String get icebreakerSecularCulture => 'מה הקשר שלך לתרבות היהודית?';

  @override
  String get icebreakerSecularFamilyTraditions =>
      'יש מסורות משפחתיות ששומרים עליהן?';

  @override
  String get icebreakerSecularHolidays => 'אילו חגים חוגגים אצלך?';

  @override
  String get icebreakerDefaultHoliday => 'מהו החג היהודי האהוב עליך?';

  @override
  String get icebreakerDefaultFamilyTraditions => 'יש מסורות משפחתיות מיוחדות?';

  @override
  String get icebreakerDefaultPracticingFamily => 'גדלת במשפחה שומרת מסורת?';

  @override
  String icebreakerLocationKnowWell(String location) {
    return 'יש לך המלצות על $location?';
  }

  @override
  String icebreakerLocationFavoriteSpot(String location) {
    return 'מהו המקום האהוב עליך ב־$location?';
  }

  @override
  String icebreakerLocationOriginallyFrom(String location) {
    return '$location זה המקום שבו נולדת, או שעברת לשם?';
  }

  @override
  String icebreakerLocationRestaurant(String location) {
    return 'יש מסעדה טובה שכדאי לנסות ב־$location?';
  }

  @override
  String get icebreakerGenericDinnerGuest =>
      'אם אפשר היה לארח לארוחת ערב כל אדם, חי או מת, מי זה היה?';

  @override
  String get icebreakerGenericPerfectDay => 'איך נראה היום המושלם בעיניך?';

  @override
  String get icebreakerGenericHiddenTalent =>
      'יש לך כישרון נסתר שמעטים מכירים?';

  @override
  String get icebreakerGenericSpontaneous =>
      'מה הדבר הכי ספונטני שעשית אי פעם?';

  @override
  String get icebreakerGenericSeaOrMountain => 'מה עדיף בחופשה: ים או הרים?';

  @override
  String get icebreakerGenericLottery =>
      'אם מחר היית זוכה בלוטו, מה היית עושה קודם?';

  @override
  String get icebreakerGenericGuiltyPleasure => 'מהו ה־guilty pleasure שלך?';

  @override
  String get icebreakerGenericDream => 'יש חלום שעוד לא התגשם?';

  @override
  String get icebreakerGenericBestAdvice => 'מהי העצה הטובה ביותר שקיבלת?';

  @override
  String get icebreakerGenericBreakfastOrDinner =>
      'מה עדיף: ארוחת בוקר בחוץ או ארוחת ערב בחוץ?';

  @override
  String get settingsLanguage => 'שפה';

  @override
  String get settingsLanguageSystem => 'שפת הטלפון';
}
