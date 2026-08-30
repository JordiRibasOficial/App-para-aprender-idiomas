import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/repositories/marketing_consent_repository.dart';

class SupabaseMarketingConsentRepository implements MarketingConsentRepository {
  const SupabaseMarketingConsentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> optIn({required String email}) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      // Can't happen through the current UI (only offered right after a
      // successful sign-up), but fail silently rather than crash: this is
      // a best-effort call, never one the caller's flow depends on.
      debugPrint('save-marketing-contact skipped: no signed-in session.');
      return;
    }

    try {
      await _client.functions.invoke(
        'save-marketing-contact',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {'email': email},
      );
    } on FunctionException catch (e) {
      debugPrint('save-marketing-contact failed: ${e.status} ${e.details}');
    }
  }
}
