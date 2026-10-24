import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mazl/core/services/store/store_gateway.dart';

/// Un plugin qui ne répond qu'à `buyConsumable` : toute autre méthode appelée
/// par l'adaptateur fait échouer le test.
class _RecordingPlugin implements InAppPurchase {
  PurchaseParam? param;
  bool? autoConsume;
  bool? answer = true;

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    param = purchaseParam;
    this.autoConsume = autoConsume;
    return answer!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test('buyConsumable : le plugin est appelé avec autoConsume à false', () async {
    final plugin = _RecordingPlugin();
    final gateway = InAppPurchaseGateway(plugin: plugin);
    final param = PurchaseParam(
      productDetails: ProductDetails(
        id: 'com.mazl.app.boost.1',
        title: 'Boost',
        description: 'Boost',
        price: '1,99 €',
        rawPrice: 1.99,
        currencyCode: 'EUR',
      ),
    );

    final started = await gateway.buyConsumable(param);

    expect(started, isTrue);
    expect(plugin.param, same(param));
    // Le crédit est tenu par le serveur : le plugin ne doit jamais consommer
    // (terminer) la transaction avant la réponse du serveur.
    expect(plugin.autoConsume, isFalse);
  });
}
