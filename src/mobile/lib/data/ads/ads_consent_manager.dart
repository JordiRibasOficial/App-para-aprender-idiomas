import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wraps Google's User Messaging Platform (UMP) SDK, bundled inside
/// google_mobile_ads. Every AdMob publisher is required to collect consent
/// from EEA/UK end users under GDPR before requesting ads — see
/// https://developers.google.com/admob/flutter/privacy/gdpr. This must run
/// before [MobileAds.instance.initialize] and before any ad is requested.
class AdsConsentManager {
  const AdsConsentManager._();

  /// Requests a consent info update and, if Google determines this user's
  /// region requires it, shows the consent form. Bounded by [timeout] so a
  /// slow or unreachable consent server never blocks app startup — if it
  /// can't resolve in time, ad requests simply proceed as non-personalized
  /// until the next app launch retries consent.
  static Future<void> gatherConsent({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (!completer.isCompleted) completer.complete();
          });
        } else if (!completer.isCompleted) {
          completer.complete();
        }
      },
      (formError) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future.timeout(timeout, onTimeout: () {});
  }
}
