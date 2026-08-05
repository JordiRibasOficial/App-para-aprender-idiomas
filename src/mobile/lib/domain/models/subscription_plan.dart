enum SubscriptionPeriod { monthly, annual }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.productId,
    required this.period,
    required this.title,
    required this.formattedPrice,
    required this.rawPrice,
    required this.currencyCode,
  });

  final String productId;
  final SubscriptionPeriod period;
  final String title;

  /// Store-formatted price string (e.g. "€7.99"), ready to display as-is.
  final String formattedPrice;

  /// Numeric price in major currency units, used only to compute the
  /// annual-savings percentage — never displayed directly (use
  /// [formattedPrice] for that).
  final double rawPrice;
  final String currencyCode;

  static const monthlyProductId = 'monthly_sub';
  static const annualProductId = 'annual_sub';
  static const productIds = {monthlyProductId, annualProductId};

  // TODO: confirmar precio definitivo con el usuario antes del Paso 13.
  // Valores de mercado razonables solo para maquetar la UI del paywall sin
  // conexión real a las tiendas (eso llega en el Paso 9).
  static const List<SubscriptionPlan> placeholderPlans = [
    SubscriptionPlan(
      productId: monthlyProductId,
      period: SubscriptionPeriod.monthly,
      title: 'Mensual',
      formattedPrice: '€7.99',
      rawPrice: 7.99,
      currencyCode: 'EUR',
    ),
    SubscriptionPlan(
      productId: annualProductId,
      period: SubscriptionPeriod.annual,
      title: 'Anual',
      formattedPrice: '€44.99',
      rawPrice: 44.99,
      currencyCode: 'EUR',
    ),
  ];

  /// Fraction saved by paying [annual] once instead of [monthly] 12 times,
  /// e.g. `0.53` for 53%. Returns 0 if the monthly price is 0.
  static double annualSavingsRatio({
    required SubscriptionPlan monthly,
    required SubscriptionPlan annual,
  }) {
    final monthlyYearCost = monthly.rawPrice * 12;
    if (monthlyYearCost <= 0) return 0;
    return 1 - (annual.rawPrice / monthlyYearCost);
  }
}
