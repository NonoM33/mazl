import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/premium/premium_settings.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/passport/screens/passport_screen.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../support/duo_harness.dart';
import '../../support/premium_fakes.dart';
import '../duo/duo_geometry.dart';

// The Passeport in the seven postures of the foldable iPhone, light and dark:
// nothing off the safe area, in the fold or under the system, every control
// 44 pt touchable all over, and a way out in every posture.

const _telAviv = Passport(
  city: 'Tel Aviv',
  latitude: 32.0853,
  longitude: 34.7818,
);

Future<void> _open(
  WidgetTester tester,
  DuoPose pose,
  Brightness brightness, {
  bool plus = true,
  Passport? passport = _telAviv,
}) => pumpScreenInDuo(
  tester,
  pose,
  PassportScreen(
    api: FakePremiumSettingsApi(isPlus: plus, passport: passport),
    searchCities: (query) async => const [],
    offerPlus: (context, moment) async => true,
  ),
  brightness: brightness,
);

void main() {
  setUpAll(loadAppFonts);

  for (final pose in DuoPose.values) {
    for (final brightness in Brightness.values) {
      final where = '${pose.name}, ${brightness.name}';

      duoTestWidgets('subscriber with an active passport, $where', (
        tester,
      ) async {
        await _open(tester, pose, brightness);

        expect(find.text('Votre passeport : Tel-Aviv'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(tappableProblems(tester, pose), isEmpty);
        expect(foldCrossingProblems(tester, pose), isEmpty);
        expect(navigationOutsideColumnProblems(tester, pose), isEmpty);
      });

      duoTestWidgets('free member, $where', (tester) async {
        await _open(tester, pose, brightness, plus: false, passport: null);

        expect(
          find.text('Le passeport est réservé aux abonnés mazl+.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(tappableProblems(tester, pose), isEmpty);
        expect(foldCrossingProblems(tester, pose), isEmpty);
        expectTouchTarget(
          tester,
          find.byKey(const ValueKey('passport-see-plus')),
          'the mazl+ button in $where',
        );
      });

      duoTestWidgets('controls are touchable all over, $where', (tester) async {
        await _open(tester, pose, brightness);

        expectTouchTarget(
          tester,
          find.byKey(const ValueKey('passport-back-home')),
          'back to my city in $where',
        );
        for (final city in ['telAviv', 'paris']) {
          final row = find.byKey(ValueKey('passport-city-$city'));
          await tester.scrollUntilVisible(
            row,
            120,
            scrollable: find
                .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pump();
          expectTouchTarget(tester, row, '$city row in $where');
        }
      });
    }
  }

  duoTestWidgets('closed: the back button is in the column and leaves the '
      'screen', (tester) async {
    await _open(tester, DuoPose.closed, Brightness.light);

    final back = find.byWidgetPredicate(
      (w) =>
          (w is Tooltip && w.message == 'Retour') ||
          (w is Semantics &&
              (w.properties.button ?? false) &&
              w.properties.label == 'Retour'),
    );
    expect(back, findsWidgets);
    await tester.tap(back.hitTestable().first);
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PassportScreen), findsNothing);
  });

  duoTestWidgets('opened flat the page can always be left too', (tester) async {
    await _open(tester, DuoPose.openPortrait, Brightness.dark);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PassportScreen), findsNothing);
  });

  test('the text of the page keeps AA contrast in both themes', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final scheme = theme.colorScheme;
      final bg = theme.scaffoldBackgroundColor;
      expect(
        contrastRatio(scheme.primary, bg),
        greaterThanOrEqualTo(4.5),
        reason: '${theme.brightness.name}: the section label',
      );
      expect(
        contrastRatio(scheme.onSurfaceVariant, bg),
        greaterThanOrEqualTo(4.5),
        reason: '${theme.brightness.name}: the explanation',
      );
      expect(
        contrastRatio(scheme.onSurface, bg),
        greaterThanOrEqualTo(4.5),
        reason: '${theme.brightness.name}: the city',
      );
    }
  });
}
