import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../analytics/analytics.dart';
import '../../analytics/analytics_transport.dart';
import '../../services/api_service.dart';
import 'privacy_providers.dart';
import 'service_providers.dart';

Future<String>? _appVersion;

Future<String> _readAppVersion() => _appVersion ??= PackageInfo.fromPlatform()
    .then((info) => '${info.version}+${info.buildNumber}')
    .catchError((Object _) => '0.0.0');

/// Where the events go. Overridden by a fake in tests.
final analyticsTransportProvider = Provider<AnalyticsTransport>(
  (ref) => HttpAnalyticsTransport(
    platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    appVersion: _readAppVersion,
  ),
);

/// The usage measurement, for the life of the app. It follows the member's
/// authentication; the consent is pushed to it by `AnalyticsHost` and by
/// [decideAnalyticsConsent].
final analyticsProvider = Provider<Analytics>(
  (ref) => followAuthentication(
    ref,
    Analytics(transport: ref.watch(analyticsTransportProvider)),
  ),
);

/// Makes [analytics] follow the member's sign-in and sign-out, and stop with
/// [ref]. Public so that tests build the measurement with their own clock and
/// timers and still run this wiring.
Analytics followAuthentication(Ref<Analytics> ref, Analytics analytics) {
  ref.listen<bool>(isAuthenticatedProvider, (_, signedIn) {
    signedIn ? analytics.signedIn() : analytics.signedOut();
  }, fireImmediately: true);
  ref.onDispose(analytics.dispose);
  return analytics;
}

/// Records the member's answer on the server and, once it is accepted, tells
/// the measurement at once (a withdrawal empties the queue before anything else
/// can leave).
Future<ApiResponse<void>> decideAnalyticsConsent(
  WidgetRef ref, {
  required bool granted,
  required String version,
}) async {
  final response = await ref
      .read(privacyConsentApiProvider)
      .decideAnalytics(granted: granted, version: version);
  if (response.success) {
    ref.read(analyticsProvider).consentDecided(granted: granted);
    ref.invalidate(analyticsConsentProvider);
  }
  return response;
}
