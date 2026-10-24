// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

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
  String get coupleFeedDashboardSettingsTooltip => 'Настройки';

  @override
  String get coupleFeedDashboardMe => 'Я';

  @override
  String get coupleFeedDashboardPartnerFallback => 'Партнёр';

  @override
  String coupleFeedDashboardDaysTogether(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString дня вместе',
      many: '$countString дней вместе',
      few: '$countString дня вместе',
      one: '$countString день вместе',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedDashboardDailyQuestion => 'Вопрос дня';

  @override
  String get coupleFeedDashboardAnswer => 'Ответить';

  @override
  String get coupleFeedDashboardAnswerHint => 'Ваш ответ…';

  @override
  String get coupleFeedDashboardSend => 'Отправить';

  @override
  String get coupleFeedDashboardAnswerSent =>
      'Ответ отправлен. Ваш партнёр получит уведомление.';

  @override
  String get coupleFeedDashboardActivities => 'Занятия для двоих';

  @override
  String get coupleFeedDashboardMilestones => 'Наши этапы';

  @override
  String get coupleFeedDashboardSeeAll => 'Смотреть все';

  @override
  String get coupleFeedDashboardEvents => 'События для пар';

  @override
  String get coupleFeedDashboardJewishCalendar => 'Еврейский календарь';

  @override
  String get coupleFeedStoriesTitle => 'Истории пар';

  @override
  String get coupleFeedDashboardSeeAllStories => 'Смотреть все';

  @override
  String get coupleFeedDashboardEventSampleTitle =>
      'Кулинарный мастер-класс по кошерной кухне';

  @override
  String get coupleFeedDashboardEventSampleWhen =>
      'Воскресенье, 20 января - 15:00';

  @override
  String get coupleFeedDashboardEventSampleTag => 'Пары';

  @override
  String get coupleFeedDashboardAllEvents => 'Все события';

  @override
  String get coupleFeedDashboardParasha => 'Шаббат Бешалах';

  @override
  String get coupleFeedDashboardShabbatTimes => 'Начало: 17:23 - Конец: 18:34';

  @override
  String get coupleFeedDashboardShabbatDinner => 'Ужин';

  @override
  String get coupleFeedDashboardShabbatPrayer => 'Молитва';

  @override
  String get coupleFeedDashboardShabbatRest => 'Отдых';

  @override
  String get coupleFeedStoryShareTitle => 'Поделитесь своей историей';

  @override
  String get coupleFeedDashboardShareStoryLine =>
      'Вдохновите сообщество MAZL своей историей';

  @override
  String get coupleFeedDashboardSeeStories => 'Смотреть истории';

  @override
  String get coupleFeedMilestoneFirstWeekTitle => 'Первая неделя';

  @override
  String get coupleFeedMilestoneFirstWeekLine => '7 дней вместе';

  @override
  String get coupleFeedMilestoneFirstMonthTitle => 'Первый месяц';

  @override
  String get coupleFeedMilestoneFirstMonthLine => '30 дней любви';

  @override
  String get coupleFeedMilestoneThreeMonthsTitle => 'Три месяца';

  @override
  String get coupleFeedMilestoneThreeMonthsLine => '3 месяца счастья';

  @override
  String get coupleFeedMilestoneSixMonthsTitle => 'Полгода';

  @override
  String get coupleFeedMilestoneSixMonthsLine => '6 месяцев рука об руку';

  @override
  String get coupleFeedMilestoneFirstYearTitle => 'Первый год';

  @override
  String get coupleFeedMilestoneFirstYearLine => '365 дней с MAZL';

  @override
  String get coupleFeedQuestion1 =>
      'Какой Ваш любимый момент недели, проведённой вместе?';

  @override
  String get coupleFeedQuestion1Category => 'Близость';

  @override
  String get coupleFeedQuestion2 =>
      'Если бы Вы могли поехать куда угодно, куда бы Вы отправились?';

  @override
  String get coupleFeedQuestion2Category => 'Мечты';

  @override
  String get coupleFeedQuestion3 => 'Что заставило Вас улыбнуться сегодня?';

  @override
  String get coupleFeedQuestion3Category => 'Повседневность';

  @override
  String get coupleFeedQuestion4 =>
      'Как бы Вы хотели отпраздновать ближайший Шаббат?';

  @override
  String get coupleFeedQuestion4Category => 'Иудаизм';

  @override
  String get coupleFeedQuestion4Option1 => 'Романтический ужин дома';

  @override
  String get coupleFeedQuestion4Option2 => 'Приглашение к друзьям';

  @override
  String get coupleFeedQuestion4Option3 => 'Кошерный ресторан';

  @override
  String get coupleFeedQuestion4Option4 => 'Общинный Шаббатон';

  @override
  String get coupleFeedQuestion5 =>
      'Какую черту характера Вы больше всего цените в партнёре?';

  @override
  String get coupleFeedQuestion5Category => 'Признательность';

  @override
  String get coupleFeedIdeaShabbatCookingTitle => 'Готовим к Шаббату';

  @override
  String get coupleFeedIdeaShabbatCookingCategory => 'Дом';

  @override
  String get coupleFeedIdeaTorahTitle => 'Изучение Торы';

  @override
  String get coupleFeedIdeaDateNightTitle => 'Свидание';

  @override
  String get coupleFeedIdeaDateNightCategory => 'Романтика';

  @override
  String get coupleFeedIdeaSportTitle => 'Спорт вместе';

  @override
  String get coupleFeedIdeaChesedTitle => 'Хесед вместе';

  @override
  String get coupleFeedIdeaChesedCategory => 'Община';

  @override
  String get coupleFeedIdeaTravelCategory => 'Приключения';

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
  String get coupleFeedFailureNetwork =>
      'Сервер недоступен. Попробуйте ещё раз.';

  @override
  String get coupleFeedFailureMalformed => 'Неожиданный ответ сервера.';

  @override
  String get coupleFeedFailureNotInCouple => 'Режим пары не включён.';

  @override
  String get coupleFeedFailureNotFound => 'Не найдено.';

  @override
  String get coupleFeedFailureFull => 'На это событие мест нет.';

  @override
  String get coupleFeedFailureServer =>
      'Сервер не смог ответить. Попробуйте ещё раз.';

  @override
  String get coupleFeedStoriesEmptyTitle => 'Историй пар пока нет';

  @override
  String get coupleFeedStoriesEmptyLine =>
      'Первые истории любви MAZL скоро появятся здесь.';

  @override
  String coupleFeedStoryShareText(String name1, String name2, String excerpt) {
    return '$name1 и $name2 познакомились в MAZL. Их история: $excerpt...';
  }

  @override
  String coupleFeedStoryStatusSince(String status, String date) {
    return '$status · с $date';
  }

  @override
  String get coupleFeedStatusDating => 'В отношениях';

  @override
  String get coupleFeedStatusEngaged => 'Помолвлены';

  @override
  String get coupleFeedStatusMarried => 'В браке';

  @override
  String get coupleFeedStoryShareLine =>
      'Вдохновите сообщество MAZL, поделившись своей историей.';

  @override
  String get coupleFeedStoryStatusLabel => 'Ваш статус';

  @override
  String get coupleFeedStoryTextLabel => 'Ваша история (мин. 100 символов)';

  @override
  String get coupleFeedStoryTextHint =>
      'Как Вы познакомились? Что Вам понравилось в другом человеке?…';

  @override
  String get coupleFeedStoryPhotosLabel => 'Фото (необязательно)';

  @override
  String get coupleFeedStoryPhotosHint => 'Добавьте фото пары';

  @override
  String get coupleFeedStorySubmit => 'Отправить нашу историю';

  @override
  String get coupleFeedStoryTooShort =>
      'История должна содержать не менее 100 символов';

  @override
  String get coupleFeedStoryThanks =>
      'Спасибо. Ваша история будет опубликована после проверки.';

  @override
  String get eventsTitle => 'Мероприятия';

  @override
  String get eventsCalendarTooltip => 'Календарь';

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
  String get settingsShabbatAutoPause => 'Автопауза';

  @override
  String get settingsHolidayAlerts => 'Уведомления о праздниках';

  @override
  String get settingsHolidayAlertsHint => 'Напоминания перед праздниками';

  @override
  String get settingsSectionNotifications => 'Уведомления';

  @override
  String get settingsNotifMatches => 'Новые совпадения';

  @override
  String get settingsNotifMessages => 'Сообщения';

  @override
  String get settingsNotifSuperLikes => 'Суперлайки';

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
  String get settingsShabbatCity => 'По Парижу, Франция';

  @override
  String get settingsShabbatSettingsHeader => 'Настройки';

  @override
  String get settingsShabbatEnable => 'Включить режим Шаббата';

  @override
  String get settingsShabbatEnableHint =>
      'Уведомления автоматически приостанавливаются на время Шаббата';

  @override
  String get settingsShabbatIncludeHolidays => 'Включать праздники';

  @override
  String get settingsShabbatIncludeHolidaysHint => 'Пауза также в Йом-Тов';

  @override
  String get settingsShabbatBuffer => 'Запас времени до зажигания свечей';

  @override
  String settingsMinutesShort(int minutes) {
    return '$minutes мин';
  }

  @override
  String settingsMinutesSpoken(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минуты',
      many: '$minutes минут',
      few: '$minutes минуты',
      one: '$minutes минута',
    );
    return '$_temp0';
  }

  @override
  String get settingsShabbatEdit => 'Изменить';

  @override
  String get settingsShabbatExplanation =>
      'Уведомления приостановлены, а сообщения ждут. Вы получите всё после окончания Шаббата, а Ваш статус будет показывать «Режим Шаббата».';

  @override
  String get settingsShabbatHeroTitle => 'Шаббат\nшалом.';

  @override
  String get settingsShabbatHeroSubtitle =>
      'Mazl отдыхает вместе с Вами. Сообщения дождутся Авдалы.';

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
}
