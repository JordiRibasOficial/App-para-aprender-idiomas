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
//
// One testWidgets per screenshot, not one long sequential flow: a shared
// multi-screenshot run kept producing byte-identical captures for
// consecutive screens (confirmed by checksum across several CI runs) —
// takeScreenshot()'s native call appears to leave something in a bad
// state for whatever tap/interaction immediately follows it. Starting
// each screenshot fresh (its own pumpWidget, its own single
// takeScreenshot() call with nothing after it) sidesteps the whole
// failure class instead of chasing timing workarounds for it. Costs more
// CI time (onboarding repeats per screenshot) in exchange for reliability.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_para_aprender_idiomas/data/mock_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/subscription_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/router/app_router.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps a fresh app instance. MockSubscriptionRepository, not the real
  /// InAppPurchaseSubscriptionRepository: this emulator has no real Play
  /// Store connection, so the real repository correctly returns an empty
  /// plan list — confirmed by a real capture that came back showing "Los
  /// planes de suscripción no están disponibles todavía." instead of the
  /// Premium plans. Correct app behavior (already covered by
  /// app_test.dart), but useless for a store screenshot, which needs to
  /// actually show the plans.
  Future<void> pumpFreshApp(WidgetTester tester) async {
    // appRouter is a module-level GoRouter singleton (same one app_test.dart
    // has to reset — see its restart-simulation comment), and every
    // testWidgets in this file runs in the same process. Without this, each
    // test after the first starts wherever the previous test's navigation
    // left off instead of at Welcome — confirmed by a real CI failure
    // where 03-nivel onward couldn't find "Empezar" because the router was
    // still sitting on the language-selection route from 02-idioma.
    appRouter.go('/');

    // Real on-device SharedPreferences, not a host-test fake — it
    // persists across tests in this file (same running app process, same
    // device storage). Confirmed by a real CI failure: 04-lecciones is
    // the first test to actually complete onboarding (taps "Continuar
    // como invitado"), and every test after it failed to find "Empezar"
    // because the app now skipped straight to the lesson list — onboarding
    // was already marked complete from 04's real, persisted write. Clearing
    // it here makes every test start from a genuinely fresh install.
    await (await SharedPreferences.getInstance()).clear();

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
    // surface to something takeScreenshot() can actually read from. Must
    // happen once per test, before that test's screenshot.
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
  }

  /// Walks Welcome -> language (English default) -> level (A1 default) ->
  /// guest, landing on the lesson list. Same tap pattern proven stable in
  /// app_test.dart.
  Future<void> completeOnboardingAsGuest(WidgetTester tester) async {
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Continuar como invitado'));
    await tester.pumpAndSettle();

    expect(find.text('Inglés · A1'), findsOneWidget);
  }

  testWidgets('01-welcome', (tester) async {
    await pumpFreshApp(tester);
    await binding.takeScreenshot('01-welcome');
  });

  testWidgets('02-idioma', (tester) async {
    await pumpFreshApp(tester);
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02-idioma'); // shows the Premium lock badge on pt/fr/ja
  });

  testWidgets('03-nivel', (tester) async {
    await pumpFreshApp(tester);
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03-nivel');
  });

  testWidgets('04-lecciones', (tester) async {
    await pumpFreshApp(tester);
    await completeOnboardingAsGuest(tester);
    await binding.takeScreenshot('04-lecciones');
  });

  testWidgets('05-ejercicio', (tester) async {
    await pumpFreshApp(tester);
    await completeOnboardingAsGuest(tester);
    await tester.tap(find.text('Saludos básicos'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo se dice \'Hola\' en inglés?'), findsOneWidget);
    await binding.takeScreenshot('05-ejercicio');
  });

  testWidgets('06-ejercicio2', (tester) async {
    await pumpFreshApp(tester);
    await completeOnboardingAsGuest(tester);
    await tester.tap(find.text('Presentarse'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('06-ejercicio2');
  });

  testWidgets('07-premium', (tester) async {
    await pumpFreshApp(tester);
    await completeOnboardingAsGuest(tester);
    await tester.tap(find.byIcon(Icons.workspace_premium_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Hazte Premium'), findsOneWidget); // sanity: paywall actually reached
    await binding.takeScreenshot('07-premium');
  });
}
