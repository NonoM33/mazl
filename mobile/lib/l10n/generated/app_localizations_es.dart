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
  String get authLoginEmail => 'Usar mi correo electrónico';

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
  String get authErrorInvalidCredentials => 'Correo o contraseña incorrectos';

  @override
  String get authErrorCancelled => 'Inicio de sesión cancelado.';

  @override
  String get authErrorEmailTaken => 'Este correo ya está en uso.';

  @override
  String get authErrorUnsupported =>
      'Este método de inicio de sesión no está disponible en este dispositivo.';

  @override
  String get authErrorLoginFailed => 'Error al iniciar sesión';

  @override
  String get authErrorRegisterFailed => 'Error en el registro';

  @override
  String get authErrorTermsRequired => 'Acepta las condiciones de uso';

  @override
  String get authEmailTitleLogin => 'Iniciar sesión';

  @override
  String get authEmailTitleRegister => 'Registro';

  @override
  String get authEmailSubtitleLogin => 'Qué bueno verte de nuevo';

  @override
  String get authEmailSubtitleRegister => 'Crea tu cuenta MAZL';

  @override
  String get authFieldName => 'Nombre';

  @override
  String get authFieldEmail => 'Correo electrónico';

  @override
  String get authFieldPassword => 'Contraseña';

  @override
  String get authFieldPasswordConfirm => 'Confirmar contraseña';

  @override
  String get authStrengthWeak => 'Débil';

  @override
  String get authStrengthFair => 'Media';

  @override
  String get authStrengthGood => 'Buena';

  @override
  String get authStrengthExcellent => 'Excelente';

  @override
  String get authTermsCheckbox =>
      'Acepto las Condiciones de uso y la Política de privacidad';

  @override
  String get authForgotLink => '¿Olvidaste tu contraseña?';

  @override
  String get authSubmitLogin => 'Iniciar sesión';

  @override
  String get authSubmitRegister => 'Crear mi cuenta';

  @override
  String get authToggleNoAccount => '¿Aún no tienes cuenta?';

  @override
  String get authToggleHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authToggleCreate => 'Crear una cuenta';

  @override
  String get authToggleSignIn => 'Iniciar sesión';

  @override
  String get authValidationEmailRequired => 'Correo obligatorio';

  @override
  String get authValidationEmailInvalid => 'Correo no válido';

  @override
  String get authValidationPasswordRequired => 'Contraseña obligatoria';

  @override
  String get authValidationPasswordMin => 'Mínimo 8 caracteres';

  @override
  String get authValidationPasswordUpper => 'Al menos una mayúscula';

  @override
  String get authValidationPasswordDigit => 'Al menos un número';

  @override
  String get authValidationPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get authValidationNameRequired => 'Nombre obligatorio';

  @override
  String get authValidationNameMin => 'Mínimo 2 caracteres';

  @override
  String get authVerifyTitle => 'Revisa tu correo';

  @override
  String get authVerifySent => 'Hemos enviado un correo de verificación a:';

  @override
  String get authVerifyInstruction =>
      'Haz clic en el enlace del correo para activar tu cuenta.';

  @override
  String get authVerifyOk => 'Vale, lo reviso';

  @override
  String get authForgotTitle => 'Contraseña olvidada';

  @override
  String get authForgotInstruction =>
      'Introduce tu correo para recibir un enlace de restablecimiento.';

  @override
  String get authForgotSent => 'Correo de restablecimiento enviado';

  @override
  String get authForgotSend => 'Enviar';

  @override
  String get authRouteErrorTitle => 'Página no encontrada';

  @override
  String get authRouteErrorBody => 'Ha ocurrido un error';

  @override
  String get authRouteErrorHome => 'Volver al inicio';

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
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma del teléfono';

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
}
