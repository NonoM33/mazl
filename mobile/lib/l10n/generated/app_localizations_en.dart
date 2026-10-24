// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get errorTimeout => 'Timed out. Check your connection.';

  @override
  String get errorNetwork => 'No connection. Check your network and try again.';

  @override
  String get errorServer => 'The server is unavailable. Try again in a moment.';

  @override
  String get errorSessionExpired => 'Session expired. Please sign in again.';

  @override
  String get errorForbidden => 'You\'re not allowed to do this.';

  @override
  String get errorNotFound => 'Not found: this item no longer exists.';

  @override
  String get errorConflict => 'This action is no longer possible.';

  @override
  String get errorTooLarge => 'File too large.';

  @override
  String get errorRateLimited => 'Too many attempts. Please wait a moment.';

  @override
  String get errorInvalid => 'Request refused. Check what you entered.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonSee => 'View';

  @override
  String get commonShare => 'Share';

  @override
  String get commonReport => 'Report';

  @override
  String get commonOk => 'OK';

  @override
  String get commonLater => 'Later';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonNotSpecified => 'Not specified';

  @override
  String get commonLoadError => 'Couldn’t load';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Phone language';

  @override
  String get verificationProfileEyebrow => 'Your profile';

  @override
  String get verificationTitle => 'Verification';

  @override
  String get verificationLevel1 => 'Level 1';

  @override
  String get verificationLevel2 => 'Level 2';

  @override
  String get verificationPhotoTitle => 'Photo verified';

  @override
  String get verificationIdentityTitle => 'Identity verified';

  @override
  String get verificationVerifiedPill => 'Verified';

  @override
  String get verificationConsent =>
      'We compare your face with your photos. The images are not kept; only an encrypted fingerprint is, and it can be deleted at any time.';

  @override
  String get verificationPhotoVerifiedLine => 'Your face matches your photos.';

  @override
  String verificationPhotoVerifiedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Verified on $dateString.';
  }

  @override
  String get verificationRemoveAction => 'Remove my verification';

  @override
  String get verificationVerifyPhotoAction => 'Verify my photo';

  @override
  String get verificationVerifyIdentityAction => 'Verify my identity';

  @override
  String verificationBlockedToday(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Limit reached, you can try again at $timeString.';
  }

  @override
  String verificationBlockedLater(DateTime date, DateTime time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Limit reached, you can try again on $dateString at $timeString.';
  }

  @override
  String get verificationIdentityCheckedNoDate =>
      'Document checked through its chip.';

  @override
  String verificationIdentityCheckedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Checked on $dateString.';
  }

  @override
  String get verificationIdentityPitch =>
      'Passport or ID card, read through its chip. A selfie confirms it is really you.';

  @override
  String get verificationRemoveDialogTitle => 'Remove my verification?';

  @override
  String get verificationRemoveDialogBody =>
      'Your badge and your face print will be deleted.';

  @override
  String verificationPhotosMismatch(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of your photos do not look like you: they do not count.',
      one: 'One of your photos does not look like you: it does not count.',
    );
    return '$_temp0';
  }

  @override
  String get verificationLivenessFront => 'Look at the camera';

  @override
  String get verificationLivenessLeft => 'Slowly turn your head to the left';

  @override
  String get verificationLivenessRight => 'Slowly turn your head to the right';

  @override
  String get verificationLivenessHintNoFace =>
      'Put your face inside the circle';

  @override
  String get verificationLivenessHintMultipleFaces =>
      'Only one person in the frame';

  @override
  String get verificationLivenessHintTooSmall => 'Move a little closer';

  @override
  String get verificationLivenessHintOffCenter =>
      'Center your face in the circle';

  @override
  String get verificationLivenessHintLookStraight => 'Look straight ahead';

  @override
  String get verificationLivenessHintTurnMore => 'Turn a little more';

  @override
  String get verificationLivenessHintTurnLess =>
      'Not that far, come back a little';

  @override
  String get verificationLivenessHintTurnOtherWay => 'Turn the other way';

  @override
  String verificationLivenessPoseCounter(int current, int total) {
    return 'Pose $current / $total';
  }

  @override
  String verificationLivenessPosesTaken(int done, int total) {
    return 'Poses captured: $done of $total';
  }

  @override
  String get verificationLivenessPrivacy =>
      'Alone in the frame, well lit. The images are not kept.';

  @override
  String get verificationLivenessExpiredTitle => 'Session expired';

  @override
  String get verificationLivenessExpiredBody =>
      'The allotted time has run out. You can start again.';

  @override
  String get verificationCameraNeededTitle => 'Camera needed';

  @override
  String get verificationCameraNeededBody =>
      'MAZL uses the front camera to check that you are the person in your photos.';

  @override
  String get verificationCameraOpenSettings => 'Open settings';

  @override
  String get verificationCameraAllow => 'Allow camera access';

  @override
  String get verificationCameraUnavailableTitle => 'Camera unavailable';

  @override
  String get verificationCameraUnavailableBody =>
      'The front camera could not be started.';

  @override
  String get verificationIntroTitle => 'Verify your identity.';

  @override
  String get verificationIntroSubtitle =>
      'The “Identity verified” badge tells others that you really are the person in the photos. You need a biometric passport or ID card, two minutes and a bit of light.';

  @override
  String get verificationIntroStep1 => 'Photograph the photo page';

  @override
  String get verificationIntroStep1Detail => 'To read the two bottom lines.';

  @override
  String get verificationIntroStep2 => 'Place the phone on the chip';

  @override
  String get verificationIntroStep2Detail =>
      'The chip, signed by the state, is what counts.';

  @override
  String get verificationIntroStep3 => 'A moving selfie';

  @override
  String get verificationIntroStep3Detail =>
      'Compared with the photo on the chip.';

  @override
  String get verificationIntroPrivacy =>
      'Nothing is kept: we only keep the result.';

  @override
  String get verificationIntroStart => 'Start';

  @override
  String verificationStepLabel(int step, int total) {
    return 'Step $step / $total';
  }

  @override
  String get verificationScanTitle => 'Frame the photo page.';

  @override
  String get verificationScanHint =>
      'The two lines of “<” at the bottom are enough. Avoid glare.';

  @override
  String get verificationScanManual => 'Enter by hand';

  @override
  String get verificationScanFrameSemantics =>
      'Camera preview: place the two bottom lines of the document inside the highlighted frame';

  @override
  String get verificationCameraNotAvailable => 'The camera is not available.';

  @override
  String get verificationScanUnavailableBody =>
      'You can enter the details from the photo page by hand.';

  @override
  String get verificationScanEnterDetails => 'Enter the details';

  @override
  String get verificationManualTitle => 'Enter the details.';

  @override
  String get verificationManualSubtitle =>
      'Copy them from the photo page of your document.';

  @override
  String get verificationFieldDocumentNumber => 'Document number';

  @override
  String get verificationFieldBirthDate => 'Date of birth';

  @override
  String get verificationFieldExpiryDate => 'Expiry date';

  @override
  String get verificationDateHint => 'DD/MM/YYYY';

  @override
  String get verificationManualUseCamera => 'Scan with the camera';

  @override
  String get verificationErrorDocumentNumber =>
      'Between 5 and 12 letters or digits.';

  @override
  String get verificationErrorInvalidDate => 'Invalid date.';

  @override
  String get verificationReviewTitle => 'Check these details.';

  @override
  String get verificationReviewConfirm => 'That\'s me';

  @override
  String get verificationRescan => 'Scan again';

  @override
  String get verificationNfcWaitingTitle => 'Place your document on the phone.';

  @override
  String get verificationNfcPlacement =>
      'The top of the phone against the closed cover of the passport, or against the back of the ID card. Remove the case if needed.';

  @override
  String get verificationNfcRead => 'Read the document';

  @override
  String get verificationNfcIllustration =>
      'The top of the phone resting against the closed cover of the passport';

  @override
  String get verificationNfcReadingTitle => 'Don\'t move.';

  @override
  String get verificationNfcReadingSubtitle =>
      'Keep the document against the top of the phone until the reading is finished.';

  @override
  String get verificationNfcProgressLabel => 'Reading the chip';

  @override
  String verificationNfcProgressValue(int percent) {
    return '$percent%';
  }

  @override
  String get verificationNfcStepDetect => 'Detecting the document';

  @override
  String get verificationNfcStepConnect => 'Secure connection';

  @override
  String get verificationNfcStepPhoto => 'Reading the photo';

  @override
  String get verificationNfcStepSignature => 'Reading the signature';

  @override
  String verificationNfcStepSemantics(String label, String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'done': '$label, done',
      'active': '$label, in progress',
      'waiting': '$label, waiting',
      'other': '$label',
    });
    return '$_temp0';
  }

  @override
  String get verificationNfcSilentBody =>
      'This often happens on the first try. Nothing was sent.';

  @override
  String get verificationNfcRescanBody =>
      'Nothing was sent. Read the photo page again to start over with correct data.';

  @override
  String get verificationNfcTip1 => 'Take the case off your phone.';

  @override
  String get verificationNfcTip2 =>
      'Put the top of the phone in the middle of the cover, passport closed.';

  @override
  String get verificationNfcTip3 => 'Stay still for about ten seconds.';

  @override
  String get verificationNfcRereadPhotoPage => 'Read the photo page again';

  @override
  String get verificationManualReviewLink =>
      'Send my document for manual review';

  @override
  String get verificationFaceTitle => 'Chip read.';

  @override
  String get verificationFaceSubtitle =>
      'One moving selfie left, compared with the photo on the chip.';

  @override
  String get verificationFaceAction => 'Take the selfie';

  @override
  String get verificationSubmitSending => 'Verification in progress…';

  @override
  String get verificationSubmitPreparing => 'Getting ready…';

  @override
  String get verificationDoneTitle => 'Identity verified.';

  @override
  String get verificationDoneSubtitle =>
      'The chip in your document and your selfie match. Your profile now carries the badge.';

  @override
  String get verificationDoneAction => 'Done';

  @override
  String get verificationBadgeLabel => 'Identity verified';

  @override
  String get verificationDoneBadgeCaption => 'What others see on your profile.';

  @override
  String get verificationDoneStoredLabel => 'Photos and chip';

  @override
  String get verificationDoneStoredValue => 'Never stored';

  @override
  String get verificationDoneKeptLabel => 'Kept';

  @override
  String get verificationDoneKeptValue =>
      'Country, expiry, anonymous fingerprint';

  @override
  String get verificationDoneProfileLabel => 'Profile';

  @override
  String get verificationDoneProfileValue => 'Date of birth from the document';

  @override
  String get verificationComingSoon => 'Coming soon';

  @override
  String get verificationFailureChipDataInvalid =>
      'The chip data is unreadable.';

  @override
  String get verificationFailureChipSignatureInvalid =>
      'The document\'s signature could not be verified.';

  @override
  String get verificationFailureNotRecognized => 'Document not recognized.';

  @override
  String get verificationDocumentExpired => 'This document has expired.';

  @override
  String get verificationFailureUnderage =>
      'You must be 18 to verify your identity.';

  @override
  String get verificationDocumentAlreadyUsed =>
      'This document is already linked to another account.';

  @override
  String get verificationDocumentBanned => 'This document cannot be used.';

  @override
  String get verificationDocumentFaceMismatch =>
      'Your face does not match the photo in the document.';

  @override
  String get verificationFailureSessionExpired => 'The session has expired.';

  @override
  String get verificationFailureImagesUnreadable =>
      'The images could not be read.';

  @override
  String get verificationFailureNoFace => 'No face detected.';

  @override
  String get verificationFailureMultipleFaces => 'Only one face should appear.';

  @override
  String get verificationFailureFaceTooSmall => 'Move closer to the camera.';

  @override
  String get verificationFailurePoseMismatch =>
      'The requested movements were not recognized.';

  @override
  String get verificationFailureDuplicateFrames =>
      'Move your head as requested.';

  @override
  String get verificationFailureInconsistentIdentity =>
      'The face changed during the capture.';

  @override
  String get verificationFailureNoProfilePhoto =>
      'First add a photo to your profile.';

  @override
  String get verificationFailureProfileMismatch =>
      'Your face does not match your profile photo.';

  @override
  String get verificationFailureDailyLimit =>
      'You have reached today\'s limit of attempts. Come back tomorrow.';

  @override
  String get verificationFailureGeneric => 'The verification failed.';

  @override
  String get verificationFailureNoNfc => 'This phone has no NFC reader.';

  @override
  String get verificationFailureNfcDisabled =>
      'Turn on NFC in the phone settings.';

  @override
  String get verificationFailureTagLost =>
      'The document moved. Hold it still against the phone.';

  @override
  String get verificationFailureChipMismatch =>
      'The details entered do not match the chip.';

  @override
  String get verificationFailureUnreadableDocument =>
      'This document cannot be read.';

  @override
  String get verificationFailureChipSilent => 'The chip did not respond.';

  @override
  String get verificationFailureReadFailed => 'The reading failed.';

  @override
  String get verificationFailureConnection =>
      'Can\'t connect. Check your connection.';

  @override
  String get verificationActionRereadDocument => 'Read the document again';

  @override
  String get verificationActionOtherDocument => 'Another document';

  @override
  String get verificationReasonNoFace =>
      'No face detected. Face the camera in a well-lit place.';

  @override
  String get verificationReasonMultipleFaces =>
      'Several faces detected. Stay alone in the frame.';

  @override
  String get verificationReasonFaceTooSmall =>
      'Your face is too far away. Move closer to the camera.';

  @override
  String get verificationReasonPoseMismatch =>
      'The requested poses were not recognized. Follow the instructions carefully.';

  @override
  String get verificationReasonDuplicateFrames =>
      'The images are too similar. Move your head as requested.';

  @override
  String get verificationReasonInconsistentIdentity =>
      'The images do not show the same person. Start again on your own.';

  @override
  String get verificationReasonNoProfilePhoto =>
      'First add to your profile a photo where your face is clearly visible.';

  @override
  String get verificationReasonProfileMismatch =>
      'Your face does not match your main photo. Choose a recent photo where you are clearly visible.';

  @override
  String get verificationReasonDailyLimit =>
      'You have reached the limit of attempts for today. Come back tomorrow.';

  @override
  String get verificationReasonSessionExpired =>
      'The session has expired. Start again.';

  @override
  String get verificationReasonSessionInvalid =>
      'The session is no longer valid. Start again.';

  @override
  String get verificationReasonImagesUnreadable =>
      'The images could not be read. Start again.';

  @override
  String get verificationReasonAppUpdate =>
      'Update the app to verify your profile.';

  @override
  String get verificationReasonChipAuth =>
      'The document\'s chip could not be authenticated.';

  @override
  String get verificationReasonUnderage => 'You must be at least 18.';

  @override
  String get verificationReasonNetwork =>
      'Can\'t connect. Check your network and try again.';

  @override
  String get verificationReasonGeneric =>
      'Something went wrong. Try again in a moment.';

  @override
  String get verificationNfcAlertApproach =>
      'Bring your document close to the top of the phone.';

  @override
  String get verificationNfcAlertAuthenticating =>
      'Don\'t move. Secure connection…';

  @override
  String get verificationNfcAlertReadingPhoto => 'Reading the photo… 40%';

  @override
  String get verificationNfcAlertReadingSignature =>
      'Reading the signature… 85%';

  @override
  String get verificationNfcAlertDone => 'Done.';
}
