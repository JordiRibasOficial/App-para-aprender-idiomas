import '../models/account_session.dart';
import 'sign_up_result.dart';

/// Thrown by [AccountRepository] methods on invalid credentials, a
/// duplicate email, a weak password, or a network failure — the caller
/// shows [message] inline rather than a generic error.
class AccountException implements Exception {
  const AccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Real user accounts (Supabase Auth) — email/password today, Google/Apple/
/// Facebook to follow in later rounds. Deliberately separate from
/// [OnboardingRepository]: onboarding is local, one-shot, device-only
/// bookkeeping, while this talks to a real backend identity that entitlement
/// (subscriptions), premium content, and data export/deletion all key off.
abstract interface class AccountRepository {
  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<AccountSession> signInWithEmail({
    required String email,
    required String password,
  });
}
