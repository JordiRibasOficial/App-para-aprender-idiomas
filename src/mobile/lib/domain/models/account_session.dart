/// A real, authenticated Supabase Auth identity — as opposed to a guest,
/// which has none. [userId] is the Supabase `auth.users` row id; [email] is
/// always present today since email/password is the only way to create one,
/// but stays nullable for when Google/Apple/Facebook (which can return a
/// session without an email in edge cases, e.g. a private-relay Apple email
/// being withheld) are added.
class AccountSession {
  const AccountSession({required this.userId, this.email});

  final String userId;
  final String? email;
}
