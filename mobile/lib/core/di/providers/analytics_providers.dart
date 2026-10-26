import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../analytics/analytics.dart';
import '../../analytics/analytics_transport.dart';
import '../../services/api_service.dart';
import 'privacy_providers.dart';

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

/// The usage measurement, for the life of the app. `AnalyticsHost` tells it
/// when the member signs in and out and gives it the consent read from the
/// server; [decideAnalyticsConsent] tells it the member's answer.
final analyticsProvider = Provider<Analytics>((ref) {
  final analytics = Analytics(transport: ref.watch(analyticsTransportProvider));
  ref.onDispose(analytics.dispose);
  return analytics;
});

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
