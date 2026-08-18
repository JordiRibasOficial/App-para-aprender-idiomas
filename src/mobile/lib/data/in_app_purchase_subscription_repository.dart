import 'dart:async';
import 'dart:io' show Platform;

import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/models/entitlement.dart';
import '../domain/models/subscription_plan.dart';
import '../domain/repositories/purchase_verifier.dart';
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
/// Entitlement is granted only after [_verifier] confirms the purchase
/// server-to-server against Google Play / the App Store (see
/// src/backend/README.md) — a modified client sending a well-formed but
/// fabricated purchase gets nothing back from that call. What's still NOT
/// done here:
/// - No subscription expiry/renewal tracking of its own — entitlement state
///   depends on the store re-pushing events on [purchaseStream] (which both
///   platforms do on renewal/cancellation while the app is installed) and
///   on the backend's own record, not on this repository polling anything.
/// - No refund/chargeback reconciliation beyond what the store pushes.
class InAppPurchaseSubscriptionRepository implements SubscriptionRepository {
  // Not `required this._verifier`: that would make the external parameter
  // name the private `_verifier`, which callers in other files can't
  // reference. `verifier` stays the public constructor parameter name.
  InAppPurchaseSubscriptionRepository({required PurchaseVerifier verifier})
    // ignore: prefer_initializing_formals
    : _verifier = verifier {
    _purchaseSubscription = _iap.purchaseStream.listen(_onPurchaseUpdate);
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  final PurchaseVerifier _verifier;
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

    final response = await _iap.queryProductDetails(
      SubscriptionPlan.productIds,
    );
    if (response.error != null) return const [];

    return response.productDetails.map(_planFromProductDetails).toList();
  }

  @override
  Future<void> purchase(SubscriptionPlan plan) async {
    final response = await _iap.queryProductDetails({plan.productId});
    if (response.productDetails.isEmpty) {
      throw StateError('Product not found in the store: ${plan.productId}');
    }

    final purchaseParam = PurchaseParam(
      productDetails: response.productDetails.first,
    );
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndGrant(purchase);
        case PurchaseStatus.error:
          _purchaseErrorController.add(
            purchase.error?.message ??
                'No se pudo completar la compra de ${purchase.productID}.',
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

  /// The identifier `_verifier` needs to look this purchase up server-side:
  /// the Play Billing purchase token on Android, the App Store transaction
  /// id on iOS. Both come from [PurchaseDetails] but from different fields
  /// per platform — see the store plugins' own source for why
  /// (`verificationData.serverVerificationData` is an App Store *receipt*
  /// blob on iOS, not a transaction id).
  String _storeTransactionId(PurchaseDetails purchase) {
    return Platform.isIOS
        ? (purchase.purchaseID ?? '')
        : purchase.verificationData.serverVerificationData;
  }

  Future<void> _verifyAndGrant(PurchaseDetails purchase) async {
    if (purchase.verificationData.localVerificationData.isEmpty) {
      _purchaseErrorController.add(
        'La compra de ${purchase.productID} no trae datos de verificación — no se activó.',
      );
      return;
    }

    final storeTransactionId = _storeTransactionId(purchase);
    if (storeTransactionId.isEmpty) {
      _purchaseErrorController.add(
        'La compra de ${purchase.productID} no trae un identificador verificable — no se activó.',
      );
      return;
    }

    try {
      final result = await _verifier.verify(
        platform: Platform.isIOS ? 'ios' : 'android',
        productId: purchase.productID,
        purchaseToken: storeTransactionId,
      );
      if (result.isActive) {
        _entitlementController.add(
          Entitlement(
            status: EntitlementStatus.active,
            activeProductId: purchase.productID,
          ),
        );
      } else {
        _purchaseErrorController.add(
          'La compra de ${purchase.productID} no está activa según el servidor — no se activó.',
        );
      }
    } on Exception catch (e) {
      _purchaseErrorController.add(
        'No se pudo verificar la compra de ${purchase.productID}: $e',
      );
    }
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription.cancel());
    unawaited(_entitlementController.close());
    unawaited(_purchaseErrorController.close());
  }
}
