import '../models/account_session.dart';

/// Result of [AccountRepository.signUpWithEmail]. Two outcomes, not one,
/// because Supabase Auth only returns a live session immediately when the
/// project has email confirmation turned off — the common default is *on*,
/// in which case sign-up creates the account but the caller isn't signed in
/// until they click the confirmation link Supabase emails them.
sealed class SignUpResult {
  const SignUpResult();
}

final class SignedIn extends SignUpResult {
  const SignedIn(this.session);
  final AccountSession session;
}

final class ConfirmationRequired extends SignUpResult {
  const ConfirmationRequired(this.email);
  final String email;
}
