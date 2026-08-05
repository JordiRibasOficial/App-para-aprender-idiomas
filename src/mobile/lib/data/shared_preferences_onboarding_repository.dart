import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/onboarding_state.dart';
import '../domain/repositories/onboarding_repository.dart';

class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  static const _completedKey = 'onboarding_completed';
  static const _levelKey = 'onboarding_level';
  static const _targetLanguageKey = 'onboarding_target_language';
  static const _authModeKey = 'onboarding_auth_mode';
  static const _emailKey = 'onboarding_email';

  @override
  Future<OnboardingState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_completedKey) ?? false;
    if (!completed) return const OnboardingState();

    final authModeName = prefs.getString(_authModeKey);
    return OnboardingState(
      completed: true,
      selectedLevel: prefs.getString(_levelKey),
      targetLanguage: prefs.getString(_targetLanguageKey),
      authMode: authModeName == null ? null : AuthMode.values.byName(authModeName),
      email: prefs.getString(_emailKey),
    );
  }

  @override
  Future<OnboardingState> complete({
    required String level,
    required String targetLanguage,
    required AuthMode authMode,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    await prefs.setString(_levelKey, level);
    await prefs.setString(_targetLanguageKey, targetLanguage);
    await prefs.setString(_authModeKey, authMode.name);
    if (email != null) await prefs.setString(_emailKey, email);

    return OnboardingState(
      completed: true,
      selectedLevel: level,
      targetLanguage: targetLanguage,
      authMode: authMode,
      email: email,
    );
  }
}
