import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../data/ads/ad_unit_ids.dart';
import '../providers/ads_providers.dart';
import '../providers/subscription_providers.dart';

/// A banner ad shown only to non-Premium users, hidden the instant
/// [entitlementProvider] reports an active subscription — never shown to
/// paying users. Renders nothing (and never touches the ads SDK) whenever
/// [adsEnabledProvider] is false, which is every host-side test and the
/// integration test by default — see ads_providers.dart.
class PremiumGatedBannerAd extends ConsumerStatefulWidget {
  const PremiumGatedBannerAd({super.key});

  @override
  ConsumerState<PremiumGatedBannerAd> createState() => _PremiumGatedBannerAdState();
}

class _PremiumGatedBannerAdState extends ConsumerState<PremiumGatedBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    if (_bannerAd != null) return;
    final ad = BannerAd(
      adUnitId: AdUnitIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  void _releaseAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
  }

  @override
  Widget build(BuildContext context) {
    final adsEnabled = ref.watch(adsEnabledProvider);
    if (!adsEnabled) return const SizedBox.shrink();

    final isPremium = ref.watch(entitlementProvider).value?.isActive ?? false;

    ref.listen(entitlementProvider, (previous, next) {
      final active = next.value?.isActive ?? false;
      if (active && _bannerAd != null) {
        setState(_releaseAd);
      }
    });

    if (isPremium) return const SizedBox.shrink();

    _loadAd();

    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
