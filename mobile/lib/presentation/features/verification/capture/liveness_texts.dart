import '../../../../core/services/verification_api.dart';
import '../../../../l10n/l10n.dart';
import 'liveness_controller.dart';

String challengeInstruction(AppLocalizations l10n, FaceChallenge challenge) => switch (challenge) {
      FaceChallenge.front => l10n.verificationLivenessFront,
      FaceChallenge.left => l10n.verificationLivenessLeft,
      FaceChallenge.right => l10n.verificationLivenessRight,
    };

/// Short hint under the instruction; null when nothing needs fixing.
String? poseFeedbackText(AppLocalizations l10n, PoseFeedback feedback) => switch (feedback) {
      PoseFeedback.noFace => l10n.verificationLivenessHintNoFace,
      PoseFeedback.multipleFaces => l10n.verificationLivenessHintMultipleFaces,
      PoseFeedback.tooSmall => l10n.verificationLivenessHintTooSmall,
      PoseFeedback.offCenter => l10n.verificationLivenessHintOffCenter,
      PoseFeedback.lookStraight => l10n.verificationLivenessHintLookStraight,
      PoseFeedback.turnMore => l10n.verificationLivenessHintTurnMore,
      PoseFeedback.turnLess => l10n.verificationLivenessHintTurnLess,
      PoseFeedback.turnOtherWay => l10n.verificationLivenessHintTurnOtherWay,
      PoseFeedback.holding => null,
    };
