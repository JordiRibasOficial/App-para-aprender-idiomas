abstract interface class TermsAcceptanceRepository {
  /// Whether the user has explicitly accepted the current version of the
  /// Terms and Privacy Policy (see [kCurrentTermsVersion]) — not just any
  /// past version. Bumping the version forces re-acceptance after a
  /// material change, the same pattern App Store/Play Store review expects.
  Future<bool> hasAcceptedCurrentVersion();

  Future<void> acceptCurrentVersion();
}

/// Bump this whenever terms-of-service-draft.md/privacy-policy-draft.md
/// change in a material way (see their own "Última actualización" date) —
/// changing it invalidates every past acceptance and shows the screen
/// again on next launch.
const kCurrentTermsVersion = '2026-08-19';
