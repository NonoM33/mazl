import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/core/services/store/credits_service.dart';
import 'package:mazl/core/services/store/store_session.dart';
import 'package:mazl/core/services/store/subscription_api.dart';
import 'package:mazl/core/services/store/subscription_service.dart';

import '../../../support/credits_fakes.dart';
import '../../../support/store_fakes.dart';

void main() {
  late FakeSubscriptionApi subscriptionApi;
  late FakeCreditsApi creditsApi;
  late SubscriptionService subscriptions;
  late CreditsService credits;
  late StoreSession session;

  setUp(() {
    storeJournal.clear();
    subscriptionApi = FakeSubscriptionApi()
      ..onGetSubscription = () => ApiReply(200, activeSubscriptionBody());
    creditsApi = FakeCreditsApi();
    final gateway = FakeStoreGateway();
    addTearDown(gateway.controller.close);
    subscriptions = SubscriptionService.create(
      gateway: gateway,
      api: subscriptionApi,
      platform: TargetPlatform.iOS,
      now: () => testNow,
    );
    credits = CreditsService.create(
      gateway: gateway,
      api: creditsApi,
      platform: TargetPlatform.iOS,
    );
    addTearDown(subscriptions.dispose);
    addTearDown(credits.dispose);
    session = StoreSession(subscriptions: subscriptions, credits: credits);
  });

  test('la connexion rafraîchit l\'abonnement ET le solde', () async {
    await session.onSignedIn('jwt');

    expect(subscriptions.isMazlPro, isTrue);
    expect(credits.available(CreditKind.superLike), 15);
    expect(creditsApi.getCalls, 1);
  });

  test('la déconnexion vide l\'abonnement ET le solde', () async {
    await session.onSignedIn('jwt');

    session.onSignedOut();

    expect(subscriptions.isMazlPro, isFalse);
    expect(credits.balance, isNull);
  });

  test('sans jeton, rien n\'est lu', () async {
    await session.onSignedIn(null);

    expect(creditsApi.getCalls, 0);
    expect(credits.balance, isNull);
  });
}
