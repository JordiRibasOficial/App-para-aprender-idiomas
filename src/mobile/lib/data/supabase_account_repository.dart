import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/account_session.dart';
import '../domain/repositories/account_repository.dart';
import '../domain/repositories/sign_up_result.dart';

class SupabaseAccountRepository implements AccountRepository {
  const SupabaseAccountRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final AuthResponse response;
    try {
      response = await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw AccountException(e.message);
    }

    final session = response.session;
    final user = response.user;
    if (session != null && user != null) {
      return SignedIn(AccountSession(userId: user.id, email: user.email));
    }
    // No session back: the project requires email confirmation (the
    // Supabase default) — the account exists but isn't usable yet.
    return ConfirmationRequired(email);
  }

  @override
  Future<AccountSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final AuthResponse response;
    try {
      response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw AccountException(e.message);
    }

    final session = response.session;
    final user = response.user;
    if (session == null || user == null) {
      throw const AccountException('No se pudo iniciar sesión.');
    }
    return AccountSession(userId: user.id, email: user.email);
  }
}
