import 'package:flutter/foundation.dart';

/// Single funnel for uncaught errors (see main.dart's `runZonedGuarded` /
/// `FlutterError.onError` / `PlatformDispatcher.instance.onError` wiring).
///
/// No remote crash reporter (Sentry, Crashlytics, ...) is wired up yet —
/// this only logs locally, visible via `flutter logs` / `adb logcat` /
/// Xcode console during development, and covered by the OS-level crash
/// reports Play Console / App Store Connect already collect for anything
/// that escapes to a native crash. Swap the body of this function for a
/// real reporter's call once one is configured; every call site (this is
/// the only one) stays the same.
void reportError(Object error, StackTrace? stack) {
  debugPrint('Uncaught error: $error');
  if (stack != null) debugPrint(stack.toString());
}
