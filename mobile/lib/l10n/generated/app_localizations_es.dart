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
  String get errorNetwork => 'Sin conexión. Revisa tu red e inténtalo de nuevo.';

  @override
  String get errorServer => 'El servidor no está disponible. Inténtalo de nuevo en un momento.';

  @override
  String get errorSessionExpired => 'La sesión ha caducado. Vuelve a iniciar sesión.';

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
  String get errorInvalid => 'Solicitud rechazada. Revisa los datos introducidos.';

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
  String get profileCoupleElsewhereBody => 'Ya estás en modo pareja con otra persona.';

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
  String get profileCoupleAvailableBody => 'Habéis hecho match. Activa el modo pareja para compartir actividades juntos.';

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
  String get profileCompatibilityBasis => 'Calculada a partir de vuestros dos perfiles.';

  @override
  String get profileCompatibilityUnavailable => 'La compatibilidad no está disponible por ahora.';

  @override
  String profileCompatibilityUnlockTitle(String name) {
    return 'Descubre tu puntuación de compatibilidad con $name.';
  }

  @override
  String get profileCompatibilityUnlockBody => 'Calculado a partir de tus prácticas, tus intenciones y tus valores.';

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
  String get profileCompatibilityIncomplete => 'Completa los perfiles para ver más detalles';

  @override
  String get profileCompatibilityNote => 'La puntuación se basa en las preferencias y los puntos en común';

  @override
  String get profileCompatibilityGotIt => 'Entendido';

  @override
  String get profilePromptsMine => 'Mis preguntas';

  @override
  String get profilePromptsSubtitle => 'Responde a preguntas para mostrar tu personalidad';

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
  String get profilePromptFamilyTradition => 'Una tradición familiar que adoro...';

  @override
  String get profilePromptFavoriteHoliday => 'Mi fiesta judía favorita...';

  @override
  String get profilePromptFridayNight => 'Los viernes por la noche en mi casa...';

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
  String get profileIntentionSeriousDescription => 'Busco una relación duradera';

  @override
  String get profileIntentionOpenDescription => 'Veremos adónde nos lleva';

  @override
  String get profileIntentionFriendsFirstDescription => 'Empecemos por conocernos';

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
  String get profileUploadUnavailable => 'La subida no está disponible por ahora';

  @override
  String get profileDeletePhotoTitle => '¿Eliminar la foto?';

  @override
  String get profilePhotoDeleted => 'Foto eliminada';

  @override
  String get profileServiceUnavailable => 'Servicio no disponible temporalmente';

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
  String get profileSetupAboutYouSubtitle => 'Esta información será visible en tu perfil';

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
  String get profileSetupPhotosSubtitle => 'Añade al menos 2 fotos para continuar';

  @override
  String get profileSetupPhotosTip => 'Los perfiles con fotos de buena calidad reciben 3 veces más matches.';

  @override
  String get profileSetupPracticeTitle => 'Tu práctica';

  @override
  String get profileSetupPracticeSubtitle => 'Ayúdanos a encontrar a alguien que encaje contigo';

  @override
  String get profileSetupLookingTitle => 'Lo que buscas';

  @override
  String get profileSetupLookingSubtitle => 'Ayúdanos a mostrarte los perfiles adecuados';

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
  String get profileShadchanNote => 'Nuestro AI Shadchan usará estas preferencias para proponerte perfiles compatibles.';

  @override
  String get profileReportThisProfile => 'Denunciar este perfil';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma del teléfono';
}
