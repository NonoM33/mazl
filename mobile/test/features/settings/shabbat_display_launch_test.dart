import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/presentation/features/settings/screens/shabbat_mode_screen.dart';

import '../../helpers/l10n_helpers.dart';

// L'affichage se lance depuis l'écran Mode Shabbat, AVANT Shabbat.

class _Api implements ApiService {
  @override
  Future<ApiResponse<UserProfile>> getCurrentUser() async =>
      ApiResponse.failure('offline', ApiErrorKind.network);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_Api: ${invocation.memberName}');
}

Future<void> _pump(WidgetTester tester, {Locale locale = kTestLocale}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: RoutePaths.shabbatMode,
    routes: [
      GoRoute(
        path: RoutePaths.shabbatMode,
        builder: (_, _) => ShabbatModeScreen(
          apiService: _Api(),
          clock: () => DateTime(2026, 1, 7),
        ),
        routes: [
          GoRoute(
            path: 'display',
            builder: (_, _) => const Scaffold(body: Text('AFFICHAGE')),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: router,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  test('le chemin de l\'affichage est sous l\'écran Mode Shabbat', () {
    expect(RoutePaths.shabbatDisplay, '${RoutePaths.shabbatMode}/display');
  });

  testWidgets('le bouton ouvre l\'affichage', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Lancer l\'affichage'));
    await tester.pumpAndSettle();

    expect(find.text('AFFICHAGE'), findsOneWidget);
  });

  testWidgets('le texte dit de le lancer avant Shabbat, sans rien promettre '
      'd\'autre', (tester) async {
    await _pump(tester);

    expect(find.textContaining('avant Shabbat'), findsOneWidget);
    expect(find.textContaining('l\'écran reste allumé'), findsOneWidget);
    for (final promise in const ['notification', 'silence', 'pause', 'Pause']) {
      expect(find.textContaining(promise), findsNothing, reason: promise);
    }
  });

  final labels = {
    const Locale('fr'): 'Lancer l\'affichage',
    const Locale('en'): 'Start the display',
    const Locale('es'): 'Iniciar la pantalla',
    const Locale('he'): 'הפעלת התצוגה',
    const Locale('ru'): 'Запустить экран',
  };
  for (final entry in labels.entries) {
    testWidgets('${entry.key.languageCode} : le bouton est traduit', (
      tester,
    ) async {
      await _pump(tester, locale: entry.key);

      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
