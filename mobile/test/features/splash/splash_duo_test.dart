import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/splash/splash_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';

// The splash logo on the foldable iPhone (iPhone Duo): flat it is centred;
// half open it must not run through the curve.

Future<void> _pump(
  WidgetTester tester,
  DuoPose pose, {
  TextDirection direction = TextDirection.ltr,
}) async {
  setDuoPose(tester, pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: duoAppBuilder(DuoPoseController(pose))(context, child),
      ),
      home: const Scaffold(body: SplashBrand()),
    ),
  );
  await settleFold(tester);
}

Rect _logo(WidgetTester tester) =>
    tester.getRect(find.bySemanticsLabel('mazl'));

void main() {
  setUpAll(loadAppFonts);

  testWidgets('flat: the logo is centred in the page', (tester) async {
    await _pump(tester, DuoPose.openLandscape);
    final area = DuoPose.openLandscape.safeRect;
    expect(_logo(tester).center.dx, closeTo(area.center.dx, 1));
    expect(
      _logo(tester).center.dy,
      closeTo(DuoPose.openLandscape.size.height / 2, 1),
    );
  });

  testWidgets('book: the logo is whole on the left page, centred there', (
    tester,
  ) async {
    await _pump(tester, DuoPose.halfOpenBook);
    final fold = DuoPose.halfOpenBook.fold!;
    final logo = _logo(tester);
    expect(logo.right, lessThanOrEqualTo(fold.left));
    expect(logo.center.dx, closeTo(fold.left / 2, 1));
  });

  testWidgets('book in Hebrew: the logo is on the right page', (tester) async {
    await _pump(tester, DuoPose.halfOpenBook, direction: TextDirection.rtl);
    final fold = DuoPose.halfOpenBook.fold!;
    expect(_logo(tester).left, greaterThanOrEqualTo(fold.right));
  });

  testWidgets('laptop: the logo is whole above the fold', (tester) async {
    await _pump(tester, DuoPose.halfOpenLaptop);
    final fold = DuoPose.halfOpenLaptop.fold!;
    final logo = _logo(tester);
    expect(logo.bottom, lessThanOrEqualTo(fold.top));
    expect(logo.center.dy, closeTo(fold.top / 2, 1));
  });
}
