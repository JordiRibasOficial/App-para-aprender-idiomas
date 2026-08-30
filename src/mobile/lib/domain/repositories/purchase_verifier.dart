/// Verifies a store purchase server-to-server before the app trusts it as an
/// active entitlement — see src/backend/README.md. Abstracted so
/// [InAppPurchaseSubscriptionRepository] doesn't depend on Supabase
/// directly, and so tests can inject a fake instead of hitting a real
/// backend.
abstract interface class PurchaseVerifier {
  // No email parameter: the backend now requires a real account for this
  // call (see requireAccountAccessToken) and sends the TRLGDCU
  // purchase-confirmation email to that account's own address — see
  // src/backend/supabase/functions/verify-purchase/handler.ts.
  Future<PurchaseVerificationResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
  });
}

class PurchaseVerificationResult {
  const PurchaseVerificationResult({required this.isActive, this.expiresAt});

  final bool isActive;
  final DateTime? expiresAt;
}
