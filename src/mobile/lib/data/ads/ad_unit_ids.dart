import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// AdMob ad unit IDs.
///
/// These are Google's official public *test* IDs — see
/// https://developers.google.com/admob/flutter/test-ads. They always
/// return test ads, never real ones, and never earn revenue. Swap them
/// for real ad unit IDs from an AdMob account (see
/// docs/business/play-console-setup-guide.md) before publishing.
class AdUnitIds {
  AdUnitIds._();

  static const _testAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testIosBanner = 'ca-app-pub-3940256099942544/2934735716';

  static String get banner {
    if (kIsWeb) return '';
    return Platform.isIOS ? _testIosBanner : _testAndroidBanner;
  }
}
