import 'consent_fields.dart';

/// Consent to the measurement of the use of the app (purpose `analytics`), as
/// returned by `GET /api/privacy/consents` (docs/analytics/plan-de-marquage.md).
class AnalyticsConsent {
  const AnalyticsConsent({
    required this.granted,
    required this.version,
    required this.decidedAt,
    required this.currentVersion,
    required this.text,
  });

  factory AnalyticsConsent.fromJson(Map<String, dynamic> json) {
    final granted = json['granted'];
    if (granted != null && granted is! bool) {
      throw const FormatException('granted');
    }
    return AnalyticsConsent(
      granted: granted as bool?,
      version: optionalConsentString(json, 'version'),
      decidedAt: optionalConsentDate(json, 'decided_at'),
      currentVersion: requiredConsentString(json, 'current_version'),
      text: requiredConsentString(json, 'text'),
    );
  }

  /// null when the member was never asked.
  final bool? granted;
  final String? version;
  final DateTime? decidedAt;
  final String currentVersion;

  /// The exact wording the member agrees to, as sent by the server.
  final String text;

  /// The server only honours a consent given to the current wording.
  bool get isValid => granted == true && version == currentVersion;
}
