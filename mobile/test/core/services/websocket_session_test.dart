import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/push_notification_service.dart';
import 'package:mazl/core/services/session_end.dart';
import 'package:mazl/core/services/websocket_service.dart';
import 'package:web_socket_channel/io.dart';

/// V1-CONTRAT §5: the WebSocket closed with 4001 or 4003 ends the session and
/// does NOT reconnect (it used to retry forever); any other close reconnects.
/// The server here is a real socket on the loopback, closing with real codes.

class _FakePush implements PushNotificationService {
  int logouts = 0;

  @override
  Future<void> logoutUser() async => logouts++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  late int closeWith;
  late _FakePush push;
  late AuthService auth;
  final socket = WebSocketService();

  setUpAll(() {
    push = _FakePush();
    auth = AuthService.forTesting(push: push);
    AuthService.instanceForTesting = auth;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    push.logouts = 0;
    await auth.debugSignIn(
      AuthUser(
        id: '7',
        email: 'jeanne@example.com',
        provider: AuthProvider.apple,
        jwtToken: 'tok-1',
      ),
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      await ws.close(closeWith, 'test');
    });
    WebSocketService.channelFactory = (_) => IOWebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:${server.port}/ws'),
    );
  });

  tearDown(() async {
    socket.disconnect();
    await server.close(force: true);
  });

  Future<void> connectAndWaitForClose() async {
    await socket.connect();
    // The server closes right after the upgrade.
    for (var i = 0; i < 50 && socket.isConnected; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  test('closed with 4001: signs out, expired, no reconnection', () async {
    closeWith = webSocketTokenExpiredClose;
    await connectAndWaitForClose();
    expect(auth.isAuthenticated, isFalse);
    expect(auth.sessionEndReason, SessionEndReason.expired);
    expect(push.logouts, 1);
    expect(socket.hasPendingReconnect, isFalse);
  });

  test('closed with 4003: signs out, account disabled, no reconnection', () async {
    closeWith = webSocketAccountDisabledClose;
    await connectAndWaitForClose();
    expect(auth.isAuthenticated, isFalse);
    expect(auth.sessionEndReason, SessionEndReason.accountDisabled);
    expect(socket.hasPendingReconnect, isFalse);
  });

  for (final code in [1000, 4000, 4002]) {
    test('closed with $code: the member stays, the socket retries', () async {
      closeWith = code;
      await connectAndWaitForClose();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.sessionEndReason, isNull);
      expect(push.logouts, 0);
      expect(socket.hasPendingReconnect, isTrue);
    });
  }
}
