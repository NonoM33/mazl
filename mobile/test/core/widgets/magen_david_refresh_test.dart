import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/widgets/magen_david_refresh.dart';

const _size = Size.square(36);

double _length(Path path) =>
    path.computeMetrics().fold(0.0, (sum, m) => sum + m.length);

MagenDavidPainter _painter(double progress) =>
    MagenDavidPainter(progress: progress, color: Colors.blue);

MagenDavidPainter _livePainter(WidgetTester tester) {
  final paints = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((p) => p.painter)
      .whereType<MagenDavidPainter>();
  return paints.single;
}

Widget _app({
  required Future<void> Function() onRefresh,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Scaffold(
          body: MagenDavidRefresh(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < 20; i++)
                  SizedBox(height: 60, child: Text('$i')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('MagenDavidPainter', () {
    test('draws nothing at 0 %', () {
      final p = _painter(0);
      expect(_length(p.upwardPath(_size)), 0);
      expect(_length(p.downwardPath(_size)), 0);
    });

    test('traces the upward triangle first, the downward one second', () {
      final full = _length(_painter(0.5).upwardPath(_size));
      // Equilateral triangle inscribed in the radius: perimeter 3 r sqrt(3).
      final r = _size.shortestSide / 2 - 1.5;
      expect(full, closeTo(3 * r * math.sqrt(3), 0.01));

      final quarter = _painter(0.25);
      expect(_length(quarter.upwardPath(_size)), closeTo(full / 2, 0.01));
      expect(_length(quarter.downwardPath(_size)), 0);

      final threeQuarters = _painter(0.75);
      expect(_length(threeQuarters.upwardPath(_size)), closeTo(full, 0.01));
      expect(
        _length(threeQuarters.downwardPath(_size)),
        closeTo(full / 2, 0.01),
      );
    });

    test('is a complete interlaced star at 100 %', () {
      final p = _painter(1);
      final up = _length(p.upwardPath(_size));
      expect(up, greaterThan(0));
      expect(_length(p.downwardPath(_size)), closeTo(up, 0.01));
    });

    test('never draws more than the full star past 100 %', () {
      expect(_painter(3).downwardFraction, 1);
      expect(_painter(-1).upwardFraction, 0);
    });

    test('repaints only when something visible changes', () {
      final a = _painter(0.4);
      expect(a.shouldRepaint(_painter(0.4)), isFalse);
      expect(a.shouldRepaint(_painter(0.5)), isTrue);
      expect(
        a.shouldRepaint(
          const MagenDavidPainter(
            progress: 0.4,
            color: Colors.blue,
            rotation: 1,
          ),
        ),
        isTrue,
      );
    });
  });

  group('MagenDavidRefresh', () {
    final haptics = <String>[];

    setUp(() {
      haptics.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments as String);
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets(
      'a pull past the threshold calls onRefresh once, light haptic',
      (tester) async {
        var calls = 0;
        final done = Completer<void>();
        await tester.pumpWidget(
          _app(
            onRefresh: () {
              calls++;
              return done.future;
            },
          ),
        );

        await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));

        expect(calls, 1);
        expect(haptics, contains('HapticFeedbackType.lightImpact'));
        done.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('a short pull does not refresh nor vibrate', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_app(onRefresh: () async => calls++));

      final gesture = await tester.startGesture(const Offset(200, 200));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(haptics, isEmpty);
    });

    testWidgets('traces progressively while pulling', (tester) async {
      final done = Completer<void>();
      await tester.pumpWidget(_app(onRefresh: () => done.future));

      final gesture = await tester.startGesture(const Offset(200, 200));
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      final early = _livePainter(tester).progress;
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      final late = _livePainter(tester).progress;

      expect(early, greaterThan(0));
      expect(late, greaterThan(early));
      await gesture.up();
      done.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('turns while loading and says « Actualisation »', (
      tester,
    ) async {
      final done = Completer<void>();
      await tester.pumpWidget(_app(onRefresh: () => done.future));
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pump(const Duration(milliseconds: 600));

      final first = _livePainter(tester).rotation;
      await tester.pump(const Duration(milliseconds: 600));
      final second = _livePainter(tester).rotation;

      expect(second, isNot(first));
      expect(_livePainter(tester).progress, 1);
      expect(find.bySemanticsLabel('Actualisation'), findsOneWidget);

      done.complete();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Actualisation'), findsNothing);
    });

    testWidgets('Reduce Motion: no rotation, no progressive tracing', (
      tester,
    ) async {
      final done = Completer<void>();
      await tester.pumpWidget(
        _app(onRefresh: () => done.future, reduceMotion: true),
      );

      final gesture = await tester.startGesture(const Offset(200, 200));
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      // A small pull already shows the complete star, not a partial tracing.
      expect(_livePainter(tester).progress, 1);
      await gesture.moveBy(const Offset(0, 300));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pump(const Duration(milliseconds: 800));
      expect(_livePainter(tester).rotation, 0);
      expect(find.bySemanticsLabel('Actualisation'), findsOneWidget);

      done.complete();
      await tester.pumpAndSettle();
    });
  });

  group('no bare RefreshIndicator in lib/', () {
    const widgetFile = 'lib/core/widgets/magen_david_refresh.dart';
    final bare = RegExp(r'\bRefreshIndicator\s*(\.\w+)?\s*\(');

    List<String> offenders() {
      final out = <String>[];
      for (final e in Directory('lib').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart') || e.path == widgetFile) {
          continue;
        }
        final code = e
            .readAsLinesSync()
            .where((l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        if (bare.hasMatch(code)) out.add(e.path);
      }
      return out..sort();
    }

    test('every pull-to-refresh goes through MagenDavidRefresh', () {
      expect(
        offenders(),
        isEmpty,
        reason:
            'Use MagenDavidRefresh (lib/core/widgets/magen_david_refresh.dart) '
            'instead of a bare RefreshIndicator.',
      );
    });

    test('the sweep sees screens that refresh, and the pattern matches', () {
      final users = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.readAsStringSync().contains('MagenDavidRefresh('))
          .length;
      expect(users, greaterThanOrEqualTo(10));
      expect(bare.hasMatch('return RefreshIndicator(\n onRefresh'), isTrue);
      expect(bare.hasMatch('RefreshIndicator.adaptive('), isTrue);
      expect(bare.hasMatch('MagenDavidRefresh('), isFalse);
    });
  });
}
