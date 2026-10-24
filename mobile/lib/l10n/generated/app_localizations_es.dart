// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get likesMessageAction => 'Mensaje';

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
  String matchingPicksMatchBody(String name) {
    return 'Has hecho match con $name.';
  }

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
}
