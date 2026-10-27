import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/presentation/features/chat/widgets/typing_indicator.dart';
import '../../helpers/l10n_helpers.dart';

// « … écrit » is a tekhelet thread that ties a knot like the ones of the
// tsitsit, then undoes it. The geometry is a pure function of the cycle time
// t in [0, 1): a knot is a loop, so the thread crosses itself while it is tied
// and never when it is undone.

const _bubble = Size(56, 36);

/// Two segments cross when each one's ends lie strictly on either side of the
/// other one (orientation test).
bool _segmentsCross(Offset a, Offset b, Offset c, Offset d) {
  double side(Offset p, Offset q, Offset r) =>
      (q.dx - p.dx) * (r.dy - p.dy) - (q.dy - p.dy) * (r.dx - p.dx);
  final d1 = side(a, b, c);
  final d2 = side(a, b, d);
  final d3 = side(c, d, a);
  final d4 = side(c, d, b);
  return d1 * d2 < 0 && d3 * d4 < 0;
}

/// True when two segments that do not touch each other cross: the thread
/// forms a loop.
bool _crossesItself(List<Offset> points) {
  for (var i = 0; i < points.length - 1; i++) {
    for (var j = i + 2; j < points.length - 1; j++) {
      if (_segmentsCross(points[i], points[i + 1], points[j], points[j + 1])) {
        return true;
      }
    }
  }
  return false;
}

TypingThreadPainter _painter(WidgetTester tester) {
  final paint = tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(TypingIndicator),
          matching: find.byType(CustomPaint),
        ),
      )
      .firstWhere((p) => p.painter is TypingThreadPainter);
  return paint.painter! as TypingThreadPainter;
}

Future<void> _pump(WidgetTester tester, {bool reduced = false}) =>
    pumpLocalized(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: const Scaffold(body: Center(child: TypingIndicator())),
        ),
      ),
    );

void main() {
  group('geometry of the thread', () {
    test('it is untied at the start of the cycle, a straight ripple', () {
      expect(_crossesItself(typingThreadPoints(0, _bubble)), isFalse);
      expect(_crossesItself(typingThreadPoints(0.05, _bubble)), isFalse);
    });

    test('the knot is tied in the middle of the cycle', () {
      expect(
        _crossesItself(
          typingThreadPoints(MazlMotion.typingThreadKnotFormed, _bubble),
        ),
        isTrue,
      );
    });

    test('it is untied again before the cycle ends', () {
      expect(_crossesItself(typingThreadPoints(0.95, _bubble)), isFalse);
      expect(_crossesItself(typingThreadPoints(0.999, _bubble)), isFalse);
    });

    test('the loop opens and closes: crossing only around the middle', () {
      final tied = [
        for (var i = 0; i < 100; i++)
          if (_crossesItself(typingThreadPoints(i / 100, _bubble))) i / 100,
      ];
      expect(tied, isNotEmpty);
      expect(tied.first, greaterThan(0.1));
      expect(tied.last, lessThan(0.9));
      // One contiguous stretch: it is tied once, not flickering.
      expect(tied.last - tied.first, closeTo((tied.length - 1) / 100, 1e-9));
    });

    test('it stays inside the bubble, stroke included, at every instant', () {
      for (var i = 0; i < 200; i++) {
        final points = typingThreadPoints(i / 200, _bubble);
        final margin = typingThreadStrokeWidth / 2;
        for (final p in points) {
          expect(p.dx, greaterThanOrEqualTo(margin), reason: 't=${i / 200}');
          expect(p.dx, lessThanOrEqualTo(_bubble.width - margin));
          expect(p.dy, greaterThanOrEqualTo(margin));
          expect(p.dy, lessThanOrEqualTo(_bubble.height - margin));
        }
      }
    });

    test('the middle of the cycle differs from the start', () {
      expect(
        typingThreadPoints(0, _bubble),
        isNot(typingThreadPoints(0.25, _bubble)),
      );
    });

    test(
      'no jump at the loop: t = 0 and t just below 1 are the same drawing',
      () {
        final start = typingThreadPoints(0, _bubble);
        final end = typingThreadPoints(1 - 1e-9, _bubble);
        expect(end.length, start.length);
        for (var i = 0; i < start.length; i++) {
          expect((end[i] - start[i]).distance, lessThan(1e-3), reason: 'i=$i');
        }
      },
    );

    test('both ends of the thread stay anchored', () {
      final first = typingThreadPoints(0, _bubble).first;
      final last = typingThreadPoints(0, _bubble).last;
      for (var i = 0; i < 20; i++) {
        final points = typingThreadPoints(i / 20, _bubble);
        expect((points.first - first).distance, lessThan(1e-9));
        expect((points.last - last).distance, lessThan(1e-9));
      }
    });
  });

  group('the typing bubble', () {
    testWidgets('keeps its 56 × 36 size and its semantics label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      expect(tester.getSize(find.byType(TypingIndicator)), const Size(56, 36));
      expect(
        find.bySemanticsLabel('Votre correspondant écrit'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('draws the thread in the accent colour and nothing else', (
      tester,
    ) async {
      await _pump(tester);
      final scheme = Theme.of(
        tester.element(find.byType(TypingIndicator)),
      ).colorScheme;
      expect(_painter(tester).color, scheme.primary);
    });

    testWidgets('the thread is redrawn as the cycle advances', (tester) async {
      await _pump(tester);
      final first = _painter(tester).t;
      await tester.pump(MazlMotion.typingThreadCycle ~/ 3);
      final second = _painter(tester).t;
      expect(second, isNot(first));
      expect(
        typingThreadPoints(second, _bubble),
        isNot(typingThreadPoints(first, _bubble)),
      );
    });

    testWidgets('the knot ties and unties while it runs', (tester) async {
      await _pump(tester);
      var sawTied = false;
      var sawUntied = false;
      for (var i = 0; i < 36; i++) {
        final crossing = _crossesItself(
          typingThreadPoints(_painter(tester).t, _bubble),
        );
        sawTied = sawTied || crossing;
        sawUntied = sawUntied || !crossing;
        await tester.pump(MazlMotion.typingThreadCycle ~/ 36);
      }
      expect(sawTied, isTrue);
      expect(sawUntied, isTrue);
    });

    testWidgets('reduced motion: no frame is scheduled, the knot is tied', (
      tester,
    ) async {
      await _pump(tester, reduced: true);
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      final painter = _painter(tester);
      expect(painter.t, MazlMotion.typingThreadKnotFormed);
      expect(_crossesItself(typingThreadPoints(painter.t, _bubble)), isTrue);
      await tester.pump(MazlMotion.typingThreadCycle);
      expect(_painter(tester).t, MazlMotion.typingThreadKnotFormed);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('turning reduced motion on while it runs freezes the knot', (
      tester,
    ) async {
      await _pump(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await _pump(tester, reduced: true);
      // The frame the stopped ticker had already asked for may still run.
      await tester.pump();
      await tester.pump(MazlMotion.typingThreadCycle);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(_painter(tester).t, MazlMotion.typingThreadKnotFormed);
    });

    for (final brightness in Brightness.values) {
      testWidgets('uses the theme colours in ${brightness.name} mode', (
        tester,
      ) async {
        await pumpLocalized(
          tester,
          const Scaffold(body: Center(child: TypingIndicator())),
          brightness: brightness,
        );
        final scheme = Theme.of(
          tester.element(find.byType(TypingIndicator)),
        ).colorScheme;
        expect(_painter(tester).color, scheme.primary);
      });
    }
  });
}
