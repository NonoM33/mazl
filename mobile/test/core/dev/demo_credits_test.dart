import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/demo_routes.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/core/services/store/credits_service.dart';

import '../../support/credits_fakes.dart';
import '../../support/store_fakes.dart';

/// Rejoue les VRAIES méthodes d'`ApiService` contre les données fictives.
Future<T> _demo<T>(Future<T> Function(ApiService api) body) =>
    http.runWithClient(
      () => body(ApiService()),
      () => DemoHttpClient(
        MockClient((request) async => fail('Réseau réel : ${request.url}')),
        latency: Duration.zero,
      ),
    );

Map<String, dynamic> _get(String path) {
  final reply = DemoRoutes.respond(DemoRequest('GET', path, const {}, const {}));
  expect(reply.status, 200);
  return reply.body as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(DevSession.start);
  tearDown(DevSession.stop);

  test('GET /api/credits : la forme du serveur, des valeurs plausibles', () {
    final body = _get('/api/credits');

    expect(body['success'], isTrue);
    final balance = CreditBalance.fromJson(body['credits']);
    expect(balance.superLike.dailyAllowance, 1);
    expect(balance.superLike.available, 1);
    expect(balance.boost.dailyAllowance, 0);
    expect(balance.boost.available, 1);
    expect(balance.resetsAt.isAfter(DateTime.now().toUtc()), isTrue);
  });

  test('un super like dépense un crédit, le suivant est refusé (402)', () async {
    final credits = installTestCredits();

    final first = await _demo(
      (a) => a.sendSwipe(targetUserId: 202, action: 'super_like'),
    );
    expect(first.success, isTrue);
    expect(CreditBalance.fromJson(first.data!['credits']).superLike.available, 0);
    expect(credits.available(CreditKind.superLike), 0);

    final second = await _demo(
      (a) => a.sendSwipe(targetUserId: 203, action: 'super_like'),
    );
    expect(second.success, isFalse);
    expect(second.isCreditsExhausted, isTrue);
    expect(second.errorKind, ApiErrorKind.creditsExhausted);
  });

  test('un like ou un passe ne coûte rien et ne renvoie pas de crédits', () async {
    final liked = await _demo(
      (a) => a.sendSwipe(targetUserId: 202, action: 'like'),
    );
    expect(liked.data!.containsKey('credits'), isFalse);
    expect(CreditBalance.fromJson(_get('/api/credits')['credits']).superLike.available, 1);
  });

  test('le boost : un crédit, puis déjà actif (409), jamais de second débit', () async {
    final credits = installTestCredits();

    final status = await _demo((a) => a.getBoostStatus());
    expect(status.data!.isActive, isFalse);
    expect(status.data!.remainingBoosts, 1);
    expect(status.data!.credits!.boost.available, 1);

    final started = await _demo((a) => a.activateBoost());
    expect(started.success, isTrue);
    expect(started.data!.isActive, isTrue);
    expect(credits.available(CreditKind.boost), 0);

    final again = await _demo((a) => a.activateBoost());
    expect(again.isBoostAlreadyActive, isTrue);
    expect(again.errorKind, ApiErrorKind.boostAlreadyActive);
    expect(credits.available(CreditKind.boost), 0);
  });

  test('la connexion fictive charge le solde fictif, sans réseau réel', () async {
    // L'API HTTP réelle du service, servie par DemoHttpClient.
    final credits = CreditsService.create(gateway: FakeStoreGateway());
    final previous = CreditsService.debugReplaceShared(credits);
    addTearDown(() {
      CreditsService.debugReplaceShared(previous);
      credits.dispose();
    });
    const secureStorage = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async => null);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorage, null),
    );
    await http.runWithClient(
      () async {
        await AuthService().signInAsDemo();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      () => DemoHttpClient(
        MockClient((request) async => fail('Réseau réel : ${request.url}')),
        latency: Duration.zero,
      ),
    );

    expect(credits.available(CreditKind.superLike), 1);
    expect(credits.available(CreditKind.boost), 1);

    await AuthService().signOut();
    expect(credits.balance, isNull);
  });
}
