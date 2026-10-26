import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/analytics/analytics_event.dart';

/// The plan (docs/analytics/plan-de-marquage.md §2, "sent by the app"), written
/// out here from the document, not from the code under test.
const _plan = <String, Set<String>>{
  'app_opened': {},
  'screen_viewed': {'screen'},
  'onboarding_step_viewed': {'step', 'step_name'},
  'signup_completed': {},
  'paywall_viewed': {'source'},
  'purchase_started': {'product_id'},
  'purchase_cancelled': {'product_id'},
  'analytics_consent_granted': {},
};

List<AnalyticsEvent?> _everyConstructor() => [
  AnalyticsEvent.appOpened(),
  AnalyticsEvent.screenViewed('discover'),
  AnalyticsEvent.onboardingStepViewed(step: 3, stepName: 'photos'),
  AnalyticsEvent.signupCompleted(),
  AnalyticsEvent.paywallViewed('premium'),
  AnalyticsEvent.purchaseStarted('com.mazl.plus.monthly'),
  AnalyticsEvent.purchaseCancelled('com.mazl.plus.monthly'),
  AnalyticsEvent.analyticsConsentGranted(),
];

void main() {
  test('every constructor sends exactly the names and keys of the plan', () {
    final events = _everyConstructor();
    expect(events, everyElement(isNotNull));
    expect({for (final e in events) e!.name}, _plan.keys.toSet());
    for (final event in events) {
      expect(
        event!.properties.keys.toSet(),
        _plan[event.name],
        reason: event.name,
      );
    }
  });

  test('values are sent as the plan types them', () {
    expect(AnalyticsEvent.screenViewed('discover')!.properties, {
      'screen': 'discover',
    });
    expect(
      AnalyticsEvent.onboardingStepViewed(
        step: 3,
        stepName: 'photos',
      )!.properties,
      {'step': 3, 'step_name': 'photos'},
    );
    expect(AnalyticsEvent.purchaseStarted('a.b_c1')!.properties, {
      'product_id': 'a.b_c1',
    });
  });

  group('forbidden values make the event disappear', () {
    final badIdentifiers = [
      '',
      'jeanne@example.com',
      '/chat/42',
      'chat 42',
      'Discover',
      '1discover',
      'a' * 41,
      'écran',
      'a-b',
    ];
    for (final bad in badIdentifiers) {
      test('screen "$bad"', () {
        expect(AnalyticsEvent.screenViewed(bad), isNull);
        expect(AnalyticsEvent.paywallViewed(bad), isNull);
        expect(
          AnalyticsEvent.onboardingStepViewed(step: 1, stepName: bad),
          isNull,
        );
      });
    }

    test('the longest identifier is still fine', () {
      expect(AnalyticsEvent.screenViewed('a' * 40), isNotNull);
    });

    for (final bad in ['', 'Com.mazl', 'a b', 'a@b.c', '.a', 'a' * 81, 'a/b']) {
      test('product "$bad"', () {
        expect(AnalyticsEvent.purchaseStarted(bad), isNull);
        expect(AnalyticsEvent.purchaseCancelled(bad), isNull);
      });
    }

    test('step out of 0..30', () {
      expect(
        AnalyticsEvent.onboardingStepViewed(step: -1, stepName: 'a'),
        isNull,
      );
      expect(
        AnalyticsEvent.onboardingStepViewed(step: 31, stepName: 'a'),
        isNull,
      );
      expect(
        AnalyticsEvent.onboardingStepViewed(step: 0, stepName: 'a'),
        isNotNull,
      );
      expect(
        AnalyticsEvent.onboardingStepViewed(step: 30, stepName: 'a'),
        isNotNull,
      );
    });
  });
}
