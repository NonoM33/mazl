import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/presentation/common/widgets/like_fill/like_fill.dart';
import 'package:mazl/presentation/common/widgets/like_fill/like_fill_painter.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';

// docs/design/MOUVEMENT.md: the heart button fills from the exact point the
// finger touched, finishes when the tap is confirmed, bounces once, and makes
// no haptic. The expectations come from that description, not from the
// widget's code.

const _button = Key('button');

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

Future<void> _pump(
  WidgetTester tester,
  VoidCallback onTap, {
  bool reduced = false,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Directionality(textDirection: direction, child: child!),
      ),
      home: Scaffold(
        body: Center(
          child: LikeFill(
            key: _button,
            onTap: onTap,
            background: Colors.black,
            fillColor: Colors.blue,
            shape: const StadiumBorder(),
            size: const Size(200, 64),
            builder: (context, fill) => Center(
              child: Icon(LucideIcons.heart, size: 22, color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A ticker starts counting on its first frame: draw one before timing.
Future<void> _firstFrame(WidgetTester tester) => tester.pump();

LikeFillPainter _disc(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(LikeFill.discKey)).painter!
        as LikeFillPainter;

double _scale(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(LikeFill.popKey))
    .transform
    .getMaxScaleOnAxis();

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('the disc is centred on the touch point ($direction)', (
      tester,
    ) async {
      await _pump(tester, () {}, direction: direction);
      final box = tester.getRect(find.byKey(_button));
      for (final local in [const Offset(6, 32), const Offset(194, 20)]) {
        final gesture = await tester.startGesture(box.topLeft + local);
        await _firstFrame(tester);
        await tester.pump(const Duration(milliseconds: 50));
        expect(_disc(tester).center, local);
        expect(_disc(tester).progress, greaterThan(0));
        await gesture.up();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('half way the heart is not full, at the end it is, one call', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, () => taps++);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_button)),
    );
    await _firstFrame(tester);
    await tester.pump(MazlMotion.likeFillDuration * 0.3);
    expect(_disc(tester).progress, inExclusiveRange(0, 1));
    await tester.pump(MazlMotion.likeFillDuration);
    // Resting finger: never the whole button before the tap is confirmed.
    expect(_disc(tester).progress, lessThan(1));
    expect(taps, 0);

    await gesture.up();
    expect(taps, 1);
    await _firstFrame(tester);
    await tester.pump(MazlMotion.likeFillFinish);
    expect(_disc(tester).progress, 1);

    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(_disc(tester).progress, 0, reason: 'the button goes back to rest');
  });

  testWidgets('the button makes the common bounce once the disc is full', (
    tester,
  ) async {
    await _pump(tester, () {});
    await tester.tap(find.byKey(_button));
    expect(_scale(tester), 1);
    await _firstFrame(tester);
    await tester.pump(MazlMotion.likeFillFinish);
    // The bounce starts once the disc is full, on the next frames.
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    await tester.pump(MazlMotion.popDuration * 0.5);
    expect(_scale(tester), closeTo(MazlMotion.popScale, 0.02));
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(1, 1e-9));
  });

  testWidgets('a cancelled tap calls nothing and empties the disc', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, () => taps++);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_button)),
    );
    await _firstFrame(tester);
    await tester.pump(MazlMotion.likeFillDuration * 0.5);
    expect(_disc(tester).progress, greaterThan(0));

    await gesture.moveBy(const Offset(0, 300));
    await _firstFrame(tester);
    await tester.pump(MazlMotion.likeFillCancel);
    expect(taps, 0);
    expect(_disc(tester).progress, 0);
    expect(_scale(tester), 1);
    await tester.pumpAndSettle();
    expect(taps, 0);
  });

  testWidgets('no haptic feedback at all', (tester) async {
    final haptics = await _recordHaptics(tester);
    await _pump(tester, () {});
    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();
    expect(haptics, isEmpty);
  });

  testWidgets('reduced motion: no partial disc, no bounce, callback runs', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, () => taps++, reduced: true);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_button)),
    );
    await tester.pump(MazlMotion.likeFillDuration);
    expect(_disc(tester).progress, 0, reason: 'nothing grows under the finger');
    await gesture.up();
    expect(taps, 1);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(_scale(tester), 1);
      expect(_disc(tester).progress, anyOf(0, 1));
    }
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  for (final size in [40.0, 44.0]) {
    testWidgets('a ${size.toInt()} pt round heart still answers 2 px from '
        'the edge of its 44 x 44 pt area', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RoundIconButton(
                key: _button,
                icon: LucideIcons.heart,
                tooltip: 'Aimer',
                size: size,
                style: RoundButtonStyle.accent,
                fillsFromTouch: true,
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );
      final area = tester.getRect(find.byKey(_button));
      expect(area.width, greaterThanOrEqualTo(44));
      expect(area.height, greaterThanOrEqualTo(44));
      // The corners of a 44 pt circle are outside its own shape.
      for (final point in [
        if (size < 44) ...[
          area.topLeft + const Offset(2, 2),
          area.bottomRight - const Offset(2, 2),
        ],
        area.centerLeft + const Offset(2, 0),
        area.centerRight - const Offset(2, 0),
        area.topCenter + const Offset(0, 2),
        area.bottomCenter - const Offset(0, 2),
      ]) {
        await tester.tapAt(point);
        await tester.pumpAndSettle();
      }
      expect(taps, size < 44 ? 6 : 4);
    });
  }
}
