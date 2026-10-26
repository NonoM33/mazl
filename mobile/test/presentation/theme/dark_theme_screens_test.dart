import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/motion/reduce_motion_scope.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/chat/screens/conversations_screen.dart';
import 'package:mazl/presentation/features/events/screens/events_list_screen.dart';
import 'package:mazl/presentation/features/matching/screens/discover_screen.dart';
import 'package:mazl/presentation/features/settings/screens/settings_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/couple/couple_flow_fakes.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/fake_discover_api.dart';
import '../../support/credits_fakes.dart';
import '../../support/dark_theme_audit.dart';

// Mode sombre : les écrans les plus vus ne gardent aucune surface claire
// derrière un texte clair. Le contraste est calculé sur le rendu réel.

/// Jamais détruit : les services de l'app sont des singletons que le scope
/// détruirait avec lui (voir settings_honest_rows_test.dart).
final _sharedContainer = ProviderContainer();

Future<void> _pumpDark(
  WidgetTester tester,
  Widget home, {
  Brightness brightness = Brightness.dark,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _sharedContainer,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: kTestLocale,
        builder: (context, child) =>
            darkCaptureBuilder(context, ReduceMotionScope(child: child!)),
        home: home,
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

MockClient _events() => MockClient((request) async {
  final event = {
    'id': 1,
    'title': 'Dîner de Shabbat',
    'description': 'Un grand repas chez Jeanne.',
    'event_type': 'lecture',
    'location': 'Synagogue de la Victoire',
    'address': '44 rue de la Victoire, Paris',
    'date': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
    'time': '19:30',
    'price': 12,
    'currency': 'EUR',
    'max_attendees': 40,
    'attendee_count': 12,
  };
  final free = {...event, 'id': 2, 'title': 'Soirée rencontres', 'price': 0};
  return http.Response(
    jsonEncode({
      'success': true,
      'events': [event, free],
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
});

MockClient _conversations() => MockClient((request) async {
  return http.Response(
    jsonEncode({
      'success': true,
      'conversations': [
        {
          'id': 7,
          'matchId': 3,
          'lastMessage': 'On se retrouve à 19 h ?',
          'lastMessageAt': DateTime.now().toIso8601String(),
          'unreadCount': 2,
          'otherUser': {'user_id': 9, 'display_name': 'Sarah Exemple'},
        },
        {
          'id': 8,
          'matchId': 4,
          'unreadCount': 0,
          'otherUser': {'user_id': 10, 'display_name': 'David Exemple'},
        },
      ],
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
});

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
    installTestCredits();
  });

  tearDown(PremiumGate.resetForTest);

  for (final brightness in Brightness.values) {
    testWidgets('Réglages (${brightness.name})', (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'MAZL',
        packageName: 'app.mazl',
        version: '2.3.4',
        buildNumber: '567',
        buildSignature: '',
      );
      final couple = CoupleService.forTesting(
        api: FakeCoupleApi(),
        pollInterval: const Duration(hours: 1),
      );
      addTearDown(couple.dispose);
      await couple.initialize();
      CoupleService.instanceForTesting = couple;

      await _pumpDark(
        tester,
        const SettingsScreen(),
        size: const Size(390, 3200),
        brightness: brightness,
      );
      await captureDarkPng(tester, 'reglages-${brightness.name}');

      expect(lowContrastTexts(tester), isEmpty);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('Découvrir (${brightness.name})', (tester) async {
      final api = FakeDiscoverApi(discoverProfiles(3));
      await _pumpDark(
        tester,
        DiscoverScreen(
          apiService: api,
          likeAllowanceApi: FakeLikeAllowanceApi.free(remaining: 7),
        ),
        brightness: brightness,
      );
      await captureDarkPng(tester, 'decouvrir-${brightness.name}');

      expect(lowContrastTexts(tester), isEmpty);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('Événements (${brightness.name})', (tester) async {
      await http.runWithClient(() async {
        await _pumpDark(
          tester,
          const EventsListScreen(),
          brightness: brightness,
        );
        await captureDarkPng(tester, 'evenements-${brightness.name}');

        expect(find.text('Dîner de Shabbat'), findsWidgets);
        expect(lowContrastTexts(tester), isEmpty);
      }, _events);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('Messages (${brightness.name})', (tester) async {
      await http.runWithClient(() async {
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const ConversationsScreen()),
          ],
        );
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: brightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: kTestLocale,
              builder: darkCaptureBuilder,
              routerConfig: router,
            ),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 150));
        }
        await captureDarkPng(tester, 'messages-${brightness.name}');

        expect(find.text('Sarah Exemple'), findsOneWidget);
        expect(lowContrastTexts(tester), isEmpty);
      }, _conversations);
    });
  }
}
