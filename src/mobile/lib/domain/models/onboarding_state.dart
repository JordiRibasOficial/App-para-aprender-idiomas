enum AuthMode { guest, email }

/// Onboarding never talks to a backend in the MVP — [AuthMode.email] only
/// means "I gave you an email to reach me at later", not a real account.
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
