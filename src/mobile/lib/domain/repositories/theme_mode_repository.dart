import '../models/app_theme_mode.dart';

abstract interface class ThemeModeRepository {
  /// Returns the stored preference, or [AppThemeMode.system] if the user
  /// never overrode it.
  Future<AppThemeMode> load();

  Future<void> save(AppThemeMode mode);
}
