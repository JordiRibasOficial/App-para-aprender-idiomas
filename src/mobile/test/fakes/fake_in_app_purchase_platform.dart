import 'dart:async';

import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

/// In-process fake for [InAppPurchasePlatform], so
/// `InAppPurchaseSubscriptionRepository` can be tested without real store
/// platform channels. Register it via `InAppPurchasePlatform.instance =
/// fake` — see `in_app_purchase_subscription_repository_test.dart` for the
/// setup dance this requires.
class FakeInAppPurchasePlatform extends InAppPurchasePlatform {
  FakeInAppPurchasePlatform({this.available = true, this.products = const []});

  bool available;
  List<ProductDetails> products;

  final List<PurchaseParam> purchaseCalls = [];
  final List<PurchaseDetails> completedPurchases = [];
  bool restoreCalled = false;

  final _purchaseController = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseController.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async {
    final found = products.where((p) => identifiers.contains(p.id)).toList();
    final notFound = identifiers.where((id) => products.every((p) => p.id != id)).toList();
    return ProductDetailsResponse(productDetails: found, notFoundIDs: notFound);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    purchaseCalls.add(purchaseParam);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoreCalled = true;
  }

  void emitPurchaseUpdate(List<PurchaseDetails> purchases) {
    _purchaseController.add(purchases);
  }

  Future<void> dispose() => _purchaseController.close();
}
