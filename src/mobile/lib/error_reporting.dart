import 'package:flutter/foundation.dart';

/// Single funnel for every uncaught error's *local* visibility (see
/// main.dart's `runZonedGuarded` / `FlutterError.onError` /
/// `PlatformDispatcher.instance.onError` wiring) — always logs locally,
/// visible via `flutter logs` / `adb logcat` / Xcode console.
///
/// In release builds, the same errors also reach Sentry, but not through a
/// call in here: main.dart's `SentryFlutter.init` installs Sentry's own
/// FlutterError.onError/PlatformDispatcher.instance.onError handlers first,
/// and the wiring around this function's call sites chains through them
/// rather than replacing them — so Sentry already captures every error via
/// that chain by the time reportError() runs. Calling Sentry again from
/// here would double-report. See sentry_config.dart for the DSN and
/// docs/business/crash-reporting-review.md for why Sentry was chosen.
void reportError(Object error, StackTrace? stack) {
  debugPrint('Uncaught error: $error');
  if (stack != null) debugPrint(stack.toString());
}
