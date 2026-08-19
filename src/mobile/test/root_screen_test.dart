import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/domain/models/onboarding_state.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/onboarding_repository.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/onboarding_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/root_screen.dart';

/// Fails every [load] call — the only way to reach RootScreen's `error:`
/// branch, which InMemoryOnboardingRepository can't simulate.
class _FailingOnboardingRepository implements OnboardingRepository {
  @override
  Future<OnboardingState> load() => Future.error(StateError('disk is full'));

  @override
  Future<OnboardingState> complete({
    required String level,
    required String targetLanguage,
    required AuthMode authMode,
    String? email,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets(
    'shows a friendly error instead of a blank screen when onboarding state fails to load',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(
              _FailingOnboardingRepository(),
            ),
          ],
          child: const MaterialApp(home: RootScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No se pudo iniciar la app'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
