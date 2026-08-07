// Captures real store-listing screenshots at the actual device resolution
// of the CI Android emulator (Pixel 6 profile, 1080x2400) — replacing the
// Flutter Web + Playwright placeholders in docs/business/store-screenshots/
// (390x844, not a real device size). Deliberately a separate file from
// app_test.dart: this one is driven via `flutter drive` (required for
// takeScreenshot() to work — see test_driver/integration_test.dart), while
// app_test.dart stays on `flutter test integration_test/`, the invocation
// already proven stable in integration-test-android/-ios. Mixing the two
// in one file would put a `flutter drive`-only requirement on the test
// that CI's stability took real work to reach.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:app_para_aprender_idiomas/data/mock_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/subscription_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/router/app_router.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture store-listing screenshots along the guest onboarding + lesson flow',
      (tester) async {
    // MockSubscriptionRepository, not the real InAppPurchaseSubscriptionRepository:
    // this emulator has no real Play Store connection, so the real repository
    // correctly returns an empty plan list — confirmed by a real capture that
    // came back showing "Los planes de suscripción no están disponibles
    // todavía." instead of the Premium plans. That's correct app behavior
    // (already covered by app_test.dart), but useless for a store screenshot,
    // which needs to actually show the plans. The rest of this test still
    // exercises the real onboarding/lesson code paths on a real device — this
    // override only swaps the one piece that structurally can't produce
    // meaningful content in CI.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(MockSubscriptionRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Android only, but harmless on iOS too: switches the rendering
    // surface to something takeScreenshot() can actually read from.
    // Must happen once, before the first screenshot.
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    await binding.takeScreenshot('01-welcome');

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02-idioma'); // shows the Premium lock badge on pt/fr/ja

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03-nivel');

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Continuar como invitado'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04-lecciones');

    final lessons = find.byType(ListTile);

    await tester.tap(lessons.first);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05-ejercicio');

    // Not tester.pageBack(): LessonListScreen navigates to a lesson via
    // context.go(), which replaces the route instead of pushing on top
    // of it — there's no pop target for pageBack() to find (confirmed by
    // a real CI failure: pageBack() found no back button at all).
    appRouter.go('/');
    await tester.pumpAndSettle();

    await tester.tap(lessons.at(1));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('06-ejercicio2');

    // Not tester.pageBack(): LessonListScreen navigates to a lesson via
    // context.go(), which replaces the route instead of pushing on top
    // of it — there's no pop target for pageBack() to find (confirmed by
    // a real CI failure: pageBack() found no back button at all).
    appRouter.go('/');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.workspace_premium_outlined));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('07-premium');
  });
}
