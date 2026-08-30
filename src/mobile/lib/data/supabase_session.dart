import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when a backend call needs a real account and the caller doesn't
/// have one — see [requireAccountAccessToken].
class NoAccountException implements Exception {
  const NoAccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Returns an access token for [client]'s current session — purchase
/// verification, Premium content, and "Mis datos" all require a real
/// account now (see AuthChoiceScreen/AccountRepository), not an anonymous
/// identity: unlike a one-off anonymous sign-in, an account survives
/// reinstalling the app or switching devices, so entitlement tied to it
/// isn't silently orphaned. Throws instead of creating one on the fly —
/// callers gate on having an account first (see requireAccount in
/// presentation/account/require_account.dart) so this is a backstop, not
/// the primary UX.
Future<String> requireAccountAccessToken(SupabaseClient client) async {
  final session = client.auth.currentSession;
  if (session == null || session.user.isAnonymous) {
    throw const NoAccountException(
      'Se necesita una cuenta para esto — crea una cuenta primero.',
    );
  }
  return session.accessToken;
}
