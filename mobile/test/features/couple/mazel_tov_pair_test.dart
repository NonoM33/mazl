import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/screens/mazel_tov_screen.dart';
import '../../helpers/l10n_helpers.dart';

// Characterization of the Mazal Tov couple visual: the layout was extracted
// into a shared widget (PairedAvatars) and must not have moved by a pixel.
// Expected numbers come from the design (96 px photos, 44 px heart, 12 px on
// each side of the heart, photos 24 px apart at rest-minus-start), not from
// the code under test.

bool _isCircle(Widget w) =>
    w is Container &&
    w.decoration is BoxDecoration &&
    (w.decoration! as BoxDecoration).shape == BoxShape.circle;

Rect _rectOfSize(WidgetTester tester, double side, {required bool photo}) {
  final finder = find.byWidgetPredicate((w) => _isCircle(w));
  final rects = [
    for (final e in finder.evaluate()) tester.getRect(find.byElementPredicate((x) => x == e)),
  ].where((r) => (r.width - side).abs() < 0.01 && (r.height - side).abs() < 0.01);
  expect(rects, isNotEmpty, reason: 'no ${photo ? 'photo' : 'heart'} circle of $side px');
  return rects.first;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: AppTheme.lightTheme,
      home: const MazelTovScreen(partnerName: 'Myriam'),
    ),
  );
}

List<Rect> _photos(WidgetTester tester) {
  final all = [
    for (final e in find.byWidgetPredicate(_isCircle).evaluate())
      tester.getRect(find.byElementPredicate((x) => x == e)),
  ].where((r) => (r.width - 96).abs() < 0.01).toList()..sort((a, b) => a.left.compareTo(b.left));
  return all;
}

void main() {
  testWidgets('settled: photos 96, heart 44 between them, 12 px each side', (tester) async {
    await _pump(tester);
    await tester.pump(const Duration(seconds: 2));
    final photos = _photos(tester);
    expect(photos, hasLength(2));
    expect(photos[0].left, closeTo(65, 0.5));
    expect(photos[1].right, closeTo(325, 0.5));
    final heart = _rectOfSize(tester, 44, photo: false);
    expect(heart.left, closeTo(173, 0.5));
    expect(heart.right, closeTo(217, 0.5));
    expect(photos[0].center.dy, closeTo(heart.center.dy, 0.5));
    expect(photos[1].center.dy, closeTo(heart.center.dy, 0.5));
    expect(find.byIcon(LucideIcons.heart), findsOneWidget);
  });

  testWidgets('at the start the photos are 24 px further out, the heart has not moved', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pump();
    final photos = _photos(tester);
    expect(photos[0].left, closeTo(65 - 24, 0.5));
    expect(photos[1].left, closeTo(229 + 24, 0.5));
    expect(_rectOfSize(tester, 44, photo: false).left, closeTo(173, 0.5));
    await tester.pump(const Duration(seconds: 2));
  });
}
