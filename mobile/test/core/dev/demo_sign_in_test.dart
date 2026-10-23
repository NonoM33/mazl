import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/dev_login.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storageCalls = <String>[];

  setUp(() {
    storageCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async {
          storageCalls.add(call.method);
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
    if (DevSession.isActive) await AuthService().signOut();
    DevSession.stop();
  });

  test('la connexion fictive est disponible dans les tests (mode debug)', () {
    expect(kDevLoginAvailable, isTrue);
  });

  test(
    'signInAsDemo : utilisateur synthétique, session active, sans JWT',
    () async {
      final auth = AuthService();
      var notified = 0;
      auth.addListener(() => notified++);

      final result = await auth.signInAsDemo();

      expect(result.success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.id, '0');
      expect(auth.currentUser?.email, 'demo@example.com');
      expect(auth.currentUser?.displayName, 'Léa (démo)');
      expect(auth.currentUser?.jwtToken, isNull);
      expect(DevSession.isActive, isTrue);
      expect(notified, greaterThan(0));
    },
  );

  test('signInAsDemo n\'écrit RIEN en stockage sécurisé', () async {
    await AuthService().signInAsDemo();

    expect(storageCalls, isEmpty);
  });

  test(
    'signOut met fin à la session fictive sans toucher RevenueCat ni push',
    () async {
      final auth = AuthService();
      await auth.signInAsDemo();

      await auth.signOut();

      expect(auth.isAuthenticated, isFalse);
      expect(DevSession.isActive, isFalse);
      expect(storageCalls, isEmpty);
    },
  );

  test('au démarrage de la navigation, le mode couple reste éteint', () async {
    SharedPreferences.setMockInitialValues({});
    await http.runWithClient(
      () async {
        await AuthService().signInAsDemo();
        final couple = CoupleService();
        await couple.initialize();
        expect(couple.isCoupleModeEnabled, isFalse);
      },
      () => DemoHttpClient(
        MockClient((r) async => fail('réseau réel joint : ${r.url}')),
        latency: Duration.zero,
      ),
    );
  });
}
