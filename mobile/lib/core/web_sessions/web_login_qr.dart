/// Prefix of the QR code shown by app.mazl.app on its login page.
const webLoginQrPrefix = 'mazl-web:';

final _code = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// Extracts the pairing code from the text of a scanned QR code.
///
/// Only `mazl-web:` followed by a 43-character base64url code is accepted:
/// a URL or any other QR code returns null, so the app never sends a
/// stranger's payload to the server.
String? parseWebLoginQr(String raw) {
  if (!raw.startsWith(webLoginQrPrefix)) return null;
  final code = raw.substring(webLoginQrPrefix.length);
  return _code.hasMatch(code) ? code : null;
}
