import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

/// Reads/writes the onboarding email. Split out from
/// [SharedPreferencesOnboardingRepository] so tests can inject an in-memory
/// fake instead of exercising the real secure-storage platform channel.
abstract interface class SecureEmailStore {
  Future<String?> read();
  Future<void> write(String value);
}

/// Backs [SecureEmailStore] with `flutter_secure_storage` — Keychain on iOS,
/// EncryptedSharedPreferences on Android — so the user's email (PII) isn't
/// sitting in a plaintext prefs file on disk.
class _FlutterSecureEmailStore implements SecureEmailStore {
  const _FlutterSecureEmailStore();

  static const _storage = FlutterSecureStorage();
  static const _key = 'onboarding_email';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  SharedPreferencesOnboardingRepository({SecureEmailStore? secureEmailStore})
    : _secureEmailStore = secureEmailStore ?? const _FlutterSecureEmailStore();

  static const _completedKey = 'onboarding_completed';
  static const _levelKey = 'onboarding_level';
  static const _targetLanguageKey = 'onboarding_target_language';
  static const _authModeKey = 'onboarding_auth_mode';

  final SecureEmailStore _secureEmailStore;

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
      email: await _secureEmailStore.read(),
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
    if (email != null) await _secureEmailStore.write(email);

    return OnboardingState(
      completed: true,
      selectedLevel: level,
      targetLanguage: targetLanguage,
      authMode: authMode,
      email: email,
    );
  }
}
