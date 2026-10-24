import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/router/couple_guard.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/services/websocket_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_mode_setup_screen.dart';
import 'package:mazl/presentation/features/couple/widgets/couple_flow_host.dart';
import 'package:mazl/presentation/features/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'couple_flow_fakes.dart';
import '../../helpers/l10n_helpers.dart';

Future<ApiResponse<List<Map<String, dynamic>>>> _oneMatch() async => ApiResponse.success([
      {
        'id': 3,
        'profile': {'user_id': 45, 'display_name': 'Myriam', 'picture': null},
      },
    ]);

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}

/// A router wired like the app's: same guard, refreshed by the couple state.
GoRouter _router(
  CoupleService service,
  GlobalKey<NavigatorState> navigatorKey, {
  required String initial,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initial,
    refreshListenable: service,
    redirect: (context, state) => coupleRedirect(
      location: state.matchedLocation,
      inCouple: service.isCoupleModeEnabled,
    ),
    routes: [
      GoRoute(path: '/discover', builder: (_, __) => const Scaffold(body: Text('PAGE DECOUVRIR'))),
      GoRoute(
        path: '/couple/activities',
        builder: (_, __) => const Scaffold(body: Text('PAGE ACTIVITES')),
      ),
      GoRoute(
        path: '/couple/mazel-tov',
        // Stand-in for MazelTovScreen (its layout needs the app's fonts; the
        // real one ends with the same context.go('/couple/activities')).
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return Scaffold(
            body: Column(
              children: [
                Text('Mazel Tov ${extra?['partnerName']}'),
                TextButton(
                  onPressed: () => context.go('/couple/activities'),
                  child: const Text('Commencer notre aventure'),
                ),
              ],
            ),
          );
        },
      ),
      GoRoute(path: '/couple/space/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
}

/// Never disposed: the app's services are singletons, and a ProviderScope
/// disposes the ones it creates, which would break the next test.
final _sharedContainer = ProviderContainer();

Widget _app(
  GoRouter router,
  CoupleService service,
  GlobalKey<NavigatorState> navigatorKey,
  Stream<ChatEvent> realtime,
) {
  return UncontrolledProviderScope(
    container: _sharedContainer,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      routerConfig: router,
      builder: (context, child) => CoupleFlowHost(
        service: service,
        router: router,
        navigatorKey: navigatorKey,
        realtime: realtime,
        auth: ValueNotifier<int>(0),
        isAuthenticated: () => true,
        child: child!,
      ),
    ),
  );
}

void main() {
  late FakeCoupleApi api;
  late CoupleService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeCoupleApi();
    service = CoupleService.forTesting(api: api, pollInterval: const Duration(hours: 1));
  });

  tearDown(() => service.dispose());

  group('écran de mise en place', () {
    Future<void> pumpSetup(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: kTestLocale,
        home: CoupleModeSetupScreen(service: service, loadMatches: _oneMatch),
      ));
      await tester.pump();
    }

    testWidgets('envoie une demande et montre la confirmation, sans annulation', (tester) async {
      await pumpSetup(tester);

      await tester.tap(find.text('Myriam'));
      await tester.pump();
      await tester.tap(find.text('Envoyer la demande'));
      await tester.pump();
      await tester.pump();

      expect(api.calls, contains('send:45'));
      expect(find.text('Demande envoyée'), findsOneWidget);
      expect(find.text('Myriam doit accepter. Nous vous préviendrons dès sa réponse.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Compris'), findsOneWidget);
      expect(find.text('Annuler la demande'), findsNothing);
      expect(service.isCoupleModeEnabled, isFalse);
      await service.cancelCoupleRequest(); // stops the polling timer
    });

    testWidgets('« Compris » ferme l\'écran et ramène à la page précédente', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/setup'),
                child: const Text('PAGE PRECEDENTE'),
              ),
            ),
          ),
          GoRoute(
            path: '/setup',
            builder: (_, __) => CoupleModeSetupScreen(service: service, loadMatches: _oneMatch),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, locale: kTestLocale, routerConfig: router));
      await tester.pump();
      await tester.tap(find.text('PAGE PRECEDENTE'));
      await _pumpFor(tester, const Duration(milliseconds: 400));

      await tester.tap(find.text('Myriam'));
      await tester.pump();
      await tester.tap(find.text('Envoyer la demande'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Demande envoyée'), findsOneWidget);

      await tester.tap(find.text('Compris'));
      await tester.pumpAndSettle();

      expect(find.text('Demande envoyée'), findsNothing);
      expect(find.text('PAGE PRECEDENTE'), findsOneWidget);
      await service.cancelCoupleRequest(); // stops the polling timer
    });

    testWidgets('rouvrir avec une demande en attente : confirmation et annulation', (tester) async {
      await service.sendCoupleRequest(targetUserId: 45, targetName: 'Myriam');
      await pumpSetup(tester);

      expect(find.text('Demande envoyée'), findsOneWidget);
      expect(find.text('Myriam doit accepter. Nous vous préviendrons dès sa réponse.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Annuler la demande'), findsOneWidget);

      await tester.tap(find.text('Annuler la demande'));
      await tester.pump();
      await tester.pump();

      expect(api.calls, contains('cancel:77'));
      expect(service.pendingRequest, isNull);
      expect(find.text('Avec qui ?'), findsOneWidget);
      expect(find.text('Envoyer la demande'), findsOneWidget);
    });

    testWidgets('not_matched : un message français, aucune attente', (tester) async {
      api.sendError = 'not_matched';
      await pumpSetup(tester);

      await tester.tap(find.text('Myriam'));
      await tester.pump();
      await tester.tap(find.text('Envoyer la demande'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Le mode couple ne s\'active qu\'avec un match.'), findsOneWidget);
      expect(find.textContaining('Demande envoyée'), findsNothing);
      expect(service.pendingRequest, isNull);
    });

    testWidgets('l\'envoi est sans bouton actif tant qu\'aucun match n\'est choisi', (tester) async {
      await pumpSetup(tester);
      final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Envoyer la demande'));
      expect(button.onPressed, isNull);
    });
  });

  group('parcours complet avec le routeur', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late StreamController<ChatEvent> realtime;
    late GoRouter router;

    Future<void> pumpApp(WidgetTester tester, {required String initial}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      navigatorKey = GlobalKey<NavigatorState>();
      realtime = StreamController<ChatEvent>.broadcast();
      router = _router(service, navigatorKey, initial: initial);
      await tester.pumpWidget(_app(router, service, navigatorKey, realtime.stream));
      await _pumpFor(tester, const Duration(milliseconds: 300));
    }

    tearDown(() => realtime.close());

    testWidgets('le destinataire accepte : Mazel Tov puis /couple/activities', (tester) async {
      api.acceptedCouple = contractCouple();
      await pumpApp(tester, initial: '/discover');

      realtime.add(CoupleRealtimeEvent(
        type: 'couple:request',
        payload: {'request': contractReceivedRequest()},
      ));
      await _pumpFor(tester, const Duration(milliseconds: 300));

      expect(find.text('Myriam souhaite activer le mode couple avec vous'), findsOneWidget);

      await tester.tap(find.text('Accepter'));
      await _pumpFor(tester, const Duration(milliseconds: 500));

      expect(api.calls, containsAllInOrder(['accept:91', 'archive:45']));
      expect(api.calls.where((c) => c.startsWith('send:')), isEmpty);
      expect(find.text('Mazel Tov Myriam'), findsOneWidget);

      await tester.tap(find.text('Commencer notre aventure'));
      await _pumpFor(tester, const Duration(milliseconds: 600));

      expect(find.text('PAGE ACTIVITES'), findsOneWidget);
      expect(find.text('PAGE DECOUVRIR'), findsNothing);
    });

    testWidgets('l\'émetteur apprend l\'acceptation par couple:accepted', (tester) async {
      await pumpApp(tester, initial: '/discover');
      await service.sendCoupleRequest(targetUserId: 45, targetName: 'Myriam');

      realtime.add(CoupleRealtimeEvent(
        type: 'couple:accepted',
        payload: {'couple': contractCouple()},
      ));
      await _pumpFor(tester, const Duration(milliseconds: 500));

      expect(find.text('Mazel Tov Myriam'), findsOneWidget);
      expect(api.calls, contains('archive:45'));
      await tester.tap(find.text('Commencer notre aventure'));
      await _pumpFor(tester, const Duration(milliseconds: 600));
      expect(find.text('PAGE ACTIVITES'), findsOneWidget);
    });

    testWidgets('couple:rejected : message court, plus d\'attente', (tester) async {
      await pumpApp(tester, initial: '/discover');
      await service.sendCoupleRequest(targetUserId: 45, targetName: 'Myriam');

      realtime.add(CoupleRealtimeEvent(type: 'couple:rejected', payload: {'request_id': 77}));
      await _pumpFor(tester, const Duration(milliseconds: 300));

      expect(find.text('Myriam n\'a pas donné suite à votre demande.'), findsOneWidget);
      expect(service.pendingRequest, isNull);
      expect(find.text('PAGE DECOUVRIR'), findsOneWidget);
    });

    testWidgets('en couple, ouvrir /discover ramène aux activités', (tester) async {
      api.couple = contractCouple();
      await service.initialize();
      await pumpApp(tester, initial: '/discover');
      expect(find.text('PAGE ACTIVITES'), findsOneWidget);
    });

    testWidgets('couple:ended : retour aux rencontres avec un message', (tester) async {
      api.couple = contractCouple();
      await service.initialize();
      await pumpApp(tester, initial: '/couple/activities');
      expect(find.text('PAGE ACTIVITES'), findsOneWidget);

      realtime.add(CoupleRealtimeEvent(type: 'couple:ended', payload: {'couple_id': 12}));
      await _pumpFor(tester, const Duration(milliseconds: 400));

      expect(find.text('PAGE DECOUVRIR'), findsOneWidget);
      expect(find.text('Le mode couple a pris fin.'), findsOneWidget);
    });
  });

  group('sortie du mode couple depuis les réglages', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late StreamController<ChatEvent> realtime;

    Future<void> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      api.couple = contractCouple();
      await service.initialize();
      CoupleService.instanceForTesting = service;
      navigatorKey = GlobalKey<NavigatorState>();
      realtime = StreamController<ChatEvent>.broadcast();
      final router = _router(service, navigatorKey, initial: '/couple/space/settings');
      await tester.pumpWidget(_app(router, service, navigatorKey, realtime.stream));
      await _pumpFor(tester, const Duration(milliseconds: 500));
    }

    tearDown(() => realtime.close());

    testWidgets('confirmer : DELETE attendu puis retour aux rencontres', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.text('Quitter le mode couple'));
      await _pumpFor(tester, const Duration(milliseconds: 500));
      await tester.tap(find.text('Quitter'));
      await _pumpFor(tester, const Duration(milliseconds: 600));

      expect(api.calls, contains('end:12'));
      expect(service.isCoupleModeEnabled, isFalse);
      expect(find.text('PAGE DECOUVRIR'), findsOneWidget);
    });

    testWidgets('échec du serveur : un message, on reste en couple', (tester) async {
      api.endError = 'boom';
      await pumpSettings(tester);

      await tester.tap(find.text('Quitter le mode couple'));
      await _pumpFor(tester, const Duration(milliseconds: 500));
      await tester.tap(find.text('Quitter'));
      await _pumpFor(tester, const Duration(milliseconds: 600));

      expect(api.calls, contains('end:12'));
      expect(service.isCoupleModeEnabled, isTrue);
      expect(find.text('Le serveur est indisponible. Réessayez dans un instant.'), findsOneWidget);
      expect(find.text('PAGE DECOUVRIR'), findsNothing);
    });

    testWidgets('annuler la confirmation n\'appelle rien', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.text('Quitter le mode couple'));
      await _pumpFor(tester, const Duration(milliseconds: 500));
      await tester.tap(find.text('Annuler'));
      await _pumpFor(tester, const Duration(milliseconds: 400));

      expect(api.calls.where((c) => c.startsWith('end:')), isEmpty);
      expect(service.isCoupleModeEnabled, isTrue);
    });
  });
}
