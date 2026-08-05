import '../models/entitlement.dart';
import '../models/subscription_plan.dart';

abstract interface class SubscriptionRepository {
  /// The available plans, store-priced where a real store connection
  /// exists. Returns an empty list if the store is unreachable.
  Future<List<SubscriptionPlan>> loadPlans();

  /// Emits the current entitlement whenever it changes (purchase,
  /// restoration, or — from Paso 9 onward — expiry).
  Stream<Entitlement> get entitlementStream;

  Future<void> purchase(SubscriptionPlan plan);

  Future<void> restorePurchases();

  void dispose();
}
