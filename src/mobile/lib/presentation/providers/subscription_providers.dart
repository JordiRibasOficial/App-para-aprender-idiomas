import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/foundation.dart';

import '../../data/in_app_purchase_subscription_repository.dart';
import '../../data/mock_subscription_repository.dart';
import '../../data/supabase_purchase_verifier.dart';
import '../../domain/models/entitlement.dart';
import '../../domain/models/subscription_plan.dart';
import '../../domain/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  // in_app_purchase has no web implementation; fall back to the mock so the
  // paywall UI is still explorable when running as a web build.
  if (kIsWeb) {
    return MockSubscriptionRepository();
  }
  final repository = InAppPurchaseSubscriptionRepository(
    verifier: SupabasePurchaseVerifier(Supabase.instance.client),
  );
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
