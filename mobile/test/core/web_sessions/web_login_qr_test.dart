import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/web_sessions/web_login_qr.dart';

// 43 characters, as the server issues (32 random bytes in base64url).
const _code = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNO-_';

void main() {
  test('the sample code really has 43 characters', () {
    expect(_code.length, 43);
  });

  test('accepts mazl-web: followed by a 43-character base64url code', () {
    expect(parseWebLoginQr('mazl-web:$_code'), _code);
  });

  test('refuses a URL, another scheme or plain text', () {
    expect(parseWebLoginQr('https://app.mazl.app/?c=$_code'), isNull);
    expect(parseWebLoginQr('https://example.com'), isNull);
    expect(parseWebLoginQr('mazl:$_code'), isNull);
    expect(parseWebLoginQr(_code), isNull);
    expect(parseWebLoginQr(''), isNull);
  });

  test('refuses a code of the wrong length', () {
    expect(parseWebLoginQr('mazl-web:'), isNull);
    expect(parseWebLoginQr('mazl-web:${_code.substring(1)}'), isNull);
    expect(parseWebLoginQr('mazl-web:${_code}A'), isNull);
  });

  test('refuses characters outside base64url and trailing content', () {
    expect(parseWebLoginQr('mazl-web:${_code.substring(1)}+'), isNull);
    expect(parseWebLoginQr('mazl-web:${_code.substring(1)}='), isNull);
    expect(parseWebLoginQr('mazl-web:$_code\n'), isNull);
    expect(parseWebLoginQr('mazl-web:$_code '), isNull);
    expect(parseWebLoginQr('MAZL-WEB:$_code'), isNull);
    expect(parseWebLoginQr(' mazl-web:$_code'), isNull);
  });
}
