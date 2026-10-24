import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/common/widgets/mazl_logo.dart';

import '../../support/reduce_motion_support.dart';

// Splash logo: static and at full size from the first frame under
// « Réduire les animations ».

void main() {
  group('animated logo', () {
    testWidgets('Reduce Motion on: full size from the first frame', (
      tester,
    ) async {
      setReduceMotion(tester, on: true);
      await tester.pumpWidget(
        reduceMotionApp(home: const Scaffold(body: AnimatedMazlLogo())),
      );

      expect(displacementsOf(find.byType(MazlLogoContainer)), isEmpty);
      expect(fadeOf(find.byType(MazlLogoContainer)), 1.0);
    });

    testWidgets('Reduce Motion off: the logo grows and fades in', (
      tester,
    ) async {
      await tester.pumpWidget(
        reduceMotionApp(home: const Scaffold(body: AnimatedMazlLogo())),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(displacementsOf(find.byType(MazlLogoContainer)), isNotEmpty);
      expect(fadeOf(find.byType(MazlLogoContainer)), lessThan(1));
    });
  });
}
