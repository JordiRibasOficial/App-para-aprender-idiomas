import 'dart:async';

import '../domain/models/entitlement.dart';
import '../domain/models/subscription_plan.dart';
import '../domain/repositories/subscription_repository.dart';

/// Lets the paywall UI be built and tested without a store connection.
class MockSubscriptionRepository implements SubscriptionRepository {
  MockSubscriptionRepository() {
    _controller.add(_current);
  }

  final _controller = StreamController<Entitlement>.broadcast();
  Entitlement _current = const Entitlement();

  @override
  Future<List<SubscriptionPlan>> loadPlans() async => SubscriptionPlan.placeholderPlans;

  @override
  Stream<Entitlement> get entitlementStream => _controller.stream;

  @override
  Future<void> purchase(SubscriptionPlan plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _current = Entitlement(status: EntitlementStatus.active, activeProductId: plan.productId);
    _controller.add(_current);
  }

  @override
  Future<void> restorePurchases() async {
    _controller.add(_current);
  }

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}
