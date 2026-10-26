import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/duo_tutorial/duo_tutorial_step.dart';
import 'package:mazl/core/layout/fold_state.dart';

import '../../helpers/duo_poses.dart';

/// Quelle étape du tutoriel chaque pose MESURÉE du Duo valide. Les poses
/// viennent de `DuoPose` (relevées sur le simulateur iOS 27.1), pas de valeurs
/// écrites ici pour arranger le code.
void main() {
  bool done(DuoTutorialStep step, DuoPose pose) =>
      step.isDoneBy(pose.foldState, pose.size);

  group('chaque geste n\'est validé que par SA pose', () {
    test('« Ouvrez-le » : ouvert, de face ou en paysage', () {
      expect(done(DuoTutorialStep.open, DuoPose.openPortrait), isTrue);
      expect(done(DuoTutorialStep.open, DuoPose.openLandscape), isTrue);
      expect(done(DuoTutorialStep.open, DuoPose.closed), isFalse);
      expect(done(DuoTutorialStep.open, DuoPose.halfOpenBook), isFalse);
      expect(done(DuoTutorialStep.open, DuoPose.halfOpenLaptop), isFalse);
      expect(done(DuoTutorialStep.open, DuoPose.tent), isFalse);
    });

    test('« Pliez-le comme un livre » : mi-ouvert, le pli vertical', () {
      expect(done(DuoTutorialStep.book, DuoPose.halfOpenBook), isTrue);
      expect(done(DuoTutorialStep.book, DuoPose.halfOpenLaptop), isFalse);
      expect(done(DuoTutorialStep.book, DuoPose.openLandscape), isFalse);
      expect(done(DuoTutorialStep.book, DuoPose.closed), isFalse);
    });

    test('« Posez-le sur la table » : mi-ouvert, le pli horizontal', () {
      expect(done(DuoTutorialStep.table, DuoPose.halfOpenLaptop), isTrue);
      expect(done(DuoTutorialStep.table, DuoPose.halfOpenBook), isFalse);
      expect(done(DuoTutorialStep.table, DuoPose.openPortrait), isFalse);
    });

    test(
      '« Debout, comme une tente » : la fenêtre de l\'écran extérieur, en paysage',
      () {
        expect(done(DuoTutorialStep.tent, DuoPose.tent), isTrue);
        // Fermé mais debout : la colonne de la barre est à droite, pas une tente.
        expect(done(DuoTutorialStep.tent, DuoPose.closed), isFalse);
        expect(done(DuoTutorialStep.tent, DuoPose.openLandscape), isFalse);
      },
    );

    test('bienvenue et « C\'est parti » n\'ont pas de geste', () {
      for (final pose in DuoPose.values) {
        expect(done(DuoTutorialStep.welcome, pose), isFalse, reason: pose.name);
        expect(done(DuoTutorialStep.ready, pose), isFalse, reason: pose.name);
      }
      expect(DuoTutorialStep.welcome.hasGesture, isFalse);
      expect(DuoTutorialStep.ready.hasGesture, isFalse);
      expect(DuoTutorialStep.open.hasGesture, isTrue);
    });
  });

  group(
    'la vraie tente est entrouverte : charnière partiallyOpen, écran extérieur actif',
    () {
      // Mesuré par Device Hub : la tente rapporte `closed`. Posé en V, iOS peut
      // la rapporter `partiallyOpen` avec l'écran extérieur toujours actif : même
      // fenêtre (678 x 466), aucune division de pli.
      final partiallyOpenTent = FoldState(
        hinge: HingeStatus.partiallyOpen,
        verticalBar: DuoPose.tent.foldState.verticalBar,
        occlusions: DuoPose.tent.foldState.occlusions,
        angle: 1.2,
      );
      final size = DuoPose.tent.size;

      test('reconnue comme une tente', () {
        expect(DuoTutorialStep.tent.isDoneBy(partiallyOpenTent, size), isTrue);
      });

      test(
        'et pas comme un livre ni comme un portable, malgré la charnière',
        () {
          expect(
            DuoTutorialStep.book.isDoneBy(partiallyOpenTent, size),
            isFalse,
          );
          expect(
            DuoTutorialStep.table.isDoneBy(partiallyOpenTent, size),
            isFalse,
          );
          expect(
            DuoTutorialStep.open.isDoneBy(partiallyOpenTent, size),
            isFalse,
          );
        },
      );

      test('un mi-ouvert sur l\'écran intérieur n\'est pas une tente', () {
        for (final pose in [DuoPose.halfOpenBook, DuoPose.halfOpenLaptop]) {
          expect(
            DuoTutorialStep.tent.isDoneBy(pose.foldState, pose.size),
            isFalse,
            reason: pose.name,
          );
        }
      });

      test('un pli actif écarte la tente même dans une fenêtre étroite', () {
        final withFold = FoldState(
          hinge: HingeStatus.partiallyOpen,
          divisions: const [Rect.fromLTWH(319, 0, 40, 466)],
        );
        expect(DuoTutorialStep.tent.isDoneBy(withFold, size), isFalse);
      });

      test(
        'une fenêtre de l\'écran intérieur n\'est jamais une tente (largeur 700 pt et plus)',
        () {
          expect(
            DuoTutorialStep.tent.isDoneBy(
              DuoPose.closed.foldState,
              const Size(951, 669),
            ),
            isFalse,
          );
          expect(
            DuoTutorialStep.tent.isDoneBy(
              DuoPose.closed.foldState,
              const Size(700, 466),
            ),
            isFalse,
          );
        },
      );

      test('debout et fermé ou entrouvert en portrait : pas une tente', () {
        expect(
          DuoTutorialStep.tent.isDoneBy(
            partiallyOpenTent,
            const Size(466, 678),
          ),
          isFalse,
        );
      });
    },
  );

  test('un seul geste par pose : aucune pose ne valide deux étapes', () {
    for (final pose in DuoPose.values) {
      final validated = [
        for (final step in DuoTutorialStep.values)
          if (done(step, pose)) step,
      ];
      expect(
        validated.length,
        lessThanOrEqualTo(1),
        reason: '${pose.name}: $validated',
      );
    }
  });

  group('mi-ouvert sans pli connu : la fenêtre tranche', () {
    FoldState half() => const FoldState(hinge: HingeStatus.partiallyOpen);

    test('large : un livre', () {
      expect(
        DuoTutorialStep.book.isDoneBy(half(), const Size(951, 669)),
        isTrue,
      );
      expect(
        DuoTutorialStep.table.isDoneBy(half(), const Size(951, 669)),
        isFalse,
      );
    });

    test('haute : un portable', () {
      expect(
        DuoTutorialStep.table.isDoneBy(half(), const Size(669, 951)),
        isTrue,
      );
      expect(
        DuoTutorialStep.book.isDoneBy(half(), const Size(669, 951)),
        isFalse,
      );
    });
  });

  test('un téléphone qui ne se plie pas ne valide rien', () {
    for (final step in DuoTutorialStep.values) {
      expect(step.isDoneBy(FoldState.unknown, const Size(390, 844)), isFalse);
    }
  });

  group('l\'ordre du parcours', () {
    test('six étapes, de la bienvenue à « C\'est parti »', () {
      expect(DuoTutorialStep.values, [
        DuoTutorialStep.welcome,
        DuoTutorialStep.open,
        DuoTutorialStep.book,
        DuoTutorialStep.table,
        DuoTutorialStep.tent,
        DuoTutorialStep.ready,
      ]);
    });

    test('next suit l\'ordre et s\'arrête à la dernière', () {
      expect(DuoTutorialStep.welcome.next, DuoTutorialStep.open);
      expect(DuoTutorialStep.tent.next, DuoTutorialStep.ready);
      expect(DuoTutorialStep.ready.next, isNull);
    });

    test('isLast', () {
      expect(DuoTutorialStep.ready.isLast, isTrue);
      expect(DuoTutorialStep.welcome.isLast, isFalse);
    });
  });
}
