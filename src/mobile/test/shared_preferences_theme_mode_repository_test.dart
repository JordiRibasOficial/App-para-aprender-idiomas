import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_para_aprender_idiomas/data/shared_preferences_theme_mode_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/app_theme_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesThemeModeRepository', () {
    test('load defaults to system when nothing was saved', () async {
      final repository = SharedPreferencesThemeModeRepository();

      final mode = await repository.load();

      expect(mode, AppThemeMode.system);
    });

    test('save persists the choice and load reads it back', () async {
      final repository = SharedPreferencesThemeModeRepository();

      await repository.save(AppThemeMode.dark);
      final reloaded = await SharedPreferencesThemeModeRepository().load();

      expect(reloaded, AppThemeMode.dark);
    });

    test('load tolerates a value that no longer matches a current enum name '
        'instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        // Simulates data written by a future/older app version whose
        // AppThemeMode enum doesn't match this build's — e.g. a renamed value.
        'theme_mode': 'sepia',
      });
      final repository = SharedPreferencesThemeModeRepository();

      final mode = await repository.load();

      expect(mode, AppThemeMode.system);
    });
  });
}
