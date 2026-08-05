import '../models/onboarding_state.dart';

abstract interface class OnboardingRepository {
  /// Returns the stored state, or an incomplete [OnboardingState] if
  /// onboarding was never finished.
  Future<OnboardingState> load();

  Future<OnboardingState> complete({
    required String level,
    required AuthMode authMode,
    String? email,
  });
}
