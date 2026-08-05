import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/mock_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/entitlement.dart';
import 'package:app_para_aprender_idiomas/domain/models/subscription_plan.dart';

void main() {
  group('MockSubscriptionRepository', () {
    test('loadPlans returns the placeholder plans', () async {
      final repository = MockSubscriptionRepository();

      expect(await repository.loadPlans(), SubscriptionPlan.placeholderPlans);
    });

    test('entitlementStream stays silent until a purchase or restore happens', () async {
      final repository = MockSubscriptionRepository();
      final emitted = <Entitlement>[];
      final subscription = repository.entitlementStream.listen(emitted.add);

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await subscription.cancel();
      repository.dispose();
    });

    test('restorePurchases re-emits the current entitlement without changing it', () async {
      final repository = MockSubscriptionRepository();
      final emitted = <Entitlement>[];
      final subscription = repository.entitlementStream.listen(emitted.add);

      await repository.purchase(SubscriptionPlan.placeholderPlans[0]);
      await repository.restorePurchases();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emitted.last.isActive, isTrue);
      expect(emitted.last.activeProductId, SubscriptionPlan.monthlyProductId);
      repository.dispose();
    });
  });
}
