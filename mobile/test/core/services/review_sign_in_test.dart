import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/push_notification_service.dart';

/// docs/launch/REVIEW-LOGIN-CONTRAT.md: `POST /api/auth/review` with
/// `{ username, password }`. 200 opens the session like Sign in with Apple;
/// 401 is a wrong identifier OR password (never which); 429 is too many
/// attempts. The password never reaches a log.

const _password = 'exemple-motdepasse';

class _FakePush implements PushNotificationService {
  final List<int> logins = [];

  @override
  Future<void> loginUser(int userId) async => logins.add(userId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

http.Response _json(int status, Map<String, Object?> body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _granted = _json(200, {
  'success': true,
  'token': 'jwt-revue',
  'user': {
    'id': 42,
    'email': 'app-review@mazl.app',
    'name': 'Jonathan',
    'provider': 'review',
    'isNew': false,
    'hasProfile': true,
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePush push;
  late AuthService service;
  late List<http.Request> sent;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    push = _FakePush();
    service = AuthService.forTesting(push: push);
    AuthService.instanceForTesting = service;
    sent = [];
  });

  Future<AuthResult> signIn(
    http.Response Function(http.Request request) answer, {
    String username = 'revue-apple',
  }) {
    return http.runWithClient(
      () => service.signInWithReviewCredentials(username, _password),
      () => MockClient((request) async {
        if (request.url.path == '/api/auth/review') {
          sent.add(request);
          return answer(request);
        }
        // The profile completeness read after the sign-in.
        return _json(200, {'success': true, 'data': <String>[]});
      }),
    );
  }

  test('posts the username and the password to /api/auth/review', () async {
    await signIn((_) => _granted);
    expect(sent, hasLength(1));
    expect(sent.single.method, 'POST');
    expect(sent.single.headers['Content-Type'], contains('application/json'));
    expect(jsonDecode(sent.single.body), {
      'username': 'revue-apple',
      'password': _password,
    });
  });

  test(
    '200 opens the session like Apple: user, token, push, storage',
    () async {
      final result = await signIn((_) => _granted);

      expect(result.success, isTrue);
      final user = result.user!;
      expect(user.id, '42');
      expect(user.email, 'app-review@mazl.app');
      expect(user.displayName, 'Jonathan');
      expect(user.provider, AuthProvider.review);
      expect(user.jwtToken, 'jwt-revue');
      expect(service.currentUser, same(user));
      expect(service.isAuthenticated, isTrue);
      expect(push.logins, [42]);

      final stored = await const FlutterSecureStorage().read(
        key: 'current_user',
      );
      final restored = AuthUser.fromJson(
        jsonDecode(stored!) as Map<String, dynamic>,
      );
      expect(restored.provider, AuthProvider.review);
      expect(restored.jwtToken, 'jwt-revue');
    },
  );

  test('the session never keeps the password', () async {
    await signIn((_) => _granted);
    final stored = await const FlutterSecureStorage().read(key: 'current_user');
    expect(stored, isNot(contains(_password)));
  });

  test('401 is « wrong credentials », not a generic failure', () async {
    final result = await signIn(
      (_) => _json(401, {'success': false, 'error': 'invalid_credentials'}),
    );
    expect(result.success, isFalse);
    expect(result.failure, AuthFailure.invalidCredentials);
    expect(service.isAuthenticated, isFalse);
    expect(push.logins, isEmpty);
  });

  test('429 is « too many attempts »', () async {
    final result = await signIn((_) => _json(429, {'success': false}));
    expect(result.failure, AuthFailure.rateLimited);
    expect(service.isAuthenticated, isFalse);
  });

  test('a server error is a server failure', () async {
    final result = await signIn((_) => _json(503, {'success': false}));
    expect(result.failure, AuthFailure.server);
  });

  test('403 and 404 stay generic: the screen says nothing more', () async {
    for (final status in [403, 404]) {
      final result = await signIn((_) => _json(status, {'success': false}));
      expect(result.failure, AuthFailure.unknown, reason: '$status');
      expect(service.isAuthenticated, isFalse);
    }
  });

  test('200 without success: true opens nothing', () async {
    final result = await signIn((_) => _json(200, {'success': false}));
    expect(result.success, isFalse);
    expect(service.isAuthenticated, isFalse);
  });

  test('a network error is the existing network failure', () async {
    final result = await http.runWithClient(
      () => service.signInWithReviewCredentials('revue-apple', _password),
      () => MockClient((_) async => throw const SocketException('down')),
    );
    expect(result.failure, AuthFailure.network);
    expect(service.isAuthenticated, isFalse);
  });

  group('the password never reaches a log', () {
    late List<String> logged;
    late DebugPrintCallback previous;

    setUp(() {
      logged = [];
      previous = debugPrint;
      debugPrint = (message, {wrapWidth}) => logged.add(message ?? '');
    });
    tearDown(() => debugPrint = previous);

    test('on success', () async {
      await signIn((_) => _granted);
      expect(logged, isNotEmpty);
      expect(logged.join('\n'), isNot(contains(_password)));
    });

    test('on every refusal', () async {
      for (final status in [400, 401, 403, 404, 429, 500]) {
        await signIn(
          (request) => _json(status, {
            'success': false,
            'error': 'echo ${jsonDecode(request.body)['password']}',
          }),
        );
      }
      expect(logged.join('\n'), isNot(contains(_password)));
    });

    test('on a network error that quotes the request', () async {
      await http.runWithClient(
        () => service.signInWithReviewCredentials('revue-apple', _password),
        () => MockClient(
          (request) async =>
              throw http.ClientException('failed: ${request.body}'),
        ),
      );
      expect(logged.join('\n'), isNot(contains(_password)));
    });
  });
}
