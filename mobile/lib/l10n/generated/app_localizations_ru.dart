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
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Язык телефона';
}
