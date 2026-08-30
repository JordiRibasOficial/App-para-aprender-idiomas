enum AuthMode { guest, account }

/// [AuthMode.account] means a real Supabase Auth identity (see
/// AccountRepository) — not just a contact email. [email] is that account's
/// address when [authMode] is [AuthMode.account]; unset for guests.
/// [selectedLevel] is captured for future use once more than the A1 course
/// exists; it doesn't drive any content branching yet.
class OnboardingState {
  const OnboardingState({
    this.completed = false,
    this.selectedLevel,
    this.targetLanguage,
    this.authMode,
    this.email,
  });

  final bool completed;
  final String? selectedLevel;

  /// Course code chosen on the language-selection screen (`en`/`pt`/`fr`/`ja`).
  final String? targetLanguage;
  final AuthMode? authMode;
  final String? email;
}
