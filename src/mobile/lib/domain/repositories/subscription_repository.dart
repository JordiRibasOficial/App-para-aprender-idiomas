import '../models/entitlement.dart';
import '../models/subscription_plan.dart';

abstract interface class SubscriptionRepository {
  /// The available plans, store-priced where a real store connection
  /// exists. Returns an empty list if the store is unreachable.
  Future<List<SubscriptionPlan>> loadPlans();

  /// Emits the current entitlement whenever it changes (purchase,
  /// restoration, or — from Paso 9 onward — expiry).
  Stream<Entitlement> get entitlementStream;

  /// Emits a human-readable message whenever a purchase attempt fails,
  /// is cancelled, or is rejected by local verification. The UI should
  /// listen to this to tell the user something went wrong — [purchase]
  /// itself only reports whether the request was *sent*, not whether it
  /// succeeded (that arrives asynchronously via [entitlementStream] or
  /// this stream).
  Stream<String> get purchaseErrorStream;

  Future<void> purchase(SubscriptionPlan plan);

  Future<void> restorePurchases();

  void dispose();
}
