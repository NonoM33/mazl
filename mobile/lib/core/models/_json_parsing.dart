/// Helper functions for safe JSON parsing (handles strings and numbers).
///
/// Extracted verbatim from `api_service.dart` so the data-model classes can
/// live in their own files while keeping identical parsing behaviour.
int? parseIntSafe(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? parseDoubleSafe(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
