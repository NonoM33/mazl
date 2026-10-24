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
  String get coupleSpaceAnniversaryTag => 'С годовщиной на MAZL';

  @override
  String coupleSpaceAnniversaryDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'дня вместе',
      many: 'дней вместе',
      few: 'дня вместе',
      one: 'день вместе',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceAnniversaryWith(String name) {
    return 'с $name';
  }

  @override
  String coupleSpaceAnniversaryNext(String milestone, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return 'Далее: $milestone через $_temp0';
  }

  @override
  String get coupleSpaceAnniversaryHappy => 'С годовщиной!';

  @override
  String coupleSpaceAnniversaryDaysWith(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0 с $name';
  }

  @override
  String get coupleSpaceAnniversaryThanks => 'Спасибо';

  @override
  String coupleSpaceAnniversaryShare(int count, String milestone) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return 'Мы празднуем $_temp0 вместе на MAZL. $milestone';
  }

  @override
  String get coupleSpaceMilestonesTitle => 'Ваши вехи';

  @override
  String coupleSpaceMilestoneIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return 'через $_temp0';
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
  String get profileMatchLabel => 'Мэтч';

  @override
  String get profileMatchTitle => 'Это мэтч.';

  @override
  String profileMatchBody(String name) {
    return 'Теперь Вы можете общаться с $name.';
  }

  @override
  String get profileMatchBodyUnnamed =>
      'Теперь Вы можете общаться с этим человеком.';

  @override
  String get profileSendMessage => 'Написать сообщение';

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
  String get profileShadchanNote =>
      'Наш AI Shadchan будет использовать эти предпочтения, чтобы предлагать Вам подходящие профили.';

  @override
  String get profileReportThisProfile => 'Пожаловаться на профиль';

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
