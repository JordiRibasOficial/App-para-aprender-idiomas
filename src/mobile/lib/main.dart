import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'data/ads/ads_consent_manager.dart';
import 'presentation/providers/ads_providers.dart';
import 'presentation/providers/theme_mode_providers.dart';
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
    // Unlike gatherConsent() above, MobileAds.instance.initialize() has no
    // built-in timeout — if Google's ad servers are slow or unreachable
    // (observed intermittently on the iOS Simulator in CI), this Future
    // never completes, main() never returns, and runApp() never runs, so
    // nothing — not even a test harness — ever gets a first frame. Same
    // fallback rationale as gatherConsent(): ad requests proceed
    // uninitialized this launch rather than blocking startup forever.
    await MobileAds.instance.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () => InitializationStatus(const {}),
    );
  }

  runApp(
    ProviderScope(
      overrides: [adsEnabledProvider.overrideWithValue(adsEnabled)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // .value, not .when(loading: ...): the SharedPreferences read is fast
    // but still async, and gating the whole app behind a spinner for it
    // would be a worse first frame than the one-tick flash from system to
    // a saved override. AsyncNotifier already gives every other screen
    // that watches themeModeProvider the loading/data states properly.
    final themeMode =
        ref.watch(themeModeProvider).value?.flutterThemeMode ??
        ThemeMode.system;

    return MaterialApp.router(
      title: 'App para Aprender Idiomas',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
