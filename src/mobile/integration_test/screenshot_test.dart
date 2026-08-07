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

import 'package:app_para_aprender_idiomas/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture store-listing screenshots along the guest onboarding + lesson flow',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
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

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(lessons.at(1));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('06-ejercicio2');

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.workspace_premium_outlined));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('07-premium');
  });
}
