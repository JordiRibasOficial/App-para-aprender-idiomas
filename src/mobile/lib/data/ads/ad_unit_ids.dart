import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// AdMob ad unit IDs — real IDs from the app's own AdMob account
/// (see docs/business/play-console-setup-guide.md § 6). Ad unit IDs are
/// public identifiers baked into the compiled app, not secrets.
class AdUnitIds {
  AdUnitIds._();

  static const _androidBanner = 'ca-app-pub-6843680802048559/7562391249';
  static const _iosBanner = 'ca-app-pub-6843680802048559/6066576821';

  static String get banner {
    if (kIsWeb) return '';
    return Platform.isIOS ? _iosBanner : _androidBanner;
  }
}
