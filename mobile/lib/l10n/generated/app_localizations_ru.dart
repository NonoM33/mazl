// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get chatListTitle => 'Сообщения';

  @override
  String get chatListSearchHint => 'Поиск';

  @override
  String get chatListLoadErrorTitle => 'Не удаётся загрузить';

  @override
  String get chatListLoadErrorBody =>
      'Проверьте подключение и повторите попытку.';

  @override
  String get chatListEmptyTitle => 'Пока нет бесед';

  @override
  String get chatListEmptyBody =>
      'Ваши беседы появятся здесь, как только у Вас будет первый мэтч.';

  @override
  String get chatListEmptyAction => 'Смотреть анкеты';

  @override
  String chatListNoResults(String query) {
    return 'Нет результатов по запросу «$query».';
  }

  @override
  String get chatListUnknownMember => 'Пользователь';

  @override
  String get chatNewMatch => 'Новый мэтч';

  @override
  String chatListUnreadLabel(String name) {
    return '$name, непрочитанное сообщение';
  }

  @override
  String get chatPhotoLabel => 'Фото';

  @override
  String get chatVoiceLabel => 'Голосовое сообщение';

  @override
  String get chatRemovedLabel => 'Сообщение удалено';

  @override
  String get chatOtherFallbackName => 'Ваш собеседник';

  @override
  String get chatAuthorYou => 'Вы';

  @override
  String get chatHeaderLoading => 'Загрузка…';

  @override
  String get chatHeaderTyping => 'печатает…';

  @override
  String get chatHeaderOnline => 'В сети';

  @override
  String get chatHeaderVideoCall => 'Видеозвонок';

  @override
  String get chatHeaderOptions => 'Параметры';

  @override
  String get chatOptionsViewProfile => 'Открыть профиль';

  @override
  String get chatOptionsMute => 'Отключить уведомления';

  @override
  String get chatOptionsBlock => 'Заблокировать';

  @override
  String get chatMutedConfirmation => 'Уведомления для этой беседы отключены';

  @override
  String get chatBlockFallbackName => 'Этот пользователь';

  @override
  String get chatLoading => 'Загрузка беседы';

  @override
  String get chatEmptyTitle => 'Поздоровайтесь.';

  @override
  String get chatEmptyBody =>
      'Отправьте первое сообщение, чтобы начать общение.';

  @override
  String chatMatchStart(String date) {
    return 'Мэтч · $date';
  }

  @override
  String chatNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count нового сообщения',
      many: '$count новых сообщений',
      few: '$count новых сообщения',
      one: '$count новое сообщение',
    );
    return '$_temp0';
  }

  @override
  String get chatTypingSemantics => 'Ваш собеседник печатает';

  @override
  String chatSeenAt(String time) {
    return 'Просмотрено в $time';
  }

  @override
  String get chatFailedRetry => 'Не отправлено · Повторить';

  @override
  String get chatMenuReply => 'Ответить';

  @override
  String get chatMenuCopy => 'Копировать';

  @override
  String get chatMenuUnsend => 'Отозвать';

  @override
  String get chatMenuClose => 'Закрыть меню';

  @override
  String get chatCopied => 'Сообщение скопировано';

  @override
  String get chatReportThanks => 'Спасибо, мы проверяем это сообщение.';

  @override
  String get chatReactionsTitle => 'Реакции';

  @override
  String get chatReportTitle => 'Пожаловаться на сообщение';

  @override
  String get chatReportReasonScam => 'Мошенничество или просьба о деньгах';

  @override
  String get chatReportReasonHarassment =>
      'Домогательства или неуместные высказывания';

  @override
  String get chatReportReasonInappropriate => 'Неприемлемый контент';

  @override
  String get chatReportReasonOther => 'Другое';

  @override
  String get chatScamAdviceTitle => 'Как защититься от мошенников';

  @override
  String get chatScamAdviceMoney =>
      'Никогда не отправляйте деньги, подарочные карты или криптовалюту.';

  @override
  String get chatScamAdviceApps =>
      'Остерегайтесь тех, кто очень быстро просит перейти в WhatsApp, Telegram или Signal.';

  @override
  String get chatScamAdviceVideo =>
      'Сделайте видеозвонок, прежде чем двигаться дальше.';

  @override
  String get chatScamAdviceReport =>
      'Если есть сомнения, пожалуйтесь на беседу: мы её проверим.';

  @override
  String get chatScamTitle => 'Будьте осторожны';

  @override
  String get chatScamBody =>
      'Никогда не переводите деньги тем, с кем Вы не встречались.';

  @override
  String get chatScamLearnMore => 'Подробнее';

  @override
  String get chatPhotoReveal => 'Показать фото';

  @override
  String get chatVoicePlayFailed => 'Не удаётся воспроизвести';

  @override
  String get chatVoicePlay => 'Воспроизвести голосовое сообщение';

  @override
  String get chatVoicePause => 'Пауза';

  @override
  String get chatComposerHint => 'Сообщение';

  @override
  String get chatComposerAttach => 'Прикрепить фото';

  @override
  String get chatComposerSend => 'Отправить';

  @override
  String get chatComposerSendVoice => 'Отправить голосовое сообщение';

  @override
  String get chatComposerPhotoError =>
      'Не удалось добавить фото. Проверьте разрешения.';

  @override
  String get chatComposerMicDenied =>
      'Разрешите доступ к микрофону в настройках, чтобы отправлять голосовые сообщения.';

  @override
  String get chatComposerRecordError =>
      'Сейчас не удаётся записать. Повторите попытку.';

  @override
  String get chatComposerHoldLonger =>
      'Удерживайте микрофон дольше, чтобы записать сообщение.';

  @override
  String get chatComposerHoldHint =>
      'Удерживайте микрофон, чтобы записать голосовое сообщение.';

  @override
  String get chatMicSemantics =>
      'Удерживайте, чтобы записать голосовое сообщение';

  @override
  String get chatAttachPhotos => 'Фото';

  @override
  String get chatAttachPhotosLimit => 'До 10 за раз';

  @override
  String get chatAttachCamera => 'Камера';

  @override
  String get chatRecordingCancel => 'Отменить запись';

  @override
  String get chatRecordingRelease => 'Отпустите, чтобы отменить';

  @override
  String get chatRecordingSlide => '‹ Сдвиньте, чтобы отменить';

  @override
  String get chatReplyCancel => 'Отменить ответ';

  @override
  String chatReplyToOther(String name) {
    return 'Ответ для $name';
  }

  @override
  String get chatReplyToMine => 'Ответ на Ваше сообщение';

  @override
  String get chatErrorSessionExpired => 'Сессия истекла, войдите снова.';

  @override
  String get chatErrorCannotUnsend => 'Это сообщение больше нельзя отозвать.';

  @override
  String get chatErrorConversationGone => 'Эта беседа больше недоступна.';

  @override
  String get chatErrorBlocked => 'Вы больше не можете писать в этой беседе.';

  @override
  String get chatErrorTooLarge => 'Файл слишком большой.';

  @override
  String get chatErrorRateLimited =>
      'Слишком много отправок, подождите немного.';

  @override
  String get chatErrorServer => 'Сервер недоступен, повторите попытку.';

  @override
  String get chatErrorFileRejected => 'Файл отклонён, попробуйте другой.';

  @override
  String get chatErrorMessageRejected => 'Сообщение отклонено.';

  @override
  String get chatErrorTimeout =>
      'Время ожидания истекло, проверьте подключение.';

  @override
  String get chatErrorNetwork => 'Нет подключения к интернету.';

  @override
  String get chatErrorUnknown => 'Произошла ошибка.';

  @override
  String get chatErrorTooManyPhotos =>
      'Не более десяти фото в одном сообщении.';

  @override
  String get chatErrorNotYetSent => 'Это сообщение ещё не отправлено.';

  @override
  String get chatErrorMessageGone => 'Этого сообщения больше нет.';

  @override
  String get chatErrorNotAuthor => 'Только автор может отозвать сообщение.';

  @override
  String get chatErrorReactionUnavailable => 'Реакция недоступна.';

  @override
  String get chatErrorSendUnavailable => 'Сейчас не удаётся отправить.';

  @override
  String get chatErrorLoadFailed => 'Не удалось загрузить беседу.';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonBack => 'Назад';

  @override
  String get errorTimeout => 'Время ожидания истекло. Проверьте подключение.';

  @override
  String get errorNetwork =>
      'Нет подключения. Проверьте сеть и повторите попытку.';

  @override
  String get errorServer => 'Сервер недоступен. Повторите попытку чуть позже.';

  @override
  String get errorSessionExpired => 'Сеанс истёк. Войдите снова.';

  @override
  String get errorForbidden => 'Это действие не разрешено.';

  @override
  String get errorNotFound => 'Не найдено: этот элемент больше не существует.';

  @override
  String get errorConflict => 'Это действие больше невозможно.';

  @override
  String get errorTooLarge => 'Файл слишком большой.';

  @override
  String get errorRateLimited => 'Слишком много попыток. Подождите немного.';

  @override
  String get errorInvalid => 'Запрос отклонён. Проверьте введённые данные.';

  @override
  String get errorUnknown => 'Что-то пошло не так. Повторите попытку.';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonRemove => 'Убрать';

  @override
  String get commonSkip => 'Пропустить';

  @override
  String get commonSee => 'Открыть';

  @override
  String get commonShare => 'Поделиться';

  @override
  String get commonReport => 'Пожаловаться';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonLater => 'Позже';

  @override
  String get commonToday => 'Сегодня';

  @override
  String get commonYesterday => 'Вчера';

  @override
  String get commonNotSpecified => 'Не указано';

  @override
  String get commonLoadError => 'Ошибка загрузки';

  @override
  String get icebreakerWidgetTitle => 'Нужно вдохновение?';

  @override
  String get icebreakerWidgetSubtitle =>
      'Несколько идей, с чего начать разговор';

  @override
  String get icebreakerTopicFallback => 'это';

  @override
  String icebreakerPromptLoved(String promptText, String followUp) {
    return 'Мне понравился твой ответ на «$promptText». $followUp';
  }

  @override
  String icebreakerPromptSmiled(String promptText) {
    return 'Твой ответ про «$promptText» заставил меня улыбнуться. Расскажешь подробнее?';
  }

  @override
  String icebreakerPromptCurious(String answer, String topic) {
    return 'Мне интересно, откуда такой ответ — «$answer» — на вопрос про $topic';
  }

  @override
  String get icebreakerFollowUpIntrigued => 'Это меня заинтриговало.';

  @override
  String get icebreakerFollowUpKnowMore => 'Хочется узнать больше.';

  @override
  String get icebreakerFollowUpTellMe => 'Расскажешь?';

  @override
  String get icebreakerFollowUpInteresting => 'Звучит интересно.';

  @override
  String get icebreakerBioTravelRecent =>
      'Какие поездки у тебя были недавно? Хочу послушать твои истории.';

  @override
  String get icebreakerBioTravelDream =>
      'Какое место мечты ты хочешь посетить следующим?';

  @override
  String get icebreakerBioMusicGenre => 'Какую музыку ты слушаешь сейчас?';

  @override
  String get icebreakerBioMusicConcert =>
      'Какой хороший концерт запомнился тебе в последнее время?';

  @override
  String get icebreakerBioCookingNow =>
      'Что вкусного ты готовишь в последнее время?';

  @override
  String get icebreakerBioCookingSignature => 'Какое у тебя фирменное блюдо?';

  @override
  String get icebreakerBioSportWhich => 'Каким спортом ты занимаешься?';

  @override
  String get icebreakerBioSportWatchOrPlay =>
      'Тебе больше нравится смотреть или заниматься самому?';

  @override
  String get icebreakerBioReadingNow => 'Что ты сейчас читаешь?';

  @override
  String get icebreakerBioReadingLastBook =>
      'Какая последняя книга оставила в тебе след?';

  @override
  String get icebreakerBioCinemaRecent =>
      'Посоветуешь хороший фильм из недавних?';

  @override
  String get icebreakerBioCinemaOrSeries =>
      'Тебе больше по душе кино или сериалы?';

  @override
  String get icebreakerBioHikingTrails => 'Знаешь красивые тропы поблизости?';

  @override
  String get icebreakerBioHikingBest =>
      'Какой у тебя был самый красивый поход?';

  @override
  String get icebreakerBioPhotoSubjects => 'Что ты чаще всего фотографируешь?';

  @override
  String get icebreakerBioPhotoCamera => 'Какой камерой ты пользуешься?';

  @override
  String get icebreakerOrthodoxSynagogue =>
      'Есть ли у тебя любимая синагога поблизости?';

  @override
  String get icebreakerOrthodoxShabbat => 'Как ты обычно проводишь Шаббат?';

  @override
  String get icebreakerOrthodoxKosherRestaurant =>
      'Есть ли у тебя любимый кошерный ресторан?';

  @override
  String get icebreakerTraditionalTraditions =>
      'Какие еврейские традиции для тебя важнее всего?';

  @override
  String get icebreakerTraditionalShabbat => 'Как ты обычно отмечаешь Шаббат?';

  @override
  String get icebreakerTraditionalHoliday =>
      'Есть ли у тебя любимый еврейский праздник?';

  @override
  String get icebreakerSecularCulture =>
      'Какие у тебя отношения с еврейской культурой?';

  @override
  String get icebreakerSecularFamilyTraditions =>
      'Есть ли семейные традиции, которые ты хранишь?';

  @override
  String get icebreakerSecularHolidays => 'Какие праздники ты отмечаешь?';

  @override
  String get icebreakerDefaultHoliday =>
      'Какой еврейский праздник тебе нравится больше всего?';

  @override
  String get icebreakerDefaultFamilyTraditions =>
      'Есть ли у вас в семье особые традиции?';

  @override
  String get icebreakerDefaultPracticingFamily =>
      'В твоей семье соблюдали традиции?';

  @override
  String icebreakerLocationKnowWell(String location) {
    return 'Хорошо знаешь $location? Что мне посоветуешь?';
  }

  @override
  String icebreakerLocationFavoriteSpot(String location) {
    return 'Какое твоё любимое место в $location?';
  }

  @override
  String icebreakerLocationOriginallyFrom(String location) {
    return '$location — это твои родные места или переезд?';
  }

  @override
  String icebreakerLocationRestaurant(String location) {
    return 'Есть хороший ресторан в $location, который ты посоветуешь?';
  }

  @override
  String get icebreakerGenericDinnerGuest =>
      'Если бы можно было поужинать с кем угодно, живым или мёртвым, с кем бы это было?';

  @override
  String get icebreakerGenericPerfectDay =>
      'Каким тебе видится идеальный день?';

  @override
  String get icebreakerGenericHiddenTalent =>
      'Есть ли у тебя скрытый талант, о котором мало кто знает?';

  @override
  String get icebreakerGenericSpontaneous =>
      'Какой самый спонтанный поступок был в твоей жизни?';

  @override
  String get icebreakerGenericSeaOrMountain =>
      'Что тебе больше по душе в отпуске: море или горы?';

  @override
  String get icebreakerGenericLottery =>
      'Если завтра выпадет выигрыш в лотерею, с чего начнёшь?';

  @override
  String get icebreakerGenericGuiltyPleasure =>
      'Какое у тебя тайное удовольствие?';

  @override
  String get icebreakerGenericDream =>
      'Есть ли у тебя мечта, которая ещё не сбылась?';

  @override
  String get icebreakerGenericBestAdvice =>
      'Какой лучший совет тебе когда-либо давали?';

  @override
  String get icebreakerGenericBreakfastOrDinner =>
      'Что тебе больше нравится: завтракать или ужинать вне дома?';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Язык телефона';
}
