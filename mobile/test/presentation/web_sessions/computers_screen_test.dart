import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/web_sessions_providers.dart';
import 'package:mazl/core/web_sessions/web_session_models.dart';
import 'package:mazl/presentation/features/web_sessions/screens/computers_screen.dart';
import 'package:mazl/l10n/l10n.dart';

import 'web_sessions_fakes.dart';

Future<void> _open(WidgetTester tester, FakeWebSessionsApi api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [webSessionsApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: const ComputersScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final now = DateTime(2026, 10, 24, 12);

  testWidgets('explains the feature and shows the empty state', (tester) async {
    await _open(tester, FakeWebSessionsApi());

    expect(find.textContaining('app.mazl.app'), findsOneWidget);
    expect(find.textContaining('7 jours au plus'), findsOneWidget);
    expect(find.text('Connecter un ordinateur'), findsOneWidget);
    expect(
      find.text('Aucun ordinateur n\'est connecté pour le moment.'),
      findsOneWidget,
    );
    expect(find.text('Déconnecter tous les ordinateurs'), findsNothing);
  });

  testWidgets('lists each computer with method and relative activity', (
    tester,
  ) async {
    await withClock(Clock.fixed(now), () async {
      await _open(
        tester,
        FakeWebSessionsApi(
          sessions: [
            fakeSession('s1'),
            fakeSession(
              's2',
              browser: 'Safari sur macOS',
              method: WebSessionMethod.apple,
              lastSeen: DateTime(2026, 10, 22, 12),
            ),
          ],
        ),
      );

      expect(find.text('Chrome sur macOS'), findsOneWidget);
      expect(
        find.text('Connecté par QR code · Actif il y a 5 min'),
        findsOneWidget,
      );
      expect(
        find.text('Connecté avec Apple · Actif il y a 2 j'),
        findsOneWidget,
      );
      expect(find.text('Déconnecter'), findsNWidgets(2));
    });
  });

  testWidgets('Déconnecter revokes that session and refreshes', (tester) async {
    final api = FakeWebSessionsApi(
      sessions: [
        fakeSession('s1'),
        fakeSession('s2', browser: 'Firefox sur Windows'),
      ],
    );
    await _open(tester, api);

    await tester.tap(find.text('Déconnecter').first);
    await tester.pumpAndSettle();

    expect(api.calls, contains('revoke:s1'));
    expect(find.text('Chrome sur macOS'), findsNothing);
    expect(find.text('Firefox sur Windows'), findsOneWidget);
  });

  testWidgets('disconnecting everything asks first, then revokes all', (
    tester,
  ) async {
    final api = FakeWebSessionsApi(sessions: [fakeSession('s1')]);
    await _open(tester, api);

    await tester.tap(find.text('Déconnecter tous les ordinateurs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(api.calls, isNot(contains('revokeAll')));

    await tester.tap(find.text('Déconnecter tous les ordinateurs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Déconnecter tout'));
    await tester.pumpAndSettle();

    expect(api.calls, contains('revokeAll'));
    expect(
      find.text('Aucun ordinateur n\'est connecté pour le moment.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed load shows an error and Réessayer reloads', (
    tester,
  ) async {
    final api = FakeWebSessionsApi(sessions: [fakeSession('s1')])
      ..listFails = true;
    await _open(tester, api);
    expect(find.textContaining('Impossible de charger'), findsOneWidget);

    api.listFails = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(find.text('Chrome sur macOS'), findsOneWidget);
  });
}
