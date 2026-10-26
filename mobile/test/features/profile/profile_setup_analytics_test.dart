import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/analytics/analytics.dart';
import 'package:mazl/core/di/providers/analytics_providers.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/presentation/features/profile/screens/profile_setup_screen.dart';

import '../../core/analytics/analytics_fakes.dart';
import '../../helpers/test_helpers.dart';
import '../../presentation/privacy/privacy_fakes.dart';

/// What the measurement received, as `name` or `name:step:step_name`.
Future<List<String>> _walk(
  WidgetTester tester, {
  required int stepsForward,
  bool finish = false,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final transport = FakeAnalyticsTransport();
  final analytics = Analytics(
    transport: transport,
    clock: FakeClock().call,
    periodicTimer: FakeTimers().call,
  )..consentLoaded(granted: true);

  await http.runWithClient(
    () async {
      await tester.pumpWidget(
        createTestableWidget(
          const ProfileSetupScreen(),
          overrides: [
            privacyConsentApiProvider.overrideWithValue(
              FakePrivacyConsentApi(granted: true, version: '2026-10-24'),
            ),
            analyticsProvider.overrideWithValue(analytics),
          ],
        ),
      );
      await tester.pumpAndSettle();
      analytics.signedIn();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Prénom'),
        'Jeanne',
      );
      await tester.tap(find.byIcon(LucideIcons.calendar));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Une femme'));
      await tester.pump();
      for (var i = 0; i < stepsForward; i++) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
      }
      if (finish) {
        await tester.tap(find.text('Un homme'));
        await tester.pump();
        await tester.tap(find.text('Terminer'));
        await tester.pumpAndSettle();
      }
    },
    () => MockClient((request) async {
      if (request.method == 'PUT' && request.url.path == '/api/profile') {
        return http.Response(
          jsonEncode({
            'success': true,
            'profile': {'id': 1, 'user_id': 1},
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'success': true}), 200);
    }),
  );
  await analytics.flush();
  return [
    for (final batch in transport.batches)
      for (final queued in batch)
        [
          queued.event.name,
          ...queued.event.properties.values.map((v) => '$v'),
        ].join(':'),
  ];
}

void main() {
  testWidgets('each step of the sign-up is reported once, with a stable name', (
    tester,
  ) async {
    final events = await _walk(tester, stepsForward: 3);
    expect(events.where((e) => e.startsWith('onboarding_step_viewed')), [
      'onboarding_step_viewed:0:basicInfo',
      'onboarding_step_viewed:1:photos',
      'onboarding_step_viewed:2:jewishPractice',
      'onboarding_step_viewed:3:preferences',
    ]);
    expect(events, isNot(contains('signup_completed')));
  });

  testWidgets('the first step is reported when the screen opens', (
    tester,
  ) async {
    final events = await _walk(tester, stepsForward: 0);
    expect(events, ['onboarding_step_viewed:0:basicInfo']);
  });

  testWidgets('signup_completed comes once the profile is saved', (
    tester,
  ) async {
    final events = await _walk(tester, stepsForward: 3, finish: true);
    expect(events.where((e) => e == 'signup_completed'), hasLength(1));
    expect(events.last, 'signup_completed');
  });
}
