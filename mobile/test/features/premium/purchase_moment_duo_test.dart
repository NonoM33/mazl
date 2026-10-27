import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/premium/purchase_moments.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../duo/duo_geometry.dart';

// The offer that comes by itself, in the seven poses of the foldable iPhone
// (iPhone Duo), light and dark, in the languages with the longest or the
// right-to-left text: nothing crosses the fold, both buttons are fully in
// view, in the safe area and at least 44 x 44 pt, « Plus tard » included.

Future<void> _open(
  WidgetTester tester,
  DuoPose pose,
  PurchaseMoment moment,
  Locale locale,
  Brightness brightness,
) async {
  setDuoPose(tester, pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: brightness == Brightness.light
          ? ThemeMode.light
          : ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: duoAppBuilder(DuoPoseController(pose)),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => PurchaseMoments.offer(context, moment),
            child: const Text('declencher'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('declencher'));
  await tester.pumpAndSettle();
  await settleFold(tester);
}

void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PurchaseMoments.resetForTest();
    PremiumGate.resetForTest();
  });

  for (final pose in DuoPose.values) {
    for (final locale in const [Locale('fr'), Locale('he'), Locale('ru')]) {
      for (final brightness in Brightness.values) {
        for (final moment in PurchaseMoment.values) {
          testWidgets('${pose.name} ${locale.languageCode} ${brightness.name} '
              '${moment.name}', (tester) async {
            await _open(tester, pose, moment, locale, brightness);
            final reason = '${moment.name} in ${pose.name}';

            expect(tester.takeException(), isNull, reason: reason);
            expect(tappableProblems(tester, pose), isEmpty, reason: reason);
            expect(foldCrossingProblems(tester, pose), isEmpty, reason: reason);
            final l10n = lookupAppLocalizations(locale);
            final cta = find.byType(PlusCtaButton);
            final later = find.widgetWithText(OutlinedButton, l10n.commonLater);
            for (final button in [cta, later]) {
              expect(button, findsOneWidget, reason: reason);
              expect(
                primaryProblem(tester, pose, button),
                isNull,
                reason: reason,
              );
              final size = tester.getSize(button);
              expect(size.width, greaterThanOrEqualTo(44), reason: reason);
              expect(size.height, greaterThanOrEqualTo(44), reason: reason);
            }
            expect(tester.getSize(later), tester.getSize(cta), reason: reason);
          });
        }
      }
    }
  }
}
