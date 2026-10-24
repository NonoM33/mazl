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
