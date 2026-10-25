import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/push_notification_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// V1-CONTRAT §4: `POST /api/auth/apple` also receives `authorizationCode`, so
/// the server can get the refresh token Apple wants revoked when the account
/// is deleted (App Store rule 5.1.1(v)).

class _FakePush implements PushNotificationService {
  @override
  Future<void> loginUser(int userId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<Map<String, dynamic>> bodySentFor(
    AuthorizationCredentialAppleID credential,
  ) async {
    Map<String, dynamic>? sent;
    final service = AuthService.forTesting(push: _FakePush());
    AuthService.instanceForTesting = service;
    await http.runWithClient(() async {
      await service.signInWithAppleCredential(credential);
    }, () => MockClient((request) async {
      if (request.url.path == '/api/auth/apple') {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'token': 'jwt-1',
            'user': {'id': 7, 'email': 'jeanne@example.com', 'name': 'Jeanne'},
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'success': true}), 200);
    }));
    return sent!;
  }

  test('the authorization code travels with the identity token', () async {
    final body = await bodySentFor(
      AuthorizationCredentialAppleID(
        userIdentifier: 'apple-user',
        givenName: 'Jeanne',
        familyName: 'Exemple',
        authorizationCode: 'c-abc123',
        email: 'jeanne@example.com',
        identityToken: 'id-token',
        state: null,
      ),
    );
    expect(body['authorizationCode'], 'c-abc123');
    expect(body['identityToken'], 'id-token');
    expect(body['fullName'], 'Jeanne Exemple');
    expect(body['email'], 'jeanne@example.com');
  });
}
