// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get authLoginEyebrow => 'Знакомства · Еврейская община';

  @override
  String get authLoginTagline =>
      'Серьёзные знакомства между людьми, которых объединяют общие ценности.';

  @override
  String get authLoginApple => 'Продолжить через Apple';

  @override
  String get authLoginGoogle => 'Продолжить через Google';

  @override
  String get authLoginDev => 'Тестовый вход (dev)';

  @override
  String authLegal(String terms, String privacy) {
    return 'Продолжая, Вы принимаете $terms и $privacy.';
  }

  @override
  String get authLegalTermsLink => 'Условия использования';

  @override
  String get authLegalPrivacyLink => 'Политику конфиденциальности';

  @override
  String get authErrorGeneric => 'Произошла ошибка. Повторите попытку.';

  @override
  String get authErrorCancelled => 'Вход отменён.';

  @override
  String get authErrorUnsupported =>
      'Этот способ входа недоступен на этом устройстве.';

  @override
  String authErrorAccountDisabled(String contact) {
    return 'Ваш аккаунт отключён. Напишите нам: $contact.';
  }

  @override
  String get authRouteErrorTitle => 'Страница не найдена';

  @override
  String get authRouteErrorBody => 'Произошла ошибка';

  @override
  String get authRouteErrorHome => 'На главную';

  @override
  String get boostTitle => 'Буст';

  @override
  String get boostHeadlineActive => 'Буст включён';

  @override
  String get boostHeadlineIdle => 'Продвиньте свой профиль';

  @override
  String get boostTagline => 'Вас увидят в 10 раз больше людей.';

  @override
  String boostMinutesLeft(int minutes) {
    return 'Осталось $minutes мин.';
  }

  @override
  String get boostDuringTitle => 'Во время этого буста';

  @override
  String get boostViews => 'Просмотры';

  @override
  String get boostLikes => 'Лайки';

  @override
  String get boostBenefitsTitle => 'Преимущества буста';

  @override
  String get boostBenefitFirst => 'Вы будете первым в рекомендациях';

  @override
  String boostBenefitVisibility(int minutes) {
    return 'В 10 раз больше внимания в течение $minutes мин';
  }

  @override
  String get boostBenefitMatches => 'Больше шансов на мэтч';

  @override
  String get boostBenefitStats =>
      'Статистика в реальном времени во время буста';

  @override
  String get boostActivate => 'Включить буст';

  @override
  String boostRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count буста',
      many: 'Осталось $count бустов',
      few: 'Осталось $count буста',
      one: 'Остался $count буст',
    );
    return '$_temp0';
  }

  @override
  String get boostActivated => 'Буст включён. Ваш профиль теперь на виду.';

  @override
  String get boostActivateFailed => 'Ошибка при включении';

  @override
  String get boostUpsellTitle => 'Безлимитные бусты';

  @override
  String get boostUpsellBody => 'Используйте буст без ограничений с mazl+';

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
  String linkOpenError(String target) {
    return 'Сейчас не удаётся открыть $target.';
  }

  @override
  String get coupleFeedCategoryWellness => 'Велнес';

  @override
  String get coupleFeedCategoryGastronomy => 'Гастрономия';

  @override
  String get coupleFeedFilterGastronomy => 'Гастро';

  @override
  String get coupleFeedCategoryCulture => 'Культура';

  @override
  String get coupleFeedCategorySport => 'Спорт';

  @override
  String get coupleFeedCategoryTravel => 'Путешествия';

  @override
  String get coupleFeedCategorySpiritual => 'Духовность';

  @override
  String get coupleFeedCategoryDiy => 'Своими руками';

  @override
  String get coupleFeedCategoryRomantic => 'Романтика';

  @override
  String get coupleFeedFilterAll => 'Все';

  @override
  String get coupleFeedEventCategoryDinner => 'Ужин';

  @override
  String get coupleFeedEventCategoryTasting => 'Дегустация';

  @override
  String get coupleFeedEventCategoryParty => 'Вечеринка';

  @override
  String get coupleFeedEventCategoryWorkshop => 'Мастер-класс';

  @override
  String get coupleFeedEventCategoryBrunch => 'Бранч';

  @override
  String get coupleFeedEventCategorySpiritual => 'Духовность';

  @override
  String get coupleFeedEventCategoryTravel => 'Выходные';

  @override
  String get coupleFeedEventCategoryConcert => 'Концерт';

  @override
  String get coupleFeedEventCategoryGame => 'Игры';

  @override
  String get coupleFeedEventCategoryOther => 'Событие';

  @override
  String get coupleFeedPriceFree => 'Бесплатно';

  @override
  String coupleFeedEventPricePerCouple(String price) {
    return '$price за пару';
  }

  @override
  String coupleFeedDurationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String coupleFeedDurationHours(int hours) {
    return '$hours ч';
  }

  @override
  String coupleFeedDurationHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String coupleFeedRatingWithReviews(String rating, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$rating ($countString отзыва)',
      many: '$rating ($countString отзывов)',
      few: '$rating ($countString отзыва)',
      one: '$rating ($countString отзыв)',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedKosher => 'Кошерно';

  @override
  String get coupleFeedFeatured => 'Рекомендуем';

  @override
  String get coupleFeedPartnerMazl => 'Партнёр MAZL';

  @override
  String coupleFeedPartnerDiscountMazl(int percent) {
    return 'Скидка $percent % · Партнёр MAZL';
  }

  @override
  String coupleFeedPartnerDiscount(int percent) {
    return 'Скидка $percent % · Партнёр';
  }

  @override
  String get coupleFeedActivitiesTitle => 'Занятия';

  @override
  String get coupleFeedSavedTitle => 'Сохранённые занятия';

  @override
  String get coupleFeedActivitiesEmptyTitle => 'Пока нет занятий';

  @override
  String get coupleFeedActivitiesEmptyLine => 'Скоро появятся новые идеи.';

  @override
  String get coupleFeedRefresh => 'Обновить';

  @override
  String get coupleFeedSeeDetail => 'Подробнее';

  @override
  String coupleFeedActivitySavedSnack(String title) {
    return 'Сохранено: $title';
  }

  @override
  String coupleFeedActivitySaveCardError(String title) {
    return 'Не удалось сохранить «$title». Попробуйте ещё раз.';
  }

  @override
  String coupleFeedActivityPassCardError(String title) {
    return 'Не удалось пропустить «$title». Попробуйте ещё раз.';
  }

  @override
  String get coupleFeedActivityNotFoundTitle => 'Занятие не найдено';

  @override
  String get coupleFeedActivityNotFoundLine => 'Оно больше не доступно.';

  @override
  String get coupleFeedActivityRemoveError =>
      'Не удалось убрать это занятие. Попробуйте ещё раз.';

  @override
  String get coupleFeedActivitySaveError =>
      'Не удалось сохранить это занятие. Попробуйте ещё раз.';

  @override
  String get coupleFeedActivitySavedConfirm => 'Занятие сохранено';

  @override
  String coupleFeedCodeCopied(String code) {
    return 'Код $code скопирован';
  }

  @override
  String get coupleFeedRemoveFromSaved => 'Убрать из сохранённых занятий';

  @override
  String coupleFeedActivityShareText(String title) {
    return 'Идея для свидания: «$title» (через MAZL)';
  }

  @override
  String get coupleFeedPromoCodeLabel => 'Промокод MAZL';

  @override
  String get coupleFeedCopyCode => 'Скопировать код';

  @override
  String get coupleFeedDescription => 'Описание';

  @override
  String get coupleFeedTags => 'Теги';

  @override
  String get coupleFeedAddress => 'Адрес';

  @override
  String get coupleFeedContact => 'Контакты';

  @override
  String get coupleFeedCall => 'Позвонить';

  @override
  String get coupleFeedWebsite => 'Сайт';

  @override
  String get coupleFeedFromPrice => 'От';

  @override
  String get coupleFeedBook => 'Забронировать';

  @override
  String get coupleFeedSavedRemoveTitle => 'Убрать из списка?';

  @override
  String coupleFeedSavedRemoveBody(String title) {
    return 'Убрать «$title» из Ваших сохранённых занятий?';
  }

  @override
  String get coupleFeedSavedRemoved => 'Занятие убрано';

  @override
  String coupleFeedSavedRemoveError(String title) {
    return 'Не удалось убрать «$title». Попробуйте ещё раз.';
  }

  @override
  String get coupleFeedSavedEmptyTitle => 'Нет сохранённых занятий';

  @override
  String get coupleFeedSavedEmptyLine =>
      'Смахните карточку вверх, чтобы сохранить её.';

  @override
  String get coupleFeedSavedEmptyAction => 'Найти занятия';

  @override
  String get coupleFeedEventsTitle => 'События';

  @override
  String get coupleFeedEventsUpcoming => 'Скоро';

  @override
  String coupleFeedEventsRegisteredTab(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Записаны ($countString)';
  }

  @override
  String get coupleFeedEventsEmptyAll => 'Нет доступных событий';

  @override
  String get coupleFeedEventsEmptyRegistered =>
      'Вы не записаны ни на одно событие';

  @override
  String get coupleFeedEventsDiscover => 'Посмотреть события';

  @override
  String coupleFeedEventRegisteredSnack(String title) {
    return 'Вы записаны на «$title»';
  }

  @override
  String coupleFeedEventRegisteredSnackDetail(String title) {
    return 'Вы записаны на «$title»';
  }

  @override
  String get coupleFeedEventRegisterError =>
      'Не удалось записаться. Попробуйте ещё раз.';

  @override
  String get coupleFeedEventCancelError =>
      'Не удалось отменить запись. Попробуйте ещё раз.';

  @override
  String get coupleFeedEventCancelTitle => 'Отменить запись?';

  @override
  String coupleFeedEventCancelBody(String title) {
    return 'Вы действительно хотите отменить запись на «$title»?';
  }

  @override
  String get coupleFeedEventCancelNo => 'Нет';

  @override
  String get coupleFeedEventCancelYes => 'Да, отменить';

  @override
  String get coupleFeedEventCancelled => 'Запись отменена';

  @override
  String get coupleFeedEventFull => 'Мест нет';

  @override
  String coupleFeedEventSpots(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString места',
      many: '$countString мест',
      few: '$countString места',
      one: '$countString место',
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
      other: 'Осталось $countString места',
      many: 'Осталось $countString мест',
      few: 'Осталось $countString места',
      one: 'Остался $countString место',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedEventRegister => 'Записаться';

  @override
  String get coupleFeedEventCancelMine => 'Отменить запись';

  @override
  String get coupleFeedEventNotFoundTitle => 'Событие не найдено';

  @override
  String get coupleFeedEventNotFoundLine => 'Оно больше не доступно.';

  @override
  String get coupleFeedEventFactPlace => 'Место';

  @override
  String get coupleFeedEventFactDressCode => 'Дресс-код';

  @override
  String get coupleFeedEventFactOrganizer => 'Организатор';

  @override
  String get coupleFeedEventIncluded => 'Что включено';

  @override
  String get coupleFeedLoadFailedTitle => 'Не удалось загрузить';

  @override
  String get coupleSpaceTabActivities => 'Активности';

  @override
  String get coupleSpaceTabCalendar => 'Календарь';

  @override
  String get coupleSpaceTabEvents => 'Мероприятия';

  @override
  String get coupleSpaceTabSpace => 'Наше место';

  @override
  String get coupleSpaceTitle => 'Наше место';

  @override
  String get coupleSpaceSettingsTooltip => 'Настройки';

  @override
  String get coupleSpaceYou => 'Вы';

  @override
  String get coupleSpacePartnerFallback => 'Ваша половинка';

  @override
  String coupleSpaceTogetherSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return 'Вместе уже $_temp0';
  }

  @override
  String get coupleSpaceStoryBegins => 'Ваша история начинается';

  @override
  String get coupleSpaceStatSavedActivities => 'Сохранённые\nзанятия';

  @override
  String get coupleSpaceStatUpcomingEvents => 'Ближайшие\nсобытия';

  @override
  String get coupleSpaceStatMemories => 'Созданные\nмоменты';

  @override
  String get coupleSpaceQuickActions => 'Быстрые действия';

  @override
  String get coupleSpaceQuickAddMemory => 'Добавить\nмомент';

  @override
  String get coupleSpaceQuickAddBucket => 'Добавить в\nбакет-лист';

  @override
  String get coupleSpaceQuickAddDate => 'Добавить\nдату';

  @override
  String get coupleSpaceMemoriesTitle => 'Наши воспоминания';

  @override
  String get coupleSpaceMemoriesEmptyTitle => 'Пока нет воспоминаний';

  @override
  String get coupleSpaceMemoriesEmptyHint =>
      'Добавьте ваши первые общие воспоминания.';

  @override
  String get coupleSpaceBucketTitle => 'Бакет-лист';

  @override
  String coupleSpaceBucketProgress(int done, int total) {
    return 'Бакет-лист · $done/$total';
  }

  @override
  String get coupleSpaceBucketEmptyTitle => 'Ваш бакет-лист пуст';

  @override
  String get coupleSpaceBucketEmptyHint =>
      'Добавьте впечатления, которые хотите пережить вместе.';

  @override
  String get coupleSpaceDatesTitle => 'Важные даты';

  @override
  String get coupleSpaceSeeAll => 'Показать все';

  @override
  String get coupleSpaceDatesEmptyTitle => 'Нет важных дат';

  @override
  String get coupleSpaceDatesEmptyHint =>
      'Добавьте годовщины, праздники и другие даты.';

  @override
  String get coupleSpaceBadgesTitle => 'Наши значки';

  @override
  String get coupleSpaceBadgesEmptyTitle => 'Пока нет значков';

  @override
  String get coupleSpaceBadgesEmptyHint =>
      'Занимайтесь вместе, чтобы открывать значки.';

  @override
  String get coupleSpaceGoalDone => 'Цель достигнута';

  @override
  String get coupleSpaceGoalFailed =>
      'Не удалось отметить цель. Попробуйте ещё раз.';

  @override
  String coupleSpaceRefreshFailed(String reason) {
    return 'Не удалось обновить. $reason';
  }

  @override
  String get coupleSpaceLoadFailedTitle => 'Не удалось загрузить';

  @override
  String get coupleSpaceSheetAdd => 'Добавить';

  @override
  String get coupleSpaceAddMemoryTitle => 'Добавить воспоминание';

  @override
  String get coupleSpaceFieldTitle => 'Название';

  @override
  String get coupleSpaceFieldDescription => 'Описание';

  @override
  String get coupleSpaceAddBucketTitle => 'Добавить в бакет-лист';

  @override
  String get coupleSpaceBucketFieldLabel => 'Что вы хотите сделать вместе?';

  @override
  String get coupleSpaceBucketFieldHint => 'Например: северное сияние';

  @override
  String get coupleSpaceAddDateTitle => 'Добавить важную дату';

  @override
  String get coupleSpaceDateFieldHint => 'Например: наша годовщина';

  @override
  String get coupleSpaceFieldDate => 'Дата';

  @override
  String coupleSpaceAddFailed(String reason) {
    return 'Не удалось добавить. $reason';
  }

  @override
  String get coupleSpaceSetupTitle => 'Режим пары';

  @override
  String get coupleSpaceSetupWho => 'С кем?';

  @override
  String get coupleSpaceSetupSend => 'Отправить запрос';

  @override
  String get coupleSpaceSetupNoMatches => 'Пока нет мэтчей.';

  @override
  String get coupleSpaceSetupMatchesError => 'Не удалось загрузить Ваши мэтчи.';

  @override
  String get coupleSpaceSetupSentTitle => 'Запрос отправлен';

  @override
  String coupleSpaceSetupSentBody(String name) {
    return 'Запрос ждёт ответа от $name. Мы сообщим Вам, как только он появится.';
  }

  @override
  String get coupleSpaceSetupSentBodyAnonymous =>
      'Запрос ждёт ответа. Мы сообщим Вам, как только он появится.';

  @override
  String get coupleSpaceSetupGotIt => 'Понятно';

  @override
  String get coupleSpaceSetupCancelRequest => 'Отменить запрос';

  @override
  String get coupleSpaceMazelTovTitle => 'Мазл тов';

  @override
  String coupleSpaceMazelTovCongrats(String name) {
    return 'Поздравляем Вас и $name';
  }

  @override
  String get coupleSpaceMazelTovWelcome =>
      'MAZL сопровождает Вас на этом новом этапе.';

  @override
  String get coupleSpaceMazelTovStart => 'Начать наше приключение';

  @override
  String coupleSpaceRequestTitle(String name) {
    return '$name хочет включить режим пары с Вами';
  }

  @override
  String get coupleSpaceRequestTitleAnonymous =>
      'Этот человек хочет включить режим пары с Вами';

  @override
  String get coupleSpaceRequestAccept => 'Принять';

  @override
  String get coupleSpaceRequestDecline => 'Нет, спасибо';

  @override
  String coupleSpaceFlowDeclinedNamed(String name) {
    return 'Запрос к $name остался без ответа.';
  }

  @override
  String get coupleSpaceFlowDeclined => 'Ваш запрос не был принят.';

  @override
  String get coupleSpaceFlowEnded => 'Режим пары завершён.';

  @override
  String get coupleSpaceArchiveMessage =>
      'Любовь нашлась на Mazl, и я больше не ищу знакомств. Удачи в поисках!';

  @override
  String get coupleSpaceFailNotMatched =>
      'Режим пары включается только с мэтчем.';

  @override
  String get coupleSpaceFailAlreadyInCouple => 'Один из Вас уже в режиме пары.';

  @override
  String get coupleSpaceFailRequestPending =>
      'С этим человеком уже есть ожидающий запрос.';

  @override
  String get coupleSpaceFailRequestGone =>
      'Этот запрос больше не ожидает ответа.';

  @override
  String get coupleSpaceFailUnavailable =>
      'С этим человеком сейчас нельзя связаться.';

  @override
  String get coupleSpaceFailSelf => 'Отправить запрос себе нельзя.';

  @override
  String get coupleSpaceFailNotInCouple => 'Режим пары не активен.';

  @override
  String get coupleSpaceFailCannotLeave =>
      'Сейчас невозможно выйти из режима пары.';

  @override
  String get coupleSpaceFailUnknown =>
      'Что-то пошло не так. Попробуйте ещё раз чуть позже.';

  @override
  String get coupleSpaceFailEventFull => 'Все места на мероприятие заняты.';

  @override
  String get coupleSpaceFailServer =>
      'Сервер не смог ответить. Попробуйте ещё раз.';

  @override
  String get coupleSpaceFailUnexpected => 'Неожиданный ответ сервера.';

  @override
  String get coupleSpaceStatusSingle => 'Не в отношениях';

  @override
  String get coupleSpaceStatusDating => 'На свиданиях';

  @override
  String get coupleSpaceStatusInRelationship => 'В отношениях';

  @override
  String get coupleSpaceStatusEngaged => 'Помолвлены';

  @override
  String get coupleSpaceStatusMarried => 'В браке';

  @override
  String coupleSpaceDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недели',
      many: '$count недель',
      few: '$count недели',
      one: '$count неделя',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count месяца',
      many: '$count месяцев',
      few: '$count месяца',
      one: '$count месяц',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count года',
      many: '$count лет',
      few: '$count года',
      one: '$count год',
    );
    return '$_temp0';
  }

  @override
  String get coupleSpaceCalendarTitle => 'Календарь';

  @override
  String get coupleSpaceCalendarShabbatIdeas => 'Идеи на этот Шаббат';

  @override
  String get coupleSpaceCalendarUpcoming => 'Ближайшие праздники';

  @override
  String get coupleSpaceCalendarPrevMonth => 'Предыдущий месяц';

  @override
  String get coupleSpaceCalendarNextMonth => 'Следующий месяц';

  @override
  String get coupleSpaceCalendarOngoing => 'Идёт сейчас';

  @override
  String coupleSpaceCalendarCountdown(int count) {
    return 'Через $count дн.';
  }

  @override
  String get coupleSpaceCalendarIdeas => 'Идеи для пары';

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
  String get eventsTitle => 'Мероприятия';

  @override
  String get eventsFilterAll => 'Все';

  @override
  String get eventsFilterHolidays => 'Праздники';

  @override
  String get eventsTypeShabbat => 'Шаббат';

  @override
  String get eventsTypeShabbatDinner => 'Ужин в Шаббат';

  @override
  String get eventsTypeSpeedDating => 'Спид-дейтинг';

  @override
  String get eventsTypeHoliday => 'Праздник';

  @override
  String get eventsTypeLecture => 'Занятие';

  @override
  String get eventsTypeSocial => 'Встреча';

  @override
  String get eventsTypeOther => 'Мероприятие';

  @override
  String get eventsLoading => 'Загрузка...';

  @override
  String get eventsLoadError => 'Не удалось загрузить мероприятия';

  @override
  String get eventsEmptyTitle => 'Нет мероприятий';

  @override
  String get eventsEmptyHint =>
      'Загляните позже,\nчтобы увидеть новые мероприятия.';

  @override
  String get eventsTomorrow => 'Завтра';

  @override
  String eventsInDays(int days) {
    return 'Через $days дн.';
  }

  @override
  String eventsDateAtTime(String date, String time) {
    return '$date в $time';
  }

  @override
  String get eventsFree => 'Бесплатно';

  @override
  String eventsAttendeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участника',
      many: '$count участников',
      few: '$count участника',
      one: '$count участник',
    );
    return '$_temp0';
  }

  @override
  String get eventsAlmostFull => 'Почти заполнено';

  @override
  String get eventsFull => 'Мест нет';

  @override
  String get eventsNotFound => 'Мероприятие не найдено';

  @override
  String get eventsInfoDate => 'Дата';

  @override
  String get eventsInfoTime => 'Время';

  @override
  String get eventsInfoPlace => 'Место';

  @override
  String get eventsInfoParticipants => 'Участники';

  @override
  String get eventsInfoPrice => 'Цена';

  @override
  String get eventsDescription => 'Описание';

  @override
  String eventsCapacity(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$count / $max места',
      many: '$count / $max мест',
      few: '$count / $max места',
      one: '$count / $max место',
    );
    return '$_temp0';
  }

  @override
  String eventsRegisteredCount(int count) {
    return 'Записались: $count';
  }

  @override
  String eventsPricePerPerson(String price) {
    return '$price с человека';
  }

  @override
  String get eventsRsvpConfirmedBanner => 'Вы записаны на это мероприятие';

  @override
  String get eventsRsvpCancel => 'Отменить запись';

  @override
  String eventsRsvpJoinPaid(String price) {
    return 'Записаться - $price';
  }

  @override
  String get eventsRsvpJoinFree => 'Записаться бесплатно';

  @override
  String get eventsRsvpCancelled => 'Запись отменена';

  @override
  String get eventsRsvpDone => 'Запись подтверждена';

  @override
  String eventsShareMessage(String title) {
    return 'Присоединяйтесь ко мне на «$title» в MAZL';
  }

  @override
  String get genreLookingForRequired => 'Укажите, кого Вы ищете';

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
  String get jewishCalendarShabbatTitle => 'Этот Шаббат';

  @override
  String jewishCalendarParashat(String name) {
    return 'Недельная глава: $name';
  }

  @override
  String jewishCalendarParshaPair(String first, String second) {
    return '$first – $second';
  }

  @override
  String get jewishCalendarCandleLighting => 'Зажигание свечей';

  @override
  String get jewishCalendarHavdalah => 'Гавдала';

  @override
  String get jewishCalendarCategoryPreparation => 'Подготовка';

  @override
  String get jewishCalendarCategorySpiritual => 'Духовное';

  @override
  String get jewishCalendarCategoryRelaxation => 'Отдых';

  @override
  String get jewishCalendarActivityShabbatDinnerTitle =>
      'Приготовить ужин вместе';

  @override
  String get jewishCalendarActivityShabbatDinnerBody =>
      'Приготовьте халу и праздничную трапезу';

  @override
  String get jewishCalendarActivityShabbatCandlesTitle => 'Зажечь свечи';

  @override
  String get jewishCalendarActivityShabbatCandlesBody =>
      'Общий момент духовности';

  @override
  String get jewishCalendarActivityShabbatWalkTitle => 'Прогулка в Шаббат';

  @override
  String get jewishCalendarActivityShabbatWalkBody =>
      'Спокойная прогулка после трапезы';

  @override
  String get jewishCalendarActivityShabbatParashaTitle =>
      'Изучение недельной главы';

  @override
  String get jewishCalendarActivityShabbatParashaBody =>
      'Изучайте вместе недельную главу';

  @override
  String get jewishCalendarActivityPesachSederTitle => 'Подготовить седер';

  @override
  String get jewishCalendarActivityPesachSederBody => 'Накройте стол вместе';

  @override
  String get jewishCalendarActivityPesachCleaningTitle =>
      'Сделать уборку к Песаху';

  @override
  String get jewishCalendarActivityPesachCleaningBody =>
      'Весенняя уборка командой';

  @override
  String get jewishCalendarHolidayRoshHashanaName => 'Рош ха-Шана';

  @override
  String get jewishCalendarHolidayRoshHashanaDescription =>
      'Еврейский Новый год';

  @override
  String get jewishCalendarHolidayYomKippurName => 'Йом-Киппур';

  @override
  String get jewishCalendarHolidayYomKippurDescription => 'День Искупления';

  @override
  String get jewishCalendarHolidaySukkotName => 'Суккот';

  @override
  String get jewishCalendarHolidaySukkotDescription => 'Праздник кущей';

  @override
  String get jewishCalendarHolidaySheminiAtzeretName => 'Шмини Ацерет';

  @override
  String get jewishCalendarHolidaySheminiAtzeretDescription =>
      'Восьмой день собрания';

  @override
  String get jewishCalendarHolidaySimchatTorahName => 'Симхат-Тора';

  @override
  String get jewishCalendarHolidaySimchatTorahDescription => 'Радость Торы';

  @override
  String get jewishCalendarHolidayHanukkahName => 'Ханука';

  @override
  String get jewishCalendarHolidayHanukkahDescription => 'Праздник огней';

  @override
  String get jewishCalendarHolidayTuBishvatName => 'Ту би-Шват';

  @override
  String get jewishCalendarHolidayTuBishvatDescription => 'Новый год деревьев';

  @override
  String get jewishCalendarHolidayPurimName => 'Пурим';

  @override
  String get jewishCalendarHolidayPurimDescription => 'Праздник жребиев';

  @override
  String get jewishCalendarHolidayPesachName => 'Песах';

  @override
  String get jewishCalendarHolidayPesachDescription => 'Праздник свободы';

  @override
  String get jewishCalendarHolidayYomHashoahName => 'Йом ха-Шоа';

  @override
  String get jewishCalendarHolidayYomHashoahDescription =>
      'День памяти жертв Холокоста';

  @override
  String get jewishCalendarHolidayYomHazikaronName => 'Йом ха-Зикарон';

  @override
  String get jewishCalendarHolidayYomHazikaronDescription =>
      'День памяти павших солдат';

  @override
  String get jewishCalendarHolidayYomHaatzmautName => 'Йом ха-Ацмаут';

  @override
  String get jewishCalendarHolidayYomHaatzmautDescription =>
      'День независимости Израиля';

  @override
  String get jewishCalendarHolidayYomYerushalayimName => 'Йом Йерушалаим';

  @override
  String get jewishCalendarHolidayYomYerushalayimDescription =>
      'День воссоединения Иерусалима';

  @override
  String get jewishCalendarHolidayLagBaomerName => 'Лаг ба-Омер';

  @override
  String get jewishCalendarHolidayLagBaomerDescription => '33-й день Омера';

  @override
  String get jewishCalendarHolidayShavuotName => 'Шавуот';

  @override
  String get jewishCalendarHolidayShavuotDescription => 'Дарование Торы';

  @override
  String get jewishCalendarIdeaFestiveDinner => 'Праздничный ужин';

  @override
  String get jewishCalendarIdeaTashlich => 'Ташлих вместе';

  @override
  String get jewishCalendarIdeaMutualForgiveness =>
      'Попросить прощения друг у друга';

  @override
  String get jewishCalendarIdeaBuildSukkah => 'Построить сукку вместе';

  @override
  String get jewishCalendarIdeaInviteFriends => 'Пригласить друзей';

  @override
  String get jewishCalendarIdeaPrayerForRain => 'Молитва о дожде';

  @override
  String get jewishCalendarIdeaDanceWithTorah => 'Танцевать с Торой';

  @override
  String get jewishCalendarIdeaLightCandlesTogether => 'Зажечь свечи вместе';

  @override
  String get jewishCalendarIdeaHomemadeSufganiyot => 'Домашние суфганиёт';

  @override
  String get jewishCalendarIdeaCoupleCostumes => 'Парные костюмы';

  @override
  String get jewishCalendarIdeaMishloachManot => 'Мишлоах манот вместе';

  @override
  String get jewishCalendarIdeaRomanticSeder => 'Романтический седер';

  @override
  String get jewishCalendarIdeaTripToIsrael => 'Поездка в Израиль';

  @override
  String get jewishCalendarIdeaIsraeliBarbecue => 'Израильское барбекю';

  @override
  String get jewishCalendarIdeaConcertOrParty => 'Концерт или вечеринка';

  @override
  String get jewishCalendarIdeaCampfire => 'Костёр';

  @override
  String get jewishCalendarIdeaPicnic => 'Пикник';

  @override
  String get jewishCalendarIdeaHomemadeCheesecake => 'Домашний чизкейк';

  @override
  String get jewishCalendarIdeaStudyNight => 'Ночь изучения Торы';

  @override
  String get jewishCalendarParshaBereshis => 'Берешит';

  @override
  String get jewishCalendarParshaNoach => 'Ноах';

  @override
  String get jewishCalendarParshaLechLecha => 'Лех-Леха';

  @override
  String get jewishCalendarParshaVayera => 'Ваера';

  @override
  String get jewishCalendarParshaChayeiSara => 'Хаей Сара';

  @override
  String get jewishCalendarParshaToldos => 'Толдот';

  @override
  String get jewishCalendarParshaVayetzei => 'Ваеце';

  @override
  String get jewishCalendarParshaVayishlach => 'Ваишлах';

  @override
  String get jewishCalendarParshaVayeshev => 'Ваешев';

  @override
  String get jewishCalendarParshaMiketz => 'Микец';

  @override
  String get jewishCalendarParshaVayigash => 'Ваигаш';

  @override
  String get jewishCalendarParshaVayechi => 'Ваехи';

  @override
  String get jewishCalendarParshaShemos => 'Шмот';

  @override
  String get jewishCalendarParshaVaera => 'Ваэра';

  @override
  String get jewishCalendarParshaBo => 'Бо';

  @override
  String get jewishCalendarParshaBeshalach => 'Бешалах';

  @override
  String get jewishCalendarParshaYisro => 'Итро';

  @override
  String get jewishCalendarParshaMishpatim => 'Мишпатим';

  @override
  String get jewishCalendarParshaTerumah => 'Трума';

  @override
  String get jewishCalendarParshaTetzaveh => 'Тецаве';

  @override
  String get jewishCalendarParshaKiSisa => 'Ки тиса';

  @override
  String get jewishCalendarParshaVayakhel => 'Ваякэль';

  @override
  String get jewishCalendarParshaPekudei => 'Пекудей';

  @override
  String get jewishCalendarParshaVayikra => 'Ваикра';

  @override
  String get jewishCalendarParshaTzav => 'Цав';

  @override
  String get jewishCalendarParshaShmini => 'Шмини';

  @override
  String get jewishCalendarParshaTazria => 'Тазриа';

  @override
  String get jewishCalendarParshaMetzora => 'Мецора';

  @override
  String get jewishCalendarParshaAchreiMos => 'Ахарей мот';

  @override
  String get jewishCalendarParshaKedoshim => 'Кдошим';

  @override
  String get jewishCalendarParshaEmor => 'Эмор';

  @override
  String get jewishCalendarParshaBehar => 'Бегар';

  @override
  String get jewishCalendarParshaBechukosai => 'Бехукотай';

  @override
  String get jewishCalendarParshaBamidbar => 'Бемидбар';

  @override
  String get jewishCalendarParshaNasso => 'Насо';

  @override
  String get jewishCalendarParshaBehaaloscha => 'Беаалотха';

  @override
  String get jewishCalendarParshaShlach => 'Шлах';

  @override
  String get jewishCalendarParshaKorach => 'Корах';

  @override
  String get jewishCalendarParshaChukas => 'Хукат';

  @override
  String get jewishCalendarParshaBalak => 'Балак';

  @override
  String get jewishCalendarParshaPinchas => 'Пинхас';

  @override
  String get jewishCalendarParshaMatos => 'Матот';

  @override
  String get jewishCalendarParshaMasei => 'Масэй';

  @override
  String get jewishCalendarParshaDevarim => 'Дварим';

  @override
  String get jewishCalendarParshaVaeschanan => 'Ваэтханан';

  @override
  String get jewishCalendarParshaEikev => 'Экев';

  @override
  String get jewishCalendarParshaReeh => 'Рэ\'э';

  @override
  String get jewishCalendarParshaShoftim => 'Шофтим';

  @override
  String get jewishCalendarParshaKiSeitzei => 'Ки тейцэ';

  @override
  String get jewishCalendarParshaKiSavo => 'Ки таво';

  @override
  String get jewishCalendarParshaNitzavim => 'Ницавим';

  @override
  String get jewishCalendarParshaVayeilech => 'Ваелех';

  @override
  String get jewishCalendarParshaHaazinu => 'Гаазину';

  @override
  String get jewishCalendarParshaVzosHaberacha => 'Вэзот а-браха';

  @override
  String get layoutPaneChatTitle => 'Выберите переписку';

  @override
  String get layoutPaneChatMessage => 'Она откроется здесь, рядом со списком.';

  @override
  String get layoutPaneProfileTitle => 'Выберите пару';

  @override
  String get layoutPaneProfileMessage =>
      'Её профиль появится здесь, рядом со списком.';

  @override
  String get likesTitle => 'Лайки';

  @override
  String likesSection(String count) {
    return 'Вы понравились · $count';
  }

  @override
  String likesWaiting(int count, String label) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$label человека ждут Вашего ответа.',
      many: '$label человек ждут Вашего ответа.',
      few: '$label человека ждут Вашего ответа.',
      one: '$label человек ждёт Вашего ответа.',
    );
    return '$_temp0';
  }

  @override
  String get likesSeeWhoWithPlus => 'Узнать, кто Вас лайкнул, с mazl+';

  @override
  String likesMatchWith(String name) {
    return 'Мэтч с $name';
  }

  @override
  String likesYouLiked(String name) {
    return 'Вы лайкнули $name';
  }

  @override
  String get likesEmptyTitle => 'Пока нет лайков';

  @override
  String get likesEmptyBody =>
      'Продолжайте знакомиться и заполните свой профиль, чтобы получать больше лайков.';

  @override
  String get likesEmptyAction => 'Смотреть профили';

  @override
  String get likesPremiumBody =>
      'Узнайте, кто Вас лайкнул, и сразу устройте мэтч с теми, кто Вам нравится.';

  @override
  String get likesPremiumOffers => 'Посмотреть тарифы';

  @override
  String likesCardOpen(String title) {
    return 'Открыть лайк: $title';
  }

  @override
  String likesCardPass(String name) {
    return 'Пропустить: $name';
  }

  @override
  String likesCardLike(String name) {
    return 'Лайкнуть: $name';
  }

  @override
  String get likesLockedLabel => 'Скрытый профиль';

  @override
  String get likesLockedHint => 'Доступно с mazl+';

  @override
  String likesDistance(int km) {
    return '$km км';
  }

  @override
  String get matchingDiscoverDailyPicks => 'Подборка дня';

  @override
  String get matchingFilters => 'Фильтры';

  @override
  String get matchingDiscoverEmptyTitle => 'Вы просмотрели всех.';

  @override
  String get matchingDiscoverEmptyBody =>
      'Загляните позже или расширьте фильтры, чтобы увидеть новые профили.';

  @override
  String get matchingDiscoverOpenFilters => 'Открыть фильтры';

  @override
  String get matchingDiscoverRefresh => 'Обновить';

  @override
  String get matchingDiscoverSuperLike => 'Суперлайк';

  @override
  String get matchingDiscoverBoost => 'Буст';

  @override
  String matchingDiscoverBoostOn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минуты',
      many: '$minutes минут',
      few: '$minutes минут',
      one: '$minutes минуты',
    );
    return 'Буст включён. Вы в начале очереди в течение $_temp0.';
  }

  @override
  String get matchingDiscoverBoostFailed => 'Не удалось включить буст';

  @override
  String get matchingCardPass => 'Пропустить';

  @override
  String get matchingCardLike => 'Нравится';

  @override
  String get matchingCardViewProfile => 'Открыть профиль';

  @override
  String get matchingCardAnonymous => 'Без имени';

  @override
  String matchingCardDistance(int km) {
    return 'в $km км';
  }

  @override
  String get matchingCardVerified => 'Проверено';

  @override
  String matchingAvatarNewMatch(String name) {
    return 'Новый мэтч, $name';
  }

  @override
  String matchingAvatarMatch(String name) {
    return 'Мэтч, $name';
  }

  @override
  String get matchingMatchTitle => 'Это мэтч!';

  @override
  String matchingMatchLineNamed(String name) {
    return 'Вы с $name понравились друг другу.';
  }

  @override
  String get matchingMatchLineAnonymous => 'Вы понравились друг другу.';

  @override
  String get matchingMatchSendMessage => 'Написать сообщение';

  @override
  String get matchingMatchKeepDiscovering => 'Продолжить знакомства';

  @override
  String matchingSeeMoreWithPlus(int count) {
    return 'Показать ещё $count с mazl+';
  }

  @override
  String get matchingMatchesTitle => 'Мэтчи';

  @override
  String get matchingMatchesWhoLikedYou => 'Кто Вас лайкнул';

  @override
  String matchingMatchesNewSection(int count) {
    return 'Новые · $count';
  }

  @override
  String matchingMatchesConversationsSection(int count) {
    return 'Диалоги · $count';
  }

  @override
  String get matchingMatchesLoadFailed => 'Не удалось загрузить мэтчи';

  @override
  String get matchingMatchesEmptyTitle => 'Пока нет мэтчей';

  @override
  String get matchingMatchesEmptyBody => 'Продолжайте знакомиться.';

  @override
  String get matchingMatchesUnknownName => 'Без имени';

  @override
  String get matchingMatchesWriteHint => 'Напишите сообщение';

  @override
  String matchingMatchesViewProfileOf(String name) {
    return 'Открыть профиль: $name';
  }

  @override
  String matchingMatchesSeeMore(int count) {
    return 'Показать ещё $count';
  }

  @override
  String matchingMatchedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня назад',
      many: '$count дней назад',
      few: '$count дня назад',
      one: '$count день назад',
    );
    return '$_temp0';
  }

  @override
  String matchingMatchedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недели назад',
      many: '$count недель назад',
      few: '$count недели назад',
      one: '$count неделю назад',
    );
    return '$_temp0';
  }

  @override
  String matchingMatchedMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count месяца назад',
      many: '$count месяцев назад',
      few: '$count месяца назад',
      one: '$count месяц назад',
    );
    return '$_temp0';
  }

  @override
  String get matchingCouplePromoTitle => 'Случился мэтч?';

  @override
  String get matchingCouplePromoDismiss => 'Скрыть';

  @override
  String get matchingCouplePromoBody =>
      'Ежедневные вопросы, этапы, общий еврейский календарь: стройте отношения с mazl.';

  @override
  String get matchingCouplePromoAction => 'Включить режим пары';

  @override
  String get matchingPicksSeenAll => 'Вы просмотрели все подборки.';

  @override
  String matchingPicksNextIn(int hours, int minutes) {
    return 'Следующая подборка через $hours ч $minutes мин';
  }

  @override
  String matchingPicksUpdatedIn(int hours, int minutes) {
    return 'Обновится через $hours ч $minutes мин';
  }

  @override
  String matchingPicksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count профиля выбрано для Вас',
      many: '$count профилей выбрано для Вас',
      few: '$count профиля выбрано для Вас',
      one: '$count профиль выбран для Вас',
    );
    return '$_temp0';
  }

  @override
  String get matchingPicksDiscoverMore => 'Смотреть другие профили';

  @override
  String get matchingPicksBadge => 'Выбор';

  @override
  String get matchingFiltersReset => 'Сбросить';

  @override
  String get matchingFiltersAge => 'Возраст';

  @override
  String matchingFiltersYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count года',
      many: '$count лет',
      few: '$count года',
      one: '$count год',
    );
    return '$_temp0';
  }

  @override
  String get matchingFiltersDistance => 'Максимальное расстояние';

  @override
  String matchingFiltersKm(int count) {
    return '$count км';
  }

  @override
  String get matchingFiltersDenomination => 'Религиозное течение';

  @override
  String get matchingFiltersKashrut => 'Кашрут';

  @override
  String get matchingFiltersShabbatSection => 'Шаббат';

  @override
  String get matchingFiltersChoiceHint =>
      'Можно выбрать несколько вариантов. Профили, не ответившие на этот вопрос, не показываются.';

  @override
  String get matchingFiltersOptions => 'Параметры';

  @override
  String get matchingFiltersVerifiedTitle => 'Только проверенные профили';

  @override
  String get matchingFiltersVerifiedHint =>
      'Показывать только проверенные профили';

  @override
  String get matchingFiltersPhotoTitle => 'Только с фото';

  @override
  String get matchingFiltersPhotoHint => 'Скрыть профили без фото';

  @override
  String get matchingFiltersUpsellTitle => 'Откройте все фильтры';

  @override
  String get matchingFiltersUpsellBody =>
      'Перейдите на mazl+ для точного поиска';

  @override
  String get matchingFiltersApply => 'Применить фильтры';

  @override
  String get matchingFiltersSaved => 'Фильтры сохранены';

  @override
  String get matchingFiltersSaveFailed => 'Ошибка при сохранении';

  @override
  String get matchingFiltersAdvanced => 'Расширенные фильтры';

  @override
  String get matchingFiltersLoadFailed =>
      'Не удалось загрузить Ваши расширенные фильтры.';

  @override
  String get matchingFiltersConsentNeeded =>
      'Для этих критериев нужно Ваше согласие на обработку сведений о религиозной практике. Они не сохранены.';

  @override
  String get navigationDiscover => 'Поиск';

  @override
  String get navigationMatches => 'Совпадения';

  @override
  String get navigationMessages => 'Сообщения';

  @override
  String get navigationEvents => 'Мероприятия';

  @override
  String get navigationProfile => 'Профиль';

  @override
  String get navigationShowTabs => 'Показать вкладки';

  @override
  String get onboardingStart => 'Начать';

  @override
  String onboardingStep(String current, String total) {
    return '$current / $total';
  }

  @override
  String onboardingPageOf(int current, int total) {
    return 'Страница $current из $total';
  }

  @override
  String get onboardingPage1Title => 'Добро пожаловать в MAZL';

  @override
  String get onboardingPage1Body =>
      'Приложение для знакомств, созданное для еврейской общины.';

  @override
  String get onboardingPage2Title => 'Найдите свой мазл';

  @override
  String get onboardingPage2Body =>
      'Знакомьтесь с профилями, которые подходят Вам по ценностям и религиозной практике.';

  @override
  String get onboardingPage3Title => 'Режим пары';

  @override
  String get onboardingPage3Body =>
      'Когда любовь найдена, MAZL остаётся рядом: найдите любовь и сохраните её.';

  @override
  String get onboardingPage3Feature1 => 'Ежедневные вопросы';

  @override
  String get onboardingPage3Feature2 => 'Важные события пары';

  @override
  String get onboardingPage3Feature3 => 'Общий еврейский календарь';

  @override
  String get onboardingPage3Feature4 => 'Занятия и предложения';

  @override
  String get onboardingPage4Title => 'Режим Шаббата';

  @override
  String get onboardingPage4Body =>
      'Время зажигания свечей и Авдалы для Вашего города и экран отдыха.';

  @override
  String get onboardingPage5Title => 'Подборка дня';

  @override
  String get onboardingPage5Body =>
      'Каждый день в разделе «Поиск» Вас ждёт небольшая подборка анкет.';

  @override
  String get packsSuperLikesLabel => 'Суперлайки';

  @override
  String get packsSuperLikesTitle => 'Суперлайки закончились.';

  @override
  String get packsSuperLikesSubtitle =>
      'Возьмите ещё: купленные суперлайки не сгорают.';

  @override
  String get packsBoostsLabel => 'Бусты';

  @override
  String get packsBoostsTitle => 'Бустов не осталось.';

  @override
  String packsBoostsSubtitle(int minutes) {
    return 'Поднимите свой профиль выше на $minutes мин. Купленный буст не сгорает.';
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
    return 'Купить: $quantity за $price';
  }

  @override
  String get packsLoading => 'Загрузка предложений';

  @override
  String get packsStoreUnavailable =>
      'Магазин сейчас недоступен. Попробуйте ещё раз чуть позже.';

  @override
  String get packsPending =>
      'Покупка ожидает подтверждения. Баланс обновится, как только её одобрят.';

  @override
  String get packsBoostAlreadyActive => 'Буст уже включён.';

  @override
  String get packsErrorExhausted => 'Сейчас у Вас ничего не осталось.';

  @override
  String get plusFeatureUnlimitedLikesTitle => 'Безлимитные лайки';

  @override
  String get plusFeatureUnlimitedLikesDescription =>
      'Ставьте лайки сколько угодно, без дневного лимита.';

  @override
  String get plusFeatureSeeWhoLikesYouTitle => 'Узнать, кто Вас лайкнул';

  @override
  String get plusFeatureSeeWhoLikesYouDescription =>
      'Узнайте, кто Вас лайкнул, ещё до встречи.';

  @override
  String get plusFeatureSuperLikesTitle => 'Суперлайки';

  @override
  String get plusFeatureSuperLikesDescription =>
      'Выделяйтесь с 5 суперлайками в день.';

  @override
  String get plusFeatureBoostTitle => 'Буст';

  @override
  String get plusFeatureBoostDescription => 'Будьте в начале очереди 30 минут.';

  @override
  String get plusFeatureReadReceiptsTitle => 'Подтверждения прочтения';

  @override
  String get plusFeatureReadReceiptsDescription =>
      'Узнавайте, когда Ваши сообщения прочитаны.';

  @override
  String get plusFeatureAdvancedFiltersTitle => 'Расширенные фильтры';

  @override
  String get plusFeatureAdvancedFiltersDescription =>
      'Фильтруйте по практике, общине и не только.';

  @override
  String get plusFeaturePrioritySupportTitle => 'Приоритетная поддержка';

  @override
  String get plusFeaturePrioritySupportDescription =>
      'Получайте быстрый ответ от нашей команды.';

  @override
  String get plusReservedLabel => 'Только для mazl+';

  @override
  String get plusDiscover => 'Узнать о mazl+';

  @override
  String get plusNotNow => 'Не сейчас';

  @override
  String plusDailyLimitLabel(int limit) {
    return 'Лимит дня · $limit / $limit';
  }

  @override
  String get plusDailyLimitTitle => 'Ваши лайки на сегодня закончились.';

  @override
  String get plusDailyLimitBody =>
      'Они вернутся в полночь. Или продолжайте без ограничений и узнайте, кто Вас уже лайкнул.';

  @override
  String get plusDailyLimitNext => 'Следующие лайки через';

  @override
  String get plusDailyLimitWait => 'Дождаться полуночи';

  @override
  String get plusOfferTagline => 'Знакомьтесь без счёта.';

  @override
  String get plusPerkUnlimitedLikesDetail => 'Больше никаких 10 в день.';

  @override
  String get plusPerkSeeWhoDetail => 'Ещё до встречи.';

  @override
  String get plusPerkSuperLikesTitle => '5 суперлайков в день';

  @override
  String get plusPerkSuperLikesDetail => 'Вместо одного.';

  @override
  String get plusPerkBoostTitle => 'Один буст в день';

  @override
  String get plusPerkBoostDetail => 'В начале очереди 30 минут.';

  @override
  String get plusPerkFiltersDetail => 'Практика, община и не только.';

  @override
  String get plusYourPlan => 'Ваш тариф';

  @override
  String plusMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months месяца',
      many: '$months месяцев',
      few: '$months месяца',
      one: '$months месяц',
    );
    return '$_temp0';
  }

  @override
  String plusPerMonth(String price) {
    return '$price в месяц';
  }

  @override
  String plusPlanSavings(int percent) {
    return '-$percent %';
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
    return '$duration, $price, $perMonth, экономия $saving';
  }

  @override
  String plusContinuePrice(String price) {
    return 'Продолжить · $price';
  }

  @override
  String get plusAndroidSoon => 'Скоро на Android';

  @override
  String get plusRestore => 'Восстановить';

  @override
  String get plusTerms => 'Условия';

  @override
  String get plusPrivacy => 'Конфиденциальность';

  @override
  String get plusLegalAppStore =>
      'Автоматическое продление, отменить можно в любой момент в настройках App Store.';

  @override
  String get plusLegalGooglePlay =>
      'Автоматическое продление, отменить можно в любой момент в настройках Google Play.';

  @override
  String get plusPendingApproval =>
      'Покупка ожидает подтверждения. Подписка включится, как только её одобрят.';

  @override
  String get plusOfferRestored => 'Подписка восстановлена';

  @override
  String get plusOfferNothingFound => 'Подписка не найдена';

  @override
  String get plusPlansSoon => 'Подписки скоро будут доступны.';

  @override
  String get plusErrorPurchaseInProgress => 'Покупка уже выполняется.';

  @override
  String get plusErrorOwnedByAnotherAccount =>
      'Эта покупка в App Store уже привязана к другому аккаунту mazl.';

  @override
  String get plusErrorInvalidTransaction =>
      'Не удалось подтвердить покупку в App Store. Её проверят снова при следующем запуске.';

  @override
  String get plusErrorInvalidBody =>
      'Не удалось корректно передать Вашу покупку. Повторите через минуту.';

  @override
  String get plusErrorSignInAgain =>
      'Войдите в mazl снова, чтобы завершить покупку.';

  @override
  String get plusErrorOffline =>
      'Нет соединения. Ваша покупка сохранена и будет подтверждена, как только это станет возможным.';

  @override
  String get plusErrorGeneric =>
      'Не удалось завершить покупку. Повторите через минуту.';

  @override
  String get plusErrorInactive => 'Ваша подписка не активна.';

  @override
  String get plusErrorRestoreFailed =>
      'Не удалось восстановить покупки. Повторите через минуту.';

  @override
  String get plusActiveSubscription => 'Подписка активна';

  @override
  String plusActiveSubscriptionPlan(String plan) {
    return 'Подписка активна · $plan';
  }

  @override
  String get plusWelcomeTitle => 'Добро пожаловать в mazl+.';

  @override
  String get plusWelcomeSubtitle => 'Всё разблокировано. С чего начнёте?';

  @override
  String plusWelcomeLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count человека поставили Вам лайк',
      many: '$count человек поставили Вам лайк',
      few: '$count человека поставили Вам лайк',
      one: '$count человек поставил Вам лайк',
    );
    return '$_temp0';
  }

  @override
  String get plusWelcomeLikesDetail => 'Посмотреть сейчас';

  @override
  String get plusWelcomeBoostTitle => 'Запустить буст';

  @override
  String get plusWelcomeBoostDetail => 'В начале очереди 30 минут';

  @override
  String get plusWelcomeFiltersTitle => 'Настроить фильтры';

  @override
  String get plusWelcomeFiltersDetail => 'Практика, община и не только';

  @override
  String plusTitleDetail(String title, String detail) {
    return '$title. $detail';
  }

  @override
  String get plusSubscriptionTitle => 'Подписка';

  @override
  String get plusStatusActive => 'Активна';

  @override
  String get plusStatusCancelled => 'Отменена';

  @override
  String get plusFactPlan => 'Тариф';

  @override
  String get plusFactRenewal => 'Продление';

  @override
  String get plusFactExpiration => 'Окончание';

  @override
  String plusPlanAndPrice(String duration, String price) {
    return '$duration · $price';
  }

  @override
  String plusSuperLikesOf(int left, int max) {
    return '$left из $max';
  }

  @override
  String get plusBoostAvailable => 'Доступен';

  @override
  String get plusBoostUsed => 'Использован сегодня';

  @override
  String get plusLikesLabel => 'Лайки';

  @override
  String get plusLikesUnlimited => 'Безлимит';

  @override
  String get plusManageAppStore => 'Управлять в App Store';

  @override
  String get plusManageGooglePlay => 'Управлять в Google Play';

  @override
  String get plusManageFailed => 'Не удалось открыть управление подпиской.';

  @override
  String get plusRestorePurchases => 'Восстановить покупки';

  @override
  String get plusNoActiveSubscription => 'Активной подписки нет.';

  @override
  String get plusPurchasesRestored => 'Покупки восстановлены.';

  @override
  String get plusNothingToRestore => 'Подписка не найдена.';

  @override
  String get plusSettingsPitch => 'Безлимитные лайки, кто Вас лайкнул, буст';

  @override
  String get plusUpgradeTo => 'Перейти на mazl+';

  @override
  String plusSettingsSemanticsActive(String detail) {
    return 'mazl+. $detail';
  }

  @override
  String plusSettingsSemanticsUpgrade(String detail) {
    return 'Перейти на mazl+. $detail';
  }

  @override
  String get privacyGateUnverifiable =>
      'Не удалось проверить Ваше согласие. Проверьте соединение.';

  @override
  String get privacyGateAsk => 'Чтобы указать свою практику, дайте согласие';

  @override
  String get privacyGive => 'Дать согласие';

  @override
  String get privacyLockedHint =>
      'Станет доступно, когда Вы дадите согласие на данные о религиозной практике.';

  @override
  String get privacySheetLabel => 'Чувствительные данные · GDPR, статья 9';

  @override
  String get privacySheetTitle =>
      'Ваша религиозная практика — с Вашего согласия';

  @override
  String get privacySheetBody =>
      'Эти сведения помогают подбирать подходящие анкеты. Это чувствительные данные: они обрабатываются только с Вашего явного согласия, отдельного от условий использования. Вы можете отказаться и всё равно пользоваться MAZL.';

  @override
  String get privacySheetCheckbox =>
      'Я прочитал(а) этот текст и даю явное согласие.';

  @override
  String get privacySheetAccept => 'Согласен(на)';

  @override
  String get privacySheetDecline => 'Продолжить без этого';

  @override
  String get privacySheetErrorOutdated =>
      'Текст был обновлён. Закройте это окно и откройте его снова.';

  @override
  String get privacySheetErrorSave =>
      'Не удалось сохранить Ваш выбор. Попробуйте ещё раз.';

  @override
  String get privacySettingsTitle => 'Данные о религиозной практике';

  @override
  String get privacySettingsGrantedShort => 'Дано';

  @override
  String get privacySettingsDeniedShort => 'Не дано';

  @override
  String get privacySettingsGrantedTitle => 'Согласие дано';

  @override
  String get privacySettingsNotGrantedTitle => 'Согласие не дано';

  @override
  String get privacySettingsWithdraw => 'Отозвать согласие';

  @override
  String get privacySettingsWithdrawTitle => 'Отозвать согласие?';

  @override
  String get privacySettingsWithdrawBody =>
      'Ваше течение, кашрут, соблюдение Шаббата и намерение будут удалены из анкеты.';

  @override
  String get privacySettingsWithdrawFailed =>
      'Не удалось отозвать согласие. Попробуйте ещё раз.';

  @override
  String get privacySettingsLoadFailed =>
      'Не удалось загрузить Ваше согласие. Проверьте соединение.';

  @override
  String get profileMyProfile => 'Мой профиль';

  @override
  String get profileEdit => 'Изменить';

  @override
  String get profileSettings => 'Настройки';

  @override
  String get profileMoreOptions => 'Дополнительно';

  @override
  String get profilePass => 'Пропустить';

  @override
  String profileLikeName(String name) {
    return 'Нравится $name';
  }

  @override
  String get profileThisPerson => 'этот человек';

  @override
  String get profileFallbackName => 'Пользователь';

  @override
  String get profileFallbackReportName => 'Этот пользователь';

  @override
  String get profileDefaultLocation => 'Франция';

  @override
  String get profileDistanceUnderOneKm => 'менее 1 км';

  @override
  String profileDistanceKm(int km) {
    return '$km км';
  }

  @override
  String get profileGenderMale => 'Мужчина';

  @override
  String get profileGenderFemale => 'Женщина';

  @override
  String get profileFactPractice => 'Практика';

  @override
  String get profileFactKashrut => 'Кашрут';

  @override
  String get profileShabbat => 'Шаббат';

  @override
  String get profileFactGender => 'Пол';

  @override
  String get profileEssentials => 'Главное';

  @override
  String get profileInAFewWords => 'Коротко';

  @override
  String get profileAbout => 'О себе';

  @override
  String get profileLookingFor => 'Что я ищу';

  @override
  String get profileAddPhotos => 'Добавить фото';

  @override
  String get profileVerified => 'Профиль подтверждён';

  @override
  String get profileVerifiedPlus => 'Профиль подтверждён+';

  @override
  String get profileVerifyMyProfile => 'Подтвердить профиль';

  @override
  String profileVerificationStatus(String status) {
    return 'Статус подтверждения: $status';
  }

  @override
  String get profilePhotoPrevious => 'Предыдущее фото';

  @override
  String get profilePhotoNext => 'Следующее фото';

  @override
  String profilePhotoCounter(int current, int total) {
    return 'Фото $current из $total';
  }

  @override
  String profileCompletionEyebrow(int done, int total) {
    return 'Профиль · $done/$total';
  }

  @override
  String get profileCompletionTitle => 'Заполните профиль';

  @override
  String profileCompletionRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось $count шага',
      many: 'Осталось $count шагов',
      few: 'Осталось $count шага',
      one: 'Остался $count шаг',
    );
    return '$_temp0';
  }

  @override
  String get profileCompletionAction => 'Заполнить сейчас';

  @override
  String get profileStepPhotosDone => 'Фото добавлены';

  @override
  String get profileStepPhotosTodo => 'Добавьте не менее 2 фото';

  @override
  String get profileStepBioDone => 'О себе заполнено';

  @override
  String get profileStepBioTodo => 'Расскажите о себе в паре строк';

  @override
  String get profileStepCityDone => 'Город указан';

  @override
  String get profileStepCityTodo => 'Укажите город';

  @override
  String get profileStepVerifiedDone => 'Профиль подтверждён';

  @override
  String get profileStepVerifiedTodo => 'Подтвердите профиль';

  @override
  String get profileCoupleMode => 'Режим пары';

  @override
  String get profileCoupleInCoupleTitle => 'В паре';

  @override
  String profileCoupleInCoupleBody(String name) {
    return 'Вы в режиме пары с $name.';
  }

  @override
  String get profileCoupleElsewhereTitle => 'Режим пары уже включён';

  @override
  String get profileCoupleElsewhereBody =>
      'Вы уже в режиме пары с другим человеком.';

  @override
  String get profileCoupleReceivedTitle => 'Запрос получен';

  @override
  String profileCoupleReceivedBody(String name) {
    return '$name хочет включить режим пары с Вами.';
  }

  @override
  String get profileCoupleRespond => 'Ответить';

  @override
  String get profileCouplePendingTitle => 'Запрос отправлен';

  @override
  String profileCouplePendingBody(String name) {
    return 'Ответа от $name пока нет.';
  }

  @override
  String get profileCoupleCancelRequest => 'Отменить запрос';

  @override
  String get profileCoupleAvailableTitle => 'Перейти в режим пары';

  @override
  String get profileCoupleAvailableBody =>
      'У вас мэтч. Включите режим пары, чтобы делиться занятиями вместе.';

  @override
  String profileCoupleActivate(String name) {
    return 'Включить с $name';
  }

  @override
  String profileCoupleRequestSent(String name) {
    return 'Запрос отправлен: $name.';
  }

  @override
  String get profileCompatibility => 'Совместимость';

  @override
  String get profileCompatibilityVeryHigh => 'Очень совместимы';

  @override
  String get profileCompatibilityHigh => 'Совместимы';

  @override
  String get profileCompatibilityAverage => 'Средняя совместимость';

  @override
  String get profileCompatibilityLow => 'Низкая совместимость';

  @override
  String get profileCompatibilityBasis => 'Рассчитано по вашим двум профилям.';

  @override
  String get profileCompatibilityUnavailable =>
      'Совместимость пока недоступна.';

  @override
  String profileCompatibilityUnlockTitle(String name) {
    return 'Узнайте, насколько Вы совместимы с $name.';
  }

  @override
  String get profileCompatibilityUnlockBody =>
      'Рассчитывается по Вашей практике, намерениям и ценностям.';

  @override
  String get profileCompatibilityUnlock => 'Открыть с mazl+';

  @override
  String get profileFactorIntentions => 'Намерения';

  @override
  String get profileFactorAge => 'Возраст';

  @override
  String get profileFactorDistance => 'Расстояние';

  @override
  String get profileVerdictSameIntention => 'Вы ищете одно и то же';

  @override
  String get profileVerdictDifferentIntention => 'Разные намерения';

  @override
  String get profileVerdictSameDenomination => 'Одно течение';

  @override
  String get profileVerdictSimilarPractice => 'Похожая практика';

  @override
  String get profileVerdictDifferentPractice => 'Разная практика';

  @override
  String get profileVerdictVeryCloseAge => 'Очень близкий возраст';

  @override
  String get profileVerdictCloseAge => 'Близкий возраст';

  @override
  String get profileVerdictModerateAgeGap => 'Умеренная разница в возрасте';

  @override
  String get profileVerdictLargeAgeGap => 'Большая разница в возрасте';

  @override
  String get profileVerdictVeryNear => 'Совсем рядом (< 10 км)';

  @override
  String get profileVerdictNear => 'Близко (< 25 км)';

  @override
  String get profileVerdictModerateDistance => 'Среднее расстояние';

  @override
  String get profileVerdictFar => 'Довольно далеко';

  @override
  String profileCompatibilityCriteria(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Проанализировано $count критерия',
      many: 'Проанализировано $count критериев',
      few: 'Проанализировано $count критерия',
      one: 'Проанализирован $count критерий',
    );
    return '$_temp0';
  }

  @override
  String get profileCompatibilityScoreTitle => 'Оценка совместимости';

  @override
  String profileCompatibilityWith(String name) {
    return 'С $name';
  }

  @override
  String get profileCompatibilityDetails => 'Подробности';

  @override
  String get profileCompatibilityIncomplete =>
      'Заполните профили, чтобы увидеть больше подробностей';

  @override
  String get profileCompatibilityNote =>
      'Оценка основана на предпочтениях и общих чертах';

  @override
  String get profileCompatibilityGotIt => 'Понятно';

  @override
  String get profilePromptsMine => 'Мои вопросы';

  @override
  String get profilePromptsSubtitle =>
      'Ответьте на вопросы, чтобы показать свою индивидуальность';

  @override
  String profilePromptsMaxReached(int max) {
    return 'Достигнут максимум: $max';
  }

  @override
  String get profilePromptsAllUsed => 'Все вопросы уже использованы';

  @override
  String get profilePromptAdd => 'Добавить вопрос';

  @override
  String get profilePromptChoose => 'Выберите вопрос';

  @override
  String get profilePromptYourAnswer => 'Ваш ответ…';

  @override
  String get profilePromptDeleteTitle => 'Удалить этот вопрос?';

  @override
  String get profileIrreversibleSentence => 'Это действие нельзя отменить.';

  @override
  String get profileIrreversible => 'Это действие нельзя отменить';

  @override
  String get profilePromptDeleted => 'Вопрос удалён';

  @override
  String get profilePromptsGetToKnowMe => 'Узнайте меня лучше';

  @override
  String get profilePromptCategoryPersonality => 'Личность';

  @override
  String get profilePromptCategoryLifestyle => 'Образ жизни';

  @override
  String get profilePromptCategoryJewish => 'Иудаизм';

  @override
  String get profilePromptCategoryConversation => 'Разговор';

  @override
  String get profileOther => 'Другое';

  @override
  String get profilePromptPerfectSunday => 'Моё идеальное воскресенье...';

  @override
  String get profilePromptFunFact => 'Удивительный факт обо мне...';

  @override
  String get profilePromptLifeGoal => 'Одна из моих целей в жизни...';

  @override
  String get profilePromptPetPeeve => 'Что раздражает меня больше всего...';

  @override
  String get profilePromptProudOf => 'Я горжусь...';

  @override
  String get profilePromptLookingFor => 'Я ищу того, кто...';

  @override
  String get profilePromptIdealVacation => 'Мой идеальный отпуск...';

  @override
  String get profilePromptFavoriteFood => 'Моё любимое блюдо...';

  @override
  String get profilePromptHiddenTalent => 'Мой скрытый талант...';

  @override
  String get profilePromptBingeWatching => 'Сейчас я смотрю...';

  @override
  String get profilePromptShabbatIdeal => 'Мой идеальный Шаббат...';

  @override
  String get profilePromptFamilyTradition =>
      'Семейная традиция, которую я обожаю...';

  @override
  String get profilePromptFavoriteHoliday =>
      'Мой любимый еврейский праздник...';

  @override
  String get profilePromptFridayNight => 'Пятничный вечер у меня дома...';

  @override
  String get profilePromptIsraelMemory =>
      'Моё лучшее воспоминание об Израиле...';

  @override
  String get profilePromptJewishValue =>
      'Еврейская ценность, которая направляет меня...';

  @override
  String get profilePromptDebateMe => 'Поспорьте со мной о…';

  @override
  String get profilePromptTeachMe => 'Расскажите мне что-нибудь о…';

  @override
  String get profilePromptTogetherWeCould => 'Вместе мы могли бы...';

  @override
  String get profilePromptFirstDate => 'Идеальное первое свидание...';

  @override
  String get profileIntentionHint => 'Покажите другим, что Вы ищете';

  @override
  String get profileIntentionMarriage => 'Брак';

  @override
  String get profileIntentionSerious => 'Серьёзные отношения';

  @override
  String get profileIntentionOpen => 'Открытость ко всему';

  @override
  String get profileIntentionOpenSelector => 'Открытость ко всему';

  @override
  String get profileIntentionFriendsFirst => 'Сначала дружба';

  @override
  String get profileIntentionUndecided => 'Не знаю';

  @override
  String get profileIntentionMarriageDescription =>
      'Ищу будущего мужа или жену';

  @override
  String get profileIntentionSeriousDescription => 'Ищу долгие отношения';

  @override
  String get profileIntentionOpenDescription =>
      'Посмотрим, к чему это приведёт';

  @override
  String get profileIntentionFriendsFirstDescription =>
      'Давайте сначала познакомимся поближе';

  @override
  String get profileDenomination => 'Течение';

  @override
  String get profileDenominationSecular => 'Светский';

  @override
  String get profileDenominationTraditional => 'Традиционный';

  @override
  String get profileDenominationMasorti => 'Масорти';

  @override
  String get profileDenominationLiberal => 'Либеральный';

  @override
  String get profileDenominationModernOrthodox => 'Современная ортодоксия';

  @override
  String get profileDenominationOrthodox => 'Ортодоксия';

  @override
  String get profileDenominationChabad => 'Хабад';

  @override
  String get profileFieldKashrut => 'Кашрут';

  @override
  String get profileKashrutNone => 'Нет';

  @override
  String get profileKashrutHome => 'Кошерно дома';

  @override
  String get profileKashrutStrict => 'Строгий кашрут';

  @override
  String get profileKashrutGlatt => 'Глатт кошер';

  @override
  String get profileKashrutOptionHome => 'Дома';

  @override
  String get profileKashrutOptionStrict => 'Строгий';

  @override
  String get profileKashrutOptionGlatt => 'Глатт';

  @override
  String get profileShabbatNotObservant => 'Не соблюдаю';

  @override
  String get profileShabbatPartial => 'Шаббат частично';

  @override
  String get profileShabbatObserved => 'Шаббат соблюдается';

  @override
  String get profileShabbatStrict => 'Строгий Шаббат';

  @override
  String get profileShabbatFamily => 'Шаббат в семье';

  @override
  String get profileShabbatOptionPartial => 'Частично';

  @override
  String get profileShabbatOptionObservant => 'Соблюдаю';

  @override
  String get profileShabbatOptionStrict => 'Соблюдаю строго';

  @override
  String get profileSynagogue => 'Синагога';

  @override
  String get profileSynagogueDaily => 'Каждый день';

  @override
  String get profileSynagogueWeekly => 'Каждую неделю';

  @override
  String get profileSynagogueHolidays => 'По праздникам';

  @override
  String get profileSynagogueRarely => 'Редко';

  @override
  String get profileEditTitle => 'Редактирование профиля';

  @override
  String get profilePhotos => 'Фото';

  @override
  String get profilePhotosHint =>
      'Нажмите и удерживайте, чтобы сделать главной';

  @override
  String get profileBioHint => 'Расскажите о себе…';

  @override
  String get profileBasicInfo => 'Основная информация';

  @override
  String get profileFirstName => 'Имя';

  @override
  String get profileCity => 'Город';

  @override
  String get profilePracticeTitle => 'Моя практика';

  @override
  String get profilePrimaryPhoto => 'Главное';

  @override
  String get profileEnterFirstName => 'Введите имя';

  @override
  String get profileEnterCity => 'Введите город';

  @override
  String get profileUpdated => 'Профиль обновлён';

  @override
  String get profilePhotoAdded => 'Фото добавлено';

  @override
  String get profileUploadUnavailable => 'Загрузка сейчас недоступна';

  @override
  String get profileDeletePhotoTitle => 'Удалить фото?';

  @override
  String get profilePhotoDeleted => 'Фото удалено';

  @override
  String get profileServiceUnavailable => 'Сервис временно недоступен';

  @override
  String get profilePrimaryUpdated => 'Главное фото обновлено';

  @override
  String profileSetupStep(int step, int total) {
    return 'Шаг $step/$total';
  }

  @override
  String get profileSetupNext => 'Далее';

  @override
  String get profileSetupFinish => 'Готово';

  @override
  String get profileSetupNameRequired => 'Укажите имя, чтобы продолжить';

  @override
  String get profileSetupBirthdateRequired => 'Укажите дату рождения';

  @override
  String get profileSetupGenderRequired => 'Укажите пол';

  @override
  String get profileBirthdate => 'Дата рождения';

  @override
  String get profileBirthdateHint => 'ДД.ММ.ГГГГ';

  @override
  String get profileSetupAboutYouTitle => 'Расскажите о себе';

  @override
  String get profileSetupAboutYouSubtitle =>
      'Эта информация будет видна в Вашем профиле';

  @override
  String get profileFirstNameHint => 'Как Вас зовут?';

  @override
  String get profileIAm => 'Я';

  @override
  String get profileAMan => 'Мужчина';

  @override
  String get profileAWoman => 'Женщина';

  @override
  String get profileCityHint => 'Где Вы живёте?';

  @override
  String get profileSetupPhotosTitle => 'Добавьте фото';

  @override
  String get profileSetupPhotosSubtitle =>
      'Добавьте не менее 2 фото, чтобы продолжить';

  @override
  String get profileSetupPhotosTip =>
      'Профили с качественными фото получают в 3 раза больше мэтчей.';

  @override
  String get profileSetupPracticeTitle => 'Ваша практика';

  @override
  String get profileSetupPracticeSubtitle =>
      'Помогите нам найти того, кто Вам подходит';

  @override
  String get profileSetupLookingTitle => 'Что Вы ищете';

  @override
  String get profileSetupLookingSubtitle =>
      'Помогите нам показывать Вам подходящие профили';

  @override
  String get profileILookFor => 'Я ищу';

  @override
  String get profileAgeRange => 'Возрастной диапазон';

  @override
  String get profileMaxDistance => 'Максимальное расстояние';

  @override
  String profileDistanceSliderLabel(int km) {
    return '$km км';
  }

  @override
  String get profileGoal => 'Цель';

  @override
  String get profileSetupPreferencesNote =>
      'Эти предпочтения определяют, какие анкеты Вы увидите в разделе «Поиск». Их можно изменить в любой момент.';

  @override
  String get profileReportThisProfile => 'Пожаловаться на профиль';

  @override
  String get profileChoiceNotSent =>
      'Ваш выбор не отправлен. Попробуйте ещё раз.';

  @override
  String get safetyBlock => 'Заблокировать';

  @override
  String get safetyBlockSubtitle =>
      'Этот человек больше не сможет видеть Ваш профиль и связываться с Вами';

  @override
  String get safetyReportSubtitle => 'Сообщить о неприемлемом поведении';

  @override
  String get safetyBlockConfirmTitle => 'Заблокировать этого пользователя?';

  @override
  String safetyBlockConfirmIntro(String name) {
    return 'Если Вы заблокируете $name:';
  }

  @override
  String get safetyBlockEffectHidden =>
      'Этот человек больше не сможет видеть Ваш профиль';

  @override
  String get safetyBlockEffectNotSeen => 'Вы больше не увидите его профиль';

  @override
  String get safetyBlockEffectChats => 'Ваши переписки будут удалены';

  @override
  String get safetyBlockEffectNotNotified =>
      'Этот человек не получит уведомления';

  @override
  String safetyBlocked(String name) {
    return '$name заблокирован';
  }

  @override
  String get safetyBlockFailed => 'Ошибка при блокировке';

  @override
  String get safetyReportTitle => 'Сообщить о проблеме';

  @override
  String safetyReportWhy(String name) {
    return 'Почему Вы жалуетесь на $name?';
  }

  @override
  String get safetyReportDetailsHint => 'Дополнительные сведения (по желанию)';

  @override
  String get safetyReportAlsoBlock => 'Также заблокировать этого пользователя';

  @override
  String get safetyReportAlsoBlockHint => 'Вы больше не увидите этот профиль';

  @override
  String get safetyReportSend => 'Отправить жалобу';

  @override
  String get safetyReportThanks =>
      'Спасибо за Вашу жалобу. Наша команда её рассмотрит.';

  @override
  String get safetyReportFailed => 'Ошибка при отправке жалобы';

  @override
  String get safetyCategoryFakeProfile => 'Фальшивый профиль';

  @override
  String get safetyCategoryFakeProfileHint => 'Чужие фото, ложная личность';

  @override
  String get safetyCategoryInappropriatePhotos => 'Неприемлемые фото';

  @override
  String get safetyCategoryInappropriatePhotosHint =>
      'Сексуальный, жестокий или шокирующий контент';

  @override
  String get safetyCategoryHarassment => 'Преследование';

  @override
  String get safetyCategoryHarassmentHint =>
      'Навязчивые сообщения, угрозы, оскорбления';

  @override
  String get safetyCategorySpam => 'Спам / Мошенничество';

  @override
  String get safetyCategorySpamHint =>
      'Реклама, просьбы о деньгах, подозрительные ссылки';

  @override
  String get safetyCategoryUnderage => 'Несовершеннолетие';

  @override
  String get safetyCategoryUnderageHint => 'Похоже, этому человеку нет 18 лет';

  @override
  String get safetyCategoryOfflineBehavior => 'Поведение вне приложения';

  @override
  String get safetyCategoryOfflineBehaviorHint =>
      'Неприемлемое поведение во время встречи';

  @override
  String get safetyCategoryOther => 'Другое';

  @override
  String get safetyCategoryOtherHint => 'Другая причина (уточните)';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Язык телефона';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionAccount => 'Аккаунт';

  @override
  String get settingsEditProfile => 'Изменить профиль';

  @override
  String get settingsEmail => 'Эл. почта';

  @override
  String get settingsNotSignedIn => 'Вход не выполнен';

  @override
  String get settingsDefaultUserName => 'Пользователь';

  @override
  String get settingsSectionDiscovery => 'Поиск';

  @override
  String get settingsLocation => 'Местоположение';

  @override
  String get settingsLocationNotSet => 'Не задано';

  @override
  String get settingsMaxDistance => 'Максимальное расстояние';

  @override
  String settingsDistanceKm(int distance) {
    final intl.NumberFormat distanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String distanceString = distanceNumberFormat.format(distance);

    return '$distanceString км';
  }

  @override
  String get settingsAgeRange => 'Возрастной диапазон';

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

    return '$minString - $maxString лет';
  }

  @override
  String get settingsSectionJewish => 'Еврейские настройки';

  @override
  String get settingsShabbatMode => 'Режим Шаббата';

  @override
  String get settingsShabbatAutoPause => 'Время Шаббата';

  @override
  String get settingsSectionCouple => 'Режим пары';

  @override
  String get settingsSectionSubscription => 'Подписка';

  @override
  String get settingsRestorePurchases => 'Восстановить покупки';

  @override
  String get settingsRestoreSuccess => 'Покупки успешно восстановлены.';

  @override
  String get settingsRestoreError =>
      'Не удалось восстановить покупки. Попробуйте ещё раз.';

  @override
  String settingsSubscriptionRenewsOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'продление $dateString';
  }

  @override
  String settingsSubscriptionEndsOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'до $dateString';
  }

  @override
  String get settingsSectionPrivacy => 'Конфиденциальность и безопасность';

  @override
  String get settingsBlockedUsers => 'Заблокированные пользователи';

  @override
  String get settingsBlockedUsersHint => 'Управление заблокированными';

  @override
  String get settingsProfileVerification => 'Подтверждение профиля';

  @override
  String get settingsVerified => 'Подтверждён';

  @override
  String get settingsNotVerified => 'Не подтверждён';

  @override
  String get settingsSectionAbout => 'О приложении';

  @override
  String get settingsHelp => 'Помощь и поддержка';

  @override
  String get settingsTerms => 'Условия использования';

  @override
  String get settingsSales => 'Условия продажи';

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsLogOut => 'Выйти';

  @override
  String get settingsLogOutMessage => 'Вы действительно хотите выйти?';

  @override
  String get settingsDeleteAccount => 'Удалить аккаунт';

  @override
  String get settingsDeleteReasonPrompt => 'Почему Вы хотите уйти?';

  @override
  String get settingsDeleteReasonFoundSomeone => 'У меня появилась пара';

  @override
  String get settingsDeleteReasonNoLongerUsing =>
      'Я больше не пользуюсь приложением';

  @override
  String get settingsDeleteReasonBreak => 'Хочу сделать паузу';

  @override
  String get settingsDeleteReasonTechnical => 'Технические проблемы';

  @override
  String get settingsDeleteReasonService => 'Сервис мне не подходит';

  @override
  String get settingsDeleteReasonOther => 'Другая причина';

  @override
  String get settingsDeleteFinalTitle => 'Окончательное подтверждение';

  @override
  String get settingsDeleteIrreversible => 'Это действие необратимо.';

  @override
  String get settingsDeleteDataList =>
      'Все Ваши данные будут удалены:\n• Ваш профиль и фотографии\n• Ваши совпадения и переписки\n• История лайков\n• Ваши настройки';

  @override
  String get settingsDeleteKeep => 'Оставить аккаунт';

  @override
  String get settingsDeleteError => 'Не удалось удалить аккаунт';

  @override
  String get settingsCitySearchHint => 'Найти город...';

  @override
  String get settingsCitySearchHelp =>
      'Введите название города и выберите подсказку';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String get settingsCoupleLeave => 'Выйти из режима пары';

  @override
  String get settingsCoupleLeaveMessage =>
      'Позже Вы сможете включить его снова.';

  @override
  String get settingsCoupleLeaveConfirm => 'Выйти';

  @override
  String get settingsCoupleLeft => 'Режим пары отключён';

  @override
  String get settingsCoupleLeaveError =>
      'Не удалось выйти из режима пары. Попробуйте ещё раз.';

  @override
  String get settingsCoupleCancelRequestError =>
      'Не удалось отменить запрос. Попробуйте ещё раз.';

  @override
  String get settingsCoupleActive => 'Режим пары включён';

  @override
  String settingsCoupleWithPartner(String name) {
    return 'С $name';
  }

  @override
  String get settingsCoupleWithYourPartner => 'С Вашим партнёром';

  @override
  String get settingsCoupleOpenSpace => 'Пространство пары';

  @override
  String get settingsCoupleOpenCalendar => 'Календарь';

  @override
  String get settingsCoupleSinceToday => 'С сегодняшнего дня';

  @override
  String settingsCoupleDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return '$_temp0';
  }

  @override
  String get settingsCoupleRequestSent => 'Запрос отправлен';

  @override
  String settingsCoupleRequestSentTo(String name) {
    return 'Запрос отправлен: $name';
  }

  @override
  String get settingsCoupleWaiting => 'Ожидаем ответа';

  @override
  String get settingsCoupleCancelRequest => 'Отменить запрос';

  @override
  String get settingsCoupleInvitation => 'Вы нашли любовь?';

  @override
  String get settingsCoupleActivate => 'Включить';

  @override
  String settingsShabbatBasedOn(String place) {
    return 'Для места: $place';
  }

  @override
  String get settingsShabbatDefaultPlace => 'Париж, Франция';

  @override
  String get settingsShabbatUnknownPlaceHint =>
      'Это время для Парижа, потому что Ваш город неизвестен. Укажите его в настройках, чтобы получить точное время.';

  @override
  String get settingsShabbatExplanation =>
      'Зажигание свечей — за 18 минут до заката, Авдала — с наступлением ночи. Чтобы сменить место, измените город в настройках.';

  @override
  String get settingsShabbatHeroTitle => 'Шаббат\nшалом.';

  @override
  String get settingsShabbatHeroSubtitle => 'Mazl отдыхает вместе с Вами.';

  @override
  String get settingsShabbatCandleLighting => 'Зажигание свечей';

  @override
  String get settingsShabbatHavdalah => 'Авдала';

  @override
  String get settingsBlockedUserFallbackName => 'Пользователь';

  @override
  String get settingsBlockedUnblockTitle =>
      'Разблокировать этого пользователя?';

  @override
  String settingsBlockedUnblockMessage(String name) {
    return 'Разблокировать $name?\n\nЭтот человек снова сможет видеть Ваш профиль и писать Вам.';
  }

  @override
  String get settingsBlockedUnblockMessageUnnamed =>
      'Разблокировать этого пользователя?\n\nЭтот человек снова сможет видеть Ваш профиль и писать Вам.';

  @override
  String get settingsBlockedUnblock => 'Разблокировать';

  @override
  String settingsBlockedUnblocked(String name) {
    return 'Разблокировано: $name';
  }

  @override
  String get settingsBlockedUnblockedUnnamed => 'Пользователь разблокирован';

  @override
  String get settingsBlockedUnblockError => 'Не удалось разблокировать';

  @override
  String get settingsBlockedEmptyTitle => 'Нет заблокированных пользователей';

  @override
  String get settingsBlockedEmptyHint =>
      'Заблокированные Вами люди\nпоявятся здесь';

  @override
  String settingsBlockedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Дата блокировки: $dateString';
  }

  @override
  String get settingsRestoreNothing => 'Подписка не найдена.';

  @override
  String get verificationProfileEyebrow => 'Ваш профиль';

  @override
  String get verificationTitle => 'Верификация';

  @override
  String get verificationLevel1 => 'Уровень 1';

  @override
  String get verificationLevel2 => 'Уровень 2';

  @override
  String get verificationPhotoTitle => 'Фото подтверждено';

  @override
  String get verificationIdentityTitle => 'Личность подтверждена';

  @override
  String get verificationVerifiedPill => 'Подтверждено';

  @override
  String get verificationConsent =>
      'Мы сравниваем Ваше лицо с Вашими фото. Изображения не сохраняются; сохраняется только зашифрованный отпечаток, который можно удалить в любой момент.';

  @override
  String get verificationPhotoVerifiedLine =>
      'Ваше лицо совпадает с Вашими фото.';

  @override
  String verificationPhotoVerifiedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Подтверждено $dateString.';
  }

  @override
  String get verificationRemoveAction => 'Убрать мою верификацию';

  @override
  String get verificationVerifyPhotoAction => 'Подтвердить фото';

  @override
  String get verificationVerifyIdentityAction => 'Подтвердить личность';

  @override
  String verificationBlockedToday(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Лимит исчерпан, повторить попытку можно в $timeString.';
  }

  @override
  String verificationBlockedLater(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Лимит исчерпан, повторить попытку можно $dateString в $timeString.';
  }

  @override
  String get verificationIdentityCheckedNoDate =>
      'Документ проверен по его чипу.';

  @override
  String verificationIdentityCheckedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Проверено $dateString.';
  }

  @override
  String get verificationIdentityPitch =>
      'Паспорт или удостоверение личности, считанные по чипу. Селфи подтверждает, что это действительно Вы.';

  @override
  String get verificationRemoveDialogTitle => 'Убрать мою верификацию?';

  @override
  String get verificationRemoveDialogBody =>
      'Ваш значок и отпечаток Вашего лица будут удалены.';

  @override
  String verificationPhotosMismatch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count из Ваших фото не похожи на Вас: они не учитываются.',
      many: '$count из Ваших фото не похожи на Вас: они не учитываются.',
      few: '$count из Ваших фото не похожи на Вас: они не учитываются.',
      one: 'Одно из Ваших фото не похоже на Вас: оно не учитывается.',
    );
    return '$_temp0';
  }

  @override
  String get verificationLivenessFront => 'Смотрите в камеру';

  @override
  String get verificationLivenessLeft => 'Медленно поверните голову влево';

  @override
  String get verificationLivenessRight => 'Медленно поверните голову вправо';

  @override
  String get verificationLivenessHintNoFace => 'Поместите лицо в круг';

  @override
  String get verificationLivenessHintMultipleFaces =>
      'В кадре должен быть один человек';

  @override
  String get verificationLivenessHintTooSmall => 'Подвиньтесь чуть ближе';

  @override
  String get verificationLivenessHintOffCenter =>
      'Расположите лицо по центру круга';

  @override
  String get verificationLivenessHintLookStraight =>
      'Смотрите прямо перед собой';

  @override
  String get verificationLivenessHintTurnMore => 'Поверните ещё немного';

  @override
  String get verificationLivenessHintTurnLess =>
      'Не так сильно, вернитесь немного назад';

  @override
  String get verificationLivenessHintTurnOtherWay =>
      'Поверните голову в другую сторону';

  @override
  String verificationLivenessPoseCounter(int current, int total) {
    return 'Поза $current / $total';
  }

  @override
  String verificationLivenessPosesTaken(int done, int total) {
    return 'Снято поз: $done из $total';
  }

  @override
  String get verificationLivenessPrivacy =>
      'Только Вы в кадре, хорошее освещение. Изображения не сохраняются.';

  @override
  String get verificationLivenessExpiredTitle => 'Сеанс истёк';

  @override
  String get verificationLivenessExpiredBody =>
      'Отведённое время истекло. Можно начать заново.';

  @override
  String get verificationCameraNeededTitle => 'Нужна камера';

  @override
  String get verificationCameraNeededBody =>
      'MAZL использует фронтальную камеру, чтобы убедиться, что на Ваших фото именно Вы.';

  @override
  String get verificationCameraOpenSettings => 'Открыть настройки';

  @override
  String get verificationCameraAllow => 'Разрешить доступ к камере';

  @override
  String get verificationCameraUnavailableTitle => 'Камера недоступна';

  @override
  String get verificationCameraUnavailableBody =>
      'Не удалось запустить фронтальную камеру.';

  @override
  String get verificationIntroTitle => 'Подтвердите свою личность.';

  @override
  String get verificationIntroSubtitle =>
      'Значок «Личность подтверждена» показывает другим, что на фото действительно Вы. Понадобятся биометрический паспорт или удостоверение личности, две минуты и немного света.';

  @override
  String get verificationIntroStep1 => 'Сфотографировать страницу с фото';

  @override
  String get verificationIntroStep1Detail => 'Чтобы считать две нижние строки.';

  @override
  String get verificationIntroStep2 => 'Приложить телефон к чипу';

  @override
  String get verificationIntroStep2Detail =>
      'Значение имеет чип, подписанный государством.';

  @override
  String get verificationIntroStep3 => 'Селфи в движении';

  @override
  String get verificationIntroStep3Detail => 'Сравнивается с фото на чипе.';

  @override
  String get verificationIntroPrivacy =>
      'Ничего не сохраняется: мы храним только результат.';

  @override
  String get verificationIntroStart => 'Начать';

  @override
  String verificationStepLabel(int step, int total) {
    return 'Шаг $step / $total';
  }

  @override
  String get verificationScanTitle => 'Наведите камеру на страницу с фото.';

  @override
  String get verificationScanHint =>
      'Достаточно двух нижних строк со знаками «<». Избегайте бликов.';

  @override
  String get verificationScanManual => 'Ввести вручную';

  @override
  String get verificationScanFrameSemantics =>
      'Предпросмотр камеры: расположите две нижние строки документа внутри выделенной рамки';

  @override
  String get verificationCameraNotAvailable => 'Камера недоступна.';

  @override
  String get verificationScanUnavailableBody =>
      'Данные со страницы с фото можно ввести вручную.';

  @override
  String get verificationScanEnterDetails => 'Ввести данные';

  @override
  String get verificationManualTitle => 'Введите данные.';

  @override
  String get verificationManualSubtitle =>
      'Перепишите их со страницы с фото в Вашем документе.';

  @override
  String get verificationFieldDocumentNumber => 'Номер документа';

  @override
  String get verificationFieldBirthDate => 'Дата рождения';

  @override
  String get verificationFieldExpiryDate => 'Срок действия';

  @override
  String get verificationDateHint => 'ДД/ММ/ГГГГ';

  @override
  String get verificationManualUseCamera => 'Сканировать камерой';

  @override
  String get verificationErrorDocumentNumber => 'От 5 до 12 букв или цифр.';

  @override
  String get verificationErrorInvalidDate => 'Недопустимая дата.';

  @override
  String get verificationReviewTitle => 'Проверьте эти данные.';

  @override
  String get verificationReviewConfirm => 'Это я';

  @override
  String get verificationRescan => 'Сканировать снова';

  @override
  String get verificationNfcWaitingTitle => 'Приложите документ к телефону.';

  @override
  String get verificationNfcPlacement =>
      'Верхней частью телефона прижмите закрытую обложку паспорта или обратную сторону удостоверения личности. При необходимости снимите чехол.';

  @override
  String get verificationNfcRead => 'Считать документ';

  @override
  String get verificationNfcIllustration =>
      'Верхняя часть телефона лежит на закрытой обложке паспорта';

  @override
  String get verificationNfcReadingTitle => 'Не двигайтесь.';

  @override
  String get verificationNfcReadingSubtitle =>
      'Держите документ у верхней части телефона до конца считывания.';

  @override
  String get verificationNfcProgressLabel => 'Считывание чипа';

  @override
  String verificationNfcProgressValue(int percent) {
    return '$percent %';
  }

  @override
  String get verificationNfcStepDetect => 'Обнаружение документа';

  @override
  String get verificationNfcStepConnect => 'Защищённое соединение';

  @override
  String get verificationNfcStepPhoto => 'Считывание фото';

  @override
  String get verificationNfcStepSignature => 'Считывание подписи';

  @override
  String verificationNfcStepSemantics(String label, String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'done': '$label, завершено',
      'active': '$label, выполняется',
      'waiting': '$label, ожидание',
      'other': '$label',
    });
    return '$_temp0';
  }

  @override
  String get verificationNfcSilentBody =>
      'Так часто бывает с первой попытки. Ничего не отправлено.';

  @override
  String get verificationNfcRescanBody =>
      'Ничего не отправлено. Считайте страницу с фото заново, чтобы начать с верными данными.';

  @override
  String get verificationNfcTip1 => 'Снимите чехол с телефона.';

  @override
  String get verificationNfcTip2 =>
      'Приложите верхнюю часть телефона к центру обложки закрытого паспорта.';

  @override
  String get verificationNfcTip3 =>
      'Оставайтесь неподвижны около десяти секунд.';

  @override
  String get verificationNfcRereadPhotoPage => 'Считать страницу с фото заново';

  @override
  String get verificationManualReviewLink =>
      'Отправить документ на ручную проверку';

  @override
  String get verificationFaceTitle => 'Чип считан.';

  @override
  String get verificationFaceSubtitle =>
      'Остаётся селфи в движении, которое сравнивается с фото на чипе.';

  @override
  String get verificationFaceAction => 'Сделать селфи';

  @override
  String get verificationSubmitSending => 'Идёт проверка…';

  @override
  String get verificationSubmitPreparing => 'Подготовка…';

  @override
  String get verificationDoneTitle => 'Личность подтверждена.';

  @override
  String get verificationDoneSubtitle =>
      'Чип в Вашем документе и Ваше селфи совпадают. Теперь в Вашем профиле есть значок.';

  @override
  String get verificationDoneAction => 'Готово';

  @override
  String get verificationBadgeLabel => 'Личность подтверждена';

  @override
  String get verificationDoneBadgeCaption =>
      'Что другие видят в Вашем профиле.';

  @override
  String get verificationDoneStoredLabel => 'Фото и чип';

  @override
  String get verificationDoneStoredValue => 'Никогда не сохраняются';

  @override
  String get verificationDoneKeptLabel => 'Хранится';

  @override
  String get verificationDoneKeptValue =>
      'Страна, срок действия, анонимный отпечаток';

  @override
  String get verificationDoneProfileLabel => 'Профиль';

  @override
  String get verificationDoneProfileValue => 'Дата рождения из документа';

  @override
  String get verificationComingSoon => 'Скоро будет доступно';

  @override
  String get verificationFailureChipDataInvalid => 'Данные чипа не читаются.';

  @override
  String get verificationFailureChipSignatureInvalid =>
      'Не удалось проверить подпись документа.';

  @override
  String get verificationFailureNotRecognized => 'Документ не распознан.';

  @override
  String get verificationDocumentExpired =>
      'Срок действия этого документа истёк.';

  @override
  String get verificationFailureUnderage =>
      'Для подтверждения личности необходимо, чтобы Вам исполнилось 18 лет.';

  @override
  String get verificationDocumentAlreadyUsed =>
      'Этот документ уже привязан к другому аккаунту.';

  @override
  String get verificationDocumentBanned => 'Этот документ нельзя использовать.';

  @override
  String get verificationDocumentFaceMismatch =>
      'Ваше лицо не совпадает с фото в документе.';

  @override
  String get verificationFailureSessionExpired => 'Сеанс истёк.';

  @override
  String get verificationFailureImagesUnreadable =>
      'Не удалось прочитать изображения.';

  @override
  String get verificationFailureNoFace => 'Лицо не обнаружено.';

  @override
  String get verificationFailureMultipleFaces =>
      'В кадре должно быть только одно лицо.';

  @override
  String get verificationFailureFaceTooSmall => 'Подвиньтесь ближе к камере.';

  @override
  String get verificationFailurePoseMismatch =>
      'Запрошенные движения не распознаны.';

  @override
  String get verificationFailureDuplicateFrames =>
      'Двигайте головой, как требуется.';

  @override
  String get verificationFailureInconsistentIdentity =>
      'Лицо изменилось во время съёмки.';

  @override
  String get verificationFailureNoProfilePhoto =>
      'Сначала добавьте фото в свой профиль.';

  @override
  String get verificationFailureProfileMismatch =>
      'Ваше лицо не совпадает с фото профиля.';

  @override
  String get verificationFailureDailyLimit =>
      'Вы достигли дневного лимита попыток. Возвращайтесь завтра.';

  @override
  String get verificationFailureGeneric => 'Проверка не удалась.';

  @override
  String get verificationFailureNoNfc => 'В этом телефоне нет NFC-считывателя.';

  @override
  String get verificationFailureNfcDisabled =>
      'Включите NFC в настройках телефона.';

  @override
  String get verificationFailureTagLost =>
      'Документ сдвинулся. Держите его неподвижно у телефона.';

  @override
  String get verificationFailureChipMismatch =>
      'Введённые данные не совпадают с данными чипа.';

  @override
  String get verificationFailureUnreadableDocument =>
      'Этот документ невозможно считать.';

  @override
  String get verificationFailureChipSilent => 'Чип не ответил.';

  @override
  String get verificationFailureReadFailed => 'Считывание не удалось.';

  @override
  String get verificationFailureConnection =>
      'Не удаётся подключиться. Проверьте соединение.';

  @override
  String get verificationActionRereadDocument => 'Считать документ заново';

  @override
  String get verificationActionOtherDocument => 'Другой документ';

  @override
  String get verificationReasonNoFace =>
      'Лицо не обнаружено. Встаньте перед камерой в хорошо освещённом месте.';

  @override
  String get verificationReasonMultipleFaces =>
      'Обнаружено несколько лиц. В кадре должен быть только один человек.';

  @override
  String get verificationReasonFaceTooSmall =>
      'Ваше лицо слишком далеко. Подвиньтесь ближе к камере.';

  @override
  String get verificationReasonPoseMismatch =>
      'Запрошенные позы не распознаны. Внимательно следуйте инструкциям.';

  @override
  String get verificationReasonDuplicateFrames =>
      'Изображения слишком похожи. Двигайте головой, как требуется.';

  @override
  String get verificationReasonInconsistentIdentity =>
      'На изображениях не один и тот же человек. Начните заново так, чтобы в кадре были только Вы.';

  @override
  String get verificationReasonNoProfilePhoto =>
      'Сначала добавьте в профиль фото, на котором хорошо видно Ваше лицо.';

  @override
  String get verificationReasonProfileMismatch =>
      'Ваше лицо не совпадает с главным фото. Выберите недавнее фото, на котором Вас хорошо видно.';

  @override
  String get verificationReasonDailyLimit =>
      'Вы достигли лимита попыток на сегодня. Возвращайтесь завтра.';

  @override
  String get verificationReasonSessionExpired => 'Сеанс истёк. Начните заново.';

  @override
  String get verificationReasonSessionInvalid =>
      'Сеанс больше недействителен. Начните заново.';

  @override
  String get verificationReasonImagesUnreadable =>
      'Не удалось прочитать изображения. Начните заново.';

  @override
  String get verificationReasonAppUpdate =>
      'Обновите приложение, чтобы подтвердить профиль.';

  @override
  String get verificationReasonChipAuth =>
      'Не удалось подтвердить подлинность чипа документа.';

  @override
  String get verificationReasonUnderage => 'Вам должно быть не менее 18 лет.';

  @override
  String get verificationReasonNetwork =>
      'Не удаётся подключиться. Проверьте сеть и повторите попытку.';

  @override
  String get verificationReasonGeneric =>
      'Произошла ошибка. Повторите попытку через минуту.';

  @override
  String get verificationNfcAlertApproach =>
      'Поднесите документ к верхней части телефона.';

  @override
  String get verificationNfcAlertAuthenticating =>
      'Не двигайтесь. Защищённое соединение…';

  @override
  String get verificationNfcAlertReadingPhoto => 'Считывание фото… 40 %';

  @override
  String get verificationNfcAlertReadingSignature => 'Считывание подписи… 85 %';

  @override
  String get verificationNfcAlertDone => 'Готово.';

  @override
  String get webSessionsTitle => 'Подключённые компьютеры';

  @override
  String get webSessionsSectionLabel => 'MAZL на компьютере';

  @override
  String get webSessionsIntro =>
      'Пользуйтесь MAZL на компьютере по адресу app.mazl.app. Каждый компьютер остаётся подключённым не более 7 дней.';

  @override
  String get webSessionsConnect => 'Подключить компьютер';

  @override
  String get webSessionsConnected => 'Компьютер подключён.';

  @override
  String get webSessionsLoadFailed =>
      'Не удалось загрузить список компьютеров. Проверьте соединение.';

  @override
  String get webSessionsEmpty => 'Сейчас ни один компьютер не подключён.';

  @override
  String get webSessionsListLabel => 'Компьютеры';

  @override
  String get webSessionsRevoke => 'Отключить';

  @override
  String webSessionsRevokeNamed(String browser) {
    return 'Отключить $browser';
  }

  @override
  String get webSessionsRevokeFailed =>
      'Не удалось отключить этот компьютер. Попробуйте ещё раз.';

  @override
  String get webSessionsRevokeAll => 'Отключить все компьютеры';

  @override
  String get webSessionsRevokeAllTitle => 'Отключить все компьютеры?';

  @override
  String get webSessionsRevokeAllBody =>
      'Вам придётся заново войти на каждом компьютере.';

  @override
  String get webSessionsRevokeAllConfirm => 'Отключить все';

  @override
  String get webSessionsRevokeAllFailed =>
      'Не удалось отключить компьютеры. Попробуйте ещё раз.';

  @override
  String get webSessionsMethodQr => 'Подключён по QR-коду';

  @override
  String get webSessionsMethodGoogle => 'Подключён через Google';

  @override
  String get webSessionsMethodApple => 'Подключён через Apple';

  @override
  String get webSessionsActiveNow => 'Активность: только что';

  @override
  String webSessionsActiveMinutes(int count) {
    return 'Активность: $count мин назад';
  }

  @override
  String webSessionsActiveHours(int count) {
    return 'Активность: $count ч назад';
  }

  @override
  String get webSessionsActiveYesterday => 'Активность: вчера';

  @override
  String webSessionsActiveDays(int count) {
    return 'Активность: $count дн. назад';
  }

  @override
  String webSessionsClockTime(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get webSessionsScanInstruction =>
      'Отсканируйте QR-код, который показан на app.mazl.app';

  @override
  String get webSessionsScanCameraLabel => 'Камера для сканирования QR-кода';

  @override
  String get webSessionsCameraUnavailable =>
      'Нет доступа к камере. Разрешите доступ к камере в настройках iPhone, чтобы отсканировать код.';

  @override
  String get webSessionsScanNotMazl => 'Этот QR-код не относится к MAZL.';

  @override
  String get webSessionsScanExpired =>
      'Срок действия кода истёк. Покажите на компьютере новый код.';

  @override
  String get webSessionsScanTooMany =>
      'Слишком много попыток. Подождите немного и повторите.';

  @override
  String get webSessionsApproveInvalid =>
      'Этот запрос больше не действителен. Покажите на компьютере новый код.';

  @override
  String get webSessionsConnectionProblem =>
      'Не удалось подключиться. Проверьте сеть и повторите попытку.';

  @override
  String get webSessionsGenericProblem =>
      'Произошла ошибка. Повторите попытку чуть позже.';

  @override
  String get webSessionsConfirmLabel => 'Вход в MAZL на компьютере';

  @override
  String get webSessionsConfirmTitle => 'Подключить этот компьютер?';

  @override
  String get webSessionsConfirmBrowser => 'Браузер';

  @override
  String get webSessionsConfirmAddress => 'Адрес';

  @override
  String get webSessionsConfirmAskedAt => 'Запрос отправлен в';

  @override
  String get webSessionsConfirmWarning =>
      'Сканируйте только код, показанный на Вашем собственном компьютере. Если кто-то просит Вас отсканировать код, откажитесь.';

  @override
  String get webSessionsConfirmApprove => 'Подключить';

  @override
  String get webSessionsConfirmDeny => 'Отклонить';
}
