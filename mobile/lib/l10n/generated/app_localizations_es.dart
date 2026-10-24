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
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma del teléfono';

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
}
