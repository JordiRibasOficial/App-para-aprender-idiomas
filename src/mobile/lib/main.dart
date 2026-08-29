import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/secure_supabase_local_storage.dart';
import 'data/sentry_config.dart';
import 'data/supabase_config.dart';
import 'error_reporting.dart';
import 'presentation/providers/ads_providers.dart';
import 'presentation/providers/theme_mode_providers.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  // Catches everything reportError's own callers can't: an uncaught error
  // in an async gap that isn't running inside a Flutter-framework error
  // zone. WidgetsFlutterBinding.ensureInitialized() and runApp() must both
  // run inside this same guarded zone — splitting them across zones is a
  // documented Flutter footgun.
  runZonedGuarded(_main, reportError);
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only in release builds — see error_reporting.dart's doc comment on why
  // debug/profile/test runs stay local-only. Deliberately does NOT pass
  // `appRunner:`: this call's own default integrations
  // (FlutterErrorIntegration/OnErrorIntegration) install their own
  // FlutterError.onError/PlatformDispatcher.instance.onError handlers,
  // each of which captures to Sentry and then calls whatever handler was
  // previously set — so as long as the code below *chains through* the
  // previous handler instead of replacing it outright (which it already
  // does for FlutterError.onError, and now also does for
  // PlatformDispatcher.instance.onError), every error still reaches Sentry
  // via that chain, with reportError() staying purely the local-log funnel
  // it always was — no need to fight or strip Sentry's own integrations.
  if (kReleaseMode) {
    await SentryFlutter.init((options) {
      options.dsn = SentryConfig.dsn;
      options.tracesSampleRate = 0; // error/crash reporting only, no APM
    });
  }

  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    previousOnError?.call(details);
    reportError(details.exception, details.stack);
  };
  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    previousPlatformOnError?.call(error, stack);
    reportError(error, stack);
    return true;
  };

  // Only used for purchase verification today (see
  // SupabasePurchaseVerifier) — no user-facing feature depends on this yet,
  // so unlike ads init below there's nothing to time-box: initialize()
  // sets up the local client and restores a persisted session from disk,
  // it doesn't itself make a required network call.
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    // Default persistence is plaintext SharedPreferences, which would put
    // the refresh token (a standing credential) in a less-protected spot
    // than the onboarding email already gets — see
    // SecureSupabaseLocalStorage's doc comment.
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSupabaseLocalStorage(),
    ),
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
