import '../../../../core/services/verification_api.dart';
import 'liveness_controller.dart';

String challengeInstruction(FaceChallenge challenge) => switch (challenge) {
      FaceChallenge.front => 'Regarde l\'objectif',
      FaceChallenge.left => 'Tourne doucement la tête vers la gauche',
      FaceChallenge.right => 'Tourne doucement la tête vers la droite',
    };

/// Short hint under the instruction; null when nothing needs fixing.
String? poseFeedbackText(PoseFeedback feedback) => switch (feedback) {
      PoseFeedback.noFace => 'Place ton visage dans l\'ovale',
      PoseFeedback.multipleFaces => 'Une seule personne dans le cadre',
      PoseFeedback.tooSmall => 'Rapproche-toi un peu',
      PoseFeedback.offCenter => 'Centre ton visage dans l\'ovale',
      PoseFeedback.lookStraight => 'Regarde droit devant toi',
      PoseFeedback.turnMore => 'Tourne encore un peu',
      PoseFeedback.turnLess => 'Pas autant, reviens un peu',
      PoseFeedback.turnOtherWay => 'Tourne de l\'autre côté',
      PoseFeedback.holding => null,
    };
