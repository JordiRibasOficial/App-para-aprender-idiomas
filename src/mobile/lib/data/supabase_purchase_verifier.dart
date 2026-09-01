import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/repositories/purchase_verifier.dart';
import 'supabase_session.dart';

/// Thrown when the verify-purchase call can't be completed — network
/// failure, a non-2xx response, or a malformed body. The caller (see
/// [InAppPurchaseSubscriptionRepository]) treats this the same as a
/// negative verification result: never grant entitlement on an error.
class PurchaseVerificationException implements Exception {
  const PurchaseVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Calls the `verify-purchase` Supabase Edge Function — see
/// src/backend/README.md for what it does server-side. Requires a real
/// account (see AuthChoiceScreen/AccountRepository) — callers gate on
/// [requireAccount] before this is ever reached; see
/// [requireAccountAccessToken]'s doc comment for why entitlement is tied to
/// an account rather than an anonymous session.
class SupabasePurchaseVerifier implements PurchaseVerifier {
  const SupabasePurchaseVerifier(this._client);

  final SupabaseClient _client;

  @override
  Future<PurchaseVerificationResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
  }) async {
    final accessToken = await requireAccountAccessToken(_client);

    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'verify-purchase',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'platform': platform,
          'productId': productId,
          'purchaseToken': purchaseToken,
        },
      );
    } on FunctionException catch (e) {
      // 409 is the one status here a user can actually act on: the backend
      // binds a store purchase to the first account that claims it (see
      // src/backend/README.md § "Purchase ownership"), so this means the
      // purchase is genuinely theirs-but-on-another-account, or someone
      // else's. Everything else stays a raw diagnostic — those are bugs or
      // outages, not something the user can resolve.
      if (e.status == 409) {
        throw const PurchaseVerificationException(
          'Esta compra ya está asociada a otra cuenta. Inicia sesión con esa '
          'cuenta para restaurarla.',
        );
      }
      throw PurchaseVerificationException(
        'verify-purchase respondió ${e.status}: ${e.details}',
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const PurchaseVerificationException(
        'verify-purchase devolvió una respuesta con formato inesperado.',
      );
    }

    final expiresAtRaw = data['expiresAt'];
    return PurchaseVerificationResult(
      isActive: data['status'] == 'active',
      expiresAt: expiresAtRaw is String ? DateTime.parse(expiresAtRaw) : null,
    );
  }
}
