import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../data/ads/ads_consent_manager.dart';
import '../../data/ads/att_tracking_manager.dart';

/// Whether banner ads should actually be requested from AdMob.
///
/// Defaults to false everywhere — production included — because the ads
/// SDK needs a real platform channel that host-side widget tests (test/)
/// don't have. `main()` is the one place that overrides this to true.
/// integration_test/ deliberately does not override it either: that suite
/// boots [MyApp] directly (not through `main()`) and stays decoupled from
/// this feature for now, so a flaky ad-network call never threatens the
/// device/emulator test it took real work to get green.
final adsEnabledProvider = Provider<bool>((ref) => false);

/// Runs GDPR/UMP consent gathering + Mobile Ads SDK init in the background
/// and resolves to whether ads are actually ready to be requested.
///
/// This used to be awaited in `main()` before `runApp()`, blocking the
/// first frame on two sequential network calls to Google (see main.dart
/// for the real cold-start numbers that motivated moving it here).
/// [PremiumGatedBannerAd] watches this instead of calling MobileAds
/// directly, so a banner is never requested before the SDK finishes
/// initializing — the same short-circuit that already keeps host-side
/// widget tests off the real platform channel just moves from `main()`
/// happening-before-build to this provider's own [adsEnabledProvider]
/// check happening-before-any-plugin-call.
final adsInitializedProvider = FutureProvider<bool>((ref) async {
  if (!ref.watch(adsEnabledProvider)) return false;

  await AdsConsentManager.gatherConsent();
  // Separate from the GDPR/UMP consent above — required by Apple on iOS
  // regardless of region, before AdMob may request the IDFA. No-op on
  // platforms without ATT (see AttTrackingManager).
  await AttTrackingManager.requestAuthorizationIfNeeded();
  // Same timeout rationale as before the move: if Google's ad servers are
  // slow or unreachable, this must not hang forever — ad requests simply
  // proceed uninitialized this launch.
  await MobileAds.instance.initialize().timeout(
    const Duration(seconds: 5),
    onTimeout: () => InitializationStatus(const {}),
  );
  return true;
});
