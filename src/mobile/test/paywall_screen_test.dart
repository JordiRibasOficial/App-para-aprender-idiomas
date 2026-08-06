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
    expect(find.text('€14.99'), findsOneWidget);
    expect(find.text('€89.94'), findsOneWidget);

    // 89.94 / (14.99 * 12) = 0.5 exactly -> saves 50%.
    expect(find.text('-50%'), findsOneWidget);
  });

  testWidgets(
      'shows the auto-renewal disclosure and legal links required by App Store guideline 3.1.2',
      (tester) async {
    await tester.pumpWidget(buildPaywall(MockSubscriptionRepository()));
    await tester.pumpAndSettle();

    expect(find.textContaining('se renueva automáticamente'), findsOneWidget);
    expect(find.text('Términos de servicio'), findsOneWidget);
    expect(find.text('Política de privacidad'), findsOneWidget);
  });

  testWidgets('purchasing a plan updates the screen to the active-subscription view',
      (tester) async {
    await tester.pumpWidget(buildPaywall(MockSubscriptionRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Suscribirse — €89.94'));
    await tester.pump(); // enters the purchasing state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(); // mock purchase resolves after 300ms

    expect(find.text('¡Ya eres Premium!'), findsOneWidget);
    expect(find.text('Plan activo: annual_sub'), findsOneWidget);
  });

  testWidgets('a failed purchase shows an error snackbar and stays on the plans view',
      (tester) async {
    final repository = MockSubscriptionRepository()..simulateFailure = true;
    await tester.pumpWidget(buildPaywall(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Suscribirse — €89.94'));
    await tester.pumpAndSettle(); // mock purchase resolves after 300ms

    expect(find.text('No se pudo completar la compra de annual_sub.'), findsOneWidget);
    expect(find.text('¡Ya eres Premium!'), findsNothing);
  });

  testWidgets('restoring with nothing to restore tells the user instead of doing nothing visibly',
      (tester) async {
    await tester.pumpWidget(buildPaywall(MockSubscriptionRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restaurar compras'));
    await tester.pump(); // enters the restoring state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(); // grace period for a late entitlement elapses

    expect(find.text('No se encontraron compras anteriores.'), findsOneWidget);
    expect(find.text('¡Ya eres Premium!'), findsNothing);
  });
}
