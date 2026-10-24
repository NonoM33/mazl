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
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma del teléfono';
}
