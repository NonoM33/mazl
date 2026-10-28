import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/apple/apple_web_sign_in.dart';

void main() {
  const servicesId = 'app.mazl.signin';

  test('Android signs in with Apple through its web page', () {
    final options = appleWebAuthenticationOptions(
      platform: TargetPlatform.android,
      servicesId: servicesId,
    );

    expect(options?.clientId, servicesId);
    expect(
      options?.redirectUri.toString(),
      'https://api.mazl.app/api/auth/apple/android-callback',
    );
  });

  test('iOS keeps the native sheet', () {
    expect(
      appleWebAuthenticationOptions(
        platform: TargetPlatform.iOS,
        servicesId: servicesId,
      ),
      isNull,
    );
  });

  test('no Services ID: no Apple sign-in on Android', () {
    expect(
      appleWebAuthenticationOptions(
        platform: TargetPlatform.android,
        servicesId: '',
      ),
      isNull,
    );
  });

  test('a web answer without our state is refused', () {
    expect(appleWebAnswerIsOurs(sent: 'abc', received: 'abc'), isTrue);
    expect(appleWebAnswerIsOurs(sent: 'abc', received: 'forged'), isFalse);
    expect(appleWebAnswerIsOurs(sent: 'abc', received: null), isFalse);
  });

  test('the native sheet has no state to compare', () {
    expect(appleWebAnswerIsOurs(sent: null, received: null), isTrue);
  });
}
