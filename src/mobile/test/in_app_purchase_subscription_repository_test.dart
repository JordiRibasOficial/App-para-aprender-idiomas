import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import 'package:app_para_aprender_idiomas/data/in_app_purchase_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/entitlement.dart';
import 'package:app_para_aprender_idiomas/domain/models/subscription_plan.dart';

import 'fakes/fake_in_app_purchase_platform.dart';

ProductDetails _productDetails(String id, {double rawPrice = 7.99}) {
  return ProductDetails(
    id: id,
    title: id,
    description: '',
    price: '€$rawPrice',
    rawPrice: rawPrice,
    currencyCode: 'EUR',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // InAppPurchase.instance registers a real Android/iOS platform on first
  // access based on defaultTargetPlatform, which would open a real
  // (failing) native billing connection in this headless test host.
  // Force an unmatched platform so _getOrCreateInstance() skips
  // registration entirely, leaving InAppPurchasePlatform.instance for us
  // to set directly below.
  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    InAppPurchase.instance;
    debugDefaultTargetPlatformOverride = null;
  });

  late FakeInAppPurchasePlatform fakePlatform;
  late InAppPurchaseSubscriptionRepository repository;

  setUp(() {
    fakePlatform = FakeInAppPurchasePlatform(
      products: [
        _productDetails(SubscriptionPlan.monthlyProductId, rawPrice: 7.99),
        _productDetails(SubscriptionPlan.annualProductId, rawPrice: 44.99),
      ],
    );
    InAppPurchasePlatform.instance = fakePlatform;
    repository = InAppPurchaseSubscriptionRepository();
  });

  tearDown(() async {
    repository.dispose();
    await fakePlatform.dispose();
  });

  test('loadPlans maps store product details into domain plans', () async {
    final plans = await repository.loadPlans();

    expect(plans, hasLength(2));
    expect(
      plans.map((p) => p.productId),
      containsAll([SubscriptionPlan.monthlyProductId, SubscriptionPlan.annualProductId]),
    );
    expect(
      plans.firstWhere((p) => p.productId == SubscriptionPlan.monthlyProductId).period,
      SubscriptionPeriod.monthly,
    );
    expect(
      plans.firstWhere((p) => p.productId == SubscriptionPlan.annualProductId).period,
      SubscriptionPeriod.annual,
    );
  });

  test('loadPlans returns an empty list when the store is unavailable', () async {
    fakePlatform.available = false;

    expect(await repository.loadPlans(), isEmpty);
  });

  test('purchase queries the product and calls buyNonConsumable', () async {
    await repository.purchase(SubscriptionPlan.placeholderPlans[0]);

    expect(fakePlatform.purchaseCalls, hasLength(1));
    expect(
      fakePlatform.purchaseCalls.first.productDetails.id,
      SubscriptionPlan.monthlyProductId,
    );
  });

  test('purchase throws when the product does not exist in the store', () async {
    fakePlatform.products = [];

    expect(
      () => repository.purchase(SubscriptionPlan.placeholderPlans[0]),
      throwsStateError,
    );
  });

  test('a purchased update emits an active entitlement and completes the purchase', () async {
    final entitlements = <Entitlement>[];
    final subscription = repository.entitlementStream.listen(entitlements.add);

    fakePlatform.emitPurchaseUpdate([
      PurchaseDetails(
        productID: SubscriptionPlan.annualProductId,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
        transactionDate: null,
        status: PurchaseStatus.purchased,
      )..pendingCompletePurchase = true,
    ]);

    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(entitlements, hasLength(1));
    expect(entitlements.single.isActive, isTrue);
    expect(entitlements.single.activeProductId, SubscriptionPlan.annualProductId);
    expect(fakePlatform.completedPurchases, hasLength(1));
  });

  test('restorePurchases delegates to the platform', () async {
    await repository.restorePurchases();

    expect(fakePlatform.restoreCalled, isTrue);
  });

  test('a purchase with no local verification data is rejected, not granted', () async {
    final entitlements = <Entitlement>[];
    final errors = <String>[];
    final entitlementSub = repository.entitlementStream.listen(entitlements.add);
    final errorSub = repository.purchaseErrorStream.listen(errors.add);

    fakePlatform.emitPurchaseUpdate([
      PurchaseDetails(
        productID: SubscriptionPlan.monthlyProductId,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'test',
        ),
        transactionDate: null,
        status: PurchaseStatus.purchased,
      ),
    ]);

    await Future<void>.delayed(Duration.zero);
    await entitlementSub.cancel();
    await errorSub.cancel();

    expect(entitlements, isEmpty);
    expect(errors, hasLength(1));
    expect(errors.single, contains(SubscriptionPlan.monthlyProductId));
  });

  test('an errored purchase update is reported on purchaseErrorStream, not as an entitlement',
      () async {
    final entitlements = <Entitlement>[];
    final errors = <String>[];
    final entitlementSub = repository.entitlementStream.listen(entitlements.add);
    final errorSub = repository.purchaseErrorStream.listen(errors.add);

    fakePlatform.emitPurchaseUpdate([
      PurchaseDetails(
        productID: SubscriptionPlan.monthlyProductId,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'test',
        ),
        transactionDate: null,
        status: PurchaseStatus.error,
      )..error = IAPError(source: 'test', code: 'declined', message: 'Card declined'),
    ]);

    await Future<void>.delayed(Duration.zero);
    await entitlementSub.cancel();
    await errorSub.cancel();

    expect(entitlements, isEmpty);
    expect(errors, ['Card declined']);
  });

  test('a cancelled purchase update is reported on purchaseErrorStream', () async {
    final errors = <String>[];
    final errorSub = repository.purchaseErrorStream.listen(errors.add);

    fakePlatform.emitPurchaseUpdate([
      PurchaseDetails(
        productID: SubscriptionPlan.monthlyProductId,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'test',
        ),
        transactionDate: null,
        status: PurchaseStatus.canceled,
      ),
    ]);

    await Future<void>.delayed(Duration.zero);
    await errorSub.cancel();

    expect(errors, hasLength(1));
  });
}
