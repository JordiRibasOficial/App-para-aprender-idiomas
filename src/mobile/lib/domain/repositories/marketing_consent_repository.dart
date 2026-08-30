/// Opts a just-created account into marketing email (offers, promotions,
/// news) — a separate, explicit consent from creating the account itself
/// (LSSICE art. 21 requires prior, specific consent for commercial
/// communications, distinct from accepting the terms of service). Requires
/// a real signed-in account: see save-marketing-contact's doc comment for
/// why an anonymous or guest caller can't use this.
abstract interface class MarketingConsentRepository {
  /// Best-effort by design — a failure here must never undo or block the
  /// account creation it follows. Callers should not surface its errors to
  /// the user as a blocking failure.
  Future<void> optIn({required String email});
}
