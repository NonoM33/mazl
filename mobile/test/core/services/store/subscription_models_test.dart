import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/store/store_products.dart';
import 'package:mazl/core/services/store/subscription_models.dart';

/// Les formes JSON ci-dessous sont celles du contrat du backend, copiées à la
/// main (pas générées depuis le décodeur).
const _activeBody = <String, Object?>{
  'success': true,
  'subscription': {
    'plan_type': 'plus',
    'status': 'active',
    'expires_at': '2026-11-24T10:00:00.000Z',
    'product_id': 'com.mazl.app.plus.1m',
  },
};

const _noSubscriptionBody = <String, Object?>{
  'success': true,
  'subscription': null,
};

void main() {
  group('MazlSubscription.fromEnvelope', () {
    test('décode la réponse de GET /api/subscription (abonné)', () {
      final sub = MazlSubscription.fromEnvelope(_activeBody);

      expect(sub, isNotNull);
      expect(sub!.planType, 'plus');
      expect(sub.status, 'active');
      expect(sub.productId, 'com.mazl.app.plus.1m');
      expect(sub.expiresAt, DateTime.utc(2026, 11, 24, 10));
    });

    test('subscription: null -> pas d\'abonnement', () {
      expect(MazlSubscription.fromEnvelope(_noSubscriptionBody), isNull);
    });

    test('une enveloppe sans clé subscription -> pas d\'abonnement', () {
      expect(MazlSubscription.fromEnvelope(const {'success': true}), isNull);
    });

    test('une date illisible lève FormatException, jamais un faux abonné', () {
      expect(
        () => MazlSubscription.fromEnvelope(const {
          'success': true,
          'subscription': {
            'plan_type': 'plus',
            'status': 'active',
            'expires_at': 'demain',
            'product_id': 'com.mazl.app.plus.1m',
          },
        }),
        throwsFormatException,
      );
    });

    test('un champ obligatoire absent lève FormatException', () {
      expect(
        () => MazlSubscription.fromEnvelope(const {
          'success': true,
          'subscription': {'status': 'active'},
        }),
        throwsFormatException,
      );
    });

    test('expires_at absent : décodé sans échéance (donc jamais actif)', () {
      final sub = MazlSubscription.fromEnvelope(const {
        'success': true,
        'subscription': {
          'plan_type': 'plus',
          'status': 'active',
          'product_id': 'com.mazl.app.plus.1m',
        },
      });
      expect(sub?.expiresAt, isNull);
      expect(sub!.isActiveAt(DateTime.utc(2026, 11, 1)), isFalse);
    });
  });

  group('MazlSubscription.isActiveAt', () {
    final sub = MazlSubscription.fromEnvelope(_activeBody)!;

    test('actif tant que l\'échéance est dans le futur', () {
      expect(sub.isActiveAt(DateTime.utc(2026, 11, 24, 9, 59, 59)), isTrue);
    });

    test('inactif à l\'échéance exacte et après', () {
      expect(sub.isActiveAt(DateTime.utc(2026, 11, 24, 10)), isFalse);
      expect(sub.isActiveAt(DateTime.utc(2027)), isFalse);
    });

    test('un statut autre que « active » n\'ouvre aucun droit', () {
      final expired = MazlSubscription.fromEnvelope(const {
        'success': true,
        'subscription': {
          'plan_type': 'plus',
          'status': 'expired',
          'expires_at': '2099-01-01T00:00:00.000Z',
          'product_id': 'com.mazl.app.plus.1m',
        },
      })!;
      expect(expired.isActiveAt(DateTime.utc(2026, 11, 1)), isFalse);
    });
  });

  group('identifiants de produit', () {
    test('la liste suit les quatre durées créées dans App Store Connect', () {
      expect(kSubscriptionProductIds, [
        'com.mazl.app.plus.1m',
        'com.mazl.app.plus.3m',
        'com.mazl.app.plus.6m',
        'com.mazl.app.plus.12m',
      ]);
    });

    test('la durée se lit dans com.mazl.app.plus.<n>m', () {
      expect(monthsFromProductId('com.mazl.app.plus.1m'), 1);
      expect(monthsFromProductId('com.mazl.app.plus.6m'), 6);
      expect(monthsFromProductId('com.mazl.app.plus.12m'), 12);
    });

    test('un identifiant étranger n\'a pas de durée inventée', () {
      expect(monthsFromProductId('monthly'), isNull);
      expect(monthsFromProductId('com.mazl.app.plus.m'), isNull);
      expect(monthsFromProductId('com.mazl.app.plus.0m'), isNull);
      expect(monthsFromProductId('com.mazl.app.plus.1m.extra'), isNull);
    });
  });
}
