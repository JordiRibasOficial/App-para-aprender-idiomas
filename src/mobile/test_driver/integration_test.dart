import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Standard `flutter drive` entrypoint — the counterpart to
/// `integration_test/screenshot_test.dart`. This is what makes
/// `IntegrationTestWidgetsFlutterBinding.takeScreenshot()` actually work:
/// `flutter test integration_test/` (used by app_test.dart in CI) has no
/// screenshot callback registered and would throw, which is why
/// app_test.dart deliberately doesn't call it. `flutter drive` wires this
/// driver in, which does register one.
///
/// Uses the "_extended" driver (not integration_test_driver.dart) —
/// that's the variant that actually accepts `onScreenshot`.
Future<void> main() => integrationDriver(
  onScreenshot: (String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? args]) async {
    final file = await File('screenshots/$screenshotName.png').create(recursive: true);
    await file.writeAsBytes(screenshotBytes);
    return true;
  },
);
