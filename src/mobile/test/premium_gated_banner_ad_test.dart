import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/mock_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/entitlement.dart';
import 'package:app_para_aprender_idiomas/domain/models/subscription_plan.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/subscription_repository.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/ads_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/subscription_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/widgets/premium_gated_banner_ad.dart';

/// Reports an active entitlement from the moment it's read, unlike
/// [MockSubscriptionRepository] (which stays silent until a purchase or
/// restore happens) — used here to prove the Premium gate is checked
/// *before* the widget ever touches the real ads SDK, without needing a
/// purchase flow to get there.
class _AlreadyPremiumSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<SubscriptionPlan>> loadPlans() async =>
      SubscriptionPlan.placeholderPlans;

  @override
  Stream<Entitlement> get entitlementStream => Stream.value(
    const Entitlement(
      status: EntitlementStatus.active,
      activeProductId: 'annual_sub',
    ),
  );

  @override
  Stream<String> get purchaseErrorStream => const Stream.empty();

  @override
  Future<void> purchase(SubscriptionPlan plan) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  void dispose() {}
}

void main() {
  // Both scenarios below deliberately never reach a real ad load: the
  // widget must short-circuit to nothing before ever touching the ads
  // SDK, which host-side widget tests have no platform channel for. The
  // "ads enabled + not Premium -> loads a real ad" path only gets
  // exercised for real in integration_test/ (see ads_providers.dart).

  testWidgets(
    'renders nothing when ads are disabled (the default everywhere but main())',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(
              MockSubscriptionRepository(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(bottomNavigationBar: PremiumGatedBannerAd()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PremiumGatedBannerAd), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders nothing for a Premium user even with ads enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adsEnabledProvider.overrideWithValue(true),
          subscriptionRepositoryProvider.overrideWithValue(
            _AlreadyPremiumSubscriptionRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(bottomNavigationBar: PremiumGatedBannerAd()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PremiumGatedBannerAd), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
