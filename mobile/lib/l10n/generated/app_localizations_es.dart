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
  String get settingsShabbatMode => 'Modo Shabat';

  @override
  String get settingsShabbatAutoPause => 'Pausa automática';

  @override
  String get settingsBlockedUsers => 'Usuarios bloqueados';

  @override
  String get settingsBlockedUsersHint => 'Gestionar las personas bloqueadas';

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
