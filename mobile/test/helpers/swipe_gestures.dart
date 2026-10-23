import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A slow drag from the centre of [target]: no velocity at release, so only the
/// distance decides. Returns the gesture still held, [release] lets go.
Future<TestGesture> holdDrag(
  WidgetTester tester,
  Finder target,
  Offset by, {
  Offset from = Offset.zero,
}) async {
  final gesture = await tester.startGesture(tester.getCenter(target) + from);
  const steps = 10;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(by / steps.toDouble());
    await tester.pump(const Duration(milliseconds: 40));
  }
  await tester.pump(const Duration(milliseconds: 200));
  return gesture;
}

/// Drag, wait, let go.
Future<void> dragSlowly(
  WidgetTester tester,
  Finder target,
  Offset by, {
  Offset from = Offset.zero,
}) async {
  final gesture = await holdDrag(tester, target, by, from: from);
  await gesture.up();
}

/// A flick: [by] covered in [milliseconds], released while still moving.
Future<void> flick(
  WidgetTester tester,
  Finder target,
  Offset by,
  int milliseconds,
) async {
  final gesture = await tester.startGesture(tester.getCenter(target));
  const steps = 5;
  for (var i = 1; i <= steps; i++) {
    await gesture.moveBy(
      by / steps.toDouble(),
      timeStamp: Duration(milliseconds: milliseconds * i ~/ steps),
    );
  }
  await gesture.up(timeStamp: Duration(milliseconds: milliseconds));
}

/// About a second of frames: long enough for any exit or spring.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Records the haptics the app asks the platform for, by name
/// (`selectionClick`, `mediumImpact`…).
class HapticLog {
  HapticLog(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add(
            (call.arguments as String).replaceFirst('HapticFeedbackType.', ''),
          );
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
  }

  final List<String> calls = [];

  void clear() => calls.clear();

  @override
  String toString() => jsonEncode(calls);
}
