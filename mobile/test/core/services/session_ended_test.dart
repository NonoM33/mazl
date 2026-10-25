import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/chat/chat_api.dart';
import 'package:mazl/core/models/verification.dart';
import 'package:mazl/core/privacy/privacy_consent_api.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/http_verification_api.dart';
import 'package:mazl/core/services/push_notification_service.dart';
import 'package:mazl/core/services/session_end.dart';
import 'package:mazl/core/services/store/subscription_api.dart';
import 'package:mazl/core/web_sessions/web_sessions_api.dart';

/// V1-CONTRAT §5: a 401, or a 403 `account_disabled`, on an authenticated
/// request signs the member out (same path as the settings' « Se
/// déconnecter »: OneSignal logout, stored session erased) — once, however
/// many requests fail at the same time.

class _FakePush implements PushNotificationService {
  int logouts = 0;

  @override
  Future<void> logoutUser() async => logouts++;

  @override
  Future<void> loginUser(int userId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

http.Response _refuse(int status, [String error = 'Unauthorized']) =>
    http.Response(
      jsonEncode({'success': false, 'error': error}),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

AuthUser _member(String token) => AuthUser(
  id: '7',
  email: 'jeanne@example.com',
  provider: AuthProvider.apple,
  jwtToken: token,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePush push;
  late AuthService auth;

  // ApiService reads the AuthService singleton once, when it is first used:
  // the test instance is in place before any test touches it.
  setUpAll(() {
    push = _FakePush();
    auth = AuthService.forTesting(push: push);
    AuthService.instanceForTesting = auth;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    push.logouts = 0;
    await auth.debugSignIn(_member('tok-1'));
  });

  Future<void> settle() => pumpEventQueue();

  group('a request made with the member\'s token', () {
    test('answered 401 signs the member out', () async {
      await http.runWithClient(() async {
        await ApiService().getBlockedUsers();
        await settle();
      }, () => MockClient((_) async => _refuse(401)));

      expect(auth.isAuthenticated, isFalse);
      expect(auth.sessionEndReason, SessionEndReason.expired);
      expect(push.logouts, 1);
      expect(await const FlutterSecureStorage().read(key: 'current_user'), isNull);
    });

    test('answered 403 account_disabled signs the member out', () async {
      await http.runWithClient(() async {
        await ApiService().reportUser(userId: 3, category: 'spam');
        await settle();
      }, () => MockClient((_) async => _refuse(403, 'account_disabled')));

      expect(auth.isAuthenticated, isFalse);
      expect(auth.sessionEndReason, SessionEndReason.accountDisabled);
    });

    test('answered 403 for any other reason does not', () async {
      await http.runWithClient(() async {
        await ApiService().getBlockedUsers();
        await settle();
      }, () => MockClient((_) async => _refuse(403, 'not_matched')));

      expect(auth.isAuthenticated, isTrue);
      expect(auth.sessionEndReason, isNull);
      expect(push.logouts, 0);
    });

    test('several failing at once sign the member out ONCE', () async {
      await http.runWithClient(() async {
        await Future.wait([
          ApiService().getBlockedUsers(),
          ApiService().getConversations(),
          ApiService().getBlockedUsers(),
          ApiService().reportUser(userId: 3, category: 'spam'),
        ]);
        await settle();
      }, () => MockClient((_) async => _refuse(401)));

      expect(auth.isAuthenticated, isFalse);
      expect(push.logouts, 1);
    });

    test('a late 401 for a previous session leaves the new one alone', () async {
      final answer = Completer<http.Response>();
      await http.runWithClient(() async {
        final pending = ApiService().getBlockedUsers(); // sent with tok-1
        await settle();
        await auth.debugSignIn(_member('tok-2')); // another sign-in meanwhile
        answer.complete(_refuse(401));
        await pending;
        await settle();
      }, () => MockClient((_) => answer.future));

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.jwtToken, 'tok-2');
      expect(push.logouts, 0);
    });

    test('a new sign-in forgets that the last session ended', () async {
      await http.runWithClient(() async {
        await ApiService().getBlockedUsers();
        await settle();
      }, () => MockClient((_) async => _refuse(401)));
      expect(auth.sessionEndReason, isNotNull);

      await auth.debugSignIn(_member('tok-3'));
      expect(auth.sessionEndReason, isNull);
    });

    test('a sign-out chosen by the member is not « a session that ended »', () async {
      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.sessionEndReason, isNull);
      expect(push.logouts, 1);
    });
  });

  group('a 401 without the member\'s token', () {
    test('(a refused sign-in, a signed-out app) ends nothing', () async {
      await auth.signOut();
      push.logouts = 0;
      await http.runWithClient(() async {
        await ApiService().getBlockedUsers();
        await settle();
      }, () => MockClient((_) async => _refuse(401)));
      expect(auth.sessionEndReason, isNull);
      expect(push.logouts, 0);
    });
  });

  group('every client of the API watches the session', () {
    final clients = <String, Future<void> Function(MockClient)>{
      'chat': (server) async {
        final api = HttpChatApi(
          baseUrl: 'https://api.example.com',
          token: () => 'tok-1',
          clientFactory: () => server,
        );
        try {
          await api.getMessages(1);
        } on ChatApiException {
          // expected: the 401 is also an error of the call
        }
      },
      'privacy consent': (server) async {
        await HttpPrivacyConsentApi(
          client: server,
          baseUrl: 'https://api.example.com',
          tokenProvider: () => 'tok-1',
        ).religiousData();
      },
      'web sessions': (server) async {
        await HttpWebSessionsApi(
          client: server,
          baseUrl: 'https://api.example.com',
          tokenProvider: () => 'tok-1',
        ).listSessions();
      },
      'verification': (server) async {
        await HttpVerificationApi(
          client: server,
          baseUrl: 'https://api.example.com',
          tokenProvider: () => 'tok-1',
        ).startFaceSession(FacePurpose.photo);
      },
    };

    for (final entry in clients.entries) {
      test('${entry.key}: 401 signs the member out', () async {
        await entry.value(MockClient((_) async => _refuse(401)));
        await settle();
        expect(auth.isAuthenticated, isFalse, reason: entry.key);
        expect(push.logouts, 1, reason: entry.key);
      });
    }

    test('subscription: 401 signs the member out', () async {
      await http.runWithClient(() async {
        await HttpSubscriptionApi(
          tokenProvider: () => 'tok-1',
          baseUrl: 'https://api.example.com',
        ).get('/api/subscription/status');
        await settle();
      }, () => MockClient((_) async => _refuse(401)));
      expect(auth.isAuthenticated, isFalse);
      expect(push.logouts, 1);
    });
  });
}
