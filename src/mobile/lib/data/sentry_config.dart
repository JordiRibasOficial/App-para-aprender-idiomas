/// Sentry project DSN — safe to ship in the compiled app, same as
/// [SupabaseConfig.publishableKey]: a DSN only lets a client *submit* new
/// events to this Sentry project, it grants no read access to existing
/// data (see Sentry's own docs on the DSN not being a secret).
///
/// PLACEHOLDER — swap for the real DSN from the Sentry project (org
/// `webapps-jk`, project `flutter-kb`) → Settings → Client Keys (DSN).
/// Until replaced, [dsn] is not a valid endpoint, so
/// `SentryFlutter.init` (see main.dart) will fail to authenticate and no
/// events will be sent — a release build still runs fine either way, since
/// error_reporting.dart's local debugPrint funnel doesn't depend on Sentry.
class SentryConfig {
  const SentryConfig._();

  static const dsn = 'https://REPLACE_ME@oREPLACE.ingest.de.sentry.io/REPLACE';
}
