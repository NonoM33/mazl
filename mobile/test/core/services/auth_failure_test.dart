import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mazl/core/services/auth_service.dart';

void main() {
  group('a refused call becomes a type, never a sentence', () {
    test('wrong e-mail or password', () {
      for (final status in [400, 401, 403, 404]) {
        expect(
          authFailureForStatus(status, AuthCall.emailSignIn),
          AuthFailure.invalidCredentials,
          reason: '$status',
        );
      }
    });

    test('sign-up: address already used, invalid data', () {
      expect(
        authFailureForStatus(409, AuthCall.register),
        AuthFailure.emailTaken,
      );
      expect(
        authFailureForStatus(422, AuthCall.register),
        AuthFailure.invalidInput,
      );
      expect(
        authFailureForStatus(400, AuthCall.register),
        AuthFailure.invalidInput,
      );
    });

    test('too many attempts and server outages, whatever the call', () {
      for (final call in AuthCall.values) {
        expect(authFailureForStatus(429, call), AuthFailure.rateLimited);
        expect(authFailureForStatus(503, call), AuthFailure.server);
      }
    });

    test('an unexpected status stays unknown', () {
      expect(
        authFailureForStatus(418, AuthCall.socialSignIn),
        AuthFailure.unknown,
      );
      expect(
        authFailureForStatus(401, AuthCall.deleteAccount),
        AuthFailure.unknown,
      );
    });

    test('a dropped connection is « network », anything else « unknown »', () {
      expect(authFailureOf(const SocketException('down')), AuthFailure.network);
      expect(authFailureOf(http.ClientException('down')), AuthFailure.network);
      expect(authFailureOf(TimeoutException('slow')), AuthFailure.network);
      expect(authFailureOf(StateError('boom')), AuthFailure.unknown);
    });

    test('AuthResult.failure carries the type and no server text', () {
      final result = AuthResult.failure(AuthFailure.cancelled);
      expect(result.success, isFalse);
      expect(result.failure, AuthFailure.cancelled);
      expect(result.errorMessage, 'cancelled');
    });
  });
}
