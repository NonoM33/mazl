// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get authLoginEyebrow => 'Citas · Comunidad judía';

  @override
  String get authLoginTagline =>
      'Citas serias entre personas que comparten tus valores.';

  @override
  String get authLoginApple => 'Continuar con Apple';

  @override
  String get authLoginGoogle => 'Continuar con Google';

  @override
  String get authLoginDev => 'Inicio de sesión ficticio (dev)';

  @override
  String authLegal(String terms, String privacy) {
    return 'Al continuar, aceptas las $terms y la $privacy.';
  }

  @override
  String get authLegalTermsLink => 'Condiciones';

  @override
  String get authLegalPrivacyLink => 'Política de privacidad';

  @override
  String get authErrorGeneric => 'Ha ocurrido un error. Inténtalo de nuevo.';

  @override
  String get authErrorCancelled => 'Inicio de sesión cancelado.';

  @override
  String get authErrorUnsupported =>
      'Este método de inicio de sesión no está disponible en este dispositivo.';

  @override
  String get authRouteErrorTitle => 'Página no encontrada';

  @override
  String get authRouteErrorBody => 'Ha ocurrido un error';

  @override
  String get authRouteErrorHome => 'Volver al inicio';

  @override
  String get boostTitle => 'Boost';

  @override
  String get boostHeadlineActive => 'Boost activo';

  @override
  String get boostHeadlineIdle => 'Impulsa tu perfil';

  @override
  String get boostTagline => 'Haz que te vean 10 veces más personas.';

  @override
  String boostMinutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min restantes',
      one: '$minutes min restante',
    );
    return '$_temp0';
  }

  @override
  String get boostDuringTitle => 'Durante este Boost';

  @override
  String get boostViews => 'Visitas';

  @override
  String get boostLikes => 'Likes';

  @override
  String get boostBenefitsTitle => 'Ventajas del Boost';

  @override
  String get boostBenefitFirst => 'Aparece el primero en las sugerencias';

  @override
  String boostBenefitVisibility(int minutes) {
    return '10 veces más visibilidad durante $minutes min';
  }

  @override
  String get boostBenefitMatches => 'Más posibilidades de hacer match';

  @override
  String get boostBenefitStats =>
      'Estadísticas en tiempo real durante el Boost';

  @override
  String get boostActivate => 'Activar el Boost';

  @override
  String boostRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count Boosts',
      one: 'Queda $count Boost',
    );
    return '$_temp0';
  }

  @override
  String get boostActivated =>
      'Boost activado. Tu perfil ya está en primer plano.';

  @override
  String get boostActivateFailed => 'Error al activar';

  @override
  String get boostUpsellTitle => 'Boosts ilimitados';

  @override
  String get boostUpsellBody => 'Usa el Boost sin límite con mazl+';

  @override
  String get chatListTitle => 'Mensajes';

  @override
  String get chatListSearchHint => 'Buscar';

  @override
  String get chatListLoadErrorTitle => 'No se puede cargar';

  @override
  String get chatListLoadErrorBody =>
      'Comprueba tu conexión y vuelve a intentarlo.';

  @override
  String get chatListEmptyTitle => 'Aún no hay conversaciones';

  @override
  String get chatListEmptyBody =>
      'Tus conversaciones aparecerán aquí en cuanto tengas tu primer match.';

  @override
  String get chatListEmptyAction => 'Descubrir';

  @override
  String chatListNoResults(String query) {
    return 'Sin resultados para «$query».';
  }

  @override
  String get chatListUnknownMember => 'Usuario';

  @override
  String get chatNewMatch => 'Nuevo match';

  @override
  String chatListUnreadLabel(String name) {
    return '$name, mensaje sin leer';
  }

  @override
  String get chatPhotoLabel => 'Foto';

  @override
  String get chatVoiceLabel => 'Mensaje de voz';

  @override
  String get chatRemovedLabel => 'Mensaje retirado';

  @override
  String get chatOtherFallbackName => 'Tu match';

  @override
  String get chatAuthorYou => 'Tú';

  @override
  String get chatHeaderLoading => 'Cargando…';

  @override
  String get chatHeaderTyping => 'escribiendo…';

  @override
  String get chatHeaderOnline => 'En línea';

  @override
  String get chatHeaderVideoCall => 'Videollamada';

  @override
  String get chatHeaderOptions => 'Opciones';

  @override
  String get chatOptionsViewProfile => 'Ver perfil';

  @override
  String get chatOptionsMute => 'Silenciar notificaciones';

  @override
  String get chatOptionsBlock => 'Bloquear';

  @override
  String get chatMutedConfirmation =>
      'Notificaciones silenciadas en esta conversación';

  @override
  String get chatBlockFallbackName => 'Este usuario';

  @override
  String get chatLoading => 'Cargando la conversación';

  @override
  String get chatEmptyTitle => 'Saluda.';

  @override
  String get chatEmptyBody => 'Envía el primer mensaje para romper el hielo.';

  @override
  String chatMatchStart(String date) {
    return 'Match · $date';
  }

  @override
  String chatNewMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes nuevos',
      one: '1 mensaje nuevo',
    );
    return '$_temp0';
  }

  @override
  String get chatTypingSemantics => 'Tu match está escribiendo';

  @override
  String chatSeenAt(String time) {
    return 'Visto a las $time';
  }

  @override
  String get chatFailedRetry => 'Error · Reintentar';

  @override
  String get chatMenuReply => 'Responder';

  @override
  String get chatMenuCopy => 'Copiar';

  @override
  String get chatMenuUnsend => 'Retirar';

  @override
  String get chatMenuClose => 'Cerrar menú';

  @override
  String get chatCopied => 'Mensaje copiado';

  @override
  String get chatReportThanks => 'Gracias, estamos revisando este mensaje.';

  @override
  String get chatReactionsTitle => 'Reacciones';

  @override
  String get chatReportTitle => 'Denunciar este mensaje';

  @override
  String get chatReportReasonScam => 'Estafa o petición de dinero';

  @override
  String get chatReportReasonHarassment => 'Acoso o comentarios inapropiados';

  @override
  String get chatReportReasonInappropriate => 'Contenido inapropiado';

  @override
  String get chatReportReasonOther => 'Otro';

  @override
  String get chatScamAdviceTitle => 'Protégete de las estafas';

  @override
  String get chatScamAdviceMoney =>
      'Nunca envíes dinero, tarjetas regalo ni criptomonedas.';

  @override
  String get chatScamAdviceApps =>
      'Desconfía de quien te pida pasar enseguida a WhatsApp, Telegram o Signal.';

  @override
  String get chatScamAdviceVideo =>
      'Haz una videollamada antes de comprometerte.';

  @override
  String get chatScamAdviceReport =>
      'Si tienes dudas, denuncia la conversación: la revisamos.';

  @override
  String get chatScamTitle => 'Ten cuidado';

  @override
  String get chatScamBody =>
      'Nunca transfieras dinero a alguien que no conoces en persona.';

  @override
  String get chatScamLearnMore => 'Saber más';

  @override
  String get chatPhotoReveal => 'Ver foto';

  @override
  String get chatVoicePlayFailed => 'No se puede reproducir';

  @override
  String get chatVoicePlay => 'Reproducir mensaje de voz';

  @override
  String get chatVoicePause => 'Pausar';

  @override
  String get chatComposerHint => 'Mensaje';

  @override
  String get chatComposerAttach => 'Adjuntar fotos';

  @override
  String get chatComposerSend => 'Enviar';

  @override
  String get chatComposerSendVoice => 'Enviar mensaje de voz';

  @override
  String get chatComposerPhotoError =>
      'No se pudo añadir la foto. Revisa los permisos.';

  @override
  String get chatComposerMicDenied =>
      'Permite el micrófono en los ajustes para enviar un mensaje de voz.';

  @override
  String get chatComposerRecordError =>
      'No se puede grabar ahora. Inténtalo de nuevo.';

  @override
  String get chatComposerHoldLonger =>
      'Mantén pulsado el micrófono más tiempo para grabar.';

  @override
  String get chatComposerHoldHint =>
      'Mantén pulsado el micrófono para grabar un mensaje de voz.';

  @override
  String get chatMicSemantics => 'Mantén pulsado para grabar un mensaje de voz';

  @override
  String get chatAttachPhotos => 'Fotos';

  @override
  String get chatAttachPhotosLimit => 'Hasta 10 a la vez';

  @override
  String get chatAttachCamera => 'Cámara';

  @override
  String get chatRecordingCancel => 'Cancelar grabación';

  @override
  String get chatRecordingRelease => 'Suelta para cancelar';

  @override
  String get chatRecordingSlide => '‹ Desliza para cancelar';

  @override
  String get chatReplyCancel => 'Cancelar respuesta';

  @override
  String chatReplyToOther(String name) {
    return 'Respuesta a $name';
  }

  @override
  String get chatReplyToMine => 'Respuesta a tu mensaje';

  @override
  String get chatErrorSessionExpired =>
      'Sesión caducada, vuelve a iniciar sesión.';

  @override
  String get chatErrorCannotUnsend => 'Este mensaje ya no se puede retirar.';

  @override
  String get chatErrorConversationGone =>
      'Esta conversación ya no está disponible.';

  @override
  String get chatErrorBlocked => 'Ya no puedes escribir en esta conversación.';

  @override
  String get chatErrorTooLarge => 'Archivo demasiado grande.';

  @override
  String get chatErrorRateLimited => 'Demasiados envíos, espera un momento.';

  @override
  String get chatErrorServer =>
      'El servidor no está disponible, inténtalo de nuevo.';

  @override
  String get chatErrorFileRejected => 'Archivo rechazado, prueba con otro.';

  @override
  String get chatErrorMessageRejected => 'Mensaje rechazado.';

  @override
  String get chatErrorTimeout => 'Tiempo agotado, revisa tu conexión.';

  @override
  String get chatErrorNetwork => 'Sin conexión a internet.';

  @override
  String get chatErrorUnknown => 'Ha ocurrido un error.';

  @override
  String get chatErrorTooManyPhotos => 'Diez fotos como máximo por mensaje.';

  @override
  String get chatErrorNotYetSent => 'Este mensaje aún no se ha enviado.';

  @override
  String get chatErrorMessageGone => 'Este mensaje ya no existe.';

  @override
  String get chatErrorNotAuthor => 'Solo el autor puede retirar un mensaje.';

  @override
  String get chatErrorReactionUnavailable => 'Reacción no disponible.';

  @override
  String get chatErrorSendUnavailable => 'No se puede enviar ahora.';

  @override
  String get chatErrorLoadFailed => 'No se pudo cargar la conversación.';

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
  String get coupleSpaceTabActivities => 'Actividades';

  @override
  String get coupleSpaceTabCalendar => 'Calendario';

  @override
  String get coupleSpaceTabEvents => 'Eventos';

  @override
  String get coupleSpaceTabSpace => 'Nuestro espacio';

  @override
  String get coupleSpaceTitle => 'Nuestro espacio';

  @override
  String get coupleSpaceSettingsTooltip => 'Ajustes';

  @override
  String get coupleSpaceYou => 'Tú';

  @override
  String get coupleSpacePartnerFallback => 'Tu media naranja';

  @override
  String coupleSpaceTogetherSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return 'Juntos desde hace $_temp0';
  }

  @override
  String get coupleSpaceStoryBegins => 'Vuestra historia empieza';

  @override
  String get coupleSpaceStatSavedActivities => 'Actividades\nguardadas';

  @override
  String get coupleSpaceStatUpcomingEvents => 'Eventos\npróximos';

  @override
  String get coupleSpaceStatMemories => 'Recuerdos\ncreados';

  @override
  String get coupleSpaceQuickActions => 'Acciones rápidas';

  @override
  String get coupleSpaceQuickAddMemory => 'Añadir\nun recuerdo';

  @override
  String get coupleSpaceQuickAddBucket => 'Añadir a la\nlista de deseos';

  @override
  String get coupleSpaceQuickAddDate => 'Añadir\nuna fecha';

  @override
  String get coupleSpaceMemoriesTitle => 'Nuestros recuerdos';

  @override
  String get coupleSpaceMemoriesEmptyTitle => 'Aún no hay recuerdos';

  @override
  String get coupleSpaceMemoriesEmptyHint =>
      'Añade vuestros primeros recuerdos juntos.';

  @override
  String get coupleSpaceBucketTitle => 'Lista de deseos';

  @override
  String coupleSpaceBucketProgress(int done, int total) {
    return 'Lista de deseos · $done/$total';
  }

  @override
  String get coupleSpaceBucketEmptyTitle =>
      'Vuestra lista de deseos está vacía';

  @override
  String get coupleSpaceBucketEmptyHint =>
      'Añade experiencias para vivir juntos.';

  @override
  String get coupleSpaceDatesTitle => 'Fechas importantes';

  @override
  String get coupleSpaceSeeAll => 'Ver todo';

  @override
  String get coupleSpaceDatesEmptyTitle => 'Ninguna fecha importante';

  @override
  String get coupleSpaceDatesEmptyHint =>
      'Añade vuestros aniversarios, fiestas, etc.';

  @override
  String get coupleSpaceBadgesTitle => 'Nuestras insignias';

  @override
  String get coupleSpaceBadgesEmptyTitle => 'Aún no hay insignias';

  @override
  String get coupleSpaceBadgesEmptyHint =>
      'Haced actividades juntos para desbloquear insignias.';

  @override
  String get coupleSpaceGoalDone => 'Objetivo cumplido';

  @override
  String get coupleSpaceGoalFailed =>
      'No se pudo validar este objetivo. Inténtalo de nuevo.';

  @override
  String coupleSpaceRefreshFailed(String reason) {
    return 'No se pudo actualizar. $reason';
  }

  @override
  String get coupleSpaceLoadFailedTitle => 'No se pudo cargar';

  @override
  String get coupleSpaceSheetAdd => 'Añadir';

  @override
  String get coupleSpaceAddMemoryTitle => 'Añadir un recuerdo';

  @override
  String get coupleSpaceFieldTitle => 'Título';

  @override
  String get coupleSpaceFieldDescription => 'Descripción';

  @override
  String get coupleSpaceAddBucketTitle => 'Añadir a la lista de deseos';

  @override
  String get coupleSpaceBucketFieldLabel => '¿Qué quieres hacer en pareja?';

  @override
  String get coupleSpaceBucketFieldHint => 'Ej.: Ver auroras boreales';

  @override
  String get coupleSpaceAddDateTitle => 'Añadir una fecha importante';

  @override
  String get coupleSpaceDateFieldHint => 'Ej.: Nuestro aniversario';

  @override
  String get coupleSpaceFieldDate => 'Fecha';

  @override
  String coupleSpaceAddFailed(String reason) {
    return 'No se pudo añadir. $reason';
  }

  @override
  String get coupleSpaceSetupTitle => 'Modo pareja';

  @override
  String get coupleSpaceSetupWho => '¿Con quién?';

  @override
  String get coupleSpaceSetupSend => 'Enviar solicitud';

  @override
  String get coupleSpaceSetupNoMatches => 'Aún no tienes matches.';

  @override
  String get coupleSpaceSetupMatchesError =>
      'No se pudieron cargar tus matches.';

  @override
  String get coupleSpaceSetupSentTitle => 'Solicitud enviada';

  @override
  String coupleSpaceSetupSentBody(String name) {
    return '$name tiene que aceptar. Te avisaremos en cuanto responda.';
  }

  @override
  String get coupleSpaceSetupSentBodyAnonymous =>
      'Esta persona tiene que aceptar. Te avisaremos en cuanto responda.';

  @override
  String get coupleSpaceSetupGotIt => 'Entendido';

  @override
  String get coupleSpaceSetupCancelRequest => 'Cancelar la solicitud';

  @override
  String get coupleSpaceMazelTovTitle => 'Mazal tov';

  @override
  String coupleSpaceMazelTovCongrats(String name) {
    return 'Enhorabuena a ti y a $name';
  }

  @override
  String get coupleSpaceMazelTovWelcome =>
      'MAZL te acompaña en esta nueva etapa.';

  @override
  String get coupleSpaceMazelTovStart => 'Empezar nuestra aventura';

  @override
  String coupleSpaceRequestTitle(String name) {
    return '$name quiere activar el modo pareja contigo';
  }

  @override
  String get coupleSpaceRequestTitleAnonymous =>
      'Esta persona quiere activar el modo pareja contigo';

  @override
  String get coupleSpaceRequestAccept => 'Aceptar';

  @override
  String get coupleSpaceRequestDecline => 'No, gracias';

  @override
  String coupleSpaceFlowDeclinedNamed(String name) {
    return '$name no ha dado respuesta a tu solicitud.';
  }

  @override
  String get coupleSpaceFlowDeclined => 'Tu solicitud no ha prosperado.';

  @override
  String get coupleSpaceFlowEnded => 'El modo pareja ha terminado.';

  @override
  String get coupleSpaceArchiveMessage =>
      'He encontrado el amor en Mazl. Ya no estoy disponible. ¡Mucha suerte en tu búsqueda!';

  @override
  String get coupleSpaceFailNotMatched =>
      'El modo pareja solo se activa con un match.';

  @override
  String get coupleSpaceFailAlreadyInCouple =>
      'Uno de los dos ya está en modo pareja.';

  @override
  String get coupleSpaceFailRequestPending =>
      'Ya hay una solicitud pendiente con esta persona.';

  @override
  String get coupleSpaceFailRequestGone =>
      'Esta solicitud ya no está pendiente.';

  @override
  String get coupleSpaceFailUnavailable => 'Esta persona no está disponible.';

  @override
  String get coupleSpaceFailSelf => 'No puedes enviarte una solicitud a ti.';

  @override
  String get coupleSpaceFailNotInCouple => 'El modo pareja no está activo.';

  @override
  String get coupleSpaceFailCannotLeave =>
      'No se puede salir del modo pareja ahora mismo.';

  @override
  String get coupleSpaceFailUnknown =>
      'Algo salió mal. Inténtalo de nuevo en un momento.';

  @override
  String get coupleSpaceFailEventFull => 'Este evento está completo.';

  @override
  String get coupleSpaceFailServer =>
      'El servidor no pudo responder. Inténtalo de nuevo.';

  @override
  String get coupleSpaceFailUnexpected => 'Respuesta inesperada del servidor.';

  @override
  String get coupleSpaceStatusSingle => 'Sin pareja';

  @override
  String get coupleSpaceStatusDating => 'Saliendo';

  @override
  String get coupleSpaceStatusInRelationship => 'En pareja';

  @override
  String get coupleSpaceStatusEngaged => 'Prometidos';

  @override
  String get coupleSpaceStatusMarried => 'Casados';

  @override
  String coupleSpaceDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '$count semana',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '$count mes',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceDurationYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count años',
      one: '$count año',
    );
    return '$_temp0';
  }

  @override
  String get coupleSpaceAnniversaryTag => 'Feliz aniversario en MAZL';

  @override
  String coupleSpaceAnniversaryDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'días juntos',
      one: 'día juntos',
    );
    return '$_temp0';
  }

  @override
  String coupleSpaceAnniversaryWith(String name) {
    return 'con $name';
  }

  @override
  String coupleSpaceAnniversaryNext(String milestone, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return 'Próximo: $milestone en $_temp0';
  }

  @override
  String get coupleSpaceAnniversaryHappy => 'Feliz aniversario';

  @override
  String coupleSpaceAnniversaryDaysWith(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return '$_temp0 con $name';
  }

  @override
  String get coupleSpaceAnniversaryThanks => 'Gracias';

  @override
  String coupleSpaceAnniversaryShare(int count, String milestone) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return 'Celebramos $_temp0 juntos en MAZL. $milestone';
  }

  @override
  String get coupleSpaceMilestonesTitle => 'Vuestros hitos';

  @override
  String coupleSpaceMilestoneIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return 'en $_temp0';
  }

  @override
  String get coupleSpaceCalendarTitle => 'Calendario';

  @override
  String get coupleSpaceCalendarShabbatIdeas => 'Ideas para este Shabat';

  @override
  String get coupleSpaceCalendarUpcoming => 'Próximas fiestas';

  @override
  String get coupleSpaceCalendarPrevMonth => 'Mes anterior';

  @override
  String get coupleSpaceCalendarNextMonth => 'Mes siguiente';

  @override
  String get coupleSpaceCalendarOngoing => 'En curso';

  @override
  String coupleSpaceCalendarCountdown(int count) {
    return 'En $count d';
  }

  @override
  String get coupleSpaceCalendarIdeas => 'Ideas en pareja';

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
  String get genreLookingForRequired => 'Indica a quién buscas';

  @override
  String get icebreakerWidgetTitle => '¿Necesitas inspiración?';

  @override
  String get icebreakerWidgetSubtitle =>
      'Aquí tienes algunas ideas para romper el hielo';

  @override
  String get icebreakerTopicFallback => 'eso';

  @override
  String icebreakerPromptLoved(String promptText, String followUp) {
    return 'Me encantó tu respuesta a \"$promptText\". $followUp';
  }

  @override
  String icebreakerPromptSmiled(String promptText) {
    return 'Tu respuesta sobre \"$promptText\" me hizo sonreír. ¿Puedes contarme más?';
  }

  @override
  String icebreakerPromptCurious(String answer, String topic) {
    return 'Tengo curiosidad por saber por qué respondiste \"$answer\" a la pregunta sobre $topic';
  }

  @override
  String get icebreakerFollowUpIntrigued => 'Me intriga.';

  @override
  String get icebreakerFollowUpKnowMore => 'Me gustaría saber más.';

  @override
  String get icebreakerFollowUpTellMe => '¿Me cuentas?';

  @override
  String get icebreakerFollowUpInteresting => 'Suena interesante.';

  @override
  String get icebreakerBioTravelRecent =>
      '¿Dónde has viajado últimamente? Me encantaría oír tus historias.';

  @override
  String get icebreakerBioTravelDream => '¿Cuál es tu próximo destino soñado?';

  @override
  String get icebreakerBioMusicGenre =>
      '¿Qué tipo de música escuchas últimamente?';

  @override
  String get icebreakerBioMusicConcert =>
      '¿Has ido a algún buen concierto últimamente?';

  @override
  String get icebreakerBioCookingNow =>
      '¿Qué estás cocinando de rico últimamente?';

  @override
  String get icebreakerBioCookingSignature => '¿Cuál es tu plato estrella?';

  @override
  String get icebreakerBioSportWhich => '¿Qué deporte practicas?';

  @override
  String get icebreakerBioSportWatchOrPlay => '¿Prefieres verlo o practicarlo?';

  @override
  String get icebreakerBioReadingNow => '¿Qué estás leyendo ahora?';

  @override
  String get icebreakerBioReadingLastBook =>
      '¿Cuál es el último libro que te marcó?';

  @override
  String get icebreakerBioCinemaRecent =>
      '¿Has visto alguna buena película últimamente?';

  @override
  String get icebreakerBioCinemaOrSeries => '¿Prefieres cine o series?';

  @override
  String get icebreakerBioHikingTrails =>
      '¿Conoces buenos senderos por la zona?';

  @override
  String get icebreakerBioHikingBest =>
      '¿Cuál ha sido tu mejor ruta de senderismo?';

  @override
  String get icebreakerBioPhotoSubjects => '¿Qué sueles fotografiar?';

  @override
  String get icebreakerBioPhotoCamera => '¿Qué cámara usas?';

  @override
  String get icebreakerOrthodoxSynagogue =>
      '¿Tienes una sinagoga favorita por la zona?';

  @override
  String get icebreakerOrthodoxShabbat => '¿Cómo sueles pasar el Shabat?';

  @override
  String get icebreakerOrthodoxKosherRestaurant =>
      '¿Tienes un restaurante kosher favorito?';

  @override
  String get icebreakerTraditionalTraditions =>
      '¿Qué tradiciones judías son más importantes para ti?';

  @override
  String get icebreakerTraditionalShabbat => '¿Cómo sueles celebrar el Shabat?';

  @override
  String get icebreakerTraditionalHoliday =>
      '¿Tienes una fiesta judía favorita?';

  @override
  String get icebreakerSecularCulture =>
      '¿Cómo es tu relación con la cultura judía?';

  @override
  String get icebreakerSecularFamilyTraditions =>
      '¿Mantienes alguna tradición familiar?';

  @override
  String get icebreakerSecularHolidays => '¿Qué fiestas celebras?';

  @override
  String get icebreakerDefaultHoliday => '¿Cuál es tu fiesta judía favorita?';

  @override
  String get icebreakerDefaultFamilyTraditions =>
      '¿Tienes tradiciones familiares especiales?';

  @override
  String get icebreakerDefaultPracticingFamily =>
      '¿Creciste en una familia practicante?';

  @override
  String icebreakerLocationKnowWell(String location) {
    return '¿Conoces bien $location? ¿Qué me recomiendas?';
  }

  @override
  String icebreakerLocationFavoriteSpot(String location) {
    return '¿Cuál es tu rincón favorito de $location?';
  }

  @override
  String icebreakerLocationOriginallyFrom(String location) {
    return '¿Eres de $location o te mudaste allí?';
  }

  @override
  String icebreakerLocationRestaurant(String location) {
    return '¿Hay algún buen restaurante que recomiendes en $location?';
  }

  @override
  String get icebreakerGenericDinnerGuest =>
      'Si pudieras cenar con cualquier persona, viva o muerta, ¿quién sería?';

  @override
  String get icebreakerGenericPerfectDay =>
      '¿Cómo sería para ti un día perfecto?';

  @override
  String get icebreakerGenericHiddenTalent =>
      '¿Tienes algún talento oculto que poca gente conoce?';

  @override
  String get icebreakerGenericSpontaneous =>
      '¿Qué es lo más espontáneo que has hecho nunca?';

  @override
  String get icebreakerGenericSeaOrMountain =>
      '¿Prefieres vacaciones en la playa o en la montaña?';

  @override
  String get icebreakerGenericLottery =>
      'Si mañana te tocara la lotería, ¿qué harías primero?';

  @override
  String get icebreakerGenericGuiltyPleasure => '¿Cuál es tu placer culpable?';

  @override
  String get icebreakerGenericDream => '¿Tienes algún sueño por cumplir?';

  @override
  String get icebreakerGenericBestAdvice =>
      '¿Cuál es el mejor consejo que te han dado?';

  @override
  String get icebreakerGenericBreakfastOrDinner =>
      '¿Prefieres desayunar o cenar fuera?';

  @override
  String get jewishCalendarShabbatTitle => 'Este Shabat';

  @override
  String jewishCalendarParashat(String name) {
    return 'Parashá $name';
  }

  @override
  String jewishCalendarParshaPair(String first, String second) {
    return '$first – $second';
  }

  @override
  String get jewishCalendarCandleLighting => 'Encendido de velas';

  @override
  String get jewishCalendarHavdalah => 'Havdalá';

  @override
  String get jewishCalendarCategoryPreparation => 'Preparación';

  @override
  String get jewishCalendarCategorySpiritual => 'Espiritual';

  @override
  String get jewishCalendarCategoryRelaxation => 'Descanso';

  @override
  String get jewishCalendarActivityShabbatDinnerTitle =>
      'Preparar la cena juntos';

  @override
  String get jewishCalendarActivityShabbatDinnerBody =>
      'Cocina la jalá y la comida de fiesta';

  @override
  String get jewishCalendarActivityShabbatCandlesTitle => 'Encender las velas';

  @override
  String get jewishCalendarActivityShabbatCandlesBody =>
      'Un momento de espiritualidad compartido';

  @override
  String get jewishCalendarActivityShabbatWalkTitle => 'Paseo de Shabat';

  @override
  String get jewishCalendarActivityShabbatWalkBody =>
      'Un paseo tranquilo después de la comida';

  @override
  String get jewishCalendarActivityShabbatParashaTitle =>
      'Estudio de la parashá';

  @override
  String get jewishCalendarActivityShabbatParashaBody =>
      'Aprended juntos la porción de la semana';

  @override
  String get jewishCalendarActivityPesachSederTitle => 'Preparar el Séder';

  @override
  String get jewishCalendarActivityPesachSederBody => 'Preparad la mesa juntos';

  @override
  String get jewishCalendarActivityPesachCleaningTitle =>
      'Hacer la limpieza de Pésaj';

  @override
  String get jewishCalendarActivityPesachCleaningBody =>
      'Limpieza de primavera en equipo';

  @override
  String get jewishCalendarHolidayRoshHashanaName => 'Rosh Hashaná';

  @override
  String get jewishCalendarHolidayRoshHashanaDescription => 'Año Nuevo judío';

  @override
  String get jewishCalendarHolidayYomKippurName => 'Yom Kipur';

  @override
  String get jewishCalendarHolidayYomKippurDescription => 'Día del Perdón';

  @override
  String get jewishCalendarHolidaySukkotName => 'Sucot';

  @override
  String get jewishCalendarHolidaySukkotDescription => 'Fiesta de las cabañas';

  @override
  String get jewishCalendarHolidaySheminiAtzeretName => 'Shemini Atzéret';

  @override
  String get jewishCalendarHolidaySheminiAtzeretDescription =>
      'Octavo día de reunión';

  @override
  String get jewishCalendarHolidaySimchatTorahName => 'Simjat Torá';

  @override
  String get jewishCalendarHolidaySimchatTorahDescription =>
      'Alegría de la Torá';

  @override
  String get jewishCalendarHolidayHanukkahName => 'Janucá';

  @override
  String get jewishCalendarHolidayHanukkahDescription => 'Fiesta de las luces';

  @override
  String get jewishCalendarHolidayTuBishvatName => 'Tu BiShvat';

  @override
  String get jewishCalendarHolidayTuBishvatDescription =>
      'Año Nuevo de los árboles';

  @override
  String get jewishCalendarHolidayPurimName => 'Purim';

  @override
  String get jewishCalendarHolidayPurimDescription => 'Fiesta de las suertes';

  @override
  String get jewishCalendarHolidayPesachName => 'Pésaj';

  @override
  String get jewishCalendarHolidayPesachDescription => 'Fiesta de la libertad';

  @override
  String get jewishCalendarHolidayYomHashoahName => 'Yom HaShoá';

  @override
  String get jewishCalendarHolidayYomHashoahDescription =>
      'Día del Recuerdo de la Shoá';

  @override
  String get jewishCalendarHolidayYomHazikaronName => 'Yom HaZikarón';

  @override
  String get jewishCalendarHolidayYomHazikaronDescription =>
      'Día del Recuerdo de los soldados caídos';

  @override
  String get jewishCalendarHolidayYomHaatzmautName => 'Yom HaAtzmaut';

  @override
  String get jewishCalendarHolidayYomHaatzmautDescription =>
      'Día de la Independencia de Israel';

  @override
  String get jewishCalendarHolidayYomYerushalayimName => 'Yom Yerushalayim';

  @override
  String get jewishCalendarHolidayYomYerushalayimDescription =>
      'Día de la reunificación de Jerusalén';

  @override
  String get jewishCalendarHolidayLagBaomerName => 'Lag BaOmer';

  @override
  String get jewishCalendarHolidayLagBaomerDescription => 'Día 33 del Omer';

  @override
  String get jewishCalendarHolidayShavuotName => 'Shavuot';

  @override
  String get jewishCalendarHolidayShavuotDescription => 'Entrega de la Torá';

  @override
  String get jewishCalendarIdeaFestiveDinner => 'Cena festiva';

  @override
  String get jewishCalendarIdeaTashlich => 'Tashlij juntos';

  @override
  String get jewishCalendarIdeaMutualForgiveness => 'Pedirse perdón mutuamente';

  @override
  String get jewishCalendarIdeaBuildSukkah => 'Construir la sucá juntos';

  @override
  String get jewishCalendarIdeaInviteFriends => 'Invitar a amigos';

  @override
  String get jewishCalendarIdeaPrayerForRain => 'Oración por la lluvia';

  @override
  String get jewishCalendarIdeaDanceWithTorah => 'Bailar con la Torá';

  @override
  String get jewishCalendarIdeaLightCandlesTogether =>
      'Encender las velas juntos';

  @override
  String get jewishCalendarIdeaHomemadeSufganiyot => 'Sufganiot caseras';

  @override
  String get jewishCalendarIdeaCoupleCostumes => 'Disfraces en pareja';

  @override
  String get jewishCalendarIdeaMishloachManot => 'Mishloaj Manot juntos';

  @override
  String get jewishCalendarIdeaRomanticSeder => 'Séder romántico';

  @override
  String get jewishCalendarIdeaTripToIsrael => 'Viaje a Israel';

  @override
  String get jewishCalendarIdeaIsraeliBarbecue => 'Barbacoa israelí';

  @override
  String get jewishCalendarIdeaConcertOrParty => 'Concierto o fiesta';

  @override
  String get jewishCalendarIdeaCampfire => 'Hoguera';

  @override
  String get jewishCalendarIdeaPicnic => 'Pícnic';

  @override
  String get jewishCalendarIdeaHomemadeCheesecake => 'Tarta de queso casera';

  @override
  String get jewishCalendarIdeaStudyNight => 'Noche de estudio';

  @override
  String get jewishCalendarParshaBereshis => 'Bereshit';

  @override
  String get jewishCalendarParshaNoach => 'Noaj';

  @override
  String get jewishCalendarParshaLechLecha => 'Lej Lejá';

  @override
  String get jewishCalendarParshaVayera => 'Vayerá';

  @override
  String get jewishCalendarParshaChayeiSara => 'Jayei Sará';

  @override
  String get jewishCalendarParshaToldos => 'Toldot';

  @override
  String get jewishCalendarParshaVayetzei => 'Vayetzé';

  @override
  String get jewishCalendarParshaVayishlach => 'Vayishlaj';

  @override
  String get jewishCalendarParshaVayeshev => 'Vayeshev';

  @override
  String get jewishCalendarParshaMiketz => 'Miketz';

  @override
  String get jewishCalendarParshaVayigash => 'Vayigash';

  @override
  String get jewishCalendarParshaVayechi => 'Vayjí';

  @override
  String get jewishCalendarParshaShemos => 'Shemot';

  @override
  String get jewishCalendarParshaVaera => 'Vaerá';

  @override
  String get jewishCalendarParshaBo => 'Bo';

  @override
  String get jewishCalendarParshaBeshalach => 'Beshalaj';

  @override
  String get jewishCalendarParshaYisro => 'Yitró';

  @override
  String get jewishCalendarParshaMishpatim => 'Mishpatim';

  @override
  String get jewishCalendarParshaTerumah => 'Terumá';

  @override
  String get jewishCalendarParshaTetzaveh => 'Tetzavé';

  @override
  String get jewishCalendarParshaKiSisa => 'Ki Tisá';

  @override
  String get jewishCalendarParshaVayakhel => 'Vayakhel';

  @override
  String get jewishCalendarParshaPekudei => 'Pekudei';

  @override
  String get jewishCalendarParshaVayikra => 'Vayikrá';

  @override
  String get jewishCalendarParshaTzav => 'Tzav';

  @override
  String get jewishCalendarParshaShmini => 'Shemini';

  @override
  String get jewishCalendarParshaTazria => 'Tazría';

  @override
  String get jewishCalendarParshaMetzora => 'Metzorá';

  @override
  String get jewishCalendarParshaAchreiMos => 'Ajarei Mot';

  @override
  String get jewishCalendarParshaKedoshim => 'Kedoshim';

  @override
  String get jewishCalendarParshaEmor => 'Emor';

  @override
  String get jewishCalendarParshaBehar => 'Behar';

  @override
  String get jewishCalendarParshaBechukosai => 'Bejukotai';

  @override
  String get jewishCalendarParshaBamidbar => 'Bamidbar';

  @override
  String get jewishCalendarParshaNasso => 'Nasó';

  @override
  String get jewishCalendarParshaBehaaloscha => 'Behaalotejá';

  @override
  String get jewishCalendarParshaShlach => 'Shelaj';

  @override
  String get jewishCalendarParshaKorach => 'Kóraj';

  @override
  String get jewishCalendarParshaChukas => 'Jukat';

  @override
  String get jewishCalendarParshaBalak => 'Balak';

  @override
  String get jewishCalendarParshaPinchas => 'Pinjás';

  @override
  String get jewishCalendarParshaMatos => 'Matot';

  @override
  String get jewishCalendarParshaMasei => 'Masei';

  @override
  String get jewishCalendarParshaDevarim => 'Devarim';

  @override
  String get jewishCalendarParshaVaeschanan => 'Vaetjanán';

  @override
  String get jewishCalendarParshaEikev => 'Ékev';

  @override
  String get jewishCalendarParshaReeh => 'Reé';

  @override
  String get jewishCalendarParshaShoftim => 'Shoftim';

  @override
  String get jewishCalendarParshaKiSeitzei => 'Ki Tetzé';

  @override
  String get jewishCalendarParshaKiSavo => 'Ki Tavó';

  @override
  String get jewishCalendarParshaNitzavim => 'Nitzavim';

  @override
  String get jewishCalendarParshaVayeilech => 'Vayélej';

  @override
  String get jewishCalendarParshaHaazinu => 'Haazinu';

  @override
  String get jewishCalendarParshaVzosHaberacha => 'Vezot Haberajá';

  @override
  String get layoutPaneChatTitle => 'Elige una conversación';

  @override
  String get layoutPaneChatMessage => 'Se abre aquí, junto a la lista.';

  @override
  String get layoutPaneProfileTitle => 'Elige un match';

  @override
  String get layoutPaneProfileMessage =>
      'Su perfil se muestra aquí, junto a la lista.';

  @override
  String get likesTitle => 'Likes';

  @override
  String likesSection(String count) {
    return 'Les gustas · $count';
  }

  @override
  String likesWaiting(int count, String label) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$label personas esperan tu respuesta.',
      one: '$label persona espera tu respuesta.',
    );
    return '$_temp0';
  }

  @override
  String get likesSeeWhoWithPlus => 'Ver quién te ha dado like con mazl+';

  @override
  String likesMatchWith(String name) {
    return 'Match con $name';
  }

  @override
  String likesYouLiked(String name) {
    return 'Le has dado like a $name';
  }

  @override
  String get likesEmptyTitle => 'Aún no hay likes';

  @override
  String get likesEmptyBody =>
      'Sigue descubriendo perfiles y completa el tuyo para recibir más likes.';

  @override
  String get likesEmptyAction => 'Descubrir perfiles';

  @override
  String get likesPremiumBody =>
      'Descubre quién te ha dado like y haz match al instante con las personas que te gusten.';

  @override
  String get likesPremiumOffers => 'Ver planes';

  @override
  String likesCardOpen(String title) {
    return 'Ver el like de $title';
  }

  @override
  String likesCardPass(String name) {
    return 'Pasar de $name';
  }

  @override
  String likesCardLike(String name) {
    return 'Dar like a $name';
  }

  @override
  String get likesLockedLabel => 'Perfil oculto';

  @override
  String get likesLockedHint => 'Disponible con mazl+';

  @override
  String likesDistance(int km) {
    return '$km km';
  }

  @override
  String get matchingDiscoverDailyPicks => 'Selecciones del día';

  @override
  String get matchingFilters => 'Filtros';

  @override
  String get matchingDiscoverEmptyTitle => 'Ya has visto todos los perfiles.';

  @override
  String get matchingDiscoverEmptyBody =>
      'Vuelve más tarde o amplía tus filtros para ver perfiles nuevos.';

  @override
  String get matchingDiscoverOpenFilters => 'Abrir filtros';

  @override
  String get matchingDiscoverRefresh => 'Actualizar';

  @override
  String get matchingDiscoverUndo => 'Deshacer';

  @override
  String get matchingDiscoverSuperLike => 'Super like';

  @override
  String get matchingDiscoverBoost => 'Boost';

  @override
  String matchingDiscoverBoostOn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutos',
      one: '$minutes minuto',
    );
    return 'Boost activado. Estás en lo más alto durante $_temp0.';
  }

  @override
  String get matchingDiscoverBoostFailed => 'No se pudo activar el Boost';

  @override
  String get matchingCardPass => 'Pasar';

  @override
  String get matchingCardLike => 'Me gusta';

  @override
  String get matchingCardViewProfile => 'Ver perfil';

  @override
  String get matchingCardAnonymous => 'Sin nombre';

  @override
  String matchingCardDistance(int km) {
    return 'a $km km';
  }

  @override
  String get matchingCardVerified => 'Perfil verificado';

  @override
  String matchingAvatarNewMatch(String name) {
    return 'Nuevo match, $name';
  }

  @override
  String matchingAvatarMatch(String name) {
    return 'Match, $name';
  }

  @override
  String get matchingMatchTitle => '¡Es un match!';

  @override
  String matchingMatchLineNamed(String name) {
    return '$name y tú os habéis gustado.';
  }

  @override
  String get matchingMatchLineAnonymous => 'Os habéis gustado.';

  @override
  String get matchingMatchSendMessage => 'Enviar un mensaje';

  @override
  String get matchingMatchKeepDiscovering => 'Seguir descubriendo';

  @override
  String matchingSeeMoreWithPlus(int count) {
    return 'Ver $count más con mazl+';
  }

  @override
  String get matchingMatchesTitle => 'Matches';

  @override
  String get matchingMatchesWhoLikedYou => 'Quién te ha dado like';

  @override
  String matchingMatchesNewSection(int count) {
    return 'Nuevos · $count';
  }

  @override
  String matchingMatchesConversationsSection(int count) {
    return 'Conversaciones · $count';
  }

  @override
  String get matchingMatchesLoadFailed => 'No se pudieron cargar los matches';

  @override
  String get matchingMatchesEmptyTitle => 'Aún no tienes matches';

  @override
  String get matchingMatchesEmptyBody => 'Sigue descubriendo perfiles.';

  @override
  String get matchingMatchesUnknownName => 'Sin nombre';

  @override
  String get matchingMatchesWriteHint => 'Escríbele';

  @override
  String matchingMatchesViewProfileOf(String name) {
    return 'Ver el perfil de $name';
  }

  @override
  String matchingMatchesSeeMore(int count) {
    return 'Ver $count más';
  }

  @override
  String matchingMatchedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count días',
      one: 'Hace $count día',
    );
    return '$_temp0';
  }

  @override
  String matchingMatchedWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count semanas',
      one: 'Hace $count semana',
    );
    return '$_temp0';
  }

  @override
  String matchingMatchedMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count meses',
      one: 'Hace $count mes',
    );
    return '$_temp0';
  }

  @override
  String get matchingCouplePromoTitle => '¿Ha habido match?';

  @override
  String get matchingCouplePromoDismiss => 'Ocultar';

  @override
  String get matchingCouplePromoBody =>
      'Preguntas diarias, etapas y calendario judío compartido: construye tu relación con mazl.';

  @override
  String get matchingCouplePromoAction => 'Activar el modo pareja';

  @override
  String get matchingPicksSeenAll => 'Has visto todas tus selecciones.';

  @override
  String matchingPicksNextIn(int hours, int minutes) {
    return 'Próximas selecciones en $hours h $minutes min';
  }

  @override
  String matchingPicksUpdatedIn(int hours, int minutes) {
    return 'Se actualiza en $hours h $minutes min';
  }

  @override
  String matchingPicksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perfiles seleccionados para ti',
      one: '$count perfil seleccionado para ti',
    );
    return '$_temp0';
  }

  @override
  String get matchingPicksDiscoverMore => 'Descubrir más perfiles';

  @override
  String get matchingPicksBadge => 'Selección';

  @override
  String get matchingFiltersReset => 'Restablecer';

  @override
  String get matchingFiltersAge => 'Rango de edad';

  @override
  String matchingFiltersYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count años',
      one: '$count año',
    );
    return '$_temp0';
  }

  @override
  String get matchingFiltersDistance => 'Distancia máxima';

  @override
  String matchingFiltersKm(int count) {
    return '$count km';
  }

  @override
  String get matchingFiltersDenomination => 'Corriente religiosa';

  @override
  String get matchingFiltersDenominationAll => 'Todas';

  @override
  String get matchingFiltersDenominationOrthodox => 'Ortodoxo';

  @override
  String get matchingFiltersDenominationMasorti => 'Masortí';

  @override
  String get matchingFiltersDenominationLiberal => 'Liberal';

  @override
  String get matchingFiltersDenominationTraditional => 'Tradicionalista';

  @override
  String get matchingFiltersDenominationChabad => 'Jabad';

  @override
  String get matchingFiltersDenominationSephardi => 'Sefardí';

  @override
  String get matchingFiltersDenominationAshkenazi => 'Asquenazí';

  @override
  String get matchingFiltersObservances => 'Prácticas religiosas';

  @override
  String get matchingFiltersShabbat => 'Shomer Shabat';

  @override
  String get matchingFiltersKosher => 'Kosher';

  @override
  String get matchingFiltersKosherStrict => 'Kosher estricto';

  @override
  String get matchingFiltersDailyPrayer => 'Oración diaria';

  @override
  String get matchingFiltersMikveh => 'Mikve';

  @override
  String get matchingFiltersTzniut => 'Tzniut';

  @override
  String get matchingFiltersEducation => 'Nivel de estudios';

  @override
  String get matchingFiltersEducationAll => 'Todos';

  @override
  String get matchingFiltersEducationHighSchool => 'Instituto';

  @override
  String get matchingFiltersEducationBaccalaureate => 'Bachillerato';

  @override
  String get matchingFiltersEducationBachelor => 'Grado';

  @override
  String get matchingFiltersEducationMaster => 'Máster';

  @override
  String get matchingFiltersEducationDoctorate => 'Doctorado';

  @override
  String get matchingFiltersEducationYeshiva => 'Yeshivá / Seminario';

  @override
  String get matchingFiltersHeight => 'Altura';

  @override
  String get matchingFiltersHeightMin => 'Mín.';

  @override
  String get matchingFiltersHeightMax => 'Máx.';

  @override
  String matchingFiltersCm(int count) {
    return '$count cm';
  }

  @override
  String get matchingFiltersHeightClear => 'Quitar el filtro de altura';

  @override
  String get matchingFiltersOptions => 'Opciones';

  @override
  String get matchingFiltersVerifiedTitle => 'Solo perfiles verificados';

  @override
  String get matchingFiltersVerifiedHint => 'Ver solo perfiles verificados';

  @override
  String get matchingFiltersPhotoTitle => 'Solo con foto';

  @override
  String get matchingFiltersPhotoHint => 'Excluir perfiles sin foto';

  @override
  String get matchingFiltersOnlineTitle => 'En línea ahora';

  @override
  String get matchingFiltersOnlineHint => 'Ver a quienes están activos';

  @override
  String get matchingFiltersUpsellTitle => 'Desbloquea todos los filtros';

  @override
  String get matchingFiltersUpsellBody =>
      'Pásate a mazl+ para búsquedas precisas';

  @override
  String get matchingFiltersApply => 'Aplicar filtros';

  @override
  String get matchingFiltersSaved => 'Filtros guardados';

  @override
  String get matchingFiltersSaveFailed => 'Error al guardar';

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
  String get onboardingStart => 'Empezar';

  @override
  String onboardingStep(String current, String total) {
    return '$current / $total';
  }

  @override
  String onboardingPageOf(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get onboardingPage1Title => 'Te damos la bienvenida a MAZL';

  @override
  String get onboardingPage1Body =>
      'La app de citas pensada para la comunidad judía.';

  @override
  String get onboardingPage2Title => 'Encuentra tu mazal';

  @override
  String get onboardingPage2Body =>
      'Descubre perfiles compatibles con tus valores y tu práctica religiosa.';

  @override
  String get onboardingPage3Title => 'Modo pareja';

  @override
  String get onboardingPage3Body =>
      'Cuando encuentras el amor, MAZL te acompaña: encuentra el amor y consérvalo.';

  @override
  String get onboardingPage3Feature1 => 'Preguntas diarias';

  @override
  String get onboardingPage3Feature2 => 'Hitos de pareja';

  @override
  String get onboardingPage3Feature3 => 'Calendario judío compartido';

  @override
  String get onboardingPage3Feature4 => 'Actividades y sugerencias';

  @override
  String get onboardingPage4Title => 'Modo Shabat';

  @override
  String get onboardingPage4Body =>
      'Una pausa automática durante Shabat y las fiestas, sin configurar nada.';

  @override
  String get onboardingPage5Title => 'AI Shadchan';

  @override
  String get onboardingPage5Body =>
      'Nuestra inteligencia artificial te ayuda a encontrar a la persona adecuada.';

  @override
  String get packsSuperLikesLabel => 'Super likes';

  @override
  String get packsSuperLikesTitle => 'Te has quedado sin super likes.';

  @override
  String get packsSuperLikesSubtitle =>
      'Consigue más: los que compras no caducan nunca.';

  @override
  String get packsBoostsLabel => 'Boosts';

  @override
  String get packsBoostsTitle => 'Te has quedado sin Boosts.';

  @override
  String packsBoostsSubtitle(int minutes) {
    return 'Pon tu perfil en cabeza durante $minutes min. Un Boost comprado no caduca nunca.';
  }

  @override
  String packsPackSuperLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Super Likes',
      one: '$count Super Like',
    );
    return '$_temp0';
  }

  @override
  String packsPackBoosts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Boosts',
      one: '$count Boost',
    );
    return '$_temp0';
  }

  @override
  String packsPackSemantics(String quantity, String price) {
    return 'Comprar $quantity por $price';
  }

  @override
  String get packsLoading => 'Cargando las ofertas';

  @override
  String get packsStoreUnavailable =>
      'La tienda no está disponible ahora mismo. Inténtalo de nuevo en un momento.';

  @override
  String get packsPending =>
      'Compra pendiente de aprobación. Tu saldo se actualizará en cuanto se valide.';

  @override
  String get packsBoostAlreadyActive => 'Ya hay un Boost en marcha.';

  @override
  String get packsErrorExhausted => 'Ahora mismo no te queda ninguno.';

  @override
  String get plusFeatureUnlimitedLikesTitle => 'Likes ilimitados';

  @override
  String get plusFeatureUnlimitedLikesDescription =>
      'Da like tanto como quieras, sin límite diario.';

  @override
  String get plusFeatureSeeWhoLikesYouTitle => 'Ver quién te ha dado like';

  @override
  String get plusFeatureSeeWhoLikesYouDescription =>
      'Descubre quién te ha dado like antes incluso de cruzarte con esa persona.';

  @override
  String get plusFeatureSuperLikesTitle => 'Super likes';

  @override
  String get plusFeatureSuperLikesDescription =>
      'Destaca con 5 super likes al día.';

  @override
  String get plusFeatureBoostTitle => 'Boost';

  @override
  String get plusFeatureBoostDescription =>
      'Ponte a la cabeza durante 30 minutos.';

  @override
  String get plusFeatureRewindTitle => 'Retroceder';

  @override
  String get plusFeatureRewindDescription =>
      'Recupera un «Pasar» demasiado rápido.';

  @override
  String get plusFeatureReadReceiptsTitle => 'Confirmaciones de lectura';

  @override
  String get plusFeatureReadReceiptsDescription =>
      'Sabe cuándo se han leído tus mensajes.';

  @override
  String get plusFeatureAdvancedFiltersTitle => 'Filtros avanzados';

  @override
  String get plusFeatureAdvancedFiltersDescription =>
      'Filtra por práctica, comunidad y más.';

  @override
  String get plusFeaturePrioritySupportTitle => 'Soporte prioritario';

  @override
  String get plusFeaturePrioritySupportDescription =>
      'Recibe una respuesta rápida de nuestro equipo.';

  @override
  String get plusReservedLabel => 'Reservado a mazl+';

  @override
  String get plusDiscover => 'Descubrir mazl+';

  @override
  String get plusNotNow => 'Ahora no';

  @override
  String plusDailyLimitLabel(int limit) {
    return 'Límite del día · $limit / $limit';
  }

  @override
  String get plusDailyLimitTitle => 'Tus likes de hoy se han agotado.';

  @override
  String get plusDailyLimitBody =>
      'Vuelven a medianoche. O sigue sin contar y descubre quién ya te ha dado like.';

  @override
  String get plusDailyLimitNext => 'Próximos likes en';

  @override
  String get plusDailyLimitWait => 'Esperar a medianoche';

  @override
  String get plusOfferTagline => 'Conoce gente sin contar.';

  @override
  String get plusPerkUnlimitedLikesDetail => 'Se acabaron los 10 al día.';

  @override
  String get plusPerkSeeWhoDetail => 'Antes incluso de cruzarte con ellos.';

  @override
  String get plusPerkSuperLikesTitle => '5 super likes al día';

  @override
  String get plusPerkSuperLikesDetail => 'En lugar de uno solo.';

  @override
  String get plusPerkBoostTitle => 'Un Boost al día';

  @override
  String get plusPerkBoostDetail => 'A la cabeza durante 30 minutos.';

  @override
  String get plusPerkFiltersDetail => 'Práctica, comunidad y más.';

  @override
  String get plusYourPlan => 'Tu plan';

  @override
  String plusMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months meses',
      one: '1 mes',
    );
    return '$_temp0';
  }

  @override
  String plusPerMonth(String price) {
    return '$price al mes';
  }

  @override
  String plusPlanSavings(int percent) {
    return '-$percent %';
  }

  @override
  String plusPlanSemantics(String duration, String price, String perMonth) {
    return '$duration, $price, $perMonth';
  }

  @override
  String plusPlanSemanticsSaving(
    String duration,
    String price,
    String perMonth,
    String saving,
  ) {
    return '$duration, $price, $perMonth, ahorro $saving';
  }

  @override
  String plusContinuePrice(String price) {
    return 'Continuar · $price';
  }

  @override
  String get plusAndroidSoon => 'Próximamente en Android';

  @override
  String get plusRestore => 'Restaurar';

  @override
  String get plusTerms => 'Condiciones';

  @override
  String get plusPrivacy => 'Privacidad';

  @override
  String get plusLegalAppStore =>
      'Renovación automática, cancelable en cualquier momento en los ajustes de App Store.';

  @override
  String get plusLegalGooglePlay =>
      'Renovación automática, cancelable en cualquier momento en los ajustes de Google Play.';

  @override
  String get plusPendingApproval =>
      'Compra pendiente de aprobación. Tu suscripción se activará en cuanto se valide.';

  @override
  String get plusOfferRestored => 'Suscripción restaurada';

  @override
  String get plusOfferNothingFound => 'No se ha encontrado ninguna suscripción';

  @override
  String get plusPlansSoon =>
      'Las suscripciones estarán disponibles próximamente.';

  @override
  String get plusErrorPurchaseInProgress => 'Ya hay una compra en curso.';

  @override
  String get plusErrorOwnedByAnotherAccount =>
      'Esta compra de App Store ya está asociada a otra cuenta de mazl.';

  @override
  String get plusErrorInvalidTransaction =>
      'No hemos podido validar esta compra con App Store. Se volverá a comprobar en el próximo inicio.';

  @override
  String get plusErrorInvalidBody =>
      'Tu compra no se ha podido enviar correctamente. Inténtalo de nuevo en un momento.';

  @override
  String get plusErrorSignInAgain =>
      'Vuelve a iniciar sesión en mazl para completar tu compra.';

  @override
  String get plusErrorOffline =>
      'No hay conexión. Tu compra se conserva y se validará en cuanto sea posible.';

  @override
  String get plusErrorGeneric =>
      'La compra no se ha podido completar. Inténtalo de nuevo en un momento.';

  @override
  String get plusErrorInactive => 'Tu suscripción no está activa.';

  @override
  String get plusErrorRestoreFailed =>
      'La restauración ha fallado. Inténtalo de nuevo en un momento.';

  @override
  String get plusActiveSubscription => 'Suscripción activa';

  @override
  String plusActiveSubscriptionPlan(String plan) {
    return 'Suscripción activa · $plan';
  }

  @override
  String get plusWelcomeTitle => 'Te damos la bienvenida a mazl+.';

  @override
  String get plusWelcomeSubtitle =>
      'Todo está desbloqueado. ¿Por dónde quieres empezar?';

  @override
  String plusWelcomeLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas te han dado like',
      one: '1 persona te ha dado like',
    );
    return '$_temp0';
  }

  @override
  String get plusWelcomeLikesDetail => 'Verlos ahora';

  @override
  String get plusWelcomeBoostTitle => 'Lanzar tu Boost';

  @override
  String get plusWelcomeBoostDetail => 'A la cabeza durante 30 minutos';

  @override
  String get plusWelcomeFiltersTitle => 'Afinar tus filtros';

  @override
  String get plusWelcomeFiltersDetail => 'Práctica, comunidad y más';

  @override
  String plusTitleDetail(String title, String detail) {
    return '$title. $detail';
  }

  @override
  String get plusSubscriptionTitle => 'Suscripción';

  @override
  String get plusStatusActive => 'Activa';

  @override
  String get plusStatusCancelled => 'Cancelada';

  @override
  String get plusFactPlan => 'Plan';

  @override
  String get plusFactRenewal => 'Renovación';

  @override
  String get plusFactExpiration => 'Caducidad';

  @override
  String plusPlanAndPrice(String duration, String price) {
    return '$duration · $price';
  }

  @override
  String plusSuperLikesOf(int left, int max) {
    return '$left de $max';
  }

  @override
  String get plusBoostAvailable => 'Disponible';

  @override
  String get plusBoostUsed => 'Usado hoy';

  @override
  String get plusLikesLabel => 'Likes';

  @override
  String get plusLikesUnlimited => 'Ilimitados';

  @override
  String get plusManageAppStore => 'Gestionar en App Store';

  @override
  String get plusManageGooglePlay => 'Gestionar en Google Play';

  @override
  String get plusManageFailed =>
      'No se ha podido abrir la gestión de la suscripción.';

  @override
  String get plusRestorePurchases => 'Restaurar mis compras';

  @override
  String get plusNoActiveSubscription => 'No hay ninguna suscripción activa.';

  @override
  String get plusPurchasesRestored => 'Compras restauradas.';

  @override
  String get plusNothingToRestore => 'No se ha encontrado ninguna suscripción.';

  @override
  String get plusSettingsPitch =>
      'Likes ilimitados, ver quién te ha dado like, Boost';

  @override
  String get plusUpgradeTo => 'Pasar a mazl+';

  @override
  String plusSettingsSemanticsActive(String detail) {
    return 'mazl+. $detail';
  }

  @override
  String plusSettingsSemanticsUpgrade(String detail) {
    return 'Pasar a mazl+. $detail';
  }

  @override
  String get privacyGateUnverifiable =>
      'No hemos podido comprobar tu consentimiento. Revisa tu conexión.';

  @override
  String get privacyGateAsk => 'Para indicar tu práctica, da tu consentimiento';

  @override
  String get privacyGive => 'Dar mi consentimiento';

  @override
  String get privacyLockedHint =>
      'Disponible cuando des tu consentimiento para los datos de práctica religiosa.';

  @override
  String get privacySheetLabel => 'Datos sensibles · RGPD, artículo 9';

  @override
  String get privacySheetTitle =>
      'Tu práctica religiosa, con tu consentimiento';

  @override
  String get privacySheetBody =>
      'Esta información ayuda a proponerte perfiles compatibles. Son datos sensibles, tratados solo con tu consentimiento explícito, distinto de las condiciones de uso. Puedes rechazar y usar MAZL igualmente.';

  @override
  String get privacySheetCheckbox =>
      'He leído este texto y doy mi consentimiento explícito.';

  @override
  String get privacySheetAccept => 'Acepto';

  @override
  String get privacySheetDecline => 'Continuar sin';

  @override
  String get privacySheetErrorOutdated =>
      'El texto se ha actualizado. Cierra esta ventana y vuelve a abrirla.';

  @override
  String get privacySheetErrorSave =>
      'No se ha podido guardar tu elección. Inténtalo de nuevo.';

  @override
  String get privacySettingsTitle => 'Datos de práctica religiosa';

  @override
  String get privacySettingsGrantedShort => 'Concedido';

  @override
  String get privacySettingsDeniedShort => 'No concedido';

  @override
  String get privacySettingsGrantedTitle => 'Consentimiento dado';

  @override
  String get privacySettingsNotGrantedTitle => 'Consentimiento no dado';

  @override
  String get privacySettingsWithdraw => 'Retirar mi consentimiento';

  @override
  String get privacySettingsWithdrawTitle => '¿Retirar tu consentimiento?';

  @override
  String get privacySettingsWithdrawBody =>
      'Tu corriente, tu kashrut, tu práctica del Shabat y tu intención se borrarán de tu perfil.';

  @override
  String get privacySettingsWithdrawFailed =>
      'No se ha podido retirar tu consentimiento. Inténtalo de nuevo.';

  @override
  String get privacySettingsLoadFailed =>
      'No hemos podido cargar tu consentimiento. Revisa tu conexión.';

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
  String get profileChoiceNotSent =>
      'Tu elección no se ha enviado. Inténtalo de nuevo.';

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

  @override
  String get settingsRestoreNothing => 'No se encontró ninguna suscripción.';

  @override
  String get shadchanTitle => 'Shadchan IA';

  @override
  String get shadchanHeaderTitle => 'Tu Shadchan personal';

  @override
  String get shadchanHeaderBody =>
      'Nuestra IA analiza tus preferencias para proponerte perfiles muy compatibles';

  @override
  String get shadchanTodayTitle => 'Sugerencias del día';

  @override
  String shadchanNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuevas',
      one: '$count nueva',
    );
    return '$_temp0';
  }

  @override
  String get shadchanEmptyTitle => 'Has repasado todas tus sugerencias.';

  @override
  String get shadchanEmptyBody =>
      'Vuelve mañana para ver nuevas propuestas de tu Shadchan.';

  @override
  String get shadchanEmptyAction => 'Descubrir más perfiles';

  @override
  String shadchanPassed(String name) {
    return 'Has descartado a $name';
  }

  @override
  String shadchanLiked(String name) {
    return 'Has añadido a $name a tus likes';
  }

  @override
  String get shadchanHowTitle => '¿Cómo funciona?';

  @override
  String get shadchanHowStepAnalyze =>
      'Nuestra IA analiza tu perfil y tus preferencias';

  @override
  String get shadchanHowStepCompare =>
      'Los compara con los perfiles compatibles';

  @override
  String get shadchanHowStepDaily =>
      'Recibes sugerencias personalizadas cada día';

  @override
  String get shadchanWhy => '¿Por qué esta sugerencia?';

  @override
  String get shadchanMatchBadge => 'Match';

  @override
  String get shadchanReasonSamePractice => 'Mismo nivel de práctica';

  @override
  String get shadchanReasonInterests => 'Intereses en común: viajes, cocina';

  @override
  String get shadchanReasonGoals => 'Objetivos parecidos';

  @override
  String get shadchanReasonFamily => 'Valores familiares alineados';

  @override
  String get shadchanReasonMusic => 'Pasión compartida por la música';

  @override
  String get shadchanReasonLocation => 'Zonas de residencia compatibles';

  @override
  String get shadchanReasonReligion => 'Práctica religiosa parecida';

  @override
  String get shadchanReasonProfession => 'Sectores profesionales cercanos';

  @override
  String get shadchanReasonCouple => 'La misma visión de la pareja';

  @override
  String get verificationProfileEyebrow => 'Tu perfil';

  @override
  String get verificationTitle => 'Verificación';

  @override
  String get verificationLevel1 => 'Nivel 1';

  @override
  String get verificationLevel2 => 'Nivel 2';

  @override
  String get verificationPhotoTitle => 'Foto verificada';

  @override
  String get verificationIdentityTitle => 'Identidad verificada';

  @override
  String get verificationVerifiedPill => 'Verificada';

  @override
  String get verificationConsent =>
      'Comparamos tu rostro con tus fotos. Las imágenes no se guardan; solo se conserva una huella cifrada, que puedes borrar en cualquier momento.';

  @override
  String get verificationPhotoVerifiedLine =>
      'Tu rostro coincide con tus fotos.';

  @override
  String verificationPhotoVerifiedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Verificada el $dateString.';
  }

  @override
  String get verificationRemoveAction => 'Quitar mi verificación';

  @override
  String get verificationVerifyPhotoAction => 'Verificar mi foto';

  @override
  String get verificationVerifyIdentityAction => 'Verificar mi identidad';

  @override
  String verificationBlockedToday(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Límite alcanzado, podrás volver a intentarlo a las $timeString.';
  }

  @override
  String verificationBlockedLater(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Límite alcanzado, podrás volver a intentarlo el $dateString a las $timeString.';
  }

  @override
  String get verificationIdentityCheckedNoDate =>
      'Documento comprobado mediante su chip.';

  @override
  String verificationIdentityCheckedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Comprobada el $dateString.';
  }

  @override
  String get verificationIdentityPitch =>
      'Pasaporte o documento de identidad, leído a través de su chip. Un selfie confirma que eres tú.';

  @override
  String get verificationRemoveDialogTitle => '¿Quitar mi verificación?';

  @override
  String get verificationRemoveDialogBody =>
      'Tu insignia y la huella de tu rostro se eliminarán.';

  @override
  String verificationPhotosMismatch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de tus fotos no se parecen a ti: no cuentan.',
      one: 'Una de tus fotos no se parece a ti: no cuenta.',
    );
    return '$_temp0';
  }

  @override
  String get verificationLivenessFront => 'Mira a la cámara';

  @override
  String get verificationLivenessLeft =>
      'Gira despacio la cabeza hacia la izquierda';

  @override
  String get verificationLivenessRight =>
      'Gira despacio la cabeza hacia la derecha';

  @override
  String get verificationLivenessHintNoFace =>
      'Coloca tu rostro dentro del círculo';

  @override
  String get verificationLivenessHintMultipleFaces =>
      'Solo una persona en el encuadre';

  @override
  String get verificationLivenessHintTooSmall => 'Acércate un poco';

  @override
  String get verificationLivenessHintOffCenter =>
      'Centra tu rostro en el círculo';

  @override
  String get verificationLivenessHintLookStraight => 'Mira al frente';

  @override
  String get verificationLivenessHintTurnMore => 'Gira un poco más';

  @override
  String get verificationLivenessHintTurnLess => 'No tanto, vuelve un poco';

  @override
  String get verificationLivenessHintTurnOtherWay => 'Gira hacia el otro lado';

  @override
  String verificationLivenessPoseCounter(int current, int total) {
    return 'Pose $current / $total';
  }

  @override
  String verificationLivenessPosesTaken(int done, int total) {
    return 'Poses capturadas: $done de $total';
  }

  @override
  String get verificationLivenessPrivacy =>
      'Solo en el encuadre y con buena luz. Las imágenes no se guardan.';

  @override
  String get verificationLivenessExpiredTitle => 'Sesión caducada';

  @override
  String get verificationLivenessExpiredBody =>
      'Se acabó el tiempo disponible. Puedes volver a empezar.';

  @override
  String get verificationCameraNeededTitle => 'Cámara necesaria';

  @override
  String get verificationCameraNeededBody =>
      'MAZL usa la cámara frontal para comprobar que eres la persona de tus fotos.';

  @override
  String get verificationCameraOpenSettings => 'Abrir ajustes';

  @override
  String get verificationCameraAllow => 'Permitir la cámara';

  @override
  String get verificationCameraUnavailableTitle => 'Cámara no disponible';

  @override
  String get verificationCameraUnavailableBody =>
      'No se pudo iniciar la cámara frontal.';

  @override
  String get verificationIntroTitle => 'Verifica tu identidad.';

  @override
  String get verificationIntroSubtitle =>
      'La insignia «Identidad verificada» indica a los demás que eres realmente la persona de las fotos. Necesitas un pasaporte o un documento de identidad biométrico, dos minutos y un poco de luz.';

  @override
  String get verificationIntroStep1 => 'Fotografiar la página de la foto';

  @override
  String get verificationIntroStep1Detail =>
      'Para leer las dos líneas de abajo.';

  @override
  String get verificationIntroStep2 => 'Apoyar el teléfono sobre el chip';

  @override
  String get verificationIntroStep2Detail =>
      'El chip firmado por el Estado es el que cuenta.';

  @override
  String get verificationIntroStep3 => 'Un selfie en movimiento';

  @override
  String get verificationIntroStep3Detail => 'Se compara con la foto del chip.';

  @override
  String get verificationIntroPrivacy =>
      'No se guarda nada: solo conservamos el resultado.';

  @override
  String get verificationIntroStart => 'Empezar';

  @override
  String verificationStepLabel(int step, int total) {
    return 'Paso $step / $total';
  }

  @override
  String get verificationScanTitle => 'Encuadra la página de la foto.';

  @override
  String get verificationScanHint =>
      'Bastan las dos líneas de «<» de abajo. Evita los reflejos.';

  @override
  String get verificationScanManual => 'Introducir a mano';

  @override
  String get verificationScanFrameSemantics =>
      'Vista previa de la cámara: coloca las dos líneas de abajo del documento dentro del marco resaltado';

  @override
  String get verificationCameraNotAvailable => 'La cámara no está disponible.';

  @override
  String get verificationScanUnavailableBody =>
      'Puedes introducir a mano los datos de la página de la foto.';

  @override
  String get verificationScanEnterDetails => 'Introducir los datos';

  @override
  String get verificationManualTitle => 'Introduce los datos.';

  @override
  String get verificationManualSubtitle =>
      'Cópialos de la página de la foto de tu documento.';

  @override
  String get verificationFieldDocumentNumber => 'Número de documento';

  @override
  String get verificationFieldBirthDate => 'Fecha de nacimiento';

  @override
  String get verificationFieldExpiryDate => 'Fecha de caducidad';

  @override
  String get verificationDateHint => 'DD/MM/AAAA';

  @override
  String get verificationManualUseCamera => 'Escanear con la cámara';

  @override
  String get verificationErrorDocumentNumber =>
      'Entre 5 y 12 letras o números.';

  @override
  String get verificationErrorInvalidDate => 'Fecha no válida.';

  @override
  String get verificationReviewTitle => 'Comprueba estos datos.';

  @override
  String get verificationReviewConfirm => 'Soy yo';

  @override
  String get verificationRescan => 'Escanear de nuevo';

  @override
  String get verificationNfcWaitingTitle =>
      'Apoya tu documento en el teléfono.';

  @override
  String get verificationNfcPlacement =>
      'La parte superior del teléfono contra la tapa cerrada del pasaporte, o contra el reverso del documento de identidad. Quita la funda si hace falta.';

  @override
  String get verificationNfcRead => 'Leer el documento';

  @override
  String get verificationNfcIllustration =>
      'La parte superior del teléfono apoyada contra la tapa cerrada del pasaporte';

  @override
  String get verificationNfcReadingTitle => 'No te muevas.';

  @override
  String get verificationNfcReadingSubtitle =>
      'Mantén el documento contra la parte superior del teléfono hasta que termine la lectura.';

  @override
  String get verificationNfcProgressLabel => 'Lectura del chip';

  @override
  String verificationNfcProgressValue(int percent) {
    return '$percent %';
  }

  @override
  String get verificationNfcStepDetect => 'Detección del documento';

  @override
  String get verificationNfcStepConnect => 'Conexión segura';

  @override
  String get verificationNfcStepPhoto => 'Lectura de la foto';

  @override
  String get verificationNfcStepSignature => 'Lectura de la firma';

  @override
  String verificationNfcStepSemantics(String label, String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'done': '$label, terminado',
      'active': '$label, en curso',
      'waiting': '$label, en espera',
      'other': '$label',
    });
    return '$_temp0';
  }

  @override
  String get verificationNfcSilentBody =>
      'Esto pasa a menudo en el primer intento. No se ha enviado nada.';

  @override
  String get verificationNfcRescanBody =>
      'No se ha enviado nada. Vuelve a leer la página de la foto para empezar con datos correctos.';

  @override
  String get verificationNfcTip1 => 'Quita la funda del teléfono.';

  @override
  String get verificationNfcTip2 =>
      'Apoya la parte superior del teléfono en el centro de la tapa, con el pasaporte cerrado.';

  @override
  String get verificationNfcTip3 => 'No te muevas durante unos diez segundos.';

  @override
  String get verificationNfcRereadPhotoPage =>
      'Volver a leer la página de la foto';

  @override
  String get verificationManualReviewLink =>
      'Enviar mi documento para revisión manual';

  @override
  String get verificationFaceTitle => 'Chip leído.';

  @override
  String get verificationFaceSubtitle =>
      'Solo queda un selfie en movimiento, que se compara con la foto del chip.';

  @override
  String get verificationFaceAction => 'Hacer el selfie';

  @override
  String get verificationSubmitSending => 'Verificación en curso…';

  @override
  String get verificationSubmitPreparing => 'Preparando…';

  @override
  String get verificationDoneTitle => 'Identidad verificada.';

  @override
  String get verificationDoneSubtitle =>
      'El chip de tu documento y tu selfie coinciden. Tu perfil ya tiene la insignia.';

  @override
  String get verificationDoneAction => 'Terminar';

  @override
  String get verificationBadgeLabel => 'Identidad verificada';

  @override
  String get verificationDoneBadgeCaption =>
      'Lo que ven los demás en tu perfil.';

  @override
  String get verificationDoneStoredLabel => 'Fotos y chip';

  @override
  String get verificationDoneStoredValue => 'Nunca se guardan';

  @override
  String get verificationDoneKeptLabel => 'Se conserva';

  @override
  String get verificationDoneKeptValue => 'País, caducidad, huella anónima';

  @override
  String get verificationDoneProfileLabel => 'Perfil';

  @override
  String get verificationDoneProfileValue =>
      'Fecha de nacimiento del documento';

  @override
  String get verificationComingSoon => 'Próximamente';

  @override
  String get verificationFailureChipDataInvalid =>
      'Los datos del chip son ilegibles.';

  @override
  String get verificationFailureChipSignatureInvalid =>
      'No se pudo verificar la firma del documento.';

  @override
  String get verificationFailureNotRecognized => 'Documento no reconocido.';

  @override
  String get verificationDocumentExpired => 'Este documento ha caducado.';

  @override
  String get verificationFailureUnderage =>
      'Hay que tener 18 años para verificar la identidad.';

  @override
  String get verificationDocumentAlreadyUsed =>
      'Este documento ya está asociado a otra cuenta.';

  @override
  String get verificationDocumentBanned => 'Este documento no se puede usar.';

  @override
  String get verificationDocumentFaceMismatch =>
      'Tu rostro no coincide con la foto del documento.';

  @override
  String get verificationFailureSessionExpired => 'La sesión ha caducado.';

  @override
  String get verificationFailureImagesUnreadable =>
      'No se pudieron leer las imágenes.';

  @override
  String get verificationFailureNoFace => 'No se ha detectado ningún rostro.';

  @override
  String get verificationFailureMultipleFaces =>
      'Solo debe aparecer un rostro.';

  @override
  String get verificationFailureFaceTooSmall => 'Acércate a la cámara.';

  @override
  String get verificationFailurePoseMismatch =>
      'No se reconocieron los movimientos pedidos.';

  @override
  String get verificationFailureDuplicateFrames =>
      'Mueve la cabeza como se te pide.';

  @override
  String get verificationFailureInconsistentIdentity =>
      'El rostro cambió durante la captura.';

  @override
  String get verificationFailureNoProfilePhoto =>
      'Primero añade una foto a tu perfil.';

  @override
  String get verificationFailureProfileMismatch =>
      'Tu rostro no coincide con tu foto de perfil.';

  @override
  String get verificationFailureDailyLimit =>
      'Has alcanzado el límite de intentos de hoy. Vuelve mañana.';

  @override
  String get verificationFailureGeneric => 'La verificación ha fallado.';

  @override
  String get verificationFailureNoNfc => 'Este teléfono no tiene lector NFC.';

  @override
  String get verificationFailureNfcDisabled =>
      'Activa el NFC en los ajustes del teléfono.';

  @override
  String get verificationFailureTagLost =>
      'El documento se ha movido. Mantenlo inmóvil contra el teléfono.';

  @override
  String get verificationFailureChipMismatch =>
      'Los datos introducidos no coinciden con el chip.';

  @override
  String get verificationFailureUnreadableDocument =>
      'Este documento no se puede leer.';

  @override
  String get verificationFailureChipSilent => 'El chip no ha respondido.';

  @override
  String get verificationFailureReadFailed => 'La lectura ha fallado.';

  @override
  String get verificationFailureConnection =>
      'No se puede conectar. Comprueba tu conexión.';

  @override
  String get verificationActionRereadDocument => 'Volver a leer el documento';

  @override
  String get verificationActionOtherDocument => 'Otro documento';

  @override
  String get verificationReasonNoFace =>
      'No se ha detectado ningún rostro. Colócate frente a la cámara, en un lugar bien iluminado.';

  @override
  String get verificationReasonMultipleFaces =>
      'Se han detectado varios rostros. Debe aparecer una sola persona en el encuadre.';

  @override
  String get verificationReasonFaceTooSmall =>
      'Tu rostro está demasiado lejos. Acércate a la cámara.';

  @override
  String get verificationReasonPoseMismatch =>
      'No se reconocieron las poses pedidas. Sigue bien las indicaciones.';

  @override
  String get verificationReasonDuplicateFrames =>
      'Las imágenes son demasiado parecidas. Mueve la cabeza como se te pide.';

  @override
  String get verificationReasonInconsistentIdentity =>
      'Las imágenes no muestran a la misma persona. Vuelve a empezar sin nadie más a tu lado.';

  @override
  String get verificationReasonNoProfilePhoto =>
      'Primero añade a tu perfil una foto en la que se vea bien tu rostro.';

  @override
  String get verificationReasonProfileMismatch =>
      'Tu rostro no coincide con tu foto principal. Elige una foto reciente en la que se te vea bien.';

  @override
  String get verificationReasonDailyLimit =>
      'Has alcanzado el límite de intentos de hoy. Vuelve mañana.';

  @override
  String get verificationReasonSessionExpired =>
      'La sesión ha caducado. Vuelve a empezar.';

  @override
  String get verificationReasonSessionInvalid =>
      'La sesión ya no es válida. Vuelve a empezar.';

  @override
  String get verificationReasonImagesUnreadable =>
      'No se pudieron leer las imágenes. Vuelve a empezar.';

  @override
  String get verificationReasonAppUpdate =>
      'Actualiza la aplicación para verificar tu perfil.';

  @override
  String get verificationReasonChipAuth =>
      'No se pudo autenticar el chip del documento.';

  @override
  String get verificationReasonUnderage => 'Debes tener al menos 18 años.';

  @override
  String get verificationReasonNetwork =>
      'No se puede conectar. Comprueba tu red e inténtalo de nuevo.';

  @override
  String get verificationReasonGeneric =>
      'Ha ocurrido un error. Inténtalo de nuevo en un momento.';

  @override
  String get verificationNfcAlertApproach =>
      'Acerca tu documento a la parte superior del teléfono.';

  @override
  String get verificationNfcAlertAuthenticating =>
      'No te muevas. Conexión segura…';

  @override
  String get verificationNfcAlertReadingPhoto => 'Leyendo la foto… 40 %';

  @override
  String get verificationNfcAlertReadingSignature => 'Leyendo la firma… 85 %';

  @override
  String get verificationNfcAlertDone => 'Terminado.';

  @override
  String get videoCallInProgress => 'Llamada en curso...';

  @override
  String get videoCallFlip => 'Girar';

  @override
  String get videoCallCamera => 'Cámara';

  @override
  String get videoCallMic => 'Micro';

  @override
  String get videoCallEnd => 'Finalizar';

  @override
  String get visitorsTitle => 'Quién ha visitado mi perfil';

  @override
  String visitorsTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visitas',
      one: '$count visita',
    );
    return '$_temp0';
  }

  @override
  String visitorsThisWeek(int count) {
    return '$count esta semana';
  }

  @override
  String get visitorsBannerTitle => 'Descubre quién te ha visitado';

  @override
  String get visitorsBannerBody => 'Pásate a mazl+ para ver los perfiles';

  @override
  String get visitorsEmptyTitle => 'Aún no hay visitas';

  @override
  String get visitorsEmptyBody =>
      'Completa tu perfil y usa un Boost para atraer más visitas.';

  @override
  String get visitorsEmptyAction => 'Activar un Boost';

  @override
  String get visitorsLockedTitle => 'Solo con mazl+';

  @override
  String get visitorsLockedBody =>
      'Pásate a mazl+ para descubrir quién ha visitado tu perfil y contactar con esas personas directamente.';

  @override
  String get visitorsLockedAction => 'Descubrir mazl+';

  @override
  String get visitorsNew => 'NUEVO';

  @override
  String visitorsAgoMinutes(int count) {
    return 'Hace $count min';
  }

  @override
  String visitorsAgoHours(int count) {
    return 'Hace $count h';
  }

  @override
  String visitorsAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count días',
      one: 'Hace $count día',
    );
    return '$_temp0';
  }

  @override
  String visitorsAgoWeeks(int count) {
    return 'Hace $count sem.';
  }

  @override
  String get webSessionsTitle => 'Ordenadores conectados';

  @override
  String get webSessionsSectionLabel => 'MAZL en ordenador';

  @override
  String get webSessionsIntro =>
      'Usa MAZL en el ordenador en app.mazl.app. Cada ordenador permanece conectado 7 días como máximo.';

  @override
  String get webSessionsConnect => 'Conectar un ordenador';

  @override
  String get webSessionsConnected => 'Ordenador conectado.';

  @override
  String get webSessionsLoadFailed =>
      'No hemos podido cargar tus ordenadores. Revisa tu conexión.';

  @override
  String get webSessionsEmpty =>
      'Ahora mismo no hay ningún ordenador conectado.';

  @override
  String get webSessionsListLabel => 'Ordenadores';

  @override
  String get webSessionsRevoke => 'Desconectar';

  @override
  String webSessionsRevokeNamed(String browser) {
    return 'Desconectar $browser';
  }

  @override
  String get webSessionsRevokeFailed =>
      'No se ha podido desconectar este ordenador. Inténtalo de nuevo.';

  @override
  String get webSessionsRevokeAll => 'Desconectar todos los ordenadores';

  @override
  String get webSessionsRevokeAllTitle => '¿Desconectar todos los ordenadores?';

  @override
  String get webSessionsRevokeAllBody =>
      'Tendrás que volver a iniciar sesión en cada ordenador.';

  @override
  String get webSessionsRevokeAllConfirm => 'Desconectar todo';

  @override
  String get webSessionsRevokeAllFailed =>
      'No se han podido desconectar los ordenadores. Inténtalo de nuevo.';

  @override
  String get webSessionsMethodQr => 'Conectado por código QR';

  @override
  String get webSessionsMethodGoogle => 'Conectado con Google';

  @override
  String get webSessionsMethodApple => 'Conectado con Apple';

  @override
  String get webSessionsActiveNow => 'Actividad ahora mismo';

  @override
  String webSessionsActiveMinutes(int count) {
    return 'Actividad hace $count min';
  }

  @override
  String webSessionsActiveHours(int count) {
    return 'Actividad hace $count h';
  }

  @override
  String get webSessionsActiveYesterday => 'Actividad ayer';

  @override
  String webSessionsActiveDays(int count) {
    return 'Actividad hace $count d';
  }

  @override
  String webSessionsClockTime(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get webSessionsScanInstruction =>
      'Escanea el código QR que aparece en app.mazl.app';

  @override
  String get webSessionsScanCameraLabel => 'Cámara de lectura del código QR';

  @override
  String get webSessionsCameraUnavailable =>
      'No se puede acceder a la cámara. Permite el acceso a la cámara en los ajustes de tu iPhone para escanear un código.';

  @override
  String get webSessionsScanNotMazl =>
      'Este código QR no es un código de MAZL.';

  @override
  String get webSessionsScanExpired =>
      'Este código ha caducado. Muestra un código nuevo en el ordenador.';

  @override
  String get webSessionsScanTooMany =>
      'Demasiados intentos. Espera un momento antes de volver a intentarlo.';

  @override
  String get webSessionsApproveInvalid =>
      'Esta solicitud ya no es válida. Muestra un código nuevo en el ordenador.';

  @override
  String get webSessionsConnectionProblem =>
      'No se pudo conectar. Revisa tu red e inténtalo de nuevo.';

  @override
  String get webSessionsGenericProblem =>
      'Ha ocurrido un error. Inténtalo de nuevo en un momento.';

  @override
  String get webSessionsConfirmLabel => 'Inicio de sesión en MAZL en ordenador';

  @override
  String get webSessionsConfirmTitle => '¿Conectar este ordenador?';

  @override
  String get webSessionsConfirmBrowser => 'Navegador';

  @override
  String get webSessionsConfirmAddress => 'Dirección';

  @override
  String get webSessionsConfirmAskedAt => 'Solicitado a las';

  @override
  String get webSessionsConfirmWarning =>
      'Escanea solo el código que aparece en tu propio ordenador. Si alguien te pide que escanees un código, recházalo.';

  @override
  String get webSessionsConfirmApprove => 'Conectar';

  @override
  String get webSessionsConfirmDeny => 'Rechazar';
}
