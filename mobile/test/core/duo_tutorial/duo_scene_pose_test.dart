import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/duo_tutorial/duo_scene_pose.dart';
import 'package:mazl/core/duo_tutorial/duo_tutorial_step.dart';
import 'package:mazl/core/layout/fold_state.dart';

import '../../helpers/duo_poses.dart';

DuoScenePose sceneFor(
  DuoPose pose, {
  DuoTutorialStep step = DuoTutorialStep.welcome,
  bool validated = false,
  bool reduceMotion = false,
}) => DuoScenePose.from(
  fold: pose.foldState,
  size: pose.size,
  step: step,
  validated: validated,
  reduceMotion: reduceMotion,
);

/// Ce que la page 3D reçoit pour chaque pose mesurée : la charnière réelle,
/// l'axe du pli (vu de la fenêtre) et si l'appareil est de côté.
void main() {
  test('fermé et debout : charnière fermée, angle 0, pas de côté', () {
    final pose = sceneFor(DuoPose.closed);
    expect(pose.hinge, HingeStatus.closed);
    expect(pose.angle, 0);
    expect(pose.sideways, isFalse);
    expect(pose.verticalBar, VerticalBarSide.right);
  });

  test('en tente : fermé et de côté, colonne à gauche', () {
    final pose = sceneFor(DuoPose.tent);
    expect(pose.sideways, isTrue);
    expect(pose.verticalBar, VerticalBarSide.left);
  });

  test(
    'tente entrouverte (charnière partiallyOpen, écran extérieur) : de côté aussi',
    () {
      final pose = DuoScenePose.from(
        fold: FoldState(
          hinge: HingeStatus.partiallyOpen,
          verticalBar: VerticalBarSide.left,
          angle: 1.2,
        ),
        size: DuoPose.tent.size,
        step: DuoTutorialStep.tent,
        validated: false,
        reduceMotion: false,
      );
      expect(pose.sideways, isTrue);
      expect(pose.angle, 1.2);
    },
  );

  test('un mi-ouvert sur l\'écran intérieur n\'est pas de côté', () {
    expect(sceneFor(DuoPose.halfOpenBook).sideways, isFalse);
    expect(sceneFor(DuoPose.halfOpenLaptop).sideways, isFalse);
  });

  test('livre : le pli vertical, l\'angle réel', () {
    final pose = sceneFor(DuoPose.halfOpenBook);
    expect(pose.axis, DuoAxis.vertical);
    expect(pose.angle, 1.9);
  });

  test('portable : le pli horizontal', () {
    expect(sceneFor(DuoPose.halfOpenLaptop).axis, DuoAxis.horizontal);
  });

  test('ouvert à plat : l\'axe suit l\'orientation de la fenêtre', () {
    expect(sceneFor(DuoPose.openLandscape).axis, DuoAxis.vertical);
    expect(sceneFor(DuoPose.openPortrait).axis, DuoAxis.horizontal);
  });

  test(
    'sans angle donné par le système, un angle par défaut pour la charnière',
    () {
      const size = Size(669, 951);
      DuoScenePose of(HingeStatus hinge) => DuoScenePose.from(
        fold: FoldState(hinge: hinge),
        size: size,
        step: DuoTutorialStep.open,
        validated: false,
        reduceMotion: false,
      );
      expect(of(HingeStatus.closed).angle, 0);
      expect(of(HingeStatus.fullyOpen).angle, closeTo(3.14159, 1e-3));
      expect(of(HingeStatus.partiallyOpen).angle, 1.9);
    },
  );

  test(
    'l\'angle est arrondi : un bruit de 0,0001 rad n\'envoie rien de plus',
    () {
      final a = DuoScenePose.from(
        fold: const FoldState(hinge: HingeStatus.partiallyOpen, angle: 1.90001),
        size: const Size(951, 669),
        step: DuoTutorialStep.book,
        validated: false,
        reduceMotion: false,
      );
      final b = DuoScenePose.from(
        fold: const FoldState(hinge: HingeStatus.partiallyOpen, angle: 1.90004),
        size: const Size(951, 669),
        step: DuoTutorialStep.book,
        validated: false,
        reduceMotion: false,
      );
      expect(a, b);
    },
  );

  group('le message envoyé à window.mazlDuo.setPose', () {
    test('contient charnière, angle, colonne et étape', () {
      final message = sceneFor(
        DuoPose.halfOpenBook,
        step: DuoTutorialStep.book,
      ).toMessage();
      expect(message['hinge'], 'partiallyOpen');
      expect(message['angle'], 1.9);
      expect(message['verticalBar'], 'right');
      expect(message['step'], 'book');
      expect(message['axis'], 'vertical');
      expect(message['sideways'], false);
      expect(message['validated'], false);
      expect(message['reduceMotion'], false);
    });

    test('une colonne inconnue part en null, pas en texte', () {
      final message = sceneFor(DuoPose.splitView).toMessage();
      expect(message['verticalBar'], isNull);
    });

    test('porte la réussite et « Réduire les animations »', () {
      final message = sceneFor(
        DuoPose.closed,
        validated: true,
        reduceMotion: true,
      ).toMessage();
      expect(message['validated'], true);
      expect(message['reduceMotion'], true);
    });

    test('chaque étape garde le nom que la page connaît', () {
      // Les noms sont ceux de STEPS dans assets/duo_tutorial/pose_math.js.
      expect(
        [for (final s in DuoTutorialStep.values) s.name],
        ['welcome', 'open', 'book', 'table', 'tent', 'ready'],
      );
    });
  });

  test('deux poses identiques sont égales, une étape change l\'égalité', () {
    expect(sceneFor(DuoPose.closed), sceneFor(DuoPose.closed));
    expect(
      sceneFor(DuoPose.closed),
      isNot(sceneFor(DuoPose.closed, step: DuoTutorialStep.open)),
    );
    expect(
      sceneFor(DuoPose.closed),
      isNot(sceneFor(DuoPose.closed, validated: true)),
    );
  });
}
