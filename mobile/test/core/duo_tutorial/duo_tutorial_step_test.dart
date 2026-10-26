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
    'la pose tente (entrouverte, écran extérieur actif) ne valide rien',
    () {
      // Mesuré par Device Hub : la tente rapporte `closed`. Posé en V, iOS peut
      // la rapporter `partiallyOpen` avec l'écran extérieur toujours actif.
      final partiallyOpenTent = FoldState(
        hinge: HingeStatus.partiallyOpen,
        verticalBar: DuoPose.tent.foldState.verticalBar,
        occlusions: DuoPose.tent.foldState.occlusions,
        angle: 1.2,
      );

      test('ni livre, ni portable, ni ouverture', () {
        final size = DuoPose.tent.size;
        for (final step in DuoTutorialStep.values) {
          expect(
            step.isDoneBy(partiallyOpenTent, size),
            isFalse,
            reason: step.name,
          );
        }
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
    test('cinq étapes, de la bienvenue à « C\'est parti »', () {
      expect(DuoTutorialStep.values, [
        DuoTutorialStep.welcome,
        DuoTutorialStep.open,
        DuoTutorialStep.book,
        DuoTutorialStep.table,
        DuoTutorialStep.ready,
      ]);
    });

    test('la liste des étapes est welcome, open, book, table, ready', () {
      expect(
        [for (final step in DuoTutorialStep.values) step.name],
        ['welcome', 'open', 'book', 'table', 'ready'],
      );
    });

    test('next suit l\'ordre et s\'arrête à la dernière', () {
      expect(DuoTutorialStep.welcome.next, DuoTutorialStep.open);
      expect(DuoTutorialStep.table.next, DuoTutorialStep.ready);
      expect(DuoTutorialStep.ready.next, isNull);
    });

    test('isLast', () {
      expect(DuoTutorialStep.ready.isLast, isTrue);
      expect(DuoTutorialStep.welcome.isLast, isFalse);
    });
  });
}
