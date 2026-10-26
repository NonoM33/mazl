import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/analytics/analytics.dart';
import 'package:mazl/core/di/providers/analytics_providers.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/l10n/l10n.dart';
import 'package:mazl/presentation/features/privacy/screens/analytics_settings_screen.dart';

import '../../core/analytics/analytics_fakes.dart';
import '../../features/duo/duo_geometry.dart';
import '../../helpers/duo_poses.dart';
import 'privacy_fakes.dart';

class _Rig {
  _Rig({this.pose = DuoPose.openPortrait, bool? granted, String? version})
    : api = FakePrivacyConsentApi(
        analyticsGranted: granted,
        analyticsVersion: version,
      ) {
    analytics = Analytics(
      transport: transport,
      clock: FakeClock().call,
      periodicTimer: FakeTimers().call,
    )..signedIn();
    if (granted == true) analytics.consentLoaded(granted: true);
  }

  final DuoPose pose;
  final FakePrivacyConsentApi api;
  final transport = FakeAnalyticsTransport();
  late final Analytics analytics;

  Future<void> open(WidgetTester tester) async {
    setDuoPose(tester, pose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyConsentApiProvider.overrideWithValue(api),
          analyticsProvider.overrideWithValue(analytics),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: duoAppBuilder(DuoPoseController(pose)),
          home: const AnalyticsSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settleFold(tester);
  }
}

void main() {
  testWidgets('not granted: says so, shows the server text, offers to accept', (
    tester,
  ) async {
    await _Rig(granted: false, version: '2026-10-26').open(tester);

    expect(find.text('Mesure d\'audience désactivée'), findsOneWidget);
    expect(find.text(analyticsConsentText), findsOneWidget);
    expect(find.text('Accepter la mesure d\'audience'), findsOneWidget);
    expect(find.text('Retirer mon accord'), findsNothing);
  });

  testWidgets('accepting records it and tells the measurement', (tester) async {
    final rig = _Rig(granted: false, version: '2026-10-26');
    await rig.open(tester);

    await tester.tap(find.text('Accepter la mesure d\'audience'));
    await tester.pumpAndSettle();

    expect(rig.api.calls, contains('put:analytics:true:2026-10-26'));
    expect(rig.analytics.consent, AnalyticsConsentState.granted);
    expect(find.text('Mesure d\'audience activée'), findsOneWidget);
    expect(find.text('Retirer mon accord'), findsOneWidget);
  });

  testWidgets('withdrawing records it at once and empties the queue', (
    tester,
  ) async {
    final rig = _Rig(granted: true, version: '2026-10-26');
    await rig.open(tester);
    expect(find.text('Mesure d\'audience activée'), findsOneWidget);

    await tester.tap(find.text('Retirer mon accord'));
    await tester.pumpAndSettle();

    expect(rig.api.calls, contains('put:analytics:false:2026-10-26'));
    expect(rig.analytics.consent, AnalyticsConsentState.denied);
    expect(find.text('Mesure d\'audience désactivée'), findsOneWidget);
    expect(rig.transport.batches, isEmpty);
  });

  testWidgets('a consent given to an older text counts as not given', (
    tester,
  ) async {
    await _Rig(granted: true, version: '2026-01-01').open(tester);
    expect(find.text('Mesure d\'audience désactivée'), findsOneWidget);
  });

  testWidgets('a failed save says so and changes nothing', (tester) async {
    final rig = _Rig(granted: true, version: '2026-10-26');
    rig.api.failDecide = true;
    await rig.open(tester);

    await tester.tap(find.text('Retirer mon accord'));
    await tester.pumpAndSettle();

    expect(find.textContaining('pas pu être enregistré'), findsOneWidget);
    expect(rig.analytics.consent, AnalyticsConsentState.granted);
  });

  testWidgets('a failed read offers to retry', (tester) async {
    final rig = _Rig(granted: false);
    rig.api.failFetch = true;
    await rig.open(tester);

    expect(find.textContaining('Impossible de lire'), findsOneWidget);
    rig.api.failFetch = false;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Mesure d\'audience activée'), findsNothing);
    expect(find.text(analyticsConsentText), findsOneWidget);
  });

  for (final pose in DuoPose.values) {
    testWidgets('${pose.name}: fits, off the fold, 44 pt button', (
      tester,
    ) async {
      await _Rig(pose: pose, granted: true, version: '2026-10-26').open(tester);

      expectFitsDuoPose(tester, pose, 'analytics settings');
      expect(tappableProblems(tester, pose), isEmpty, reason: pose.name);
      expect(foldCrossingProblems(tester, pose), isEmpty, reason: pose.name);
      final size = tester.getSize(
        find.widgetWithText(OutlinedButton, 'Retirer mon accord'),
      );
      expect(size.height, greaterThanOrEqualTo(44));
    });
  }
}
