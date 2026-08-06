import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'data/ads/ads_consent_manager.dart';
import 'presentation/providers/ads_providers.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // google_mobile_ads has no web implementation — ads stay off there,
  // same as the subscription repository already falls back to a mock on
  // web (see subscription_providers.dart).
  final adsEnabled = !kIsWeb;
  if (adsEnabled) {
    await AdsConsentManager.gatherConsent();
    await MobileAds.instance.initialize();
  }

  runApp(
    ProviderScope(
      overrides: [adsEnabledProvider.overrideWithValue(adsEnabled)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'App para Aprender Idiomas',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
