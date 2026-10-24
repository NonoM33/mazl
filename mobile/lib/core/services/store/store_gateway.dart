import 'package:in_app_purchase/in_app_purchase.dart';

/// Port vers le store (App Store / Google Play). Le service d'abonnement ne
/// connaît que cette interface : les tests y branchent un faux, la production
/// l'adaptateur [InAppPurchaseGateway] du plugin officiel `in_app_purchase`.
abstract interface class StoreGateway {
  /// Achats mis à jour : nouveaux, restaurés, en attente, annulés, rejoués.
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> productIds);

  /// Lance l'achat. Les abonnements passent aussi par `buyNonConsumable`.
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam);

  /// Lance l'achat d'un consommable (Boost, Super Likes). La transaction n'est
  /// JAMAIS terminée par le plugin : `completePurchase` s'en charge, une fois
  /// le crédit confirmé par le serveur.
  Future<bool> buyConsumable(PurchaseParam purchaseParam);

  Future<void> restorePurchases();

  /// Termine la transaction auprès du store (à n'appeler qu'une fois le droit
  /// accordé, ou refusé de façon définitive).
  Future<void> completePurchase(PurchaseDetails purchase);
}

/// Adaptateur de production. Sur iOS, le plugin `in_app_purchase_storekit`
/// utilise StoreKit 2 par défaut (le JWS de la transaction arrive dans
/// `verificationData.serverVerificationData`).
///
/// L'instance du plugin n'est touchée qu'au premier appel, pour que construire
/// le service ne dépende jamais d'un canal de plateforme.
class InAppPurchaseGateway implements StoreGateway {
  InAppPurchaseGateway({InAppPurchase? plugin}) : _injected = plugin;

  final InAppPurchase? _injected;

  InAppPurchase get _plugin => _injected ?? InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _plugin.purchaseStream;

  @override
  Future<bool> isAvailable() => _plugin.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> productIds) =>
      _plugin.queryProductDetails(productIds);

  @override
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam) =>
      _plugin.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<bool> buyConsumable(PurchaseParam purchaseParam) =>
      _plugin.buyConsumable(purchaseParam: purchaseParam, autoConsume: false);

  @override
  Future<void> restorePurchases() => _plugin.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _plugin.completePurchase(purchase);
}
