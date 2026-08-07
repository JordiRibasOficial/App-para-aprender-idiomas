// Runs 07-premium in its own `flutter drive` process — see
// screenshot_helpers.dart for why 05-07 don't share a process with 01-04
// or each other.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'screenshot_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('07-premium', (tester) async {
    await pumpFreshApp(tester, binding);
    await completeOnboardingAsGuest(tester);
    await tester.tap(find.byIcon(Icons.workspace_premium_outlined));
    await tester.pumpAndSettle();
    expect(
      find.text('Hazte Premium'),
      findsOneWidget,
    ); // sanity: paywall actually reached
    // See screenshot_05_ejercicio_test.dart: a beat of real wall-clock
    // time for Android's compositor to catch up with the post-navigation
    // frame before the native capture runs. This one already came back
    // correct without it, but the same race is inherently flaky — cheap
    // insurance against it recurring here too.
    await Future<void>.delayed(const Duration(seconds: 1));
    await binding.takeScreenshot('07-premium');
  });
}
