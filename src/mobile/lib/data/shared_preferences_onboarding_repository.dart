import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/onboarding_state.dart';
import '../domain/repositories/onboarding_repository.dart';

/// `AuthMode.values.byName` throws on anything that isn't an exact current
/// enum name — a real risk for data that outlives the code that wrote it
/// (a future rename, or SharedPreferences corruption). Treating stored
/// state as untrusted boundary data here, same as any other external input,
/// instead of letting a stale value permanently strand a returning user on
/// [RootScreen]'s error branch with no in-app way to recover.
AuthMode? _authModeFromName(String? name) {
  if (name == null) return null;
  for (final mode in AuthMode.values) {
    if (mode.name == name) return mode;
  }
  return null;
}

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

    return OnboardingState(
      completed: true,
      selectedLevel: prefs.getString(_levelKey),
      targetLanguage: prefs.getString(_targetLanguageKey),
      authMode: _authModeFromName(prefs.getString(_authModeKey)),
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
