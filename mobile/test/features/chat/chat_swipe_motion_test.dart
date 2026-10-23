import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/presentation/features/chat/widgets/swipe_to_reply.dart';

// docs/design/CHAT.md §6 and balayages-proposition.html (Geste 2): past the
// threshold the row resists, the icon pops, the release is a spring seeded
// with the finger's velocity.

const _row = Key('row');
const _pop = Key('reply-icon-pop');

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

Future<void> _pumpRow(
  WidgetTester tester, {
  bool reduced = false,
  VoidCallback? onReply,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SwipeToReply(
            onReply: onReply ?? () {},
            child: const SizedBox(key: _row, width: 200, height: 48),
          ),
        ),
      ),
    ),
  );
}

double _x(WidgetTester tester) => tester.getTopLeft(find.byKey(_row)).dx;

double _popScale(WidgetTester tester) =>
    tester.widget<ScaleTransition>(find.byKey(_pop)).scale.value;

/// Drags [total] px to the right in [steps] moves, [stepMs] apart.
Future<TestGesture> _drag(
  WidgetTester tester,
  double total, {
  int steps = 8,
  int stepMs = 16,
}) async {
  final gesture = await tester.startGesture(tester.getCenter(find.byKey(_row)));
  var t = 0;
  // The first move only crosses the touch slop.
  t += stepMs;
  await gesture.moveBy(
    const Offset(20, 0),
    timeStamp: Duration(milliseconds: t),
  );
  final each = (total - 20) / steps;
  for (var i = 0; i < steps; i++) {
    t += stepMs;
    await gesture.moveBy(Offset(each, 0), timeStamp: Duration(milliseconds: t));
  }
  await tester.pump();
  return gesture;
}

void main() {
  group('swipe to reply motion', () {
    testWidgets('1:1 up to the threshold, then x0.35, stopping at 110', (
      tester,
    ) async {
      await _pumpRow(tester);
      final home = _x(tester);
      final gesture = await _drag(tester, 40);
      expect(_x(tester) - home, closeTo(40, 1.0)); // 1:1 below 64
      await gesture.moveBy(const Offset(54, 0)); // finger at 94: 30 past 64
      await tester.pump();
      expect(
        _x(tester) - home,
        closeTo(
          MazlMotion.replyThreshold + 30 * MazlMotion.replyResistance,
          0.5,
        ),
      );
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();
      expect(_x(tester) - home, closeTo(MazlMotion.replyMaxOffset, 0.01));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the icon pops once at the threshold, then settles at 1', (
      tester,
    ) async {
      await _pumpRow(tester);
      final gesture = await _drag(tester, 50);
      expect(find.byKey(_pop), findsOneWidget);
      expect(_popScale(tester), 1.0);
      await gesture.moveBy(const Offset(30, 0)); // crosses 64
      await tester.pump();
      await tester.pump(MazlMotion.popDuration * 0.5);
      expect(_popScale(tester), closeTo(MazlMotion.popScale, 0.02));
      await tester.pump(MazlMotion.popDuration);
      expect(_popScale(tester), 1.0);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('lightImpact once per crossing of the threshold', (
      tester,
    ) async {
      final haptics = await _recordHaptics(tester);
      await _pumpRow(tester);
      final gesture = await _drag(tester, 50);
      expect(haptics, isEmpty);
      await gesture.moveBy(const Offset(30, 0)); // 80: armed
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0)); // still armed
      await tester.pump();
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      await gesture.moveBy(const Offset(-120, 0)); // back under 64
      await tester.pump();
      await gesture.moveBy(const Offset(120, 0)); // crosses again
      await tester.pump();
      expect(haptics, [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.lightImpact',
      ]);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the release is a spring: not instantly 0, but reaches 0', (
      tester,
    ) async {
      await _pumpRow(tester);
      final home = _x(tester);
      final gesture = await _drag(tester, 90);
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(_x(tester) - home, greaterThan(1));
      await tester.pumpAndSettle();
      expect(_x(tester), home);
    });

    testWidgets('a fast release leaves faster than a slow one (velocity)', (
      tester,
    ) async {
      Future<double> firstFrames(int stepMs) async {
        await _pumpRow(tester);
        final home = _x(tester);
        final gesture = await _drag(tester, 70, stepMs: stepMs);
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 32));
        final moved = _x(tester) - home;
        await tester.pumpAndSettle();
        return moved;
      }

      final fast = await firstFrames(4);
      final slow = await firstFrames(120);
      expect(fast, greaterThan(slow + 1));
    });

    testWidgets('releasing past the threshold replies', (tester) async {
      var replies = 0;
      await _pumpRow(tester, onReply: () => replies++);
      final gesture = await _drag(tester, 90);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(replies, 1);
    });

    testWidgets(
      'reduce motion: clamps at the threshold, no pop, back in 120 ms',
      (tester) async {
        await _pumpRow(tester, reduced: true);
        final home = _x(tester);
        final gesture = await _drag(tester, 70);
        await gesture.moveBy(const Offset(200, 0));
        await tester.pump();
        expect(_x(tester) - home, closeTo(MazlMotion.replyThreshold, 0.01));
        expect(_popScale(tester), 1.0);
        await tester.pump(MazlMotion.popDuration * 0.5);
        expect(_popScale(tester), 1.0);
        await gesture.up();
        await tester.pump();
        await tester.pump(
          MazlMotion.reducedReturn + const Duration(milliseconds: 16),
        );
        expect(_x(tester), home);
      },
    );
  });
}
