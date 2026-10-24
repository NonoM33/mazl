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
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Язык телефона';

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
}
