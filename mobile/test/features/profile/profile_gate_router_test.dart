import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/router/app_guard.dart';
import 'package:mazl/core/services/profile_completeness_service.dart';

/// A router wired like the app's: the same [appRedirect], refreshed by the
/// profile completeness, with stand-in screens (the real ones need the app's
/// providers and fonts).
GoRouter _router(
  ProfileCompletenessService completeness, {
  required String initial,
  bool authenticated = true,
}) {
  return GoRouter(
    initialLocation: initial,
    refreshListenable: completeness,
    redirect: (context, state) => appRedirect(
      location: state.matchedLocation,
      isAuthenticated: authenticated,
      profileIncomplete: completeness.needsSetup,
      inCouple: false,
    ),
    routes: [
      GoRoute(path: '/discover', builder: (_, __) => const Scaffold(body: Text('PAGE DECOUVRIR'))),
      GoRoute(
        path: '/profile/setup',
        builder: (context, _) => Scaffold(
          body: Column(
            children: [
              const Text('PAGE CONFIGURATION'),
              TextButton(
                // What the real setup does once the profile is saved.
                onPressed: () {
                  completeness.markComplete();
                  context.go('/discover');
                },
                child: const Text('Terminer'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(path: '/profile/settings', builder: (_, __) => const Scaffold(body: Text('PAGE REGLAGES'))),
      GoRoute(
        path: '/login',
        builder: (context, _) => Scaffold(
          body: TextButton(
            // What the login screen does after ANY successful sign-in.
            onPressed: () => context.go('/discover'),
            child: const Text('Se connecter'),
          ),
        ),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  group('restored session', () {
    testWidgets('a profile missing gender is redirected to the setup', (tester) async {
      final completeness = ProfileCompletenessService.create(
        () async => ['gender', 'looking_for'],
      );
      await completeness.refresh(); // what the splash does after a restore
      await _pump(tester, _router(completeness, initial: '/discover'));

      expect(find.text('PAGE CONFIGURATION'), findsOneWidget);
      expect(find.text('PAGE DECOUVRIR'), findsNothing);
    });

    testWidgets('a profile missing only looking_for is redirected too', (tester) async {
      final completeness = ProfileCompletenessService.create(() async => ['looking_for']);
      await completeness.refresh();
      await _pump(tester, _router(completeness, initial: '/discover'));

      expect(find.text('PAGE CONFIGURATION'), findsOneWidget);
    });

    testWidgets('a complete profile reaches Discover', (tester) async {
      final completeness = ProfileCompletenessService.create(() async => <String>[]);
      await completeness.refresh();
      await _pump(tester, _router(completeness, initial: '/discover'));

      expect(find.text('PAGE DECOUVRIR'), findsOneWidget);
      expect(find.text('PAGE CONFIGURATION'), findsNothing);
    });

    testWidgets('the settings stay reachable to sign out', (tester) async {
      final completeness = ProfileCompletenessService.create(() async => ['gender']);
      await completeness.refresh();
      await _pump(tester, _router(completeness, initial: '/profile/settings'));

      expect(find.text('PAGE REGLAGES'), findsOneWidget);
    });
  });

  group('Discover answering 409 profile_incomplete', () {
    testWidgets('moves a member already on Discover to the setup', (tester) async {
      // Unknown at launch (offline): let through, the feed corrects it.
      final completeness = ProfileCompletenessService.create(() async => null);
      await completeness.refresh();
      await _pump(tester, _router(completeness, initial: '/discover'));
      expect(find.text('PAGE DECOUVRIR'), findsOneWidget);

      completeness.markIncomplete(['looking_for']); // ApiService does this on a 409
      await tester.pumpAndSettle();

      expect(find.text('PAGE CONFIGURATION'), findsOneWidget);
    });
  });

  group('profile setup', () {
    testWidgets('finishing it lets the member through to Discover', (tester) async {
      final completeness = ProfileCompletenessService.create(() async => ['gender', 'looking_for']);
      await completeness.refresh();
      await _pump(tester, _router(completeness, initial: '/discover'));
      expect(find.text('PAGE CONFIGURATION'), findsOneWidget);

      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();

      expect(find.text('PAGE DECOUVRIR'), findsOneWidget);
    });
  });

  group('login no longer depends on isNewUser', () {
    // Both go to Discover; only the guard decides.
    testWidgets('a brand new account ends up on the setup', (tester) async {
      final completeness = ProfileCompletenessService.create(() async => ['gender', 'looking_for']);
      await _pump(tester, _router(completeness, initial: '/login'));

      await completeness.refresh(); // AuthService does this after the sign-in
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('PAGE CONFIGURATION'), findsOneWidget);
    });

    testWidgets('an existing account with a complete profile ends up on Discover', (tester) async {
      final completeness = ProfileCompletenessService.create(() async => <String>[]);
      await _pump(tester, _router(completeness, initial: '/login'));

      await completeness.refresh();
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('PAGE DECOUVRIR'), findsOneWidget);
    });

    test('the login screen does not read isNewUser any more', () {
      final source = File('lib/presentation/features/auth/screens/login_screen.dart').readAsStringSync();
      expect(source, isNot(contains('isNewUser')));
      expect(source, isNot(contains('RoutePaths.profileSetup')));
    });

    test('a sign-in result does not carry isNewUser any more', () {
      final source = File('lib/core/services/auth_service.dart').readAsStringSync();
      expect(source, isNot(contains('isNewUser')));
    });
  });
}
