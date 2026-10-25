import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mazl/core/services/auth_service.dart';

void main() {
  group('a refused call becomes a type, never a sentence', () {
    test('too many attempts and server outages', () {
      expect(authFailureForStatus(429), AuthFailure.rateLimited);
      expect(authFailureForStatus(503), AuthFailure.server);
    });

    test('an unexpected status stays unknown', () {
      expect(authFailureForStatus(418), AuthFailure.unknown);
      expect(authFailureForStatus(401), AuthFailure.unknown);
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
