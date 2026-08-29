import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/foundation.dart';

import '../../data/in_app_purchase_subscription_repository.dart';
import '../../data/mock_subscription_repository.dart';
import '../../data/supabase_purchase_verifier.dart';
import '../../domain/models/entitlement.dart';
import '../../domain/models/subscription_plan.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'onboarding_providers.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  // in_app_purchase has no web implementation; fall back to the mock so the
  // paywall UI is still explorable when running as a web build.
  if (kIsWeb) {
    return MockSubscriptionRepository();
  }
  final repository = InAppPurchaseSubscriptionRepository(
    verifier: SupabasePurchaseVerifier(Supabase.instance.client),
    // ref.read, not ref.watch: this only needs the value at the moment a
    // purchase is verified, not to rebuild the repository whenever
    // onboarding state changes. onboardingProvider should already be
    // loaded by the time a purchase can happen (onboarding gates the rest
    // of the app) — a guest user simply has no email, and AsyncValue.value
    // (nullable in Riverpod 3) handles the (normally unreachable) case
    // where it somehow isn't loaded yet.
    getConfirmationEmail: () async => ref.read(onboardingProvider).value?.email,
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
