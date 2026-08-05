import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/in_app_purchase_subscription_repository.dart';
import '../../domain/models/entitlement.dart';
import '../../domain/models/subscription_plan.dart';
import '../../domain/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final repository = InAppPurchaseSubscriptionRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) {
  return ref.watch(subscriptionRepositoryProvider).loadPlans();
});

final entitlementProvider = StreamProvider<Entitlement>((ref) {
  return ref.watch(subscriptionRepositoryProvider).entitlementStream;
});

final purchaseErrorProvider = StreamProvider<String>((ref) {
  return ref.watch(subscriptionRepositoryProvider).purchaseErrorStream;
});
