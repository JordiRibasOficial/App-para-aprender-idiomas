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
/// src/backend/README.md for what it does server-side. Signs the user in
/// anonymously if there's no session yet: this app has no real accounts
/// (see AuthChoiceScreen), so an anonymous Supabase identity is enough to
/// tie a purchase to a device and is upgradable later via identity linking.
class SupabasePurchaseVerifier implements PurchaseVerifier {
  const SupabasePurchaseVerifier(this._client);

  final SupabaseClient _client;

  @override
  Future<PurchaseVerificationResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? email,
  }) async {
    final accessToken = await ensureAnonymousSession(_client);

    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'verify-purchase',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'platform': platform,
          'productId': productId,
          'purchaseToken': purchaseToken,
          'email': ?email,
        },
      );
    } on FunctionException catch (e) {
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
