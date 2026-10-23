import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/presentation/common/widgets/swipe_deck/swipe_deck.dart';

import '../../../helpers/swipe_gestures.dart';

const _cardSize = Size(400, 600);

/// A deck of [count] plain cards, each with a tappable area and a button that
/// leans in with the like progress.
class _Rig {
  _Rig({
    this.count = 3,
    this.allowed = const {
      SwipeDirection.left,
      SwipeDirection.right,
      SwipeDirection.up,
    },
    this.heavyHapticOn = const {},
  });

  final int count;
  final Set<SwipeDirection> allowed;
  SwipeVerdict? verdict;
  final Set<SwipeDirection> heavyHapticOn;

  final controller = SwipeDeckController();
  final List<String> events = [];
  int taps = 0;

  Widget build({bool reducedMotion = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Scaffold(
          body: Center(
            child: SizedBox.fromSize(
              size: _cardSize,
              child: SwipeDeck(
                controller: controller,
                itemCount: count,
                allowed: allowed,
                heavyHapticOn: heavyHapticOn,
                intents: const {
                  SwipeDirection.right: SwipeIntent(
                    icon: LucideIcons.heart,
                    color: Colors.blue,
                  ),
                  SwipeDirection.left: SwipeIntent(
                    icon: LucideIcons.x,
                    color: Colors.grey,
                  ),
                  SwipeDirection.up: SwipeIntent(
                    icon: LucideIcons.star,
                    color: Colors.blue,
                  ),
                },
                onWillSwipe: (index, direction) {
                  events.add('will $index ${direction.name}');
                  return verdict?.call(index, direction) ?? true;
                },
                onSwiped: (index, direction) =>
                    events.add('swiped $index ${direction.name}'),
                onRefused: (index, direction) =>
                    events.add('refused $index ${direction.name}'),
                onUndone: (index) => events.add('undone $index'),
                onEnd: () => events.add('end'),
                cardBuilder: (context, index, isTop) => ColoredBox(
                  key: Key('card-$index'),
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          key: Key('tap-$index'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => taps++,
                          child: const SizedBox(width: 100, height: 100),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: SwipeProgressScale(
                          progress: controller.progress,
                          direction: SwipeDirection.right,
                          child: SizedBox(
                            key: Key('button-$index'),
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<_Rig> _pump(
  WidgetTester tester, {
  _Rig? rig,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = const Size(600, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final r = rig ?? _Rig();
  await tester.pumpWidget(r.build(reducedMotion: reducedMotion));
  return r;
}

Finder _card(int i) => find.byKey(Key('card-$i'));

/// The transform applied to a card by the deck: its nearest Transform ancestor.
Matrix4 _matrixOf(WidgetTester tester, int i) => tester
    .widget<Transform>(
      find.ancestor(of: _card(i), matching: find.byType(Transform)).first,
    )
    .transform;

double _angle(Matrix4 m) => math.atan2(m.entry(1, 0), m.entry(0, 0));

double _opacityOfIcon(WidgetTester tester, IconData icon) => tester
    .widget<Opacity>(
      find
          .ancestor(of: find.byIcon(icon), matching: find.byType(Opacity))
          .first,
    )
    .opacity;

double _centerX(WidgetTester tester, int i) => tester.getCenter(_card(i)).dx;

void main() {
  group('while the finger is down', () {
    testWidgets('the card follows the finger 1:1', (tester) async {
      await _pump(tester);
      final rest = tester.getCenter(_card(0));

      final g = await holdDrag(tester, _card(0), const Offset(70, -30));

      final moved = tester.getCenter(_card(0)) - rest;
      // The pivot is the grab point: the centre turns a little around it.
      expect(moved.dx, closeTo(70, 3));
      expect(moved.dy, closeTo(-30, 3));
      await g.up();
      await settle(tester);
    });

    testWidgets(
      'rotation follows dx, up to the maximum, pivoting on the grab',
      (tester) async {
        await _pump(tester);

        final g = await holdDrag(tester, _card(0), const Offset(200, 0));

        final degrees = _angle(_matrixOf(tester, 0)) * 180 / math.pi;
        expect(degrees, closeTo(MazlMotion.deckMaxRotationDegrees / 2, 0.01));
        await g.up();
        await settle(tester);
      },
    );

    testWidgets('a card grabbed by its lower half turns the other way', (
      tester,
    ) async {
      await _pump(tester);

      final upper = await holdDrag(
        tester,
        _card(0),
        const Offset(100, 0),
        from: const Offset(0, -200),
      );
      final upperAngle = _angle(_matrixOf(tester, 0));
      await upper.up();
      await settle(tester);

      final lower = await holdDrag(
        tester,
        _card(0),
        const Offset(100, 0),
        from: const Offset(0, 200),
      );
      final lowerAngle = _angle(_matrixOf(tester, 0));
      await lower.up();
      await settle(tester);

      expect(upperAngle, greaterThan(0));
      expect(lowerAngle, closeTo(-upperAngle, 1e-9));
    });

    testWidgets('the card below grows from 0.96 to 1 and rises with the drag', (
      tester,
    ) async {
      await _pump(tester);
      expect(
        _matrixOf(tester, 1).entry(0, 0),
        closeTo(MazlMotion.deckBackScale, 1e-9),
      );
      expect(
        _matrixOf(tester, 1).getTranslation().y,
        closeTo(MazlMotion.deckBackOffset, 0.5),
      );

      final g = await holdDrag(tester, _card(0), const Offset(100, 0));
      final quarter = _matrixOf(tester, 1).entry(0, 0);
      await g.up();
      await settle(tester);

      final progress = 100 / _cardSize.width;
      expect(
        quarter,
        closeTo(
          MazlMotion.deckBackScale + (1 - MazlMotion.deckBackScale) * progress,
          1e-6,
        ),
      );
      expect(quarter, greaterThan(MazlMotion.deckBackScale));
    });

    testWidgets('the intent disc fades in with the progress, per direction', (
      tester,
    ) async {
      await _pump(tester);
      expect(_opacityOfIcon(tester, LucideIcons.heart), 0);

      final threshold = MazlMotion.deckThreshold * _cardSize.width;
      final g = await holdDrag(tester, _card(0), Offset(threshold / 2, 0));
      expect(_opacityOfIcon(tester, LucideIcons.heart), closeTo(0.5, 0.02));
      expect(_opacityOfIcon(tester, LucideIcons.x), 0);
      await g.moveBy(Offset(threshold, 0));
      await tester.pump(const Duration(milliseconds: 20));
      expect(_opacityOfIcon(tester, LucideIcons.heart), 1);
      await g.up();
      await settle(tester);
    });

    testWidgets('the disc is white and grows from its minimum scale', (
      tester,
    ) async {
      await _pump(tester);
      final threshold = MazlMotion.deckThreshold * _cardSize.width;
      final g = await holdDrag(tester, _card(0), Offset(threshold / 2, 0));

      final disc = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byIcon(LucideIcons.heart),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((disc.decoration as BoxDecoration).color, const Color(0xFFFFFFFF));
      expect((disc.decoration as BoxDecoration).boxShadow, isNull);
      final scale = tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byIcon(LucideIcons.heart),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .entry(0, 0);
      expect(
        scale,
        closeTo(
          MazlMotion.intentDiscMinScale +
              (1 - MazlMotion.intentDiscMinScale) * 0.5,
          0.02,
        ),
      );
      await g.up();
      await settle(tester);
    });

    testWidgets('the matching button grows up to its maximum with progress', (
      tester,
    ) async {
      await _pump(tester);
      double scale() => tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byKey(const Key('button-0')),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .entry(0, 0);
      expect(scale(), 1);

      final threshold = MazlMotion.deckThreshold * _cardSize.width;
      final g = await holdDrag(tester, _card(0), Offset(threshold / 2, 0));
      expect(
        scale(),
        closeTo(1 + (MazlMotion.deckButtonMaxScale - 1) * 0.5, 0.01),
      );
      await g.moveBy(Offset(threshold, 0));
      await tester.pump(const Duration(milliseconds: 20));
      expect(scale(), closeTo(MazlMotion.deckButtonMaxScale, 1e-6));
      await g.up();
      await settle(tester);
    });

    testWidgets('down is resisted, never consumes, and springs back', (
      tester,
    ) async {
      final rig = await _pump(tester);
      final rest = tester.getCenter(_card(0));

      final g = await holdDrag(tester, _card(0), const Offset(0, 200));
      expect(
        tester.getCenter(_card(0)).dy - rest.dy,
        closeTo(200 * MazlMotion.deckBlockedResistance, 2),
      );
      await g.up();
      await settle(tester);

      expect(tester.getCenter(_card(0)).dy, closeTo(rest.dy, 0.5));
      expect(rig.events, isEmpty);
    });

    testWidgets('a direction the deck does not allow is resisted too', (
      tester,
    ) async {
      final rig = await _pump(
        tester,
        rig: _Rig(allowed: {SwipeDirection.left, SwipeDirection.up}),
      );
      final rest = _centerX(tester, 0);

      final g = await holdDrag(tester, _card(0), const Offset(300, 0));
      expect(_centerX(tester, 0) - rest, lessThan(300 * 0.3));
      expect(_opacityOfIcon(tester, LucideIcons.heart), 0);
      await g.up();
      await settle(tester);

      expect(rig.events, isEmpty);
      expect(_centerX(tester, 0), closeTo(rest, 0.5));
    });

    testWidgets('taps inside a card still reach their target', (tester) async {
      final rig = await _pump(tester);

      await tester.tap(find.byKey(const Key('tap-0')));

      expect(rig.taps, 1);
    });
  });

  group('release', () {
    testWidgets('short of the threshold, the card springs back with a little '
        'overshoot', (tester) async {
      final rig = await _pump(tester);
      final rest = _centerX(tester, 0);

      final g = await holdDrag(tester, _card(0), const Offset(90, 0));
      await g.up();
      var lowest = 0.0;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        lowest = math.min(lowest, _centerX(tester, 0) - rest);
      }

      expect(rig.events, isEmpty);
      expect(_centerX(tester, 0), closeTo(rest, 0.5));
      expect(lowest, lessThan(-0.5), reason: 'a spring overshoots');
    });

    testWidgets('past the threshold, the card leaves in the exit duration, '
        'decelerating', (tester) async {
      final rig = await _pump(tester);
      final g = await holdDrag(tester, _card(0), const Offset(140, 0));
      await g.up();

      final xs = <double>[];
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (rig.events.contains('swiped 0 right')) break;
        xs.add(_centerX(tester, 0));
      }
      expect(xs.first, greaterThan(_centerX(tester, 1) - 1 + 140 - 1));
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], greaterThan(xs[i - 1]));
      }
      final steps = <double>[
        for (var i = 1; i < xs.length; i++) xs[i] - xs[i - 1],
      ];
      expect(steps.first, greaterThan(steps.last), reason: 'decelerates');

      await tester.pump(MazlMotion.deckExit);
      expect(rig.events, ['will 0 right', 'swiped 0 right']);
      expect(_card(0), findsNothing);
      expect(_card(1), findsOneWidget);
    });

    testWidgets('the card below takes the top place at rest', (tester) async {
      await _pump(tester);
      await dragSlowly(tester, _card(0), const Offset(-160, 0));
      await settle(tester);

      expect(_matrixOf(tester, 1).entry(0, 0), 1);
      expect(_matrixOf(tester, 1).getTranslation().y, 0);
      expect(_card(2), findsOneWidget);
    });

    testWidgets('the last card leaving ends the deck', (tester) async {
      final rig = await _pump(tester, rig: _Rig(count: 1));
      await dragSlowly(tester, _card(0), const Offset(160, 0));
      await settle(tester);

      expect(rig.events, ['will 0 right', 'swiped 0 right', 'end']);
      expect(
        find.descendant(
          of: find.byType(SwipeDeck),
          matching: find.byType(Stack),
        ),
        findsNothing,
      );
    });

    testWidgets('only the top card can be grabbed', (tester) async {
      final rig = await _pump(tester);
      expect(
        find.ancestor(
          of: _card(1),
          matching: find.byWidgetPredicate(
            (w) => w is IgnorePointer && w.ignoring,
          ),
        ),
        findsOneWidget,
      );
      expect(rig.events, isEmpty);
    });
  });

  group('refusal', () {
    testWidgets('the card never leaves, springs back, and the parent hears '
        'after it is back', (tester) async {
      final rig = _Rig()..verdict = (_, __) => false;
      await _pump(tester, rig: rig);
      final rest = _centerX(tester, 0);

      final g = await holdDrag(tester, _card(0), const Offset(160, 0));
      final released = _centerX(tester, 0) - rest;
      await g.up();
      var refusedAt = double.nan;
      var farthest = 0.0;
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        farthest = math.max(farthest, _centerX(tester, 0) - rest);
        if (refusedAt.isNaN && rig.events.contains('refused 0 right')) {
          refusedAt = _centerX(tester, 0) - rest;
        }
      }

      expect(rig.events, ['will 0 right', 'refused 0 right']);
      expect(farthest, lessThanOrEqualTo(released + 1));
      expect(refusedAt.abs(), lessThan(1));
      expect(_card(0), findsOneWidget);
    });

    testWidgets('an asynchronous verdict holds the card still until it comes', (
      tester,
    ) async {
      final answer = Completer<bool>();
      final rig = _Rig()..verdict = (_, __) => answer.future;
      await _pump(tester, rig: rig);
      final g = await holdDrag(tester, _card(0), const Offset(160, 0));
      final held = _centerX(tester, 0);
      await g.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_centerX(tester, 0), held);

      answer.complete(true);
      await settle(tester);

      expect(rig.events, ['will 0 right', 'swiped 0 right']);
    });

    testWidgets('a button throw that is refused leaves the card in place', (
      tester,
    ) async {
      final rig = _Rig()..verdict = (_, d) => d != SwipeDirection.up;
      await _pump(tester, rig: rig);

      final left = await rig.controller.swipe(SwipeDirection.up);
      await settle(tester);

      expect(left, isFalse);
      expect(rig.events, ['will 0 up', 'refused 0 up']);
      expect(_card(0), findsOneWidget);
    });
  });

  group('the controller', () {
    testWidgets('swipe throws the card like a finger would', (tester) async {
      final rig = await _pump(tester);

      final future = rig.controller.swipe(SwipeDirection.right);
      await tester.pump(); // the animation starts on this frame
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        _centerX(tester, 0),
        greaterThan(tester.getCenter(find.byType(SwipeDeck)).dx + 20),
      );
      await settle(tester);

      expect(await future, isTrue);
      expect(rig.events, ['will 0 right', 'swiped 0 right']);
      expect(_card(0), findsNothing);
    });

    testWidgets('a direction the deck does not allow is ignored', (
      tester,
    ) async {
      final rig = await _pump(
        tester,
        rig: _Rig(allowed: {SwipeDirection.left, SwipeDirection.up}),
      );

      expect(await rig.controller.swipe(SwipeDirection.right), isFalse);
      expect(rig.events, isEmpty);
    });

    testWidgets(
      'undo brings the card back from the side it left, on a spring',
      (tester) async {
        final rig = await _pump(tester);
        await dragSlowly(tester, _card(0), const Offset(-160, 0));
        await settle(tester);
        expect(_card(0), findsNothing);
        final rest = _centerX(tester, 1);

        final future = rig.controller.undo();
        await tester.pump(const Duration(milliseconds: 40));
        expect(_centerX(tester, 0), lessThan(rest - 100));
        await settle(tester);

        expect(await future, isTrue);
        expect(_centerX(tester, 0), closeTo(rest, 0.5));
        expect(rig.events.last, 'undone 0');
      },
    );

    testWidgets('undo with nothing to undo does nothing', (tester) async {
      final rig = await _pump(tester);

      expect(await rig.controller.undo(), isFalse);
      expect(rig.events, isEmpty);
    });
  });

  group('haptics', () {
    testWidgets('selectionClick once at the threshold, again only after '
        'going back below and crossing again', (tester) async {
      final haptics = HapticLog(tester);
      await _pump(tester);
      final threshold = MazlMotion.deckThreshold * _cardSize.width;

      final g = await holdDrag(tester, _card(0), Offset(threshold - 20, 0));
      expect(haptics.calls, isEmpty);

      await g.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(haptics.calls, ['selectionClick']);

      await g.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(haptics.calls, ['selectionClick'], reason: 'still past it');

      await g.moveBy(const Offset(-80, 0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(haptics.calls, ['selectionClick'], reason: 'going back is silent');

      await g.moveBy(const Offset(80, 0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(haptics.calls, ['selectionClick', 'selectionClick']);
      await g.up();
      await settle(tester);
    });

    testWidgets('nothing at the exit, nothing on a button', (tester) async {
      final haptics = HapticLog(tester);
      final rig = await _pump(tester);

      unawaited(rig.controller.swipe(SwipeDirection.right));
      await settle(tester);

      expect(haptics.calls, isEmpty);
    });

    testWidgets('a committed gesture leaves with no haptic of its own', (
      tester,
    ) async {
      final haptics = HapticLog(tester);
      await _pump(tester);

      final g = await holdDrag(tester, _card(0), const Offset(170, 0));
      expect(haptics.calls, ['selectionClick']);
      haptics.clear();
      await g.up();
      await settle(tester);

      expect(haptics.calls, isEmpty);
    });

    testWidgets('a flick that never reached the threshold has no haptic', (
      tester,
    ) async {
      final haptics = HapticLog(tester);
      final rig = await _pump(tester);

      await flick(tester, _card(0), const Offset(60, 0), 40);
      await settle(tester);

      expect(rig.events, ['will 0 right', 'swiped 0 right']);
      expect(haptics.calls, isEmpty);
    });

    testWidgets('a super like by finger adds a medium impact, once', (
      tester,
    ) async {
      final haptics = HapticLog(tester);
      await _pump(tester, rig: _Rig(heavyHapticOn: {SwipeDirection.up}));

      final g = await holdDrag(tester, _card(0), const Offset(0, -200));
      await g.up();
      await settle(tester);

      expect(haptics.calls, ['selectionClick', 'mediumImpact']);
    });

    testWidgets('a refused super like gets no medium impact', (tester) async {
      final haptics = HapticLog(tester);
      final rig = _Rig(heavyHapticOn: {SwipeDirection.up})
        ..verdict = (_, __) => false;
      await _pump(tester, rig: rig);

      await dragSlowly(tester, _card(0), const Offset(0, -200));
      await settle(tester);

      expect(haptics.calls, ['selectionClick']);
    });
  });

  group('reduced motion', () {
    testWidgets('the card follows the finger without turning', (tester) async {
      await _pump(tester, reducedMotion: true);
      final rest = _centerX(tester, 0);

      final g = await holdDrag(tester, _card(0), const Offset(200, 0));

      expect(_angle(_matrixOf(tester, 0)), 0);
      expect(_centerX(tester, 0) - rest, closeTo(200, 0.5));
      await g.up();
      await settle(tester);
    });

    testWidgets('no pop, no scale: the disc only fades in', (tester) async {
      await _pump(tester, reducedMotion: true);
      final threshold = MazlMotion.deckThreshold * _cardSize.width;
      final g = await holdDrag(tester, _card(0), Offset(threshold + 10, 0));
      await tester.pump(MazlMotion.popDuration ~/ 2);

      final scale = tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byIcon(LucideIcons.heart),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .entry(0, 0);
      expect(scale, 1);
      expect(_opacityOfIcon(tester, LucideIcons.heart), 1);
      await g.up();
      await settle(tester);
    });

    testWidgets('the exit is a fade where the card is, not a throw', (
      tester,
    ) async {
      final rig = await _pump(tester, reducedMotion: true);
      final g = await holdDrag(tester, _card(0), const Offset(160, 0));
      final x = _centerX(tester, 0);
      await g.up();

      await tester.pump(); // the animation starts on this frame
      await tester.pump(MazlMotion.reducedFade ~/ 2);
      expect(_centerX(tester, 0), x);
      final fading = tester
          .widget<Opacity>(
            find.ancestor(of: _card(0), matching: find.byType(Opacity)).first,
          )
          .opacity;
      expect(fading, closeTo(0.5, 0.15));

      await tester.pump(MazlMotion.reducedFade);
      await tester.pump();
      expect(rig.events, ['will 0 right', 'swiped 0 right']);
      expect(_card(0), findsNothing);
    });

    testWidgets('the return is a short ease-out, with no overshoot', (
      tester,
    ) async {
      await _pump(tester, reducedMotion: true);
      final rest = _centerX(tester, 0);
      final g = await holdDrag(tester, _card(0), const Offset(90, 0));
      await g.up();

      var lowest = 0.0;
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        lowest = math.min(lowest, _centerX(tester, 0) - rest);
      }

      expect(_centerX(tester, 0), closeTo(rest, 0.5));
      expect(lowest, greaterThanOrEqualTo(-0.01));
    });
  });
}
