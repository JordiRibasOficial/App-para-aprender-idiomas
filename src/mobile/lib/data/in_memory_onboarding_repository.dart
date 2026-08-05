import '../domain/models/onboarding_state.dart';
import '../domain/repositories/onboarding_repository.dart';

/// Session-only [OnboardingRepository] used in tests and widget previews.
class InMemoryOnboardingRepository implements OnboardingRepository {
  InMemoryOnboardingRepository({OnboardingState initialState = const OnboardingState()})
      : _state = initialState;

  OnboardingState _state;

  @override
  Future<OnboardingState> load() async => _state;

  @override
  Future<OnboardingState> complete({
    required String level,
    required String targetLanguage,
    required AuthMode authMode,
    String? email,
  }) async {
    _state = OnboardingState(
      completed: true,
      selectedLevel: level,
      targetLanguage: targetLanguage,
      authMode: authMode,
      email: email,
    );
    return _state;
  }
}
