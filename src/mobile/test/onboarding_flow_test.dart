import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_onboarding_repository.dart';
import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/onboarding_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';

void main() {
  testWidgets('a new install shows the welcome screen, not the lesson list',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
        onboardingRepositoryProvider.overrideWithValue(InMemoryOnboardingRepository()),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('App para Aprender Idiomas'), findsOneWidget);
    expect(find.text('Inglés · A1'), findsNothing);
  });

  testWidgets(
      'completing onboarding as a guest reaches the lesson list and persists the choice',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
        onboardingRepositoryProvider.overrideWithValue(InMemoryOnboardingRepository()),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cuál es tu nivel?'), findsOneWidget);

    // A1 is preselected and the only available level.
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo quieres continuar?'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Continuar como invitado'));
    await tester.pumpAndSettle();

    expect(find.text('Inglés · A1'), findsOneWidget);
  });
}
