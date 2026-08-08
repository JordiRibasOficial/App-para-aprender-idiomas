import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/shared_preferences_theme_mode_repository.dart';
import '../../domain/models/app_theme_mode.dart';
import '../../domain/repositories/theme_mode_repository.dart';

final themeModeRepositoryProvider = Provider<ThemeModeRepository>((ref) {
  return SharedPreferencesThemeModeRepository();
});

class ThemeModeNotifier extends AsyncNotifier<AppThemeMode> {
  @override
  Future<AppThemeMode> build() {
    return ref.watch(themeModeRepositoryProvider).load();
  }

  Future<void> setMode(AppThemeMode mode) async {
    await ref.read(themeModeRepositoryProvider).save(mode);
    state = AsyncData(mode);
  }

  /// Single-tap toggle for the app bar icon: system -> light -> dark -> system.
  Future<void> cycle() async {
    final current = state.value ?? AppThemeMode.system;
    final next = switch (current) {
      AppThemeMode.system => AppThemeMode.light,
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.system,
    };
    await setMode(next);
  }
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, AppThemeMode>(
      ThemeModeNotifier.new,
    );

extension AppThemeModeMapping on AppThemeMode {
  ThemeMode get flutterThemeMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
