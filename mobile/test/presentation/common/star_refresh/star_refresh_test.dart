import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/fold_state.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/presentation/common/widgets/star_refresh/star_frame.dart';
import 'package:mazl/presentation/common/widgets/star_refresh/star_painter.dart';
import 'package:mazl/presentation/common/widgets/star_refresh/star_refresh.dart';

// docs/design/MOUVEMENT.md §7bis and pull-refresh-proposition.html (variant A,
// « Le trait », chosen by Renaud on 2026-10-27): pull past the threshold and
// let go to refresh; one tick at the threshold, one at the bloom; the loading
// always ends on an upright star; the list is held under the star, then goes
// back up.

Future<List<String>> _recordHaptics(WidgetTester tester) async {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

Widget _rows(int count) => ListView.builder(
  itemCount: count,
  itemBuilder: (context, i) => SizedBox(height: 60, child: Text('row $i')),
);

Future<void> _pump(
  WidgetTester tester, {
  required RefreshCallback onRefresh,
  Widget? child,
  bool reduced = false,
  FoldState fold = FoldState.unknown,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: FoldScope(state: fold, child: page!),
      ),
      home: Scaffold(
        body: StarRefresh(onRefresh: onRefresh, child: child ?? _rows(30)),
      ),
    ),
  );
}

/// Pulls [target] down by [distance] of finger travel, slowly, and lets go.
Future<void> _pull(
  WidgetTester tester,
  double distance, {
  Finder? target,
}) async {
  final gesture = await tester.startGesture(
    tester.getTopLeft(target ?? find.byType(ListView)) + const Offset(20, 40),
  );
  for (var done = 0.0; done < distance; done += 10) {
    await gesture.moveBy(const Offset(0, 10));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump();
}

StarPainter? _star(WidgetTester tester) {
  final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
  for (final paint in paints) {
    if (paint.painter is StarPainter) return paint.painter! as StarPainter;
  }
  return null;
}

double _rowTop(WidgetTester tester) => tester.getTopLeft(find.text('row 0')).dy;

/// Pump until [condition] holds, frame by frame, at most [limit].
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration limit = const Duration(seconds: 5),
}) async {
  var waited = Duration.zero;
  while (!condition() && waited < limit) {
    await tester.pump(const Duration(milliseconds: 8));
    waited += const Duration(milliseconds: 8);
  }
}

void main() {
  testWidgets('a pull past the threshold refreshes once, and the list is held '
      'under the star until the refresh is done', (tester) async {
    final done = Completer<void>();
    var refreshes = 0;
    await _pump(
      tester,
      onRefresh: () {
        refreshes++;
        return done.future;
      },
    );
    final restingTop = _rowTop(tester);

    await _pull(tester, 400);
    await tester.pump(const Duration(seconds: 2));

    expect(refreshes, 1);
    expect(
      _rowTop(tester) - restingTop,
      moreOrLessEquals(MazlMotion.refreshHold, epsilon: 1),
    );
    expect(_star(tester), isNotNull);

    done.complete();
    await tester.pumpAndSettle();
    expect(_rowTop(tester), moreOrLessEquals(restingTop, epsilon: 0.5));
    expect(refreshes, 1);
  });

  testWidgets('a pull short of the threshold does nothing', (tester) async {
    final haptics = await _recordHaptics(tester);
    var refreshes = 0;
    await _pump(tester, onRefresh: () async => refreshes++);

    await _pull(tester, 60);
    await tester.pumpAndSettle();

    expect(refreshes, 0);
    expect(haptics, isEmpty);
  });

  testWidgets('one selection tick at the threshold, one light impact at the '
      'bloom, never before a whole turn', (tester) async {
    final haptics = await _recordHaptics(tester);
    await _pump(tester, onRefresh: () async {});

    await _pull(tester, 400);
    expect(haptics, ['HapticFeedbackType.selectionClick']);

    // The refresh is already done, yet the star finishes its first turn.
    await tester.pump(MazlMotion.refreshCycle * 0.9);
    expect(haptics, ['HapticFeedbackType.selectionClick']);

    await tester.pumpAndSettle();
    expect(haptics, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
    ]);
  });

  testWidgets('pulling back above the threshold and down again ticks once', (
    tester,
  ) async {
    final haptics = await _recordHaptics(tester);
    await _pump(tester, onRefresh: () async {});

    final gesture = await tester.startGesture(const Offset(100, 200));
    for (final dy in [...List.filled(40, 10.0), ...List.filled(20, -10.0)]) {
      await gesture.moveBy(Offset(0, dy));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.moveBy(const Offset(0, -400));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  testWidgets('the loading ends on an upright star', (tester) async {
    final haptics = await _recordHaptics(tester);
    final done = Completer<void>();
    await _pump(tester, onRefresh: () => done.future);
    await _pull(tester, 400);

    // Done in the middle of the second turn.
    await tester.pump(MazlMotion.refreshCycle * 1.4);
    done.complete();
    await _pumpUntil(
      tester,
      () => haptics.contains('HapticFeedbackType.lightImpact'),
    );

    final frame = _star(tester)!.frame;
    final third = 2 * math.pi / 3;
    final offUpright = (frame.turn % third).abs();
    expect(math.min(offUpright, third - offUpright), lessThan(0.05));
  });

  testWidgets('a list shorter than the screen can be pulled', (tester) async {
    var refreshes = 0;
    await _pump(tester, onRefresh: () async => refreshes++, child: _rows(2));

    await _pull(tester, 400);
    await tester.pumpAndSettle();

    expect(refreshes, 1);
  });

  testWidgets('reduced motion: the star never turns, no bloom swell, and the '
      'list is back quickly', (tester) async {
    final done = Completer<void>();
    await _pump(tester, onRefresh: () => done.future, reduced: true);
    final restingTop = _rowTop(tester);

    await _pull(tester, 400);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 130));
      final frame = _star(tester)!.frame;
      expect(frame.turn, 0);
      expect(frame.scale, 1);
    }

    // A fade, then a short return: each starts on the next frame.
    done.complete();
    await tester.pump();
    await tester.pump(MazlMotion.reducedFade);
    await tester.pump(MazlMotion.reducedReturn);
    await tester.pump(const Duration(milliseconds: 16));
    expect(_rowTop(tester), moreOrLessEquals(restingTop, epsilon: 0.5));
  });

  testWidgets('held like a book: the star sits on the pulled page, out of the '
      'fold', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const fold = Rect.fromLTWH(390, 0, 20, 600);
    await _pump(
      tester,
      onRefresh: () async {},
      fold: const FoldState(
        hinge: HingeStatus.partiallyOpen,
        divisions: [fold],
      ),
      child: Row(
        children: [
          SizedBox(width: 390, child: _rows(30)),
          const SizedBox(width: 20),
          Expanded(
            child: ListView(
              key: const Key('right page'),
              children: [for (var i = 0; i < 30; i++) Text('right $i')],
            ),
          ),
        ],
      ),
    );

    await _pull(tester, 400, target: find.byKey(const Key('right page')));
    final star = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is StarPainter,
      ),
    );

    expect(star.overlaps(fold), isFalse);
    expect(star.center.dx, moreOrLessEquals(605, epsilon: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('a list running across the fold puts the star on its wider '
      'side', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const fold = Rect.fromLTWH(390, 0, 20, 600);
    await _pump(
      tester,
      onRefresh: () async {},
      fold: const FoldState(
        hinge: HingeStatus.partiallyOpen,
        divisions: [fold],
      ),
    );

    await _pull(tester, 400);
    final star = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is StarPainter,
      ),
    );

    expect(star.overlaps(fold), isFalse);
    await tester.pumpAndSettle();
  });

  group('StarFrame, from the approved mock-up', () {
    test(
      'half pulled: the upward triangle is drawn, the downward one not yet',
      () {
        final frame = StarFrame.of(const StarPulled(0.5));
        expect(frame.up, StrokeSpan.whole);
        expect(frame.down.length, 0);
      },
    );

    test('fully pulled: both triangles, upright, full size, no fill', () {
      final frame = StarFrame.of(const StarPulled(1));
      expect(frame.up.length, 1);
      expect(frame.down.length, 1);
      expect(frame.turn, 0);
      expect(frame.scale, 1);
      expect(frame.fill, 0);
    });

    test('loading: the triangles become comets of the approved length', () {
      final frame = StarFrame.of(
        StarLoading(MazlMotion.refreshCometShrink * 2),
      );
      expect(frame.up.length, closeTo(MazlMotion.refreshCometShare, 1e-9));
      expect(frame.down.length, closeTo(MazlMotion.refreshCometShare, 1e-9));
    });

    test('bloom: swells to the approved scale and fills, then settles', () {
      final peak = StarFrame.of(const StarBlooming(0.3));
      expect(peak.scale, closeTo(MazlMotion.refreshBloomScale, 1e-9));
      expect(peak.fill, greaterThan(0.5));
      final end = StarFrame.of(const StarBlooming(1));
      expect(end.scale, closeTo(1, 1e-9));
      expect(end.fill, closeTo(0, 1e-9));
      expect(end.up.length, 1);
    });
  });
}
