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
}
