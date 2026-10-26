import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/push_device_server.dart';
import 'package:mazl/core/services/push_notification_service.dart';

const _token =
    'ab12cd34ef56ab12cd34ef56ab12cd34ef56ab12cd34ef56ab12cd34ef56ab12';

class _FakePush implements PushNotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

http.Response _ok() => http.Response(
  jsonEncode({'success': true}),
  200,
  headers: {'content-type': 'application/json'},
);

/// Rejoue [call] contre un faux serveur qui note ce qu'il reçoit.
Future<List<http.Request>> _serve(
  Future<void> Function() call, {
  int status = 200,
}) async {
  final seen = <http.Request>[];
  await http.runWithClient(
    call,
    () => MockClient((request) async {
      seen.add(request);
      return status == 200 ? _ok() : http.Response('{}', status);
    }),
  );
  return seen;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService auth;

  setUpAll(() {
    auth = AuthService.forTesting(push: _FakePush());
    AuthService.instanceForTesting = auth;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await auth.debugSignIn(
      AuthUser(
        id: '7',
        email: 'jeanne@example.com',
        provider: AuthProvider.apple,
        jwtToken: 'member-token',
      ),
    );
  });

  test(
    'register : PUT /api/push/devices, jeton du membre, corps exact',
    () async {
      final seen = await _serve(
        () => ApiPushDeviceServer().register(
          token: _token,
          environment: 'production',
        ),
      );

      expect(seen, hasLength(1));
      expect(seen.single.method, 'PUT');
      expect(seen.single.url.path, '/api/push/devices');
      expect(seen.single.headers['Authorization'], 'Bearer member-token');
      expect(jsonDecode(seen.single.body), {
        'token': _token,
        'environment': 'production',
      });
    },
  );

  test('unregister : DELETE /api/push/devices avec le jeton', () async {
    final seen = await _serve(
      () => ApiPushDeviceServer().unregister(token: _token),
    );

    expect(seen.single.method, 'DELETE');
    expect(seen.single.url.path, '/api/push/devices');
    expect(seen.single.headers['Authorization'], 'Bearer member-token');
    expect(jsonDecode(seen.single.body), {'token': _token});
  });

  test('un refus du serveur est une erreur', () async {
    await expectLater(
      _serve(
        () => ApiPushDeviceServer().register(
          token: _token,
          environment: 'sandbox',
        ),
        status: 500,
      ),
      throwsA(isA<PushDeviceRequestFailed>()),
    );
  });
}
