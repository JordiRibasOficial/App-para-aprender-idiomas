// Real-device/emulator/simulator UI test — the counterpart to test/, which
// only exercises the app against flutter_test's host-only bindings (fake
// SharedPreferences, no real sqflite, no real platform channels). This runs
// the actual app end to end: real local storage, real SQLite, and the real
// InAppPurchaseSubscriptionRepository (not MockSubscriptionRepository).
//
// Requires a connected device, a running emulator (Android), or a booted
// simulator (iOS) — see .github/workflows/mobile-ci.yml for how CI runs
// this on a KVM-backed Android emulator and a real iOS Simulator on
// macos-latest. Can't run inside this project's own sandbox (no KVM, no
// macOS available) — see plans/mobile-mvp-android-ios.md for that context.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/router/app_router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'onboarding, a correct answer, the paywall, and persistence across a simulated restart',
    (tester) async {
      // --- Fresh install: Welcome screen, not the lesson list ---
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      expect(find.text('App para Aprender Idiomas'), findsOneWidget);
      expect(find.text('Inglés · A1'), findsNothing);

      // --- Onboarding: language (English default) -> guest (level is A1 by
      // default and skipped since it's the only one available) ---
      // pumpAndSettle (not a single pump) between the two checkbox taps: a
      // bare pump() left the second tap racing the first checkbox's
      // ripple/gesture-arena resolution on a real device, hanging the whole
      // test indefinitely on CI's iOS Simulator (never reproduced on the
      // host-only widget-test harness, whose fake clock has no such race).
      await tester.tap(find.byType(Checkbox).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empezar'));
      await tester.pumpAndSettle();
      expect(find.text('Elige tu idioma'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cómo quieres continuar?'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Continuar como invitado'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inglés · A1'), findsOneWidget);

      // --- Paywall: must render without crashing even with no real store
      // connection available in CI (in_app_purchase.isAvailable() is false
      // there) — this is the one path the mocked test/ suite can't exercise
      // for real, since it always overrides subscriptionRepositoryProvider.
      // Visited via the AppBar icon (a real push) before opening a lesson,
      // so the way back to the lesson list is a reliable pageBack() — the
      // lesson route below is reached via go(), which doesn't leave a pop
      // target, so it's visited last instead of navigated away from. ---
      await tester.tap(find.byIcon(Icons.workspace_premium_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Hazte Premium'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Inglés · A1'), findsOneWidget);

      // --- Answer the first exercise of the first lesson correctly ---
      await tester.tap(find.text('Saludos básicos'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo se dice \'Hola\' en inglés?'), findsOneWidget);
      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Comprobar'));
      await tester.pumpAndSettle();

      expect(find.text('¡Correcto!'), findsOneWidget);

      // --- Simulate a cold restart: rebuild MyApp fresh and confirm real
      // SharedPreferences persistence lands directly on the lesson list
      // instead of showing onboarding again.
      //
      // appRouter is a module-level singleton (see app_router.dart), and
      // integration_test runs the whole test file in a single Dart
      // process/isolate on the device — so it survives this pumpWidget
      // exactly like it survives between tests in test/widget files
      // elsewhere in this suite (hence those files' `tearDown(() =>
      // appRouter.go('/'))`). Without resetting it here, GoRouter stays on
      // whatever route the exercise screen left it on, RootScreen (the
      // widget that actually reads the persisted onboarding state) never
      // gets rebuilt, and no amount of waiting makes the lesson list
      // appear — confirmed by this exact assertion timing out on both the
      // Android emulator and the iOS Simulator even with a 5s poll. A real
      // cold restart doesn't have this problem: the whole process,
      // including the GoRouter instance, is freshly created starting at
      // '/'. `go('/')` here is what actually simulates that. ---
      appRouter.go('/');
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      await _waitForCondition(
        tester,
        () => find.text('Inglés · A1').evaluate().isNotEmpty,
        description: "lesson list ('Inglés · A1') after simulated restart",
      );

      expect(find.text('Inglés · A1'), findsOneWidget);
      expect(find.text('App para Aprender Idiomas'), findsNothing);
    },
  );
}

/// Polls [condition] by pumping frames, instead of trusting a single
/// [WidgetTester.pumpAndSettle] call to have waited long enough for a real
/// platform-channel round trip (e.g. SharedPreferences) plus the resulting
/// Riverpod rebuild to finish on a real device/emulator/simulator.
Future<void> _waitForCondition(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('Timed out waiting for: $description');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
