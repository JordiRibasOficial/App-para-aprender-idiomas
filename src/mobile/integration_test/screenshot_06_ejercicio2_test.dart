// Runs 06-ejercicio2 in its own `flutter drive` process — see
// screenshot_helpers.dart for why 05-07 don't share a process with 01-04
// or each other.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'screenshot_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('06-ejercicio2', (tester) async {
    await pumpFreshApp(tester, binding);
    await completeOnboardingAsGuest(tester);
    await tester.tap(find.text('Presentarse'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('06-ejercicio2');
  });
}
