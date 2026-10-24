import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/store/credit_models.dart';
import 'package:mazl/core/services/store/credits_service.dart';

import '../../support/credits_fakes.dart';

/// Rejoue les VRAIES méthodes d'`ApiService` contre des réponses qui ont la
/// forme du serveur (`swipe.routes.ts`, `boost.routes.ts`), sans réseau.
Future<T> _serve<T>(
  Future<T> Function(ApiService api) body,
  int status,
  Object json,
) => http.runWithClient(
  () => body(ApiService()),
  () => MockClient(
    (request) async => http.Response(
      jsonEncode(json),
      status,
      headers: {'content-type': 'application/json'},
    ),
  ),
);

/// Ce que `buildBoostStatus` renvoie (clés en snake_case).
Map<String, Object?> _boostStatus({
  bool active = false,
  Map<String, Object?>? credits,
}) {
  final view = credits ?? serverCredits();
  return {
    'is_active': active,
    'expires_at': active ? '2026-11-01T12:30:00.000Z' : null,
    'active_until': active ? '2026-11-01T12:30:00.000Z' : null,
    'remaining_boosts': (view['boost']! as Map<String, Object?>)['available'],
    'boosts_used_today': 0,
    'views_during_boost': 0,
    'likes_during_boost': 0,
    'credits': view,
  };
}

void main() {
  late CreditsService credits;

  setUp(() => credits = installTestCredits());

  group('sendSwipe', () {
    test(
      'un super like accepté : le credits du serveur met le solde à jour',
      () async {
        final response = await _serve(
          (api) => api.sendSwipe(targetUserId: 101, action: 'super_like'),
          200,
          {
            'success': true,
            'match': false,
            'credits': serverCredits(superLikeRemaining: 2),
          },
        );

        expect(response.success, isTrue);
        expect(response.data?['match'], false);
        expect(credits.available(CreditKind.superLike), 14);
      },
    );

    test(
      '402 super_likes_exhausted : distinct d\'une panne, le solde est lu',
      () async {
        credits.applyFromServer(serverCredits());

        final response = await _serve(
          (api) => api.sendSwipe(targetUserId: 101, action: 'super_like'),
          402,
          {
            'success': false,
            'error': 'super_likes_exhausted',
            'credits': serverCredits(
              superLikeRemaining: 0,
              superLikePurchased: 0,
            ),
          },
        );

        expect(response.success, isFalse);
        expect(response.statusCode, 402);
        expect(response.errorCode, 'super_likes_exhausted');
        expect(response.isCreditsExhausted, isTrue);
        expect(response.body?['error'], 'super_likes_exhausted');
        expect(credits.available(CreditKind.superLike), 0);
      },
    );

    test('un 500 n\'est pas un épuisement et ne touche pas au solde', () async {
      credits.applyFromServer(serverCredits());

      final response = await _serve(
        (api) => api.sendSwipe(targetUserId: 101, action: 'super_like'),
        500,
        {'success': false, 'error': 'Failed to record swipe'},
      );

      expect(response.isCreditsExhausted, isFalse);
      expect(response.statusCode, 500);
      expect(credits.available(CreditKind.superLike), 15);
    });

    test('un like simple, sans credits : le solde ne bouge pas', () async {
      credits.applyFromServer(serverCredits());

      final response = await _serve(
        (api) => api.sendSwipe(targetUserId: 101, action: 'like'),
        200,
        {'success': true, 'match': true, 'targetUserId': 101},
      );

      expect(response.data?['match'], true);
      expect(credits.available(CreditKind.superLike), 15);
    });
  });

  group('activateBoost', () {
    test('201 : le statut et le solde viennent du serveur', () async {
      final status = _boostStatus(
        active: true,
        credits: serverCredits(boostRemaining: 0, boostPurchased: 1),
      );

      final response = await _serve((api) => api.activateBoost(), 201, {
        'success': true,
        'boost': <String, Object?>{'id': 1},
        'status': status,
        ...status,
      });

      expect(response.success, isTrue);
      expect(response.data!.isActive, isTrue);
      expect(response.data!.remainingBoosts, 1);
      expect(response.data!.credits!.boost.available, 1);
      expect(credits.available(CreditKind.boost), 1);
    });

    test(
      '402 boosts_exhausted : distinct d\'une panne, le solde est lu',
      () async {
        final response = await _serve((api) => api.activateBoost(), 402, {
          'success': false,
          'error': 'boosts_exhausted',
          'credits': serverCredits(boostRemaining: 0, boostPurchased: 0),
        });

        expect(response.success, isFalse);
        expect(response.statusCode, 402);
        expect(response.isCreditsExhausted, isTrue);
        expect(response.isBoostAlreadyActive, isFalse);
        expect(credits.available(CreditKind.boost), 0);
      },
    );

    test('409 boost_already_active : un message, rien n\'est débité', () async {
      credits.applyFromServer(serverCredits());

      final response = await _serve((api) => api.activateBoost(), 409, {
        'success': false,
        'error': 'boost_already_active',
      });

      expect(response.statusCode, 409);
      expect(response.isBoostAlreadyActive, isTrue);
      expect(response.errorKind, ApiErrorKind.boostAlreadyActive);
      expect(response.isCreditsExhausted, isFalse);
      expect(credits.available(CreditKind.boost), 2);
    });
  });

  group('getBoostStatus', () {
    test('lit credits et met le solde à jour', () async {
      final response = await _serve((api) => api.getBoostStatus(), 200, {
        'success': true,
        ..._boostStatus(credits: serverCredits(boostPurchased: 7)),
      });

      expect(response.data!.credits!.boost.purchasedBalance, 7);
      expect(response.data!.remainingBoosts, 7);
      expect(credits.available(CreditKind.boost), 7);
    });

    test('sans credits (ancien serveur) : BoostStatus.credits est nul', () {
      final status = BoostStatus.fromJson({
        'is_active': false,
        'remaining_boosts': 1,
      });
      expect(status.credits, isNull);
      expect(status.remainingBoosts, 1);
    });
  });
}
