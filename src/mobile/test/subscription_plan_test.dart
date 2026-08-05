import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/domain/models/subscription_plan.dart';

void main() {
  group('SubscriptionPlan.annualSavingsRatio', () {
    test('computes the fraction saved by the annual plan over 12 months', () {
      const monthly = SubscriptionPlan(
        productId: 'monthly_sub',
        period: SubscriptionPeriod.monthly,
        title: 'Mensual',
        formattedPrice: '€10.00',
        rawPrice: 10,
        currencyCode: 'EUR',
      );
      const annual = SubscriptionPlan(
        productId: 'annual_sub',
        period: SubscriptionPeriod.annual,
        title: 'Anual',
        formattedPrice: '€60.00',
        rawPrice: 60,
        currencyCode: 'EUR',
      );

      // 12 * 10 = 120/year paid monthly vs 60/year paid annually -> 50% saved.
      final ratio = SubscriptionPlan.annualSavingsRatio(monthly: monthly, annual: annual);

      expect(ratio, closeTo(0.5, 0.0001));
    });

    test('returns 0 when the monthly price is 0', () {
      const monthly = SubscriptionPlan(
        productId: 'monthly_sub',
        period: SubscriptionPeriod.monthly,
        title: 'Mensual',
        formattedPrice: '€0.00',
        rawPrice: 0,
        currencyCode: 'EUR',
      );
      const annual = SubscriptionPlan(
        productId: 'annual_sub',
        period: SubscriptionPeriod.annual,
        title: 'Anual',
        formattedPrice: '€60.00',
        rawPrice: 60,
        currencyCode: 'EUR',
      );

      expect(SubscriptionPlan.annualSavingsRatio(monthly: monthly, annual: annual), 0);
    });

    test('the real placeholder plans save a meaningful amount annually', () {
      final ratio = SubscriptionPlan.annualSavingsRatio(
        monthly: SubscriptionPlan.placeholderPlans[0],
        annual: SubscriptionPlan.placeholderPlans[1],
      );

      expect(ratio, greaterThan(0.3));
      expect(ratio, lessThan(1));
    });
  });
}
