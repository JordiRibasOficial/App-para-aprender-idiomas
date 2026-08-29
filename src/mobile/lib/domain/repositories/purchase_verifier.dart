/// Verifies a store purchase server-to-server before the app trusts it as an
/// active entitlement — see src/backend/README.md. Abstracted so
/// [InAppPurchaseSubscriptionRepository] doesn't depend on Supabase
/// directly, and so tests can inject a fake instead of hitting a real
/// backend.
abstract interface class PurchaseVerifier {
  Future<PurchaseVerificationResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    // Sent once, only if the user gave one during onboarding — used to
    // send the TRLGDCU purchase-confirmation email, never persisted
    // server-side. See src/backend/supabase/functions/verify-purchase/types.ts.
    String? email,
  });
}

class PurchaseVerificationResult {
  const PurchaseVerificationResult({required this.isActive, this.expiresAt});

  final bool isActive;
  final DateTime? expiresAt;
}
