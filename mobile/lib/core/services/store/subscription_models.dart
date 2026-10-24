import 'package:in_app_purchase/in_app_purchase.dart';

/// Abonnement mazl+ tel que le backend le décrit
/// (`GET /api/subscription` et réponse 200 de `POST /api/subscriptions/apple/verify`).
///
/// Le backend est la source de vérité : l'application n'invente jamais un
/// droit à partir de ce que dit le store.
class MazlSubscription {
  const MazlSubscription({
    required this.planType,
    required this.status,
    required this.productId,
    required this.expiresAt,
  });

  final String planType;
  final String status;
  final String productId;

  /// Échéance (UTC). Absente : l'abonnement n'ouvre aucun droit.
  final DateTime? expiresAt;

  /// Lit l'enveloppe `{ "success": true, "subscription": {…} | null }`.
  ///
  /// Rend null quand il n'y a pas d'abonnement. Lève [FormatException] quand
  /// l'abonnement est présent mais illisible : on ne devine jamais un droit.
  static MazlSubscription? fromEnvelope(Map<String, Object?> envelope) {
    final raw = envelope['subscription'];
    if (raw == null) return null;
    if (raw is! Map<String, Object?>) {
      throw const FormatException('subscription: objet attendu');
    }
    final expires = raw['expires_at'];
    return MazlSubscription(
      planType: _requiredString(raw, 'plan_type'),
      status: _requiredString(raw, 'status'),
      productId: _requiredString(raw, 'product_id'),
      expiresAt: expires == null ? null : _utcDate(expires),
    );
  }

  /// Vrai quand le statut est « active » et que l'échéance n'est pas passée.
  bool isActiveAt(DateTime now) {
    final end = expiresAt;
    return status == 'active' && end != null && end.isAfter(now);
  }

  static String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('subscription.$key: texte attendu');
  }

  static DateTime _utcDate(Object value) {
    if (value is! String) {
      throw const FormatException('subscription.expires_at: texte attendu');
    }
    return DateTime.parse(value).toUtc();
  }
}

/// Une formule vendable : un produit du store, avec ce que l'écran affiche.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.productId,
    required this.months,
    required this.price,
    required this.currencyCode,
    required this.priceLabel,
    required this.title,
    required this.product,
  });

  factory SubscriptionPlan.fromProduct(ProductDetails product, int months) =>
      SubscriptionPlan(
        productId: product.id,
        months: months,
        price: product.rawPrice,
        currencyCode: product.currencyCode,
        priceLabel: product.price,
        title: product.title,
        product: product,
      );

  final String productId;
  final int months;

  /// Prix total dans la devise du store (`ProductDetails.rawPrice`).
  final double price;

  /// Code ISO 4217 (« EUR », « USD »).
  final String currencyCode;

  /// Prix tel que le store l'écrit (« 14,99 € »).
  final String priceLabel;
  final String title;

  /// Le produit du store, nécessaire pour lancer l'achat.
  final ProductDetails product;
}

/// Issue d'un achat. L'annulation est une issue NORMALE : ni exception, ni
/// message d'erreur.
sealed class PurchaseResult {
  const PurchaseResult();
}

/// L'abonnement est vérifié par le serveur et actif.
final class PurchaseSucceeded extends PurchaseResult {
  const PurchaseSucceeded();
}

/// L'utilisateur a fermé la fenêtre de paiement.
final class PurchaseCancelled extends PurchaseResult {
  const PurchaseCancelled();
}

/// En attente d'une approbation (Ask to Buy) : le droit arrivera plus tard,
/// quand la transaction réapparaîtra sur le flux d'achats.
final class PurchasePending extends PurchaseResult {
  const PurchasePending();
}

/// L'achat n'a pas abouti. [message] est écrit pour l'utilisateur, en français.
final class PurchaseFailed extends PurchaseResult {
  const PurchaseFailed(this.message);

  final String message;
}

/// Issue d'une restauration.
sealed class RestoreResult {
  const RestoreResult();
}

/// Un abonnement actif a été retrouvé.
final class RestoreFound extends RestoreResult {
  const RestoreFound();
}

/// Rien à restaurer pour ce compte.
final class RestoreNothing extends RestoreResult {
  const RestoreNothing();
}

/// La restauration a échoué. [message] est écrit pour l'utilisateur.
final class RestoreFailed extends RestoreResult {
  const RestoreFailed(this.message);

  final String message;
}
