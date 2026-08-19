// Shared setup for every `integration_test/screenshot_*_test.dart` file.
// Split out so 05-07 can each run as their own `flutter drive` process
// (see screenshot_05_ejercicio_test.dart) without duplicating this logic —
// splitting into separate testWidgets within one process wasn't enough to
// avoid takeScreenshot() returning stale bytes for whatever screenshot
// follows another in the same app process; a fresh process per screenshot
// sidesteps it at the process level instead.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_para_aprender_idiomas/data/mock_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/subscription_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/router/app_router.dart';

/// Pumps a fresh app instance. MockSubscriptionRepository, not the real
/// InAppPurchaseSubscriptionRepository: this emulator has no real Play
/// Store connection, so the real repository correctly returns an empty
/// plan list — confirmed by a real capture that came back showing "Los
/// planes de suscripción no están disponibles todavía." instead of the
/// Premium plans. Correct app behavior (already covered by
/// app_test.dart), but useless for a store screenshot, which needs to
/// actually show the plans.
Future<void> pumpFreshApp(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  // appRouter is a module-level GoRouter singleton, so it (and
  // SharedPreferences below) must be reset even within a single-test
  // process — a leftover habit from the shared-process file, kept because
  // it's still correct and cheap even with one testWidgets per process.
  appRouter.go('/');
  await (await SharedPreferences.getInstance()).clear();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(
          MockSubscriptionRepository(),
        ),
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
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
  await tester.tap(find.text('Empezar'));
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
  await tester.pumpAndSettle();

  await tester.tap(
    find.widgetWithText(OutlinedButton, 'Continuar como invitado'),
  );
  await tester.pumpAndSettle();

  expect(find.text('Inglés · A1'), findsOneWidget);
}
