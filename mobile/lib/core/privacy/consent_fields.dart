/// Reading of the fields shared by every purpose of `GET /api/privacy/consents`.
String requiredConsentString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('missing $key');
  return value;
}

String? optionalConsentString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('invalid $key');
  return value;
}

DateTime? optionalConsentDate(Map<String, dynamic> json, String key) {
  final raw = optionalConsentString(json, key);
  return raw == null ? null : DateTime.parse(raw).toLocal();
}
