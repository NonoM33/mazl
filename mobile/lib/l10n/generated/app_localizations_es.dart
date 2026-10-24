// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonBack => 'Atrás';

  @override
  String get errorTimeout => 'Se agotó el tiempo. Revisa tu conexión.';

  @override
  String get errorNetwork =>
      'Sin conexión. Revisa tu red e inténtalo de nuevo.';

  @override
  String get errorServer =>
      'El servidor no está disponible. Inténtalo de nuevo en un momento.';

  @override
  String get errorSessionExpired =>
      'La sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get errorForbidden => 'No tienes permiso para hacer esto.';

  @override
  String get errorNotFound => 'No encontrado: este elemento ya no existe.';

  @override
  String get errorConflict => 'Esta acción ya no es posible.';

  @override
  String get errorTooLarge => 'El archivo es demasiado grande.';

  @override
  String get errorRateLimited => 'Demasiados intentos. Espera un momento.';

  @override
  String get errorInvalid =>
      'Solicitud rechazada. Revisa los datos introducidos.';

  @override
  String get errorUnknown => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonRemove => 'Quitar';

  @override
  String get commonSkip => 'Omitir';

  @override
  String get commonSee => 'Ver';

  @override
  String get commonShare => 'Compartir';

  @override
  String get commonReport => 'Denunciar';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonLater => 'Más tarde';

  @override
  String get commonToday => 'Hoy';

  @override
  String get commonYesterday => 'Ayer';

  @override
  String get commonNotSpecified => 'Sin especificar';

  @override
  String get commonLoadError => 'Error al cargar';

  @override
  String get safetyBlock => 'Bloquear';

  @override
  String get safetyBlockSubtitle =>
      'Esta persona ya no podrá verte ni contactarte';

  @override
  String get safetyReportSubtitle =>
      'Informar de un comportamiento inapropiado';

  @override
  String get safetyBlockConfirmTitle => '¿Bloquear a esta persona?';

  @override
  String safetyBlockConfirmIntro(String name) {
    return 'Si bloqueas a $name:';
  }

  @override
  String get safetyBlockEffectHidden =>
      'Esta persona ya no podrá ver tu perfil';

  @override
  String get safetyBlockEffectNotSeen => 'Ya no verás su perfil';

  @override
  String get safetyBlockEffectChats => 'Tus conversaciones se eliminarán';

  @override
  String get safetyBlockEffectNotNotified =>
      'Esta persona no recibirá ninguna notificación';

  @override
  String safetyBlocked(String name) {
    return '$name ha sido bloqueado';
  }

  @override
  String get safetyBlockFailed => 'Error al bloquear';

  @override
  String get safetyReportTitle => 'Informar de un problema';

  @override
  String safetyReportWhy(String name) {
    return '¿Por qué informas sobre $name?';
  }

  @override
  String get safetyReportDetailsHint => 'Más detalles (opcional)';

  @override
  String get safetyReportAlsoBlock => 'Bloquear también a esta persona';

  @override
  String get safetyReportAlsoBlockHint => 'Ya no verás este perfil';

  @override
  String get safetyReportSend => 'Enviar informe';

  @override
  String get safetyReportThanks =>
      'Gracias por tu informe. Nuestro equipo lo revisará.';

  @override
  String get safetyReportFailed => 'Error al enviar el informe';

  @override
  String get safetyCategoryFakeProfile => 'Perfil falso';

  @override
  String get safetyCategoryFakeProfileHint => 'Fotos robadas, identidad falsa';

  @override
  String get safetyCategoryInappropriatePhotos => 'Fotos inapropiadas';

  @override
  String get safetyCategoryInappropriatePhotosHint =>
      'Contenido sexual, violento o impactante';

  @override
  String get safetyCategoryHarassment => 'Acoso';

  @override
  String get safetyCategoryHarassmentHint =>
      'Mensajes insistentes, amenazas, insultos';

  @override
  String get safetyCategorySpam => 'Spam / Estafa';

  @override
  String get safetyCategorySpamHint =>
      'Publicidad, peticiones de dinero, enlaces sospechosos';

  @override
  String get safetyCategoryUnderage => 'Menor de edad';

  @override
  String get safetyCategoryUnderageHint => 'Parece que tiene menos de 18 años';

  @override
  String get safetyCategoryOfflineBehavior => 'Comportamiento fuera de la app';

  @override
  String get safetyCategoryOfflineBehaviorHint =>
      'Comportamiento inapropiado durante una cita';

  @override
  String get safetyCategoryOther => 'Otro';

  @override
  String get safetyCategoryOtherHint => 'Otra razón (explícanos cuál)';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma del teléfono';
}
