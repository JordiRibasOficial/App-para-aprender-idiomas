import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/shared_preferences_onboarding_repository.dart';
import '../../domain/models/onboarding_state.dart';
import '../../domain/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return SharedPreferencesOnboardingRepository();
});

class OnboardingNotifier extends AsyncNotifier<OnboardingState> {
  @override
  Future<OnboardingState> build() {
    return ref.watch(onboardingRepositoryProvider).load();
  }

  Future<void> complete({
    required String level,
    required String targetLanguage,
    required AuthMode authMode,
    String? email,
  }) async {
    final repository = ref.read(onboardingRepositoryProvider);
    final updated = await repository.complete(
      level: level,
      targetLanguage: targetLanguage,
      authMode: authMode,
      email: email,
    );
    state = AsyncData(updated);
  }
}

final onboardingProvider =
    AsyncNotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

/// Transient selection made on the level screen, read by the auth-choice
/// screen when it calls [OnboardingNotifier.complete].
class SelectedLevelNotifier extends Notifier<String> {
  @override
  String build() => 'A1';

  void select(String level) => state = level;
}

final onboardingSelectedLevelProvider =
    NotifierProvider<SelectedLevelNotifier, String>(SelectedLevelNotifier.new);

/// Transient selection made on the language screen, read by the auth-choice
/// screen when it calls [OnboardingNotifier.complete].
class SelectedLanguageNotifier extends Notifier<String> {
  @override
  String build() => 'en';

  void select(String targetLanguage) => state = targetLanguage;
}

final onboardingSelectedLanguageProvider =
    NotifierProvider<SelectedLanguageNotifier, String>(
      SelectedLanguageNotifier.new,
    );
