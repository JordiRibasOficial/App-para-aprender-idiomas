// Runs 05-ejercicio in its own `flutter drive` process — see
// screenshot_helpers.dart for why 05-07 don't share a process with 01-04
// or each other.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'screenshot_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('05-ejercicio', (tester) async {
    await pumpFreshApp(tester, binding);
    await completeOnboardingAsGuest(tester);
    await tester.tap(find.text('Saludos básicos'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo se dice \'Hola\' en inglés?'), findsOneWidget);
    // A real-time pause, not another pumpAndSettle(): a real CI run came
    // back with takeScreenshot() bytes identical to a screenshot from a
    // *previous, separate* flutter drive process, despite the widget
    // tree (per the assertion above) already showing this screen —
    // Android's compositor hadn't caught up with the post-navigation
    // frame yet when the native capture ran. Giving it a beat of real
    // wall-clock time is the workaround; pumpAndSettle() only waits for
    // Flutter-side animations, not the OS-level compositor.
    await Future<void>.delayed(const Duration(seconds: 1));
    await binding.takeScreenshot('05-ejercicio');
  });
}
