import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/navigation/screens/main_navigation_screen.dart';
import 'package:mazl/presentation/features/navigation/widgets/mazl_nav_bar.dart';

import '../../../helpers/l10n_helpers.dart';

const _items = [
  MazlNavItem(icon: LucideIcons.layers, label: 'one'),
  MazlNavItem(icon: LucideIcons.heart, label: 'two'),
];

GoRouter _router() => GoRouter(
  initialLocation: '/discover',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          MainNavigationScreen(navigationShell: shell),
      branches: [
        for (final name in [
          'discover',
          'matches',
          'messages',
          'events',
          'profile',
        ])
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/$name', builder: (_, _) => const SizedBox()),
            ],
          ),
      ],
    ),
  ],
);

Future<void> _pumpShell(
  WidgetTester tester,
  Locale locale, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = kSmallPhone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        routerConfig: _router(),
      ),
    ),
  );
  // Let the sequential prefetch (a 100 ms pause between calls) run to its end.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The shell prefetches its data on start: every call fails, the tabs do not care.
Future<void> _withOfflineServer(Future<void> Function() body) =>
    http.runWithClient(
      body,
      () => MockClient(
        (_) async => http.Response(jsonEncode({'success': false}), 500),
      ),
    );

void main() {
  group('onglets du bas', () {
    final labels = <String, List<String>>{
      'fr': ['Découvrir', 'Matchs', 'Messages', 'Événements', 'Profil'],
      'en': ['Discover', 'Matches', 'Messages', 'Events', 'Profile'],
      'he': ['גילוי', 'התאמות', 'הודעות', 'אירועים', 'פרופיל'],
      'es': ['Descubrir', 'Matches', 'Mensajes', 'Eventos', 'Perfil'],
      'ru': ['Поиск', 'Совпадения', 'Сообщения', 'Мероприятия', 'Профиль'],
    };
    for (final entry in labels.entries) {
      testWidgets(
        '${entry.key} : chaque onglet porte son nom pour le lecteur d\'écran',
        (tester) async {
          final semantics = tester.ensureSemantics();
          await _withOfflineServer(() async {
            await _pumpShell(tester, Locale(entry.key));

            for (final label in entry.value) {
              expect(
                find.bySemanticsLabel(label),
                findsOneWidget,
                reason: label,
              );
            }
            expect(tester.takeException(), isNull);
          });
          semantics.dispose();
        },
      );
    }
  });

  group('pastille repliée', () {
    Future<void> pumpBar(WidgetTester tester, Locale locale) => pumpLocalized(
      tester,
      Scaffold(
        extendBody: true,
        bottomNavigationBar: MazlNavBar(
          items: _items,
          currentIndex: 0,
          onTap: (_) {},
          collapsed: true,
          onExpand: () {},
        ),
      ),
      locale: locale,
    );

    testWidgets(
      'en anglais, elle s\'annonce « Show tabs » avec l\'onglet courant',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpBar(tester, const Locale('en'));

        expect(find.bySemanticsLabel('Show tabs'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('en français, le libellé d\'origine', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpBar(tester, kTestLocale);

      expect(find.bySemanticsLabel('Afficher les onglets'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
      'elle se place au début de la ligne : à gauche en français, à droite en hébreu',
      (tester) async {
        await pumpBar(tester, kTestLocale);
        final left = tester.getRect(find.byKey(const Key('mazl-nav-bar')));
        expect(left.left, MazlNavBar.sideMargin);

        await pumpBar(tester, const Locale('he'));
        await tester.pumpAndSettle();
        final right = tester.getRect(find.byKey(const Key('mazl-nav-bar')));
        expect(right.right, kSmallPhone.width - MazlNavBar.sideMargin);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
