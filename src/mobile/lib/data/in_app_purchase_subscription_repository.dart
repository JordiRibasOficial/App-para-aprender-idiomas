import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/models/entitlement.dart';
import '../domain/models/subscription_plan.dart';
import '../domain/repositories/subscription_repository.dart';

SubscriptionPlan _planFromProductDetails(ProductDetails details) {
  final period = details.id == SubscriptionPlan.monthlyProductId
      ? SubscriptionPeriod.monthly
      : SubscriptionPeriod.annual;
  return SubscriptionPlan(
    productId: details.id,
    period: period,
    title: details.title,
    formattedPrice: details.price,
    rawPrice: details.rawPrice,
    currencyCode: details.currencyCode,
  );
}

/// Real store-backed [SubscriptionRepository]. Product IDs, receipt
/// verification, and restore-state reconciliation are finished in Paso 9 —
/// this wires the plumbing (`in_app_purchase` unifies Google Play Billing
/// and StoreKit under one API) and reacts to purchase updates.
class InAppPurchaseSubscriptionRepository implements SubscriptionRepository {
  InAppPurchaseSubscriptionRepository() {
    _purchaseSubscription = _iap.purchaseStream.listen(_onPurchaseUpdate);
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  final _entitlementController = StreamController<Entitlement>.broadcast();

  @override
  Stream<Entitlement> get entitlementStream => _entitlementController.stream;

  @override
  Future<List<SubscriptionPlan>> loadPlans() async {
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) return const [];

    final response = await _iap.queryProductDetails(SubscriptionPlan.productIds);
    if (response.error != null) return const [];

    return response.productDetails.map(_planFromProductDetails).toList();
  }

  @override
  Future<void> purchase(SubscriptionPlan plan) async {
    final response = await _iap.queryProductDetails({plan.productId});
    if (response.productDetails.isEmpty) {
      throw StateError('Product not found in the store: ${plan.productId}');
    }

    final purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _entitlementController.add(
            Entitlement(status: EntitlementStatus.active, activeProductId: purchase.productID),
          );
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
        case PurchaseStatus.pending:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription.cancel());
    unawaited(_entitlementController.close());
  }
}
