import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
