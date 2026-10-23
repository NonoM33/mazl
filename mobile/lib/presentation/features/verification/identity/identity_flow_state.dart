import 'package:flutter/foundation.dart';

import '../../../../core/verification/chip/chip_reader.dart';
import '../../../../core/verification/mrz/mrz_data.dart';
import 'identity_messages.dart';

/// Screens of the level 2 verification, in order.
@immutable
sealed class IdentityFlowState {
  const IdentityFlowState();
}

/// Checking what this phone can do.
final class IdentityChecking extends IdentityFlowState {
  const IdentityChecking();
}

enum IdentityUnavailableReason { noNfc, comingSoon }

final class IdentityUnavailable extends IdentityFlowState {
  const IdentityUnavailable(this.reason);
  final IdentityUnavailableReason reason;
}

final class IdentityIntro extends IdentityFlowState {
  const IdentityIntro();
}

/// Scanning the MRZ with the camera, or typing it ([manual]).
final class IdentityMrz extends IdentityFlowState {
  const IdentityMrz({this.manual = false});
  final bool manual;
}

/// The data read from the photo page, shown back to the user before the chip
/// is opened with it: a misread MRZ is the main cause of a refused chip.
/// [manual] remembers how it was entered, to go back to the same screen.
final class IdentityMrzReview extends IdentityFlowState {
  const IdentityMrzReview(this.mrz, {this.manual = false});
  final MrzData mrz;
  final bool manual;
}

/// Waiting for, or reading, the chip.
final class IdentityNfc extends IdentityFlowState {
  const IdentityNfc(this.mrz, {this.reading = false, this.progress, this.failure});

  final MrzData mrz;
  final bool reading;
  final ChipReadProgress? progress;
  final IdentityFailureInfo? failure;
}

/// Chip read; the selfie is next.
final class IdentityFace extends IdentityFlowState {
  const IdentityFace();
}

enum IdentitySubmitStage { starting, capturing, sending }

final class IdentitySubmitting extends IdentityFlowState {
  const IdentitySubmitting(this.stage);
  final IdentitySubmitStage stage;
}

final class IdentityDone extends IdentityFlowState {
  const IdentityDone();
}

final class IdentityFailed extends IdentityFlowState {
  const IdentityFailed(this.info);
  final IdentityFailureInfo info;
}
