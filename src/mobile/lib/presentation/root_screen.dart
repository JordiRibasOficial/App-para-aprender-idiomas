import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lessons/lesson_list_screen.dart';
import 'onboarding/welcome_screen.dart';
import 'providers/onboarding_providers.dart';

/// Decides whether `/` shows onboarding or the lesson list, based on
/// whether onboarding has already been completed on this device.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingProvider);

    return onboardingAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('No se pudo iniciar la app: $error')),
      ),
      data: (state) => state.completed ? const LessonListScreen() : const WelcomeScreen(),
    );
  }
}
