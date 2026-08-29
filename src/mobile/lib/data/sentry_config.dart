/// Sentry project DSN — safe to ship in the compiled app, same as
/// [SupabaseConfig.publishableKey]: a DSN only lets a client *submit* new
/// events to this Sentry project, it grants no read access to existing
/// data (see Sentry's own docs on the DSN not being a secret).
///
/// Sentry project: org `webapps-jk`, project `flutter-kb`, EU region
/// (`ingest.de.sentry.io`) — see docs/business/crash-reporting-review.md.
class SentryConfig {
  const SentryConfig._();

  static const dsn =
      'https://46cfb4b5be6fbf25e59142ffeaf28af1@o4511994925678592.ingest.de.sentry.io/4511994974437456';
}
