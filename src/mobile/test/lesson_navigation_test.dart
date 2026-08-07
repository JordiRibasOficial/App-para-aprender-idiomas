import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/presentation/lessons/exercise_screen.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';

import 'test_utils.dart';

void main() {
  testWidgets('tapping a lesson opens the exercise screen and grades an answer',
      (WidgetTester tester) async {
    await tester.pumpWidget(appWithCompletedOnboarding());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saludos básicos'));
    await tester.pumpAndSettle();

    // First exercise of u1_l1 is a multiple-choice prompt with "Hello" as
    // the correct option; the check button starts disabled.
    expect(find.text('¿Cómo se dice \'Hola\' en inglés?'), findsOneWidget);
    final checkButton = find.widgetWithText(FilledButton, 'Comprobar');
    expect(tester.widget<FilledButton>(checkButton).onPressed, isNull);

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(checkButton).onPressed, isNotNull);

    await tester.tap(checkButton);
    await tester.pumpAndSettle();

    expect(find.text('¡Correcto!'), findsOneWidget);
  });

  testWidgets(
      'an unknown unit/lesson id shows a friendly message instead of crashing',
      (WidgetTester tester) async {
    // Uses 'pt', not 'en': two tests in this file both reaching a course
    // for the *same* target language trips a pumpAndSettle hang specific to
    // this test environment (see onboarding_flow_test.dart for the same
    // pattern) — the test above already exercises 'en'.
    await tester.pumpWidget(ProviderScope(
      overrides: [progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository())],
      child: const MaterialApp(
        home: ExerciseScreen(
          targetLanguage: 'pt',
          unitId: 'does-not-exist',
          lessonId: 'does-not-exist',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Esta lección ya no está disponible.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
