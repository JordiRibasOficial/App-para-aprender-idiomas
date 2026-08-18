import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/supabase_config.dart';
import 'presentation/providers/ads_providers.dart';
import 'presentation/providers/theme_mode_providers.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only used for purchase verification today (see
  // SupabasePurchaseVerifier) — no user-facing feature depends on this yet,
  // so unlike ads init below there's nothing to time-box: initialize()
  // sets up the local client and restores a persisted session from disk,
  // it doesn't itself make a required network call.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // google_mobile_ads has no web implementation — ads stay off there,
  // same as the subscription repository already falls back to a mock on
  // web (see subscription_providers.dart).
  //
  // Consent gathering + MobileAds.instance.initialize() used to be awaited
  // right here — two sequential network calls to Google, each with its own
  // 5s worst-case timeout (see adsInitializedProvider). A real cold-start
  // measurement on a KVM-accelerated Android emulator
  // (measure-startup.yml) showed ~3.7s of the ~4.1s time-to-first-frame
  // happening *after* the Flutter framework itself was already
  // initialized — i.e. spent sitting in this function, not building the
  // first frame. Nothing about the first frame actually depends on ads
  // being ready (PremiumGatedBannerAd already gates its own ad load on
  // adsInitializedProvider), so that work now runs in the background
  // instead of blocking runApp().
  final adsEnabled = !kIsWeb;

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
