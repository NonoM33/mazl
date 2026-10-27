import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/settings/screens/settings_screen.dart';
import 'package:mazl/presentation/features/settings/widgets/plus_privacy_section.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_helpers.dart';
import '../couple/couple_flow_fakes.dart';

/// Never disposed, like in settings_links_test.dart: the app's services are
/// singletons and a ProviderScope would dispose the ones it creates.
final _sharedContainer = ProviderContainer();

// Décision de Renaud du 2026-10-25 : aucune façade visible par un client. Les
// réglages ne montrent que ce que l'app enregistre ou applique réellement.
// Vérifié dans le code : aucun interrupteur de notification (matchs, messages,
// Super Likes, fêtes) n'était enregistré, ni côté serveur (aucune route, aucune
// table de préférences) ni côté push (aucune étiquette, et le serveur n'en
// lit aucune) ; aucune alerte de fête n'est envoyée par le serveur.
void main() {
  late CoupleService couple;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'MAZL',
      packageName: 'app.mazl',
      version: '2.3.4',
      buildNumber: '567',
      buildSignature: '',
    );
    couple = CoupleService.forTesting(
      api: FakeCoupleApi(),
      pollInterval: const Duration(hours: 1),
    );
  });

  tearDown(() => couple.dispose());

  Future<void> pumpSettings(WidgetTester tester, {Locale? locale}) async {
    await couple.initialize();
    CoupleService.instanceForTesting = couple;
    tester.view.physicalSize = const Size(390, 3200);
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

  testWidgets('no switch that saves nothing is offered', (tester) async {
    await pumpSettings(tester);

    // Every switch lives in the privacy section of the mazl+ settings, where
    // each one saves on the server (read receipts, discreet mode) and shows
    // what the server answers; none is a façade.
    expect(find.byType(PlusPrivacySection), findsOneWidget);
    expect(
      find.byType(Switch).evaluate().length,
      find
          .descendant(
            of: find.byType(PlusPrivacySection),
            matching: find.byType(Switch),
          )
          .evaluate()
          .length,
    );
    expect(find.text('Envoyer les confirmations de lecture'), findsOneWidget);
    expect(find.text('Alertes fêtes'), findsNothing);
    expect(find.text('NOTIFICATIONS'), findsNothing);
    expect(find.text('Nouveaux matchs'), findsNothing);
  });

  testWidgets('the version is the one of the installed build', (tester) async {
    await pumpSettings(tester);

    expect(find.text('2.3.4 (567)'), findsOneWidget);
    expect(find.text('1.0.0'), findsNothing);
  });

  testWidgets('the version also reads in English', (tester) async {
    await pumpSettings(tester, locale: const Locale('en'));

    expect(find.text('2.3.4 (567)'), findsOneWidget);
  });

  testWidgets('rows that open nothing are not tappable', (tester) async {
    await pumpSettings(tester);

    for (final label in ['Email', 'Version']) {
      final tile = tester.widget<ListTile>(
        find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
      );
      expect(tile.onTap, isNull, reason: label);
    }
  });
}
