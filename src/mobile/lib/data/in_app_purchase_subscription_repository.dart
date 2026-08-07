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

/// Real store-backed [SubscriptionRepository]. `in_app_purchase` unifies
/// Google Play Billing and StoreKit under one API.
///
/// **What this does NOT verify (Paso 9 scope, explicit):**
/// - No server-side receipt validation against Apple/Google's verification
///   APIs — that requires a backend, which doesn't exist yet.
/// - No cryptographic signature check of the receipt.
/// - No subscription expiry/renewal tracking of its own — entitlement state
///   depends entirely on the store re-pushing events on [purchaseStream]
///   (which both platforms do on renewal/cancellation while the app is
///   installed, but there's no independent expiry check here).
/// - No refund/chargeback reconciliation beyond what the store pushes.
///
/// What it DOES do locally: rejects a purchase as an entitlement source if
/// [PurchaseDetails.verificationData] has no local verification payload at
/// all (a purchase with literally nothing to verify is treated as
/// untrustworthy) — a presence check, not a real verification. Real
/// verification is a Paso 13+ backend concern.
class InAppPurchaseSubscriptionRepository implements SubscriptionRepository {
  InAppPurchaseSubscriptionRepository() {
    _purchaseSubscription = _iap.purchaseStream.listen(_onPurchaseUpdate);
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  final _entitlementController = StreamController<Entitlement>.broadcast();
  final _purchaseErrorController = StreamController<String>.broadcast();

  @override
  Stream<Entitlement> get entitlementStream => _entitlementController.stream;

  @override
  Stream<String> get purchaseErrorStream => _purchaseErrorController.stream;

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
          if (purchase.verificationData.localVerificationData.isEmpty) {
            _purchaseErrorController.add(
              'La compra de ${purchase.productID} no trae datos de verificación — no se activó.',
            );
          } else {
            _entitlementController.add(
              Entitlement(status: EntitlementStatus.active, activeProductId: purchase.productID),
            );
          }
        case PurchaseStatus.error:
          _purchaseErrorController.add(
            purchase.error?.message ?? 'No se pudo completar la compra de ${purchase.productID}.',
          );
        case PurchaseStatus.canceled:
          _purchaseErrorController.add('Compra cancelada.');
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
    unawaited(_purchaseErrorController.close());
  }
}
