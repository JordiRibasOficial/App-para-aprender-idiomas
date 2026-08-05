import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';

void main() {
  testWidgets('tapping a lesson opens the exercise screen and grades an answer',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository())],
      child: const MyApp(),
    ));
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
}
