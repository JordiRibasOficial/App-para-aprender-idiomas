import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_para_aprender_idiomas/data/shared_preferences_onboarding_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/onboarding_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesOnboardingRepository', () {
    test('load returns an incomplete state when nothing was saved', () async {
      final repository = SharedPreferencesOnboardingRepository();

      final state = await repository.load();

      expect(state.completed, isFalse);
      expect(state.selectedLevel, isNull);
      expect(state.authMode, isNull);
      expect(state.email, isNull);
    });

    test('complete persists the choice and load reads it back as guest', () async {
      final repository = SharedPreferencesOnboardingRepository();

      await repository.complete(level: 'A1', authMode: AuthMode.guest);
      final reloaded = await SharedPreferencesOnboardingRepository().load();

      expect(reloaded.completed, isTrue);
      expect(reloaded.selectedLevel, 'A1');
      expect(reloaded.authMode, AuthMode.guest);
      expect(reloaded.email, isNull);
    });

    test('complete persists the email when the auth mode is email', () async {
      final repository = SharedPreferencesOnboardingRepository();

      await repository.complete(level: 'A1', authMode: AuthMode.email, email: 'ana@example.com');
      final reloaded = await SharedPreferencesOnboardingRepository().load();

      expect(reloaded.completed, isTrue);
      expect(reloaded.authMode, AuthMode.email);
      expect(reloaded.email, 'ana@example.com');
    });
  });
}
