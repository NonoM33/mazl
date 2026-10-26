import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/analytics/analytics.dart';
import 'package:mazl/core/di/providers/analytics_providers.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/di/providers/service_providers.dart';
import 'package:mazl/core/services/quiet_display.dart';
import 'package:mazl/l10n/l10n.dart';
import 'package:mazl/presentation/features/privacy/widgets/analytics_host.dart';

import '../../core/analytics/analytics_fakes.dart';
import 'privacy_fakes.dart';

final _signedIn = StateProvider<bool>((_) => false);

class _Rig {
  _Rig({bool? granted, String? version = '2026-10-26', QuietDisplay? quiet})
    : api = FakePrivacyConsentApi(
        analyticsGranted: granted,
        analyticsVersion: version,
      ),
      quiet = quiet ?? QuietDisplay() {
    analytics = Analytics(
      transport: transport,
      clock: FakeClock().call,
      periodicTimer: FakeTimers().call,
    );
    router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/discover',
      routes: [
        GoRoute(
          path: '/discover',
          name: 'discover',
          builder: (_, _) => const Scaffold(body: Text('page')),
        ),
      ],
    );
  }

  final FakePrivacyConsentApi api;
  final QuietDisplay quiet;
  final transport = FakeAnalyticsTransport();
  final navigatorKey = GlobalKey<NavigatorState>();
  late final Analytics analytics;
  late final GoRouter router;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [
        privacyConsentApiProvider.overrideWithValue(api),
        analyticsProvider.overrideWithValue(analytics),
        isAuthenticatedProvider.overrideWith((ref) => ref.watch(_signedIn)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          routerConfig: router,
          builder: (context, child) => AnalyticsHost(
            router: router,
            navigatorKey: navigatorKey,
            quiet: quiet,
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester) async {
    container.read(_signedIn.notifier).state = true;
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('asks once after sign-in when never asked, not before', (
    tester,
  ) async {
    final rig = _Rig();
    await rig.pump(tester);
    expect(find.text('Aider à améliorer MAZL'), findsNothing);
    expect(rig.api.calls, isEmpty, reason: 'nothing fetched while signed out');

    await rig.signIn(tester);
    expect(find.text('Aider à améliorer MAZL'), findsOneWidget);
    expect(find.text(analyticsConsentText), findsOneWidget);
    expect(find.text('Accepter'), findsOneWidget);
    expect(find.text('Refuser'), findsOneWidget);
  });

  testWidgets(
    'accepting sends analytics_consent_granted then the held events',
    (tester) async {
      final rig = _Rig();
      await rig.pump(tester);
      await rig.signIn(tester);

      await tester.tap(find.text('Accepter'));
      await tester.pumpAndSettle();

      expect(rig.api.calls, contains('put:analytics:true:2026-10-26'));
      expect(rig.analytics.consent, AnalyticsConsentState.granted);
      expect(rig.transport.sentNames.first, 'analytics_consent_granted');
      expect(rig.transport.sentNames, contains('app_opened'));
      expect(find.text('Aider à améliorer MAZL'), findsNothing);
    },
  );

  testWidgets('refusing sends nothing and loses what was held', (tester) async {
    final rig = _Rig();
    await rig.pump(tester);
    await rig.signIn(tester);

    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();

    expect(rig.analytics.consent, AnalyticsConsentState.denied);
    expect(rig.transport.batches, isEmpty);
    expect(rig.analytics.pendingCount, 0);
  });

  testWidgets('a consent already given is loaded, not asked, not announced', (
    tester,
  ) async {
    final rig = _Rig(granted: true);
    await rig.pump(tester);
    await rig.signIn(tester);

    expect(find.text('Aider à améliorer MAZL'), findsNothing);
    expect(rig.analytics.consent, AnalyticsConsentState.granted);
    await rig.analytics.flush();
    expect(
      rig.transport.sentNames,
      isNot(contains('analytics_consent_granted')),
    );
  });

  testWidgets('a refusal already on file is respected and not asked again', (
    tester,
  ) async {
    final rig = _Rig(granted: false);
    await rig.pump(tester);
    await rig.signIn(tester);

    expect(find.text('Aider à améliorer MAZL'), findsNothing);
    expect(rig.analytics.consent, AnalyticsConsentState.denied);
  });

  testWidgets('a consent given to an older text is asked again', (
    tester,
  ) async {
    final rig = _Rig(granted: true, version: '2026-01-01');
    await rig.pump(tester);
    await rig.signIn(tester);

    expect(find.text('Aider à améliorer MAZL'), findsOneWidget);
    expect(rig.analytics.consent, AnalyticsConsentState.unknown);
  });

  testWidgets('dismissing the sheet does not ask again during the session', (
    tester,
  ) async {
    final rig = _Rig();
    await rig.pump(tester);
    await rig.signIn(tester);
    rig.navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Aider à améliorer MAZL'), findsNothing);

    rig.container.invalidate(analyticsConsentProvider);
    await tester.pumpAndSettle();
    expect(find.text('Aider à améliorer MAZL'), findsNothing);
    expect(rig.analytics.consent, AnalyticsConsentState.unknown);
  });

  testWidgets('signing out forgets the consent and the queue', (tester) async {
    final rig = _Rig(granted: true);
    await rig.pump(tester);
    await rig.signIn(tester);
    expect(rig.analytics.consent, AnalyticsConsentState.granted);

    rig.container.read(_signedIn.notifier).state = false;
    await tester.pumpAndSettle();

    expect(rig.analytics.consent, AnalyticsConsentState.unknown);
    expect(rig.analytics.pendingCount, 0);
  });

  testWidgets(
    'app_opened is recorded once, at start, and the screen after it',
    (tester) async {
      final rig = _Rig(granted: true);
      await rig.pump(tester);
      await rig.signIn(tester);
      await rig.analytics.flush();

      final names = rig.transport.sentNames;
      expect(names.where((n) => n == 'app_opened'), hasLength(1));
      expect(names, contains('screen_viewed'));
    },
  );

  testWidgets('the events before the first sign-in are kept, not wiped', (
    tester,
  ) async {
    final rig = _Rig();
    await rig.pump(tester);
    // app_opened and the first screen, signed out.
    expect(rig.analytics.pendingCount, 2);
  });

  testWidgets('going to the background flushes what waits', (tester) async {
    final rig = _Rig(granted: true);
    await rig.pump(tester);
    await rig.signIn(tester);
    expect(rig.transport.batches, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(rig.transport.sentNames, contains('app_opened'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('the Shabbat display keeps the question for later', (
    tester,
  ) async {
    final quiet = QuietDisplay()..enter();
    final rig = _Rig(quiet: quiet);
    await rig.pump(tester);
    await rig.signIn(tester);
    expect(find.text('Aider à améliorer MAZL'), findsNothing);

    quiet.leave();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Aider à améliorer MAZL'), findsOneWidget);
  });
}
