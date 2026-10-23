import '../../../../core/services/verification_api.dart';
import 'liveness_controller.dart';

String challengeInstruction(FaceChallenge challenge) => switch (challenge) {
      FaceChallenge.front => 'Regardez l\'objectif',
      FaceChallenge.left => 'Tournez doucement la tête vers la gauche',
      FaceChallenge.right => 'Tournez doucement la tête vers la droite',
    };

/// Short hint under the instruction; null when nothing needs fixing.
String? poseFeedbackText(PoseFeedback feedback) => switch (feedback) {
      PoseFeedback.noFace => 'Placez votre visage dans le cercle',
      PoseFeedback.multipleFaces => 'Une seule personne dans le cadre',
      PoseFeedback.tooSmall => 'Rapprochez-vous un peu',
      PoseFeedback.offCenter => 'Centrez votre visage dans le cercle',
      PoseFeedback.lookStraight => 'Regardez droit devant vous',
      PoseFeedback.turnMore => 'Tournez encore un peu',
      PoseFeedback.turnLess => 'Pas autant, revenez un peu',
      PoseFeedback.turnOtherWay => 'Tournez de l\'autre côté',
      PoseFeedback.holding => null,
    };
