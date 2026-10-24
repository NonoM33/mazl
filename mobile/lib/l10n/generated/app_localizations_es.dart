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
  String get coupleFeedDashboardSettingsTooltip => 'Ajustes';

  @override
  String get coupleFeedDashboardMe => 'Yo';

  @override
  String get coupleFeedDashboardPartnerFallback => 'Pareja';

  @override
  String coupleFeedDashboardDaysTogether(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString días juntos',
      one: '1 día juntos',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedDashboardDailyQuestion => 'Pregunta del día';

  @override
  String get coupleFeedDashboardAnswer => 'Responder';

  @override
  String get coupleFeedDashboardAnswerHint => 'Tu respuesta…';

  @override
  String get coupleFeedDashboardSend => 'Enviar';

  @override
  String get coupleFeedDashboardAnswerSent =>
      'Respuesta enviada. Tu pareja recibirá una notificación.';

  @override
  String get coupleFeedDashboardActivities => 'Actividades en pareja';

  @override
  String get coupleFeedDashboardMilestones => 'Nuestros hitos';

  @override
  String get coupleFeedDashboardSeeAll => 'Ver todo';

  @override
  String get coupleFeedDashboardEvents => 'Eventos para parejas';

  @override
  String get coupleFeedDashboardJewishCalendar => 'Calendario judío';

  @override
  String get coupleFeedStoriesTitle => 'Historias de parejas';

  @override
  String get coupleFeedDashboardSeeAllStories => 'Ver todas';

  @override
  String get coupleFeedDashboardEventSampleTitle => 'Clase de cocina kosher';

  @override
  String get coupleFeedDashboardEventSampleWhen =>
      'Domingo 20 de enero - 15:00';

  @override
  String get coupleFeedDashboardEventSampleTag => 'Parejas';

  @override
  String get coupleFeedDashboardAllEvents => 'Ver todos los eventos';

  @override
  String get coupleFeedDashboardParasha => 'Shabat Beshalaj';

  @override
  String get coupleFeedDashboardShabbatTimes =>
      'Entrada: 17:23 - Salida: 18:34';

  @override
  String get coupleFeedDashboardShabbatDinner => 'Cena';

  @override
  String get coupleFeedDashboardShabbatPrayer => 'Oración';

  @override
  String get coupleFeedDashboardShabbatRest => 'Descanso';

  @override
  String get coupleFeedStoryShareTitle => 'Comparte tu historia';

  @override
  String get coupleFeedDashboardShareStoryLine =>
      'Inspira a la comunidad MAZL con tu historia';

  @override
  String get coupleFeedDashboardSeeStories => 'Ver historias';

  @override
  String get coupleFeedMilestoneFirstWeekTitle => 'Primera semana';

  @override
  String get coupleFeedMilestoneFirstWeekLine => '7 días juntos';

  @override
  String get coupleFeedMilestoneFirstMonthTitle => 'Primer mes';

  @override
  String get coupleFeedMilestoneFirstMonthLine => '30 días de amor';

  @override
  String get coupleFeedMilestoneThreeMonthsTitle => 'Un trimestre';

  @override
  String get coupleFeedMilestoneThreeMonthsLine => '3 meses de felicidad';

  @override
  String get coupleFeedMilestoneSixMonthsTitle => 'Medio año';

  @override
  String get coupleFeedMilestoneSixMonthsLine => '6 meses de la mano';

  @override
  String get coupleFeedMilestoneFirstYearTitle => 'Primer año';

  @override
  String get coupleFeedMilestoneFirstYearLine => '365 días de MAZL';

  @override
  String get coupleFeedQuestion1 =>
      '¿Cuál es tu momento favorito de la semana juntos?';

  @override
  String get coupleFeedQuestion1Category => 'Conexión';

  @override
  String get coupleFeedQuestion2 =>
      'Si pudieras viajar a cualquier lugar, ¿adónde irías?';

  @override
  String get coupleFeedQuestion2Category => 'Sueños';

  @override
  String get coupleFeedQuestion3 => '¿Qué te hizo sonreír hoy?';

  @override
  String get coupleFeedQuestion3Category => 'Día a día';

  @override
  String get coupleFeedQuestion4 =>
      '¿Cómo te gustaría celebrar tu próximo Shabat?';

  @override
  String get coupleFeedQuestion4Category => 'Judaísmo';

  @override
  String get coupleFeedQuestion4Option1 => 'Cena romántica en casa';

  @override
  String get coupleFeedQuestion4Option2 => 'Invitación en casa de amigos';

  @override
  String get coupleFeedQuestion4Option3 => 'Restaurante kosher';

  @override
  String get coupleFeedQuestion4Option4 => 'Shabatón comunitario';

  @override
  String get coupleFeedQuestion5 =>
      '¿Qué rasgo de carácter admiras más de tu pareja?';

  @override
  String get coupleFeedQuestion5Category => 'Aprecio';

  @override
  String get coupleFeedIdeaShabbatCookingTitle => 'Cocinar para Shabat';

  @override
  String get coupleFeedIdeaShabbatCookingCategory => 'Hogar';

  @override
  String get coupleFeedIdeaTorahTitle => 'Estudio de la Torá';

  @override
  String get coupleFeedIdeaDateNightTitle => 'Cita nocturna';

  @override
  String get coupleFeedIdeaDateNightCategory => 'Romance';

  @override
  String get coupleFeedIdeaSportTitle => 'Deporte juntos';

  @override
  String get coupleFeedIdeaChesedTitle => 'Jésed juntos';

  @override
  String get coupleFeedIdeaChesedCategory => 'Comunidad';

  @override
  String get coupleFeedIdeaTravelCategory => 'Aventura';

  @override
  String get coupleFeedCategoryWellness => 'Bienestar';

  @override
  String get coupleFeedCategoryGastronomy => 'Gastronomía';

  @override
  String get coupleFeedFilterGastronomy => 'Gastro';

  @override
  String get coupleFeedCategoryCulture => 'Cultura';

  @override
  String get coupleFeedCategorySport => 'Deporte';

  @override
  String get coupleFeedCategoryTravel => 'Viajes';

  @override
  String get coupleFeedCategorySpiritual => 'Espiritual';

  @override
  String get coupleFeedCategoryDiy => 'Hazlo tú mismo';

  @override
  String get coupleFeedCategoryRomantic => 'Romántico';

  @override
  String get coupleFeedFilterAll => 'Todo';

  @override
  String get coupleFeedEventCategoryDinner => 'Cena';

  @override
  String get coupleFeedEventCategoryTasting => 'Degustación';

  @override
  String get coupleFeedEventCategoryParty => 'Fiesta';

  @override
  String get coupleFeedEventCategoryWorkshop => 'Taller';

  @override
  String get coupleFeedEventCategoryBrunch => 'Brunch';

  @override
  String get coupleFeedEventCategorySpiritual => 'Espiritual';

  @override
  String get coupleFeedEventCategoryTravel => 'Fin de semana';

  @override
  String get coupleFeedEventCategoryConcert => 'Concierto';

  @override
  String get coupleFeedEventCategoryGame => 'Juegos';

  @override
  String get coupleFeedEventCategoryOther => 'Evento';

  @override
  String get coupleFeedPriceFree => 'Gratis';

  @override
  String coupleFeedEventPricePerCouple(String price) {
    return '$price por pareja';
  }

  @override
  String coupleFeedDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String coupleFeedDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String coupleFeedDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String coupleFeedRatingWithReviews(String rating, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$rating ($countString opiniones)',
      one: '$rating (1 opinión)',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedKosher => 'Kosher';

  @override
  String get coupleFeedFeatured => 'Destacado';

  @override
  String get coupleFeedPartnerMazl => 'Socio MAZL';

  @override
  String coupleFeedPartnerDiscountMazl(int percent) {
    return '$percent % dto. · Socio MAZL';
  }

  @override
  String coupleFeedPartnerDiscount(int percent) {
    return '$percent % dto. · Socio';
  }

  @override
  String get coupleFeedActivitiesTitle => 'Actividades';

  @override
  String get coupleFeedSavedTitle => 'Actividades guardadas';

  @override
  String get coupleFeedActivitiesEmptyTitle => 'No hay actividades por ahora';

  @override
  String get coupleFeedActivitiesEmptyLine => 'Pronto llegarán nuevas ideas.';

  @override
  String get coupleFeedRefresh => 'Actualizar';

  @override
  String get coupleFeedSeeDetail => 'Ver detalles';

  @override
  String coupleFeedActivitySavedSnack(String title) {
    return '$title guardado';
  }

  @override
  String coupleFeedActivitySaveCardError(String title) {
    return 'No se pudo guardar «$title». Inténtalo de nuevo.';
  }

  @override
  String coupleFeedActivityPassCardError(String title) {
    return 'No se pudo omitir «$title». Inténtalo de nuevo.';
  }

  @override
  String get coupleFeedActivityNotFoundTitle => 'Actividad no encontrada';

  @override
  String get coupleFeedActivityNotFoundLine => 'Ya no se ofrece.';

  @override
  String get coupleFeedActivityRemoveError =>
      'No se pudo quitar esta actividad. Inténtalo de nuevo.';

  @override
  String get coupleFeedActivitySaveError =>
      'No se pudo guardar esta actividad. Inténtalo de nuevo.';

  @override
  String get coupleFeedActivitySavedConfirm => 'Actividad guardada';

  @override
  String coupleFeedCodeCopied(String code) {
    return 'Código $code copiado';
  }

  @override
  String get coupleFeedRemoveFromSaved => 'Quitar de actividades guardadas';

  @override
  String coupleFeedActivityShareText(String title) {
    return 'Idea de cita para nosotros: \"$title\" (vía MAZL)';
  }

  @override
  String get coupleFeedPromoCodeLabel => 'Código promocional MAZL';

  @override
  String get coupleFeedCopyCode => 'Copiar código';

  @override
  String get coupleFeedDescription => 'Descripción';

  @override
  String get coupleFeedTags => 'Etiquetas';

  @override
  String get coupleFeedAddress => 'Dirección';

  @override
  String get coupleFeedContact => 'Contacto';

  @override
  String get coupleFeedCall => 'Llamar';

  @override
  String get coupleFeedWebsite => 'Sitio web';

  @override
  String get coupleFeedFromPrice => 'Desde';

  @override
  String get coupleFeedBook => 'Reservar';

  @override
  String get coupleFeedSavedRemoveTitle => '¿Quitar de la lista?';

  @override
  String coupleFeedSavedRemoveBody(String title) {
    return '¿Quieres quitar \"$title\" de tus actividades guardadas?';
  }

  @override
  String get coupleFeedSavedRemoved => 'Actividad quitada';

  @override
  String coupleFeedSavedRemoveError(String title) {
    return 'No se pudo quitar «$title». Inténtalo de nuevo.';
  }

  @override
  String get coupleFeedSavedEmptyTitle => 'No hay actividades guardadas';

  @override
  String get coupleFeedSavedEmptyLine =>
      'Desliza una tarjeta hacia arriba para guardarla.';

  @override
  String get coupleFeedSavedEmptyAction => 'Descubrir actividades';

  @override
  String get coupleFeedEventsTitle => 'Eventos';

  @override
  String get coupleFeedEventsUpcoming => 'Próximos';

  @override
  String coupleFeedEventsRegisteredTab(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Inscritos ($countString)';
  }

  @override
  String get coupleFeedEventsEmptyAll => 'No hay eventos disponibles';

  @override
  String get coupleFeedEventsEmptyRegistered =>
      'No tienes ninguna inscripción a eventos';

  @override
  String get coupleFeedEventsDiscover => 'Descubrir eventos';

  @override
  String coupleFeedEventRegisteredSnack(String title) {
    return 'Inscripción confirmada en \"$title\"';
  }

  @override
  String coupleFeedEventRegisteredSnackDetail(String title) {
    return 'Inscripción confirmada en «$title»';
  }

  @override
  String get coupleFeedEventRegisterError =>
      'No se pudo completar la inscripción. Inténtalo de nuevo.';

  @override
  String get coupleFeedEventCancelError =>
      'No se pudo cancelar la inscripción. Inténtalo de nuevo.';

  @override
  String get coupleFeedEventCancelTitle => '¿Cancelar la inscripción?';

  @override
  String coupleFeedEventCancelBody(String title) {
    return '¿Seguro que quieres cancelar tu inscripción en \"$title\"?';
  }

  @override
  String get coupleFeedEventCancelNo => 'No';

  @override
  String get coupleFeedEventCancelYes => 'Sí, cancelar';

  @override
  String get coupleFeedEventCancelled => 'Inscripción cancelada';

  @override
  String get coupleFeedEventFull => 'Completo';

  @override
  String coupleFeedEventSpots(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString plazas',
      one: '1 plaza',
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
      other: 'Quedan $countString plazas',
      one: 'Queda 1 plaza',
    );
    return '$_temp0';
  }

  @override
  String get coupleFeedEventRegister => 'Inscribirse';

  @override
  String get coupleFeedEventCancelMine => 'Cancelar mi inscripción';

  @override
  String get coupleFeedEventNotFoundTitle => 'Evento no encontrado';

  @override
  String get coupleFeedEventNotFoundLine => 'Ya no se ofrece.';

  @override
  String get coupleFeedEventFactPlace => 'Lugar';

  @override
  String get coupleFeedEventFactDressCode => 'Vestimenta';

  @override
  String get coupleFeedEventFactOrganizer => 'Organizado por';

  @override
  String get coupleFeedEventIncluded => 'Qué incluye';

  @override
  String get coupleFeedLoadFailedTitle => 'No se pudo cargar';

  @override
  String get coupleFeedFailureNetwork =>
      'No se puede conectar con el servidor. Inténtalo de nuevo.';

  @override
  String get coupleFeedFailureMalformed => 'Respuesta inesperada del servidor.';

  @override
  String get coupleFeedFailureNotInCouple => 'El modo pareja no está activo.';

  @override
  String get coupleFeedFailureNotFound => 'No encontrado.';

  @override
  String get coupleFeedFailureFull => 'Este evento está completo.';

  @override
  String get coupleFeedFailureServer =>
      'El servidor no ha podido responder. Inténtalo de nuevo.';

  @override
  String get coupleFeedStoriesEmptyTitle => 'Aún no hay historias de parejas';

  @override
  String get coupleFeedStoriesEmptyLine =>
      'Las primeras historias de amor de MAZL se compartirán pronto.';

  @override
  String coupleFeedStoryShareText(String name1, String name2, String excerpt) {
    return '$name1 y $name2 se conocieron en MAZL. Su historia: $excerpt...';
  }

  @override
  String coupleFeedStoryStatusSince(String status, String date) {
    return '$status · desde $date';
  }

  @override
  String get coupleFeedStatusDating => 'En pareja';

  @override
  String get coupleFeedStatusEngaged => 'Comprometidos';

  @override
  String get coupleFeedStatusMarried => 'Casados';

  @override
  String get coupleFeedStoryShareLine =>
      'Inspira a la comunidad MAZL compartiendo tu historia.';

  @override
  String get coupleFeedStoryStatusLabel => 'Tu estado';

  @override
  String get coupleFeedStoryTextLabel => 'Tu historia (mín. 100 caracteres)';

  @override
  String get coupleFeedStoryTextHint =>
      '¿Cómo se conocieron? ¿Qué fue lo que más te gustó de tu pareja?…';

  @override
  String get coupleFeedStoryPhotosLabel => 'Fotos (opcional)';

  @override
  String get coupleFeedStoryPhotosHint => 'Añade fotos de pareja';

  @override
  String get coupleFeedStorySubmit => 'Enviar nuestra historia';

  @override
  String get coupleFeedStoryTooShort =>
      'Tu historia debe tener al menos 100 caracteres';

  @override
  String get coupleFeedStoryThanks =>
      'Gracias. Tu historia se publicará tras su validación.';

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
  String get profileMyProfile => 'Mi perfil';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileSettings => 'Ajustes';

  @override
  String get profileMoreOptions => 'Más opciones';

  @override
  String get profilePass => 'Pasar';

  @override
  String profileLikeName(String name) {
    return 'Me gusta $name';
  }

  @override
  String get profileThisPerson => 'esta persona';

  @override
  String get profileFallbackName => 'Usuario';

  @override
  String get profileFallbackReportName => 'Este usuario';

  @override
  String get profileDefaultLocation => 'Francia';

  @override
  String get profileDistanceUnderOneKm => 'a menos de 1 km';

  @override
  String profileDistanceKm(int km) {
    return 'a $km km';
  }

  @override
  String get profileGenderMale => 'Hombre';

  @override
  String get profileGenderFemale => 'Mujer';

  @override
  String get profileFactPractice => 'Práctica';

  @override
  String get profileFactKashrut => 'Kashrut';

  @override
  String get profileShabbat => 'Shabat';

  @override
  String get profileFactGender => 'Género';

  @override
  String get profileEssentials => 'Lo esencial';

  @override
  String get profileInAFewWords => 'En pocas palabras';

  @override
  String get profileAbout => 'Acerca de mí';

  @override
  String get profileLookingFor => 'Lo que busco';

  @override
  String get profileAddPhotos => 'Añadir fotos';

  @override
  String get profileVerified => 'Perfil verificado';

  @override
  String get profileVerifiedPlus => 'Perfil verificado+';

  @override
  String get profileVerifyMyProfile => 'Verificar mi perfil';

  @override
  String profileVerificationStatus(String status) {
    return 'Estado de verificación: $status';
  }

  @override
  String get profilePhotoPrevious => 'Foto anterior';

  @override
  String get profilePhotoNext => 'Foto siguiente';

  @override
  String profilePhotoCounter(int current, int total) {
    return 'Foto $current de $total';
  }

  @override
  String get profileMatchLabel => 'Match';

  @override
  String get profileMatchTitle => 'Es un match.';

  @override
  String profileMatchBody(String name) {
    return 'Ya puedes charlar con $name.';
  }

  @override
  String get profileMatchBodyUnnamed => 'Ya puedes charlar con esta persona.';

  @override
  String get profileSendMessage => 'Enviar un mensaje';

  @override
  String profileCompletionEyebrow(int done, int total) {
    return 'Perfil · $done/$total';
  }

  @override
  String get profileCompletionTitle => 'Completa tu perfil';

  @override
  String profileCompletionRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count pasos',
      one: 'Queda $count paso',
    );
    return '$_temp0';
  }

  @override
  String get profileCompletionAction => 'Completar ahora';

  @override
  String get profileStepPhotosDone => 'Fotos añadidas';

  @override
  String get profileStepPhotosTodo => 'Añade al menos 2 fotos';

  @override
  String get profileStepBioDone => 'Biografía completada';

  @override
  String get profileStepBioTodo => 'Descríbete en unas líneas';

  @override
  String get profileStepCityDone => 'Ciudad indicada';

  @override
  String get profileStepCityTodo => 'Indica tu ciudad';

  @override
  String get profileStepVerifiedDone => 'Perfil verificado';

  @override
  String get profileStepVerifiedTodo => 'Verifica tu perfil';

  @override
  String get profileCoupleMode => 'Modo pareja';

  @override
  String get profileCoupleInCoupleTitle => 'En pareja';

  @override
  String profileCoupleInCoupleBody(String name) {
    return 'Tú y $name estáis en modo pareja.';
  }

  @override
  String get profileCoupleElsewhereTitle => 'Ya estás en modo pareja';

  @override
  String get profileCoupleElsewhereBody =>
      'Ya estás en modo pareja con otra persona.';

  @override
  String get profileCoupleReceivedTitle => 'Solicitud recibida';

  @override
  String profileCoupleReceivedBody(String name) {
    return '$name quiere activar el modo pareja contigo.';
  }

  @override
  String get profileCoupleRespond => 'Responder';

  @override
  String get profileCouplePendingTitle => 'Solicitud enviada';

  @override
  String profileCouplePendingBody(String name) {
    return '$name aún no ha respondido.';
  }

  @override
  String get profileCoupleCancelRequest => 'Cancelar la solicitud';

  @override
  String get profileCoupleAvailableTitle => 'Pasar al modo pareja';

  @override
  String get profileCoupleAvailableBody =>
      'Habéis hecho match. Activa el modo pareja para compartir actividades juntos.';

  @override
  String profileCoupleActivate(String name) {
    return 'Activar con $name';
  }

  @override
  String profileCoupleRequestSent(String name) {
    return 'Solicitud enviada a $name.';
  }

  @override
  String get profileCompatibility => 'Compatibilidad';

  @override
  String get profileCompatibilityVeryHigh => 'Muy compatible';

  @override
  String get profileCompatibilityHigh => 'Compatible';

  @override
  String get profileCompatibilityAverage => 'Compatibilidad media';

  @override
  String get profileCompatibilityLow => 'Poco compatible';

  @override
  String get profileCompatibilityBasis =>
      'Calculada a partir de vuestros dos perfiles.';

  @override
  String get profileCompatibilityUnavailable =>
      'La compatibilidad no está disponible por ahora.';

  @override
  String profileCompatibilityUnlockTitle(String name) {
    return 'Descubre tu puntuación de compatibilidad con $name.';
  }

  @override
  String get profileCompatibilityUnlockBody =>
      'Calculado a partir de tus prácticas, tus intenciones y tus valores.';

  @override
  String get profileCompatibilityUnlock => 'Desbloquear con mazl+';

  @override
  String get profileFactorIntentions => 'Intenciones';

  @override
  String get profileFactorAge => 'Edad';

  @override
  String get profileFactorDistance => 'Distancia';

  @override
  String get profileVerdictSameIntention => 'Buscáis lo mismo';

  @override
  String get profileVerdictDifferentIntention => 'Intenciones diferentes';

  @override
  String get profileVerdictSameDenomination => 'Misma corriente';

  @override
  String get profileVerdictSimilarPractice => 'Práctica similar';

  @override
  String get profileVerdictDifferentPractice => 'Práctica diferente';

  @override
  String get profileVerdictVeryCloseAge => 'Edades muy cercanas';

  @override
  String get profileVerdictCloseAge => 'Edades cercanas';

  @override
  String get profileVerdictModerateAgeGap => 'Diferencia de edad moderada';

  @override
  String get profileVerdictLargeAgeGap => 'Gran diferencia de edad';

  @override
  String get profileVerdictVeryNear => 'Muy cerca (< 10 km)';

  @override
  String get profileVerdictNear => 'Cerca (< 25 km)';

  @override
  String get profileVerdictModerateDistance => 'Distancia moderada';

  @override
  String get profileVerdictFar => 'Bastante lejos';

  @override
  String profileCompatibilityCriteria(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count criterios analizados',
      one: '1 criterio analizado',
    );
    return '$_temp0';
  }

  @override
  String get profileCompatibilityScoreTitle => 'Puntuación de compatibilidad';

  @override
  String profileCompatibilityWith(String name) {
    return 'Con $name';
  }

  @override
  String get profileCompatibilityDetails => 'Detalles';

  @override
  String get profileCompatibilityIncomplete =>
      'Completa los perfiles para ver más detalles';

  @override
  String get profileCompatibilityNote =>
      'La puntuación se basa en las preferencias y los puntos en común';

  @override
  String get profileCompatibilityGotIt => 'Entendido';

  @override
  String get profilePromptsMine => 'Mis preguntas';

  @override
  String get profilePromptsSubtitle =>
      'Responde a preguntas para mostrar tu personalidad';

  @override
  String profilePromptsMaxReached(int max) {
    return 'Máximo de $max preguntas alcanzado';
  }

  @override
  String get profilePromptsAllUsed => 'Ya has usado todas las preguntas';

  @override
  String get profilePromptAdd => 'Añadir una pregunta';

  @override
  String get profilePromptChoose => 'Elige una pregunta';

  @override
  String get profilePromptYourAnswer => 'Tu respuesta…';

  @override
  String get profilePromptDeleteTitle => '¿Eliminar esta pregunta?';

  @override
  String get profileIrreversibleSentence => 'Esta acción no se puede deshacer.';

  @override
  String get profileIrreversible => 'Esta acción no se puede deshacer';

  @override
  String get profilePromptDeleted => 'Pregunta eliminada';

  @override
  String get profilePromptsGetToKnowMe => 'Conóceme';

  @override
  String get profilePromptCategoryPersonality => 'Personalidad';

  @override
  String get profilePromptCategoryLifestyle => 'Estilo de vida';

  @override
  String get profilePromptCategoryJewish => 'Judaísmo';

  @override
  String get profilePromptCategoryConversation => 'Conversación';

  @override
  String get profileOther => 'Otro';

  @override
  String get profilePromptPerfectSunday => 'Mi domingo perfecto...';

  @override
  String get profilePromptFunFact => 'Un dato sorprendente sobre mí...';

  @override
  String get profilePromptLifeGoal => 'Uno de mis objetivos en la vida...';

  @override
  String get profilePromptPetPeeve => 'Lo que más me molesta...';

  @override
  String get profilePromptProudOf => 'Lo que más me enorgullece...';

  @override
  String get profilePromptLookingFor => 'Busco a alguien que...';

  @override
  String get profilePromptIdealVacation => 'Mis vacaciones ideales...';

  @override
  String get profilePromptFavoriteFood => 'Mi plato favorito...';

  @override
  String get profilePromptHiddenTalent => 'Mi talento oculto...';

  @override
  String get profilePromptBingeWatching => 'Ahora mismo estoy viendo...';

  @override
  String get profilePromptShabbatIdeal => 'Mi Shabat ideal...';

  @override
  String get profilePromptFamilyTradition =>
      'Una tradición familiar que adoro...';

  @override
  String get profilePromptFavoriteHoliday => 'Mi fiesta judía favorita...';

  @override
  String get profilePromptFridayNight =>
      'Los viernes por la noche en mi casa...';

  @override
  String get profilePromptIsraelMemory => 'Mi mejor recuerdo en Israel...';

  @override
  String get profilePromptJewishValue => 'Un valor judío que me guía...';

  @override
  String get profilePromptDebateMe => 'Debate conmigo sobre…';

  @override
  String get profilePromptTeachMe => 'Enséñame algo sobre…';

  @override
  String get profilePromptTogetherWeCould => 'Juntos podríamos...';

  @override
  String get profilePromptFirstDate => 'Primera cita ideal...';

  @override
  String get profileIntentionHint => 'Muestra a los demás lo que buscas';

  @override
  String get profileIntentionMarriage => 'Matrimonio';

  @override
  String get profileIntentionSerious => 'Relación seria';

  @override
  String get profileIntentionOpen => 'Abierto/a a todo';

  @override
  String get profileIntentionOpenSelector => 'Abierto/a a todo';

  @override
  String get profileIntentionFriendsFirst => 'Primero, amistad';

  @override
  String get profileIntentionUndecided => 'No lo sé';

  @override
  String get profileIntentionMarriageDescription => 'Busco a mi futuro cónyuge';

  @override
  String get profileIntentionSeriousDescription =>
      'Busco una relación duradera';

  @override
  String get profileIntentionOpenDescription => 'Veremos adónde nos lleva';

  @override
  String get profileIntentionFriendsFirstDescription =>
      'Empecemos por conocernos';

  @override
  String get profileDenomination => 'Corriente';

  @override
  String get profileDenominationSecular => 'Laico';

  @override
  String get profileDenominationTraditional => 'Tradicional';

  @override
  String get profileDenominationMasorti => 'Masorti';

  @override
  String get profileDenominationLiberal => 'Liberal';

  @override
  String get profileDenominationModernOrthodox => 'Ortodoxo moderno';

  @override
  String get profileDenominationOrthodox => 'Ortodoxo';

  @override
  String get profileDenominationChabad => 'Jabad';

  @override
  String get profileFieldKashrut => 'Kashrut';

  @override
  String get profileKashrutNone => 'No';

  @override
  String get profileKashrutHome => 'Kosher en casa';

  @override
  String get profileKashrutStrict => 'Kosher estricto';

  @override
  String get profileKashrutGlatt => 'Glatt kosher';

  @override
  String get profileKashrutOptionHome => 'En casa';

  @override
  String get profileKashrutOptionStrict => 'Estricto';

  @override
  String get profileKashrutOptionGlatt => 'Glatt';

  @override
  String get profileShabbatNotObservant => 'No observante';

  @override
  String get profileShabbatPartial => 'Shabat parcial';

  @override
  String get profileShabbatObserved => 'Shabat observado';

  @override
  String get profileShabbatStrict => 'Shabat estricto';

  @override
  String get profileShabbatFamily => 'Shabat en familia';

  @override
  String get profileShabbatOptionPartial => 'Parcialmente';

  @override
  String get profileShabbatOptionObservant => 'Observante';

  @override
  String get profileShabbatOptionStrict => 'Muy observante';

  @override
  String get profileSynagogue => 'Sinagoga';

  @override
  String get profileSynagogueDaily => 'A diario';

  @override
  String get profileSynagogueWeekly => 'Cada semana';

  @override
  String get profileSynagogueHolidays => 'En las fiestas';

  @override
  String get profileSynagogueRarely => 'Rara vez';

  @override
  String get profileEditTitle => 'Editar perfil';

  @override
  String get profilePhotos => 'Fotos';

  @override
  String get profilePhotosHint => 'Mantén pulsado para elegirla como principal';

  @override
  String get profileBioHint => 'Cuéntanos sobre ti…';

  @override
  String get profileBasicInfo => 'Información básica';

  @override
  String get profileFirstName => 'Nombre';

  @override
  String get profileCity => 'Ciudad';

  @override
  String get profilePracticeTitle => 'Mi práctica';

  @override
  String get profilePrimaryPhoto => 'Principal';

  @override
  String get profileEnterFirstName => 'Introduce tu nombre';

  @override
  String get profileEnterCity => 'Introduce tu ciudad';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String get profilePhotoAdded => 'Foto añadida';

  @override
  String get profileUploadUnavailable =>
      'La subida no está disponible por ahora';

  @override
  String get profileDeletePhotoTitle => '¿Eliminar la foto?';

  @override
  String get profilePhotoDeleted => 'Foto eliminada';

  @override
  String get profileServiceUnavailable =>
      'Servicio no disponible temporalmente';

  @override
  String get profilePrimaryUpdated => 'Foto principal actualizada';

  @override
  String profileSetupStep(int step, int total) {
    return 'Paso $step/$total';
  }

  @override
  String get profileSetupNext => 'Siguiente';

  @override
  String get profileSetupFinish => 'Terminar';

  @override
  String get profileSetupNameRequired => 'Indica tu nombre para continuar';

  @override
  String get profileSetupBirthdateRequired => 'Indica tu fecha de nacimiento';

  @override
  String get profileSetupGenderRequired => 'Indica tu género';

  @override
  String get profileBirthdate => 'Fecha de nacimiento';

  @override
  String get profileBirthdateHint => 'DD/MM/AAAA';

  @override
  String get profileSetupAboutYouTitle => 'Cuéntanos sobre ti';

  @override
  String get profileSetupAboutYouSubtitle =>
      'Esta información será visible en tu perfil';

  @override
  String get profileFirstNameHint => '¿Cómo te llamas?';

  @override
  String get profileIAm => 'Soy';

  @override
  String get profileAMan => 'Un hombre';

  @override
  String get profileAWoman => 'Una mujer';

  @override
  String get profileCityHint => '¿Dónde vives?';

  @override
  String get profileSetupPhotosTitle => 'Añade fotos';

  @override
  String get profileSetupPhotosSubtitle =>
      'Añade al menos 2 fotos para continuar';

  @override
  String get profileSetupPhotosTip =>
      'Los perfiles con fotos de buena calidad reciben 3 veces más matches.';

  @override
  String get profileSetupPracticeTitle => 'Tu práctica';

  @override
  String get profileSetupPracticeSubtitle =>
      'Ayúdanos a encontrar a alguien que encaje contigo';

  @override
  String get profileSetupLookingTitle => 'Lo que buscas';

  @override
  String get profileSetupLookingSubtitle =>
      'Ayúdanos a mostrarte los perfiles adecuados';

  @override
  String get profileILookFor => 'Busco';

  @override
  String get profileAgeRange => 'Rango de edad';

  @override
  String get profileMaxDistance => 'Distancia máxima';

  @override
  String profileDistanceSliderLabel(int km) {
    return '$km km';
  }

  @override
  String get profileGoal => 'Objetivo';

  @override
  String get profileShadchanNote =>
      'Nuestro AI Shadchan usará estas preferencias para proponerte perfiles compatibles.';

  @override
  String get profileReportThisProfile => 'Denunciar este perfil';

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
