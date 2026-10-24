import 'package:in_app_purchase/in_app_purchase.dart';

import 'credit_models.dart';
import 'store_products.dart';

/// Un pack vendable : un consommable du store, avec ce que l'écran affiche.
class CreditPack {
  const CreditPack({required this.product, required this.details});

  /// Ce que le pack crédite (type et quantité).
  final ConsumableProduct product;

  /// Le produit du store, nécessaire pour lancer l'achat.
  final ProductDetails details;

  CreditKind get kind => product.kind;
  int get quantity => product.quantity;

  /// Prix dans la devise du store (`ProductDetails.rawPrice`).
  double get price => details.rawPrice;

  /// Code ISO 4217 (« EUR », « USD »).
  String get currencyCode => details.currencyCode;

  /// Prix tel que le store l'écrit (« 4,99 € »).
  String get priceLabel => details.price;
}
