import '../domain/models/account_session.dart';
import '../domain/repositories/account_repository.dart';
import '../domain/repositories/sign_up_result.dart';

/// Session-only [AccountRepository] used in tests and widget previews.
/// Signs up successfully by default (as if email confirmation is off);
/// configure [confirmationRequiredFor] to instead simulate the "check your
/// email" path, or [errorFor] to simulate a rejected sign-up.
class InMemoryAccountRepository implements AccountRepository {
  InMemoryAccountRepository({
    this.confirmationRequiredFor = const {},
    this.errorFor = const {},
  });

  final Set<String> confirmationRequiredFor;
  final Map<String, String> errorFor;

  final signUpCalls = <String>[];
  var _nextUserId = 0;

  @override
  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    signUpCalls.add(email);
    final error = errorFor[email];
    if (error != null) throw AccountException(error);

    if (confirmationRequiredFor.contains(email)) {
      return ConfirmationRequired(email);
    }
    return SignedIn(
      AccountSession(userId: 'fake-user-${_nextUserId++}', email: email),
    );
  }

  @override
  Future<AccountSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final error = errorFor[email];
    if (error != null) throw AccountException(error);
    return AccountSession(userId: 'fake-user-${_nextUserId++}', email: email);
  }
}
