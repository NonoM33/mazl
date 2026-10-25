import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/link_providers.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_helpers.dart';
import '../couple/couple_flow_fakes.dart';

/// Never disposed: the app's services are singletons, and a ProviderScope
/// disposes the ones it creates, which would break the next test.
final _sharedContainer = ProviderContainer(
  overrides: [
    externalLinkOpenerProvider.overrideWithValue((uri) async {
      _opened.add(uri);
      return _launcherAnswer;
    }),
  ],
);
final _opened = <Uri>[];
var _launcherAnswer = true;

/// The About section of the settings opens the public pages of docs/launch/
/// V1-CONTRAT.md §6, outside the app. The launcher is stubbed by its real
/// name, `externalLinkOpenerProvider`.
void main() {
  late CoupleService couple;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    couple = CoupleService.forTesting(
      api: FakeCoupleApi(),
      pollInterval: const Duration(hours: 1),
    );
    _opened.clear();
    _launcherAnswer = true;
  });

  tearDown(() => couple.dispose());

  Future<void> pumpSettings(WidgetTester tester, {Locale? locale}) async {
    await couple.initialize();
    CoupleService.instanceForTesting = couple;
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: _sharedContainer,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale ?? kTestLocale,
          theme: AppTheme.lightTheme,
          home: const SettingsScreen(),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapRow(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pump();
  }

  testWidgets('Aide et support writes to hello@mazl.app', (tester) async {
    await pumpSettings(tester);
    await tapRow(tester, 'Aide et support');
    expect(_opened.map((u) => u.toString()), ['mailto:hello@mazl.app']);
  });

  testWidgets("Conditions d'utilisation opens mazl.app/cgu", (tester) async {
    await pumpSettings(tester);
    await tapRow(tester, "Conditions d'utilisation");
    expect(_opened.map((u) => u.toString()), ['https://mazl.app/cgu']);
  });

  testWidgets('Conditions de vente opens mazl.app/cgv', (tester) async {
    await pumpSettings(tester);
    await tapRow(tester, 'Conditions de vente');
    expect(_opened.map((u) => u.toString()), ['https://mazl.app/cgv']);
  });

  testWidgets('Politique de confidentialité opens mazl.app/confidentialite', (
    tester,
  ) async {
    await pumpSettings(tester);
    await tapRow(tester, 'Politique de confidentialité');
    expect(_opened.map((u) => u.toString()), [
      'https://mazl.app/confidentialite',
    ]);
  });

  testWidgets('a link that cannot be opened says so, with where it points', (
    tester,
  ) async {
    _launcherAnswer = false;
    await pumpSettings(tester);
    await tapRow(tester, 'Aide et support');
    await tester.pump();
    expect(find.textContaining('hello@mazl.app'), findsOneWidget);
    expect(find.textContaining('mailto:'), findsNothing);
  });

  testWidgets('the sales conditions row exists in every language', (
    tester,
  ) async {
    for (final locale in AppLocalizations.supportedLocales) {
      await pumpSettings(tester, locale: locale);
      final l10n = lookupAppLocalizations(locale);
      expect(
        find.text(l10n.settingsSales),
        findsOneWidget,
        reason: locale.languageCode,
      );
    }
  });
}
