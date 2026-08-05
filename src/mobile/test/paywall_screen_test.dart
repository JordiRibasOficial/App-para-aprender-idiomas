import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/mock_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/subscription_repository.dart';
import 'package:app_para_aprender_idiomas/presentation/paywall/paywall_screen.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/subscription_providers.dart';

void main() {
  Widget buildPaywall(SubscriptionRepository repository) {
    return ProviderScope(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: PaywallScreen()),
    );
  }

  testWidgets('renders both plans with the correct annual savings badge', (tester) async {
    await tester.pumpWidget(buildPaywall(MockSubscriptionRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Mensual'), findsOneWidget);
    expect(find.text('Anual'), findsOneWidget);
    expect(find.text('€7.99'), findsOneWidget);
    expect(find.text('€44.99'), findsOneWidget);

    // 44.99 / (7.99 * 12) = 0.4695... -> saves ~53%.
    expect(find.text('-53%'), findsOneWidget);
  });

  testWidgets('purchasing a plan updates the screen to the active-subscription view',
      (tester) async {
    await tester.pumpWidget(buildPaywall(MockSubscriptionRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Suscribirse — €44.99'));
    await tester.pump(); // enters the purchasing state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(); // mock purchase resolves after 300ms

    expect(find.text('¡Ya eres Premium!'), findsOneWidget);
    expect(find.text('Plan activo: annual_sub'), findsOneWidget);
  });
}
