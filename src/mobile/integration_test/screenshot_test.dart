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
// Only 01-04 run here, one testWidgets per screenshot. 05-07 each get
// their own file (screenshot_05_ejercicio_test.dart etc.) run via a
// separate `flutter drive` process — see screenshot_helpers.dart for why.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'screenshot_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01-welcome', (tester) async {
    await pumpFreshApp(tester, binding);
    await binding.takeScreenshot('01-welcome');
  });

  testWidgets('02-idioma', (tester) async {
    await pumpFreshApp(tester, binding);
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot(
      '02-idioma',
    ); // shows the Premium lock badge on pt/fr/ja
  });

  testWidgets('03-nivel', (tester) async {
    await pumpFreshApp(tester, binding);
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03-nivel');
  });

  testWidgets('04-lecciones', (tester) async {
    await pumpFreshApp(tester, binding);
    await completeOnboardingAsGuest(tester);
    await binding.takeScreenshot('04-lecciones');
  });
}
