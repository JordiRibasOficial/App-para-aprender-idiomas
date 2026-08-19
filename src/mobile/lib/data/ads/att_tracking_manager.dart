import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// Wraps Apple's App Tracking Transparency (ATT) framework.
///
/// Separate from [AdsConsentManager]'s GDPR/UMP consent: ATT is required by
/// Apple since iOS 14.5 before an app (or an SDK it embeds, like AdMob) may
/// read the IDFA for ad personalization or cross-app measurement, regardless
/// of the user's region. On platforms without ATT (Android, web), the
/// plugin's own implementation reports [TrackingStatus.authorized] directly,
/// so this is a no-op there.
class AttTrackingManager {
  const AttTrackingManager._();

  /// Requests tracking authorization if the user hasn't been asked yet.
  ///
  /// Must run before [MobileAds.instance.initialize] so AdMob knows for
  /// this launch whether it's allowed to request the IDFA.
  static Future<void> requestAuthorizationIfNeeded() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}
