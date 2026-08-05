import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_onboarding_repository.dart';
import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/onboarding_state.dart';
import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/onboarding_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';

/// Wraps [MyApp] with in-memory repositories and onboarding already
/// completed, so tests land directly on the lesson list like most of the
/// suite expects. Tests that specifically exercise onboarding should build
/// their own [ProviderScope] instead.
Widget appWithCompletedOnboarding() {
  return ProviderScope(
    overrides: [
      progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
      onboardingRepositoryProvider.overrideWithValue(
        InMemoryOnboardingRepository(
          initialState: const OnboardingState(
            completed: true,
            selectedLevel: 'A1',
            targetLanguage: 'en',
            authMode: AuthMode.guest,
          ),
        ),
      ),
    ],
    child: const MyApp(),
  );
}
