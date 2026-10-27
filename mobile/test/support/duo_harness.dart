import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/theme/app_theme.dart';

import '../helpers/duo_poses.dart';
import '../helpers/l10n_helpers.dart';

// Shared pieces of the iPhone Duo tests of single widgets and screens: the
// pose and the fold of the app's own builder, light or dark, and the touch
// measures of regles/iphone-duo.md §6.0 (44 x 44 pt, tapped near the edge).

/// A `testWidgets` on iOS, as the real device: the vertical bar only exists
/// there. The override is gone before the test ends.
void duoTestWidgets(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

/// Opens [screen] on top of a first page, the way the router pushes it, in
/// [pose] and [brightness], so that it has its way back.
Future<DuoPoseController> pumpScreenInDuo(
  WidgetTester tester,
  DuoPose pose,
  Widget screen, {
  Brightness brightness = Brightness.light,
  Locale locale = kTestLocale,
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
      darkTheme: AppTheme.darkTheme.copyWith(platform: TargetPlatform.iOS),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: duoAppBuilder(controller),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push<Object?>(MaterialPageRoute(builder: (_) => screen)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settleFold(tester);
  return controller;
}

/// Whether a touch at [point] reaches [target].
bool touchReaches(WidgetTester tester, Finder target, Offset point) {
  final render = tester.renderObject(target);
  final result = HitTestResult();
  tester.binding.hitTestInView(result, point, tester.view.viewId);
  return result.path.any((entry) => entry.target == render);
}

/// [finder] is at least 44 x 44 pt, and a touch 3 pt inside each of its four
/// sides still reaches it: the whole control is touchable, not only its icon.
void expectTouchTarget(WidgetTester tester, Finder finder, String reason) {
  expect(finder, findsOneWidget, reason: reason);
  final rect = tester.getRect(finder);
  expect(rect.width, greaterThanOrEqualTo(44), reason: '$reason: width');
  expect(rect.height, greaterThanOrEqualTo(44), reason: '$reason: height');
  final c = rect.center;
  for (final point in [
    Offset(rect.left + 3, c.dy),
    Offset(rect.right - 3, c.dy),
    Offset(c.dx, rect.top + 3),
    Offset(c.dx, rect.bottom - 3),
  ]) {
    expect(
      touchReaches(tester, finder, point),
      isTrue,
      reason: '$reason: a touch at $point does not reach it ($rect)',
    );
  }
}

/// The ratio of contrast between two colors (WCAG 2).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
