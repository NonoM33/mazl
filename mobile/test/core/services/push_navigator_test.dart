import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/services/push_navigator.dart';

/// Un toucher sur une notification mène à son écran : tout de suite si l'app
/// est prête, sinon une fois le routeur monté et le membre connecté (lancement
/// à froid : écran de démarrage, connexion).
void main() {
  group('PushNavigator', () {
    late bool ready;
    late List<String> opened;
    late PushNavigator navigator;

    setUp(() {
      ready = true;
      opened = [];
      navigator = PushNavigator(
        isReady: () => ready,
        open: opened.add,
        retryEvery: const Duration(milliseconds: 500),
        giveUpAfter: const Duration(seconds: 10),
      );
    });

    tearDown(() => navigator.dispose());

    testWidgets('app prête : on y va tout de suite', (tester) async {
      navigator.handle({'type': 'new_message', 'conversation_id': 41});

      expect(opened, ['/chat/41']);
    });

    testWidgets('app pas prête : on attend, puis on y va une seule fois', (
      tester,
    ) async {
      ready = false;
      navigator.handle({'type': 'new_message', 'conversation_id': 41});
      await tester.pump(const Duration(seconds: 3));
      expect(opened, isEmpty);

      ready = true;
      await tester.pump(const Duration(seconds: 1));
      expect(opened, ['/chat/41']);

      await tester.pump(const Duration(seconds: 5));
      expect(opened, ['/chat/41'], reason: 'pas de seconde navigation');
    });

    testWidgets('on renonce si l\'app n\'est jamais prête', (tester) async {
      ready = false;
      navigator.handle({'type': 'new_message', 'conversation_id': 41});
      await tester.pump(const Duration(seconds: 20));

      ready = true;
      await tester.pump(const Duration(seconds: 5));
      expect(opened, isEmpty, reason: 'une notification périmée ne rouvre rien');
    });

    testWidgets('le dernier toucher gagne', (tester) async {
      ready = false;
      navigator.handle({'type': 'new_message', 'conversation_id': 41});
      navigator.handle({'type': 'couple_request'});

      ready = true;
      await tester.pump(const Duration(seconds: 1));
      expect(opened, ['/couple/today']);
    });

    testWidgets('un type ancien ou inconnu ne navigue pas et n\'attend pas', (
      tester,
    ) async {
      ready = false;
      navigator.handle({'type': 'event_reminder', 'eventId': 3});
      navigator.handle(const {});

      ready = true;
      await tester.pump(const Duration(seconds: 5));
      expect(opened, isEmpty);
    });
  });

  group('RouterPushTarget : le vrai routeur', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late GoRouter router;
    late bool signedIn;
    late RouterPushTarget target;

    Future<void> pumpApp(WidgetTester tester) async {
      navigatorKey = GlobalKey<NavigatorState>();
      signedIn = false;
      router = GoRouter(
        navigatorKey: navigatorKey,
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('splash')),
          GoRoute(path: '/onboarding', builder: (_, __) => const Text('onboarding')),
          GoRoute(path: '/login', builder: (_, __) => const Text('login')),
          GoRoute(path: '/profile/setup', builder: (_, __) => const Text('setup')),
          GoRoute(path: '/discover', builder: (_, __) => const Text('discover')),
          GoRoute(
            path: '/chat/:id',
            builder: (_, state) => Text('chat ${state.pathParameters['id']}'),
          ),
        ],
      );
      target = RouterPushTarget(
        navigatorKey: navigatorKey,
        isAuthenticated: () => signedIn,
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
    }

    testWidgets('l\'écran de démarrage n\'est pas « prêt »', (tester) async {
      await pumpApp(tester);
      signedIn = true;

      expect(target.isReady, isFalse);
    });

    testWidgets('connecté et sorti du démarrage : prêt', (tester) async {
      await pumpApp(tester);
      signedIn = true;
      router.go('/discover');
      await tester.pumpAndSettle();

      expect(target.isReady, isTrue);
    });

    testWidgets('pas connecté : jamais prêt, même sur un écran de l\'app', (
      tester,
    ) async {
      await pumpApp(tester);
      router.go('/discover');
      await tester.pumpAndSettle();

      expect(target.isReady, isFalse);
    });

    testWidgets('connexion, accueil et profil à compléter ne sont pas prêts', (
      tester,
    ) async {
      await pumpApp(tester);
      signedIn = true;
      for (final path in ['/onboarding', '/login', '/profile/setup']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(target.isReady, isFalse, reason: path);
      }
    });

    testWidgets('open mène au chemin demandé', (tester) async {
      await pumpApp(tester);
      signedIn = true;
      router.go('/discover');
      await tester.pumpAndSettle();

      target.open('/chat/41');
      await tester.pumpAndSettle();

      expect(find.text('chat 41'), findsOneWidget);
    });

    testWidgets('aucun navigateur monté : pas prêt', (tester) async {
      final lonelyTarget = RouterPushTarget(
        navigatorKey: GlobalKey<NavigatorState>(),
        isAuthenticated: () => true,
      );

      expect(lonelyTarget.isReady, isFalse);
    });
  });
}
