import 'package:in_app_purchase/in_app_purchase.dart';

/// Ce que le flux d'achats unique confie, par un port, à celui qui tient les
/// consommables. `SubscriptionService` reçoit TOUS les achats du store (il n'y
/// a qu'un seul écouteur de `purchaseStream`) et ne garde que les abonnements ;
/// les consommables passent ici.
abstract interface class ConsumablePurchaseHandler {
  /// Traite un achat de consommable : vérification par le serveur, puis
  /// terminaison de la transaction. Ne lève jamais.
  Future<void> handlePurchase(PurchaseDetails purchase);
}
