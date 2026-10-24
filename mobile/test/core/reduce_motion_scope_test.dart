import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/core/motion/reduce_motion_scope.dart';

// iOS « Réduire les animations » reaches Flutter as
// AccessibilityFeatures.reduceMotion, NOT as MediaQuery.disableAnimations
// (documented on MediaQueryData.disableAnimations). Every motion test used to
// set disableAnimations, so the gestures passed their reduce-motion tests and
// still turned and bounced on an iPhone with the setting on. These tests set
// the iOS flag itself.

void main() {
  late bool reduced;

  Widget probe() => MaterialApp(
    builder: (context, child) => ReduceMotionScope(child: child!),
    home: Builder(
      builder: (context) {
        reduced = MazlMotion.reduced(context);
        return const SizedBox.shrink();
      },
    ),
  );

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('the iOS Reduce Motion setting reduces motion in the app', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    await tester.pumpWidget(probe());
    expect(reduced, isTrue);
  });

  testWidgets('without it, motion stays on', (tester) async {
    await tester.pumpWidget(probe());
    expect(reduced, isFalse);
  });

  testWidgets('turning it on while the app runs takes effect at once', (
    tester,
  ) async {
    await tester.pumpWidget(probe());
    expect(reduced, isFalse);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    await tester.pump();
    expect(reduced, isTrue);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pump();
    expect(reduced, isFalse);
  });

  test('the app root goes through ReduceMotionScope', () {
    final source = File('lib/app.dart').readAsStringSync();
    expect(source, contains('ReduceMotionScope('));
  });
}
