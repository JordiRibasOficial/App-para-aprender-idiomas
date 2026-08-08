/// Pure-Dart mirror of Flutter's `ThemeMode` — the domain layer can't import
/// `package:flutter`, so this is what gets persisted and mapped to
/// `ThemeMode` at the presentation layer (see `theme_mode_providers.dart`).
enum AppThemeMode { system, light, dark }
