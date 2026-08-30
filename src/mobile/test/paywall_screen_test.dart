import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/mock_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/account_session.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/subscription_repository.dart';
import 'package:app_para_aprender_idiomas/presentation/paywall/paywall_screen.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/account_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/subscription_providers.dart';

const _fakeAccount = AccountSession(
  userId: 'test-user',
  email: 'test@example.com',
);

void main() {
  // Purchase/restore both gate on requireAccount() first — most tests here
  // are about what happens *after* that gate, so default to already having
  // one. account: null exercises the gate itself.
  Widget buildPaywall(
    SubscriptionRepository repository, {
    AccountSession? account = _fakeAccount,
  }) {
    return ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repository),
        accountSessionProvider.overrideWith((ref) => Stream.value(account)),
      ],
      child: const MaterialApp(home: PaywallScreen()),
    );
  }

  testWidgets('renders both plans with the correct annual savings badge', (
    tester,
  ) async {
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
    'plan cards expose selectable-button semantics and are activatable via them',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildPaywall(MockSubscriptionRepository()));
      await tester.pumpAndSettle();

      final monthlyLabel = 'Mensual, €14.99';
      final annualLabel = 'Anual, €89.94, ahorras 50%';

      final monthlyFlags = tester
          .getSemantics(find.bySemanticsLabel(monthlyLabel))
          .getSemanticsData()
          .flagsCollection;
      expect(monthlyFlags.isButton, isTrue);
      expect(monthlyFlags.isSelected, Tristate.isFalse);

      final annualFlags = tester
          .getSemantics(find.bySemanticsLabel(annualLabel))
          .getSemanticsData()
          .flagsCollection;
      expect(annualFlags.isButton, isTrue);
      expect(annualFlags.isSelected, Tristate.isTrue);

      // Selecting via the semantics node (as assistive tech would) must
      // actually drive selection, not just describe it.
      await tester.tap(find.bySemanticsLabel(monthlyLabel));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Suscribirse — €14.99'),
        findsOneWidget,
      );

      handle.dispose();
    },
  );

  testWidgets(
    'shows the auto-renewal disclosure and legal links required by App Store guideline 3.1.2',
    (tester) async {
      await tester.pumpWidget(buildPaywall(MockSubscriptionRepository()));
      await tester.pumpAndSettle();

      expect(find.textContaining('se renueva automáticamente'), findsOneWidget);
      expect(find.text('Términos de servicio'), findsOneWidget);
      expect(find.text('Política de privacidad'), findsOneWidget);
    },
  );

  testWidgets(
    'the Suscribirse button stays disabled until the withdrawal-right '
    'checkbox is checked',
    (tester) async {
      await tester.pumpWidget(buildPaywall(MockSubscriptionRepository()));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Suscribirse — €89.94'),
      );
      expect(button.onPressed, isNull);

      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      final buttonAfterConsent = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Suscribirse — €89.94'),
      );
      expect(buttonAfterConsent.onPressed, isNotNull);
    },
  );

  testWidgets(
    'purchasing a plan updates the screen to the active-subscription view',
    (tester) async {
      await tester.pumpWidget(buildPaywall(MockSubscriptionRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Suscribirse — €89.94'),
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Suscribirse — €89.94'),
      );
      await tester.pump(); // enters the purchasing state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(); // mock purchase resolves after 300ms

      expect(find.text('¡Ya eres Premium!'), findsOneWidget);
      expect(find.text('Plan activo: annual_sub'), findsOneWidget);
    },
  );

  testWidgets(
    'a failed purchase shows an error snackbar and stays on the plans view',
    (tester) async {
      final repository = MockSubscriptionRepository()..simulateFailure = true;
      await tester.pumpWidget(buildPaywall(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Suscribirse — €89.94'),
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Suscribirse — €89.94'),
      );
      await tester.pumpAndSettle(); // mock purchase resolves after 300ms

      expect(
        find.text('No se pudo completar la compra de annual_sub.'),
        findsOneWidget,
      );
      expect(find.text('¡Ya eres Premium!'), findsNothing);
    },
  );

  testWidgets(
    'restoring with nothing to restore tells the user instead of doing nothing visibly',
    (tester) async {
      await tester.pumpWidget(buildPaywall(MockSubscriptionRepository()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Restaurar compras'));
      await tester.tap(find.text('Restaurar compras'));
      await tester.pump(); // enters the restoring state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester
          .pumpAndSettle(); // grace period for a late entitlement elapses

      expect(
        find.text('No se encontraron compras anteriores.'),
        findsOneWidget,
      );
      expect(find.text('¡Ya eres Premium!'), findsNothing);
    },
  );

  testWidgets(
    'a guest tapping Suscribirse is asked to create an account first, and no purchase is attempted if they cancel',
    (tester) async {
      final repository = MockSubscriptionRepository();
      await tester.pumpWidget(buildPaywall(repository, account: null));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Suscribirse — €89.94'),
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Suscribirse — €89.94'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Necesitas una cuenta'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Never reached the purchasing state, so never called the repository.
      expect(find.text('¡Ya eres Premium!'), findsNothing);
    },
  );

  testWidgets(
    'a guest tapping Restaurar compras is asked to create an account first',
    (tester) async {
      await tester.pumpWidget(
        buildPaywall(MockSubscriptionRepository(), account: null),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Restaurar compras'));
      await tester.tap(find.text('Restaurar compras'));
      await tester.pumpAndSettle();

      expect(find.text('Necesitas una cuenta'), findsOneWidget);
      expect(find.text('No se encontraron compras anteriores.'), findsNothing);
    },
  );
}
