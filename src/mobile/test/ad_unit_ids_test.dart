import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/ads/ad_unit_ids.dart';

void main() {
  test(
    'banner uses Google\'s well-known test ad unit outside a release build',
    () {
      // kReleaseMode is always false under `flutter test`, so this exercises
      // exactly the branch that matters most: a developer running the app
      // locally must never hit the real, revenue-generating ad units.
      final expected = Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';

      expect(AdUnitIds.banner, expected);
    },
  );

  test('banner does not return a real production ad unit ID in this mode', () {
    expect(AdUnitIds.banner, isNot(contains('6843680802048559')));
  });
}
