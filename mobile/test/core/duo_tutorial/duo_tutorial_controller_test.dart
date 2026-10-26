import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/duo_tutorial/duo_tutorial_controller.dart';
import 'package:mazl/core/duo_tutorial/duo_tutorial_step.dart';
import 'package:mazl/core/layout/fold_state.dart';

import '../../helpers/duo_poses.dart';
import 'fake_duo_scene_renderer.dart';

const _hold = Duration(milliseconds: 700);
const _advance = Duration(milliseconds: 1500);

/// La progression du tutoriel suit la VRAIE pose : un geste n'est validé que
/// tenu un instant, la scène reçoit chaque changement de pose, et chaque étape
/// se passe sans le geste.
void main() {
  late FakeDuoSceneRenderer renderer;
  late DuoTutorialController controller;

  void put(DuoPose pose, {bool autoAdvance = true, bool reduceMotion = false}) {
    controller.update(
      fold: pose.foldState,
      size: pose.size,
      autoAdvance: autoAdvance,
      reduceMotion: reduceMotion,
    );
  }

  void inFakeAsync(void Function(FakeAsync async) body) {
    fakeAsync((async) {
      renderer = FakeDuoSceneRenderer();
      controller = DuoTutorialController(
        renderer: renderer,
        holdDuration: _hold,
        advanceDelay: _advance,
      );
      body(async);
      controller.dispose();
    });
  }

  group('la scène 3D reçoit la pose', () {
    test('une pose à chaque changement de pose réelle', () {
      inFakeAsync((async) {
        put(DuoPose.closed);
        put(DuoPose.openLandscape);
        put(DuoPose.halfOpenBook);
        expect(renderer.poses.map((p) => p.hinge), [
          HingeStatus.closed,
          HingeStatus.fullyOpen,
          HingeStatus.partiallyOpen,
        ]);
      });
    });

    test('rien de plus quand la pose ne change pas', () {
      inFakeAsync((async) {
        put(DuoPose.closed);
        put(DuoPose.closed);
        put(DuoPose.closed);
        expect(renderer.poses, hasLength(1));
      });
    });

    test('un angle qui bouge, même dans la même charnière, est envoyé', () {
      inFakeAsync((async) {
        controller.update(
          fold: const FoldState(hinge: HingeStatus.partiallyOpen, angle: 1.0),
          size: const Size(951, 669),
        );
        controller.update(
          fold: const FoldState(hinge: HingeStatus.partiallyOpen, angle: 1.4),
          size: const Size(951, 669),
        );
        expect(renderer.poses.map((p) => p.angle), [1.0, 1.4]);
      });
    });

    test('la pose porte l\'étape en cours et « Réduire les animations »', () {
      inFakeAsync((async) {
        put(DuoPose.closed, reduceMotion: true);
        expect(renderer.poses.single.step, DuoTutorialStep.welcome);
        expect(renderer.poses.single.reduceMotion, isTrue);
      });
    });

    test('changer d\'étape renvoie la pose avec la nouvelle étape', () {
      inFakeAsync((async) {
        put(DuoPose.closed);
        controller.next();
        expect(renderer.poses.last.step, DuoTutorialStep.open);
        expect(renderer.poses.last.hinge, HingeStatus.closed);
      });
    });
  });

  group('un geste se valide en le tenant', () {
    test('« Ouvrez-le » : validé après le temps de tenue, pas avant', () {
      inFakeAsync((async) {
        put(DuoPose.closed);
        controller.next();
        put(DuoPose.openPortrait, autoAdvance: false);
        expect(controller.validated, isFalse);
        async.elapse(_hold - const Duration(milliseconds: 10));
        expect(controller.validated, isFalse);
        async.elapse(const Duration(milliseconds: 20));
        expect(controller.validated, isTrue);
        expect(renderer.poses.last.validated, isTrue);
      });
    });

    test('une pose traversée en passant ne valide rien', () {
      inFakeAsync((async) {
        put(DuoPose.closed);
        controller.next();
        put(DuoPose.openPortrait, autoAdvance: false);
        async.elapse(const Duration(milliseconds: 300));
        put(DuoPose.halfOpenBook, autoAdvance: false);
        async.elapse(const Duration(seconds: 5));
        expect(controller.validated, isFalse);
      });
    });

    test('revenir dans la pose relance la tenue depuis zéro', () {
      inFakeAsync((async) {
        controller.next();
        put(DuoPose.openPortrait, autoAdvance: false);
        async.elapse(const Duration(milliseconds: 500));
        put(DuoPose.closed, autoAdvance: false);
        put(DuoPose.openPortrait, autoAdvance: false);
        async.elapse(const Duration(milliseconds: 500));
        expect(controller.validated, isFalse);
        async.elapse(const Duration(milliseconds: 250));
        expect(controller.validated, isTrue);
      });
    });

    test('la pose déjà tenue en arrivant à l\'étape se valide aussi', () {
      inFakeAsync((async) {
        put(DuoPose.openPortrait, autoAdvance: false);
        controller.next(); // bienvenue -> « Ouvrez-le », déjà ouvert
        async.elapse(_hold + const Duration(milliseconds: 10));
        expect(controller.validated, isTrue);
      });
    });

    test('une mauvaise pose ne valide pas l\'étape', () {
      inFakeAsync((async) {
        controller.next();
        put(DuoPose.halfOpenBook, autoAdvance: false);
        async.elapse(const Duration(seconds: 10));
        expect(controller.validated, isFalse);
        expect(controller.step, DuoTutorialStep.open);
      });
    });

    test('la validation survit si l\'on bouge ensuite : elle est acquise', () {
      inFakeAsync((async) {
        controller.next();
        put(DuoPose.openPortrait, autoAdvance: false);
        async.elapse(_hold + const Duration(milliseconds: 10));
        put(DuoPose.closed, autoAdvance: false);
        expect(controller.validated, isTrue);
      });
    });
  });

  group('l\'étape suivante, toute seule ou à la main', () {
    test('après la réussite, l\'étape suivante arrive d\'elle-même', () {
      inFakeAsync((async) {
        controller.next();
        put(DuoPose.openPortrait);
        async.elapse(_hold + _advance + const Duration(milliseconds: 20));
        expect(controller.step, DuoTutorialStep.book);
        expect(controller.validated, isFalse);
      });
    });

    test('pas d\'avance automatique pour VoiceOver (autoAdvance faux)', () {
      inFakeAsync((async) {
        controller.next();
        put(DuoPose.openPortrait, autoAdvance: false);
        async.elapse(const Duration(seconds: 20));
        expect(controller.step, DuoTutorialStep.open);
        expect(controller.validated, isTrue);
      });
    });

    test(
      'couper l\'avance automatique après la réussite annule celle qui est prévue',
      () {
        inFakeAsync((async) {
          controller.next();
          put(DuoPose.openPortrait);
          async.elapse(_hold + const Duration(milliseconds: 100));
          put(DuoPose.openPortrait, autoAdvance: false);
          async.elapse(const Duration(seconds: 20));
          expect(controller.step, DuoTutorialStep.open);
        });
      },
    );

    test('« Suivant » passe l\'étape sans le geste', () {
      inFakeAsync((async) {
        put(DuoPose.closed);
        controller.next();
        expect(controller.step, DuoTutorialStep.open);
        expect(controller.validated, isFalse);
        controller.next();
        expect(controller.step, DuoTutorialStep.book);
      });
    });

    test('« Suivant » après la réussite ne saute pas deux étapes', () {
      inFakeAsync((async) {
        controller.next();
        put(DuoPose.openPortrait);
        async.elapse(_hold + const Duration(milliseconds: 100));
        controller.next();
        async.elapse(const Duration(seconds: 20));
        expect(controller.step, DuoTutorialStep.book);
      });
    });

    test('toutes les étapes se passent à la main jusqu\'à la fin', () {
      inFakeAsync((async) {
        var finished = 0;
        controller.addListener(() {
          if (controller.finished) finished++;
        });
        for (var i = 0; i < DuoTutorialStep.values.length - 1; i++) {
          controller.next();
        }
        expect(controller.step, DuoTutorialStep.ready);
        expect(controller.finished, isFalse);
        controller.next();
        expect(controller.finished, isTrue);
        expect(finished, 1);
      });
    });

    test('« Passer » termine tout de suite, à n\'importe quelle étape', () {
      inFakeAsync((async) {
        controller.next();
        controller.skip();
        expect(controller.finished, isTrue);
      });
    });

    test('rien ne bouge une fois terminé', () {
      inFakeAsync((async) {
        controller.next();
        put(DuoPose.openPortrait);
        controller.skip();
        final sent = renderer.poses.length;
        async.elapse(const Duration(seconds: 20));
        put(DuoPose.halfOpenBook);
        controller.next();
        expect(controller.step, DuoTutorialStep.open);
        expect(renderer.poses, hasLength(sent));
      });
    });

    test('l\'indice d\'étape va de 0 à 5', () {
      inFakeAsync((async) {
        expect(controller.index, 0);
        controller.next();
        expect(controller.index, 1);
      });
    });
  });

  test('les écouteurs sont prévenus à chaque étape et à chaque réussite', () {
    inFakeAsync((async) {
      var notified = 0;
      controller.addListener(() => notified++);
      controller.next();
      final afterNext = notified;
      expect(afterNext, greaterThan(0));
      put(DuoPose.openPortrait, autoAdvance: false);
      async.elapse(_hold + const Duration(milliseconds: 10));
      expect(notified, greaterThan(afterNext));
    });
  });

  test('dispose coupe les minuteries : rien ne part après coup', () {
    fakeAsync((async) {
      final fake = FakeDuoSceneRenderer();
      final c = DuoTutorialController(
        renderer: fake,
        holdDuration: _hold,
        advanceDelay: _advance,
      );
      c.next();
      c.update(
        fold: DuoPose.openPortrait.foldState,
        size: DuoPose.openPortrait.size,
      );
      c.dispose();
      expect(() => async.elapse(const Duration(seconds: 10)), returnsNormally);
    });
  });
}
