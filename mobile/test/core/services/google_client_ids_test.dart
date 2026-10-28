import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/google/google_client_ids.dart';

void main() {
  test('Android asks Google for an idToken addressed to the web client', () {
    final ids = googleClientIdsFor(TargetPlatform.android);

    expect(ids.serverClientId, googleWebClientId);
    expect(ids.clientId, isNull);
  });

  test('iOS keeps signing in with its own client', () {
    final ids = googleClientIdsFor(TargetPlatform.iOS);

    expect(ids.clientId, googleIosClientId);
    expect(ids.serverClientId, isNull);
  });
}
