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
    await binding.takeScreenshot('07-premium');
  });
}
