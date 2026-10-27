import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/di/providers/storefront_providers.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/storefront/festive_icon.dart';
import 'package:mazl/core/storefront/storefront_models.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_settings_card.dart';
import 'package:mazl/presentation/features/settings/screens/settings_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/couple/couple_flow_fakes.dart';
import '../../helpers/l10n_helpers.dart';
import 'storefront_fixtures.dart';

// The settings: the strip of the campaign on the « Passer à mazl+ » card and
// the « Icône des fêtes » switch.

class _MemoryStore implements FestiveIconSettingStore {
  bool value = true;

  @override
  Future<bool> read() async => value;

  @override
  Future<void> write(bool enabled) async => value = enabled;
}

void main() {
  setUpAll(loadAppFonts);

  group('the card', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required bool isPremium,
      StorefrontCampaign? campaign,
      ThemeData? theme,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          home: Scaffold(
            body: PlusSettingsCard(
              isPremium: isPremium,
              campaign: campaign,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('shows the strip of the campaign under the pitch', (
      tester,
    ) async {
      await pumpCard(
        tester,
        isPremium: false,
        campaign: storefrontWithCampaign('hanukkah').campaign,
      );
      expect(find.byKey(const ValueKey('campaign-banner')), findsOneWidget);
      expect(find.text('La Saint-Valentin approche'), findsOneWidget);
    });

    testWidgets('no campaign, no strip', (tester) async {
      await pumpCard(tester, isPremium: false);
      expect(find.byKey(const ValueKey('campaign-banner')), findsNothing);
    });

    testWidgets('a subscriber is not sold anything', (tester) async {
      await pumpCard(
        tester,
        isPremium: true,
        campaign: storefrontWithCampaign('hanukkah').campaign,
      );
      expect(find.byKey(const ValueKey('campaign-banner')), findsNothing);
    });

    testWidgets('the whole card stays one tap target of 44 pt or more', (
      tester,
    ) async {
      await pumpCard(
        tester,
        isPremium: false,
        campaign: storefrontWithCampaign('black_friday').campaign,
        theme: AppTheme.darkTheme,
      );
      expect(tester.takeException(), isNull);
      final card = find.descendant(
        of: find.byType(PlusSettingsCard),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(card).height, greaterThanOrEqualTo(72));
    });
  });

  group('the settings screen', () {
    late CoupleService couple;
    late _MemoryStore store;

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
      store = _MemoryStore();
    });

    tearDown(() => couple.dispose());

    Future<ProviderContainer> pump(
      WidgetTester tester, {
      TargetPlatform platform = TargetPlatform.iOS,
      Storefront? storefront,
    }) async {
      await couple.initialize();
      CoupleService.instanceForTesting = couple;
      tester.view.physicalSize = const Size(390, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
        overrides: [
          festiveIconSettingStoreProvider.overrideWithValue(store),
          if (storefront != null)
            storefrontProvider.overrideWithValue(storefront),
        ],
      );
      // Never disposed: the app's services are singletons, and disposing the
      // container would dispose them for the next test.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: kTestLocale,
            theme: AppTheme.lightTheme.copyWith(platform: platform),
            home: const SettingsScreen(),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return container;
    }

    testWidgets('« Icône des fêtes » is on by default and turns off', (
      tester,
    ) async {
      final container = await pump(tester);
      final row = find.widgetWithText(SwitchListTile, 'Icône des fêtes');
      expect(row, findsOneWidget);
      expect(tester.widget<SwitchListTile>(row).value, isTrue);

      await tester.tap(row);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(row).value, isFalse);
      expect(container.read(festiveIconEnabledProvider), isFalse);
      expect(store.value, isFalse, reason: 'and it is kept for next launch');
    });

    testWidgets('the whole row is the target, 56 pt tall at least', (
      tester,
    ) async {
      await pump(tester);
      final row = find.widgetWithText(SwitchListTile, 'Icône des fêtes');
      expect(tester.getSize(row).height, greaterThanOrEqualTo(56));
      expect(tester.getSize(row).width, 390);
      // Tap near the edge, far from the switch and the text.
      await tester.tapAt(tester.getTopLeft(row) + const Offset(2, 28));
      await tester.pump();
      expect(tester.widget<SwitchListTile>(row).value, isFalse);
    });

    testWidgets('a phone that is not an iPhone has no such row', (
      tester,
    ) async {
      await pump(tester, platform: TargetPlatform.android);
      expect(find.text('Icône des fêtes'), findsNothing);
    });

    testWidgets('the strip of the campaign is on the card', (tester) async {
      await pump(tester, storefront: storefrontWithCampaign('christmas'));
      expect(find.byKey(const ValueKey('campaign-banner')), findsOneWidget);
      expect(find.byIcon(LucideIcons.sparkles), findsWidgets);
    });
  });
}
