/// An event of the usage measurement sent by the app. Only the events of the
/// plan exist (docs/analytics/plan-de-marquage.md §2) and each one is built by
/// a named factory that checks the formats of the plan: a value outside them
/// yields `null`, so the event is dropped, never an exception in the UI.
///
/// The swipes, matches, messages, validated purchases and verifications are
/// emitted by the server, never here.
class AnalyticsEvent {
  const AnalyticsEvent._(this.name, [this.properties = const {}]);

  final String name;

  /// Only the keys of the plan, only values of the plan's formats.
  final Map<String, Object> properties;

  static final _identifier = RegExp(r'^[a-z][a-zA-Z0-9_]{0,39}$');
  static final _productId = RegExp(r'^[a-z0-9][a-z0-9._]{0,79}$');

  static const _maxStep = 30;

  /// Cold start of the app.
  static AnalyticsEvent? appOpened() => const AnalyticsEvent._('app_opened');

  /// The NAME of a route (`discover`), never a path: a path may carry an id.
  static AnalyticsEvent? screenViewed(String screen) => _isIdentifier(screen)
      ? AnalyticsEvent._('screen_viewed', {'screen': screen})
      : null;

  /// One step of the profile creation.
  static AnalyticsEvent? onboardingStepViewed({
    required int step,
    required String stepName,
  }) => step >= 0 && step <= _maxStep && _isIdentifier(stepName)
      ? AnalyticsEvent._('onboarding_step_viewed', {
          'step': step,
          'step_name': stepName,
        })
      : null;

  /// Profile finished, first arrival in the app.
  static AnalyticsEvent? signupCompleted() =>
      const AnalyticsEvent._('signup_completed');

  /// The offer screen opened, from [source] (an identifier of the screen).
  static AnalyticsEvent? paywallViewed(String source) => _isIdentifier(source)
      ? AnalyticsEvent._('paywall_viewed', {'source': source})
      : null;

  static AnalyticsEvent? purchaseStarted(String productId) =>
      _product('purchase_started', productId);

  static AnalyticsEvent? purchaseCancelled(String productId) =>
      _product('purchase_cancelled', productId);

  /// First event sent, right after the member agreed.
  static AnalyticsEvent? analyticsConsentGranted() =>
      const AnalyticsEvent._('analytics_consent_granted');

  static bool _isIdentifier(String value) => _identifier.hasMatch(value);

  static AnalyticsEvent? _product(String name, String productId) =>
      _productId.hasMatch(productId)
      ? AnalyticsEvent._(name, {'product_id': productId})
      : null;
}
