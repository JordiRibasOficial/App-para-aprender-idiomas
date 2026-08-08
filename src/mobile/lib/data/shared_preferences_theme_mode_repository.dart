import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/app_theme_mode.dart';
import '../domain/repositories/theme_mode_repository.dart';

/// Same defensive lookup as `_authModeFromName` in the onboarding
/// repository: a stale value from a future/older app version shouldn't
/// throw, it should just fall back to the default.
AppThemeMode _fromName(String? name) {
  if (name == null) return AppThemeMode.system;
  for (final mode in AppThemeMode.values) {
    if (mode.name == name) return mode;
  }
  return AppThemeMode.system;
}

class SharedPreferencesThemeModeRepository implements ThemeModeRepository {
  static const _key = 'theme_mode';

  @override
  Future<AppThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _fromName(prefs.getString(_key));
  }

  @override
  Future<void> save(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
