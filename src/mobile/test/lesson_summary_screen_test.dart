import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_para_aprender_idiomas/presentation/lessons/lesson_summary_data.dart';
import 'package:app_para_aprender_idiomas/presentation/lessons/lesson_summary_screen.dart';

void main() {
  // context.go('/') needs an ancestor GoRouter — a plain MaterialApp isn't
  // enough. A two-route router (summary + a marker home) also lets the
  // "Volver a las lecciones" test assert real navigation happened, not just
  // that the tap didn't throw.
  Widget buildSummary(LessonSummaryData data) {
    final router = GoRouter(
      initialLocation: '/summary',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Lista de lecciones')),
        ),
        GoRoute(
          path: '/summary',
          builder: (context, state) => LessonSummaryScreen(data: data),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('a high score shows the "excellent" outcome', (tester) async {
    await tester.pumpWidget(
      buildSummary(
        const LessonSummaryData(
          unitId: 'u1',
          lessonTitle: 'Saludos básicos',
          score: 5,
          total: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Excelente!'), findsOneWidget);
    expect(find.text('Dominas esta lección.'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('5 de 5 correctas'), findsOneWidget);
  });

  testWidgets('a middling score shows the "good job" outcome', (tester) async {
    await tester.pumpWidget(
      buildSummary(
        const LessonSummaryData(
          unitId: 'u1',
          lessonTitle: 'Saludos básicos',
          score: 3,
          total: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Buen trabajo!'), findsOneWidget);
    expect(find.text('Vas por buen camino.'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('3 de 5 correctas'), findsOneWidget);
  });

  testWidgets('a low score shows the "keep practicing" outcome', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSummary(
        const LessonSummaryData(
          unitId: 'u1',
          lessonTitle: 'Saludos básicos',
          score: 1,
          total: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sigue practicando'), findsOneWidget);
    expect(find.text('Repasa esta lección cuando quieras.'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
  });

  testWidgets('a lesson with zero exercises does not divide by zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSummary(
        const LessonSummaryData(
          unitId: 'u1',
          lessonTitle: 'Vacía',
          score: 0,
          total: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Volver a las lecciones" navigates back to the lesson list', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSummary(
        const LessonSummaryData(
          unitId: 'u1',
          lessonTitle: 'Saludos básicos',
          score: 5,
          total: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volver a las lecciones'));
    await tester.pumpAndSettle();

    expect(find.text('Lista de lecciones'), findsOneWidget);
    expect(find.byType(LessonSummaryScreen), findsNothing);
  });
}
