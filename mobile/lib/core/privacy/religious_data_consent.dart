/// Consent to the processing of religious-practice data (GDPR article 9),
/// as returned by `GET /api/privacy/consents` (docs/web/adr/W06-rgpd-article9.md).
class ReligiousDataConsent {
  const ReligiousDataConsent({
    required this.granted,
    required this.version,
    required this.decidedAt,
    required this.currentVersion,
    required this.text,
  });

  factory ReligiousDataConsent.fromJson(Map<String, dynamic> json) {
    final granted = json['granted'];
    if (granted != null && granted is! bool) {
      throw const FormatException('granted');
    }
    return ReligiousDataConsent(
      granted: granted as bool?,
      version: _optionalString(json, 'version'),
      decidedAt: _optionalDate(json, 'decided_at'),
      currentVersion: _requiredString(json, 'current_version'),
      text: _requiredString(json, 'text'),
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

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('missing $key');
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('invalid $key');
  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final raw = _optionalString(json, key);
  return raw == null ? null : DateTime.parse(raw).toLocal();
}
