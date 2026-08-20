import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// AdMob ad unit IDs — real IDs from the app's own AdMob account
/// (see docs/business/play-console-setup-guide.md § 6). Ad unit IDs are
/// public identifiers baked into the compiled app, not secrets.
///
/// Debug/profile builds serve Google's well-known test ad unit IDs instead
/// (same publisher ID, `3940256099942544`, on every Flutter/Android/iOS
/// AdMob sample app) — requesting the *real* ad units from a developer's
/// own device during `flutter run` would generate non-genuine impressions,
/// which AdMob's invalid-traffic policy treats as a policy violation and
/// can lead to account suspension. Only a release build ships the real IDs.
class AdUnitIds {
  AdUnitIds._();

  static const _androidBannerReal = 'ca-app-pub-6843680802048559/7562391249';
  static const _iosBannerReal = 'ca-app-pub-6843680802048559/6066576821';

  static const _androidBannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';

  static String get banner {
    if (kIsWeb) return '';
    if (!kReleaseMode) {
      return Platform.isIOS ? _iosBannerTest : _androidBannerTest;
    }
    return Platform.isIOS ? _iosBannerReal : _androidBannerReal;
  }
}
