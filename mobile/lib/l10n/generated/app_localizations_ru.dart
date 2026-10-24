// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

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
  String get likesMessageAction => 'Сообщение';

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
  String get matchingDiscoverUndo => 'Отменить';

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
  String get shadchanTitle => 'Шадхан с ИИ';

  @override
  String get shadchanHeaderTitle => 'Ваш личный шадхан';

  @override
  String get shadchanHeaderBody =>
      'Наш ИИ изучает Ваши предпочтения и предлагает очень подходящие профили';

  @override
  String get shadchanTodayTitle => 'Предложения на сегодня';

  @override
  String shadchanNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count новой',
      many: '$count новых',
      few: '$count новые',
      one: '$count новая',
    );
    return '$_temp0';
  }

  @override
  String get shadchanEmptyTitle => 'Вы просмотрели все предложения.';

  @override
  String get shadchanEmptyBody =>
      'Возвращайтесь завтра за новыми предложениями от Вашего шадхана.';

  @override
  String get shadchanEmptyAction => 'Смотреть другие профили';

  @override
  String shadchanPassed(String name) {
    return 'Вы пропустили $name';
  }

  @override
  String shadchanLiked(String name) {
    return 'Вы добавили $name в лайки';
  }

  @override
  String get shadchanHowTitle => 'Как это работает?';

  @override
  String get shadchanHowStepAnalyze =>
      'Наш ИИ изучает Ваш профиль и предпочтения';

  @override
  String get shadchanHowStepCompare =>
      'Он сравнивает их с подходящими профилями';

  @override
  String get shadchanHowStepDaily =>
      'Каждый день Вы получаете персональные предложения';

  @override
  String get shadchanWhy => 'Почему это предложение?';

  @override
  String get shadchanMatchBadge => 'Мэтч';

  @override
  String get shadchanReasonSamePractice => 'Одинаковый уровень соблюдения';

  @override
  String get shadchanReasonInterests =>
      'Общие интересы: путешествия, кулинария';

  @override
  String get shadchanReasonGoals => 'Похожие цели';

  @override
  String get shadchanReasonFamily => 'Совпадающие семейные ценности';

  @override
  String get shadchanReasonMusic => 'Общая страсть к музыке';

  @override
  String get shadchanReasonLocation => 'Подходящие места проживания';

  @override
  String get shadchanReasonReligion => 'Схожая религиозная практика';

  @override
  String get shadchanReasonProfession => 'Близкие сферы работы';

  @override
  String get shadchanReasonCouple => 'Одинаковый взгляд на отношения';

  @override
  String get visitorsTitle => 'Кто посещал мой профиль';

  @override
  String visitorsTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count визита',
      many: '$count визитов',
      few: '$count визита',
      one: '$count визит',
    );
    return '$_temp0';
  }

  @override
  String visitorsThisWeek(int count) {
    return '$count за эту неделю';
  }

  @override
  String get visitorsBannerTitle => 'Узнайте, кто Вас посетил';

  @override
  String get visitorsBannerBody => 'Перейдите на mazl+, чтобы видеть профили';

  @override
  String get visitorsEmptyTitle => 'Пока нет посетителей';

  @override
  String get visitorsEmptyBody =>
      'Заполните профиль и используйте буст, чтобы привлечь больше посетителей.';

  @override
  String get visitorsEmptyAction => 'Включить буст';

  @override
  String get visitorsLockedTitle => 'Только в mazl+';

  @override
  String get visitorsLockedBody =>
      'Перейдите на mazl+, чтобы узнать, кто посещал Ваш профиль, и написать им напрямую.';

  @override
  String get visitorsLockedAction => 'Узнать о mazl+';

  @override
  String get visitorsNew => 'НОВОЕ';

  @override
  String visitorsAgoMinutes(int count) {
    return '$count мин назад';
  }

  @override
  String visitorsAgoHours(int count) {
    return '$count ч назад';
  }

  @override
  String visitorsAgoDays(int count) {
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
  String visitorsAgoWeeks(int count) {
    return '$count нед. назад';
  }
}
