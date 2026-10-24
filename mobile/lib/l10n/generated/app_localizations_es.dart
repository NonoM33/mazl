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
  String get eventsTitle => 'Eventos';

  @override
  String get eventsCalendarTooltip => 'Calendario';

  @override
  String get eventsFilterAll => 'Todos';

  @override
  String get eventsFilterHolidays => 'Fiestas';

  @override
  String get eventsTypeShabbat => 'Shabat';

  @override
  String get eventsTypeShabbatDinner => 'Cena de Shabat';

  @override
  String get eventsTypeSpeedDating => 'Speed dating';

  @override
  String get eventsTypeHoliday => 'Fiesta';

  @override
  String get eventsTypeLecture => 'Clase';

  @override
  String get eventsTypeSocial => 'Social';

  @override
  String get eventsTypeOther => 'Evento';

  @override
  String get eventsLoading => 'Cargando...';

  @override
  String get eventsLoadError => 'No se pudieron cargar los eventos';

  @override
  String get eventsEmptyTitle => 'Ningún evento';

  @override
  String get eventsEmptyHint => 'Vuelve pronto para descubrir\nnuevos eventos.';

  @override
  String get eventsTomorrow => 'Mañana';

  @override
  String eventsInDays(int days) {
    return 'En $days d';
  }

  @override
  String eventsDateAtTime(String date, String time) {
    return '$date a las $time';
  }

  @override
  String get eventsFree => 'Gratis';

  @override
  String eventsAttendeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participantes',
      one: '1 participante',
    );
    return '$_temp0';
  }

  @override
  String get eventsAlmostFull => 'Casi lleno';

  @override
  String get eventsFull => 'Completo';

  @override
  String get eventsNotFound => 'Evento no encontrado';

  @override
  String get eventsInfoDate => 'Fecha';

  @override
  String get eventsInfoTime => 'Hora';

  @override
  String get eventsInfoPlace => 'Lugar';

  @override
  String get eventsInfoParticipants => 'Participantes';

  @override
  String get eventsInfoPrice => 'Precio';

  @override
  String get eventsDescription => 'Descripción';

  @override
  String eventsCapacity(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: '$count / $max plazas',
      one: '$count / $max plaza',
    );
    return '$_temp0';
  }

  @override
  String eventsRegisteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inscritos',
      one: '1 inscrito',
    );
    return '$_temp0';
  }

  @override
  String eventsPricePerPerson(String price) {
    return '$price por persona';
  }

  @override
  String get eventsRsvpConfirmedBanner =>
      'Tu inscripción a este evento está confirmada';

  @override
  String get eventsRsvpCancel => 'Cancelar mi inscripción';

  @override
  String eventsRsvpJoinPaid(String price) {
    return 'Inscribirme - $price';
  }

  @override
  String get eventsRsvpJoinFree => 'Inscribirme gratis';

  @override
  String get eventsRsvpCancelled => 'Inscripción cancelada';

  @override
  String get eventsRsvpDone => 'Inscripción confirmada';

  @override
  String eventsShareMessage(String title) {
    return 'Únete a mí en \"$title\" en MAZL';
  }

  @override
  String get navigationDiscover => 'Descubrir';

  @override
  String get navigationMatches => 'Matches';

  @override
  String get navigationMessages => 'Mensajes';

  @override
  String get navigationEvents => 'Eventos';

  @override
  String get navigationProfile => 'Perfil';

  @override
  String get navigationShowTabs => 'Mostrar pestañas';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma del teléfono';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionAccount => 'Cuenta';

  @override
  String get settingsEditProfile => 'Editar perfil';

  @override
  String get settingsEmail => 'Correo electrónico';

  @override
  String get settingsNotSignedIn => 'Sin sesión iniciada';

  @override
  String get settingsDefaultUserName => 'Usuario';

  @override
  String get settingsSectionDiscovery => 'Descubrir';

  @override
  String get settingsLocation => 'Ubicación';

  @override
  String get settingsLocationNotSet => 'Sin definir';

  @override
  String get settingsMaxDistance => 'Distancia máxima';

  @override
  String settingsDistanceKm(int distance) {
    final intl.NumberFormat distanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String distanceString = distanceNumberFormat.format(distance);

    return '$distanceString km';
  }

  @override
  String get settingsAgeRange => 'Rango de edad';

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

    return '$minString - $maxString años';
  }

  @override
  String get settingsSectionJewish => 'Ajustes judíos';

  @override
  String get settingsShabbatMode => 'Modo Shabat';

  @override
  String get settingsShabbatAutoPause => 'Pausa automática';

  @override
  String get settingsHolidayAlerts => 'Alertas de fiestas';

  @override
  String get settingsHolidayAlertsHint => 'Avisos antes de las fiestas';

  @override
  String get settingsSectionNotifications => 'Notificaciones';

  @override
  String get settingsNotifMatches => 'Nuevos matches';

  @override
  String get settingsNotifMessages => 'Mensajes';

  @override
  String get settingsNotifSuperLikes => 'Super Likes';

  @override
  String get settingsSectionCouple => 'Modo Pareja';

  @override
  String get settingsSectionSubscription => 'Suscripción';

  @override
  String get settingsRestorePurchases => 'Restaurar compras';

  @override
  String get settingsRestoreSuccess => 'Compras restauradas correctamente.';

  @override
  String get settingsRestoreError =>
      'No se pudieron restaurar las compras. Inténtalo de nuevo.';

  @override
  String settingsSubscriptionRenewsOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'se renueva el $dateString';
  }

  @override
  String settingsSubscriptionEndsOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'hasta el $dateString';
  }

  @override
  String get settingsSectionPrivacy => 'Privacidad y seguridad';

  @override
  String get settingsBlockedUsers => 'Usuarios bloqueados';

  @override
  String get settingsBlockedUsersHint => 'Gestionar las personas bloqueadas';

  @override
  String get settingsProfileVerification => 'Verificación del perfil';

  @override
  String get settingsVerified => 'Verificado';

  @override
  String get settingsNotVerified => 'Sin verificar';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsHelp => 'Ayuda y soporte';

  @override
  String get settingsTerms => 'Condiciones de uso';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsLogOut => 'Cerrar sesión';

  @override
  String get settingsLogOutMessage => '¿Seguro que quieres cerrar sesión?';

  @override
  String get settingsDeleteAccount => 'Eliminar mi cuenta';

  @override
  String get settingsDeleteReasonPrompt => '¿Por qué quieres dejarnos?';

  @override
  String get settingsDeleteReasonFoundSomeone => 'He encontrado a alguien';

  @override
  String get settingsDeleteReasonNoLongerUsing => 'Ya no uso la aplicación';

  @override
  String get settingsDeleteReasonBreak => 'Quiero tomarme un descanso';

  @override
  String get settingsDeleteReasonTechnical => 'Problemas técnicos';

  @override
  String get settingsDeleteReasonService => 'El servicio no es lo que busco';

  @override
  String get settingsDeleteReasonOther => 'Otro motivo';

  @override
  String get settingsDeleteFinalTitle => 'Confirmación final';

  @override
  String get settingsDeleteIrreversible => 'Esta acción es irreversible.';

  @override
  String get settingsDeleteDataList =>
      'Se eliminarán todos tus datos:\n• Tu perfil y tus fotos\n• Tus matches y conversaciones\n• Tu historial de likes\n• Tus ajustes';

  @override
  String get settingsDeleteKeep => 'Conservar mi cuenta';

  @override
  String get settingsDeleteError => 'No se pudo eliminar la cuenta';

  @override
  String get settingsCitySearchHint => 'Buscar una ciudad...';

  @override
  String get settingsCitySearchHelp =>
      'Escribe el nombre de tu ciudad y elige una sugerencia';

  @override
  String get settingsSaved => 'Ajustes guardados';

  @override
  String get settingsCoupleLeave => 'Salir del modo pareja';

  @override
  String get settingsCoupleLeaveMessage =>
      'Podrás volver a activarlo más tarde si quieres.';

  @override
  String get settingsCoupleLeaveConfirm => 'Salir';

  @override
  String get settingsCoupleLeft => 'Has salido del modo pareja';

  @override
  String get settingsCoupleLeaveError =>
      'No se pudo salir del modo pareja. Inténtalo de nuevo.';

  @override
  String get settingsCoupleCancelRequestError =>
      'No se pudo cancelar la solicitud. Inténtalo de nuevo.';

  @override
  String get settingsCoupleActive => 'Modo pareja activo';

  @override
  String settingsCoupleWithPartner(String name) {
    return 'Con $name';
  }

  @override
  String get settingsCoupleWithYourPartner => 'Con tu pareja';

  @override
  String get settingsCoupleOpenSpace => 'Espacio de pareja';

  @override
  String get settingsCoupleOpenCalendar => 'Calendario';

  @override
  String get settingsCoupleSinceToday => 'Desde hoy';

  @override
  String settingsCoupleDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get settingsCoupleRequestSent => 'Solicitud enviada';

  @override
  String settingsCoupleRequestSentTo(String name) {
    return 'Solicitud enviada a $name';
  }

  @override
  String get settingsCoupleWaiting => 'Esperando su respuesta';

  @override
  String get settingsCoupleCancelRequest => 'Cancelar solicitud';

  @override
  String get settingsCoupleInvitation => '¿Has encontrado el amor?';

  @override
  String get settingsCoupleActivate => 'Activar';

  @override
  String get settingsShabbatCity => 'Basado en París, Francia';

  @override
  String get settingsShabbatSettingsHeader => 'Ajustes';

  @override
  String get settingsShabbatEnable => 'Activar el modo Shabat';

  @override
  String get settingsShabbatEnableHint =>
      'Las notificaciones se pausan automáticamente durante Shabat';

  @override
  String get settingsShabbatIncludeHolidays => 'Incluir las fiestas';

  @override
  String get settingsShabbatIncludeHolidaysHint =>
      'Pausa también durante Yom Tov';

  @override
  String get settingsShabbatBuffer => 'Margen antes de encender las velas';

  @override
  String settingsMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String settingsMinutesSpoken(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get settingsShabbatEdit => 'Editar';

  @override
  String get settingsShabbatExplanation =>
      'Las notificaciones se pausan y los mensajes esperan. Lo recibirás todo al terminar Shabat, y tu estado mostrará «Modo Shabat».';

  @override
  String get settingsShabbatHeroTitle => 'Shabat\nshalom.';

  @override
  String get settingsShabbatHeroSubtitle =>
      'Mazl descansa contigo. Tus mensajes te esperarán hasta la Havdalá.';

  @override
  String get settingsShabbatCandleLighting => 'Encendido de velas';

  @override
  String get settingsShabbatHavdalah => 'Havdalá';

  @override
  String get settingsBlockedUserFallbackName => 'Usuario';

  @override
  String get settingsBlockedUnblockTitle => '¿Desbloquear a este usuario?';

  @override
  String settingsBlockedUnblockMessage(String name) {
    return '¿Quieres desbloquear a $name?\n\nEsta persona podrá volver a ver tu perfil y contactarte.';
  }

  @override
  String get settingsBlockedUnblockMessageUnnamed =>
      '¿Quieres desbloquear a este usuario?\n\nEsta persona podrá volver a ver tu perfil y contactarte.';

  @override
  String get settingsBlockedUnblock => 'Desbloquear';

  @override
  String settingsBlockedUnblocked(String name) {
    return 'Se ha desbloqueado a $name';
  }

  @override
  String get settingsBlockedUnblockedUnnamed => 'Se ha desbloqueado al usuario';

  @override
  String get settingsBlockedUnblockError => 'No se pudo desbloquear';

  @override
  String get settingsBlockedEmptyTitle => 'Ningún usuario bloqueado';

  @override
  String get settingsBlockedEmptyHint =>
      'Las personas que bloquees\naparecerán aquí';

  @override
  String settingsBlockedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Bloqueado el $dateString';
  }
}
