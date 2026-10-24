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
  String get errorNetwork => 'Нет подключения. Проверьте сеть и повторите попытку.';

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
  String get profileMatchBodyUnnamed => 'Теперь Вы можете общаться с этим человеком.';

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
  String get profileCoupleElsewhereBody => 'Вы уже в режиме пары с другим человеком.';

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
  String get profileCoupleAvailableBody => 'У вас мэтч. Включите режим пары, чтобы делиться занятиями вместе.';

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
  String get profileCompatibilityUnavailable => 'Совместимость пока недоступна.';

  @override
  String profileCompatibilityUnlockTitle(String name) {
    return 'Узнайте, насколько Вы совместимы с $name.';
  }

  @override
  String get profileCompatibilityUnlockBody => 'Рассчитывается по Вашей практике, намерениям и ценностям.';

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
  String get profileCompatibilityIncomplete => 'Заполните профили, чтобы увидеть больше подробностей';

  @override
  String get profileCompatibilityNote => 'Оценка основана на предпочтениях и общих чертах';

  @override
  String get profileCompatibilityGotIt => 'Понятно';

  @override
  String get profilePromptsMine => 'Мои вопросы';

  @override
  String get profilePromptsSubtitle => 'Ответьте на вопросы, чтобы показать свою индивидуальность';

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
  String get profilePromptFamilyTradition => 'Семейная традиция, которую я обожаю...';

  @override
  String get profilePromptFavoriteHoliday => 'Мой любимый еврейский праздник...';

  @override
  String get profilePromptFridayNight => 'Пятничный вечер у меня дома...';

  @override
  String get profilePromptIsraelMemory => 'Моё лучшее воспоминание об Израиле...';

  @override
  String get profilePromptJewishValue => 'Еврейская ценность, которая направляет меня...';

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
  String get profileIntentionMarriageDescription => 'Ищу будущего мужа или жену';

  @override
  String get profileIntentionSeriousDescription => 'Ищу долгие отношения';

  @override
  String get profileIntentionOpenDescription => 'Посмотрим, к чему это приведёт';

  @override
  String get profileIntentionFriendsFirstDescription => 'Давайте сначала познакомимся поближе';

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
  String get profilePhotosHint => 'Нажмите и удерживайте, чтобы сделать главной';

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
  String get profileSetupAboutYouSubtitle => 'Эта информация будет видна в Вашем профиле';

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
  String get profileSetupPhotosSubtitle => 'Добавьте не менее 2 фото, чтобы продолжить';

  @override
  String get profileSetupPhotosTip => 'Профили с качественными фото получают в 3 раза больше мэтчей.';

  @override
  String get profileSetupPracticeTitle => 'Ваша практика';

  @override
  String get profileSetupPracticeSubtitle => 'Помогите нам найти того, кто Вам подходит';

  @override
  String get profileSetupLookingTitle => 'Что Вы ищете';

  @override
  String get profileSetupLookingSubtitle => 'Помогите нам показывать Вам подходящие профили';

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
  String get profileShadchanNote => 'Наш AI Shadchan будет использовать эти предпочтения, чтобы предлагать Вам подходящие профили.';

  @override
  String get profileReportThisProfile => 'Пожаловаться на профиль';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Язык телефона';
}
