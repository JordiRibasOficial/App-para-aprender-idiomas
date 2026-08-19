import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when an anonymous Supabase session can't be established.
class SupabaseSessionException implements Exception {
  const SupabaseSessionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Returns an access token for [client], signing in anonymously first if
/// there's no session yet. Shared by every repository that needs to call an
/// authenticated Edge Function — this app has no real accounts (see
/// AuthChoiceScreen), so an anonymous Supabase identity is enough to
/// authenticate those calls.
Future<String> ensureAnonymousSession(SupabaseClient client) async {
  final currentSession = client.auth.currentSession;
  if (currentSession != null) return currentSession.accessToken;

  final response = await client.auth.signInAnonymously();
  final session = response.session;
  if (session == null) {
    throw const SupabaseSessionException(
      'No se pudo iniciar sesión anónima con Supabase.',
    );
  }
  return session.accessToken;
}
