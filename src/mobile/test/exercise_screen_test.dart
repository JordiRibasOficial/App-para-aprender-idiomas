import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/course.dart';
import 'package:app_para_aprender_idiomas/domain/models/course_unit.dart';
import 'package:app_para_aprender_idiomas/domain/models/exercise.dart';
import 'package:app_para_aprender_idiomas/domain/models/lesson.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/content_repository.dart';
import 'package:app_para_aprender_idiomas/presentation/lessons/exercise_screen.dart';
import 'package:app_para_aprender_idiomas/presentation/lessons/lesson_summary_data.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/content_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';

/// Always returns [course], ignoring the requested language — the widget
/// tests below only ever ask for one target language at a time.
class _FakeContentRepository implements ContentRepository {
  _FakeContentRepository(this.course);

  final Course course;

  @override
  Future<Course> loadCourse({
    required String sourceLanguage,
    required String targetLanguage,
  }) async => course;
}

class _FailingContentRepository implements ContentRepository {
  @override
  Future<Course> loadCourse({
    required String sourceLanguage,
    required String targetLanguage,
  }) => Future.error(StateError('course asset missing'));
}

const _targetLanguage = 'en';
const _unitId = 'u1';
const _lessonId = 'l1';

Course _courseWith(List<Exercise> exercises) {
  return Course(
    sourceLanguage: 'es',
    targetLanguage: _targetLanguage,
    level: 'A1',
    units: [
      CourseUnit(
        id: _unitId,
        title: 'Unidad de prueba',
        lessons: [
          Lesson(
            id: _lessonId,
            title: 'Lección de prueba',
            exercises: exercises,
          ),
        ],
      ),
    ],
  );
}

/// Wires up just enough of the real app (router + providers) for
/// ExerciseScreen to run standalone: a GoRouter so `_next()`'s
/// `context.go(...)` to the summary route resolves, and fakes for both
/// providers ExerciseScreen depends on transitively.
Widget buildExerciseScreen(ContentRepository contentRepository) {
  final router = GoRouter(
    initialLocation: '/lesson/$_targetLanguage/$_unitId/$_lessonId',
    routes: [
      GoRoute(
        path: '/lesson/:targetLanguage/:unitId/:lessonId',
        builder: (context, state) => const ExerciseScreen(
          targetLanguage: _targetLanguage,
          unitId: _unitId,
          lessonId: _lessonId,
        ),
      ),
      GoRoute(
        path: '/lesson/:targetLanguage/:unitId/:lessonId/summary',
        builder: (context, state) {
          final data = state.extra as LessonSummaryData;
          return Scaffold(body: Text('Resumen: ${data.score}/${data.total}'));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      contentRepositoryProvider.overrideWithValue(contentRepository),
      progressRepositoryProvider.overrideWithValue(
        InMemoryProgressRepository(),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets(
    'answering incorrectly shows the correct answer and does not award a point',
    (tester) async {
      await tester.pumpWidget(
        buildExerciseScreen(
          _FakeContentRepository(
            _courseWith([
              const Exercise(
                id: 'e1',
                type: ExerciseType.multipleChoice,
                prompt: '¿Cómo se dice \'Hola\'?',
                correctAnswer: 'Hello',
                options: ['Hello', 'Goodbye'],
              ),
              const Exercise(
                id: 'e2',
                type: ExerciseType.multipleChoice,
                prompt: 'Segunda pregunta',
                correctAnswer: 'Yes',
                options: ['Yes', 'No'],
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Goodbye'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Comprobar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Incorrecto'), findsOneWidget);
      expect(find.textContaining('Hello'), findsWidgets);

      // Advancing off a wrong answer must still work — grading a question
      // wrong isn't a dead end.
      await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Segunda pregunta'), findsOneWidget);
    },
  );

  testWidgets('a fillBlank exercise grades the typed answer', (tester) async {
    await tester.pumpWidget(
      buildExerciseScreen(
        _FakeContentRepository(
          _courseWith([
            const Exercise(
              id: 'e1',
              type: ExerciseType.fillBlank,
              prompt: 'Good ___, see you tomorrow!',
              correctAnswer: 'night',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'night');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Comprobar'));
    await tester.pumpAndSettle();

    expect(find.text('¡Correcto!'), findsOneWidget);
  });

  testWidgets(
    'a matching exercise only becomes submittable once every pair is chosen, then grades correctly',
    (tester) async {
      await tester.pumpWidget(
        buildExerciseScreen(
          _FakeContentRepository(
            _courseWith([
              const Exercise(
                id: 'e1',
                type: ExerciseType.matching,
                prompt: 'Une cada saludo',
                correctAnswer: '',
                pairs: {'Hola': 'Hello', 'Adiós': 'Goodbye'},
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkButton = find.widgetWithText(FilledButton, 'Comprobar');
      expect(tester.widget<FilledButton>(checkButton).onPressed, isNull);

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(dropdowns, findsNWidgets(2));

      await tester.tap(dropdowns.at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hello').last);
      await tester.pumpAndSettle();

      // Still incomplete with only one of two pairs chosen.
      expect(tester.widget<FilledButton>(checkButton).onPressed, isNull);

      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Goodbye').last);
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(checkButton).onPressed, isNotNull);

      await tester.tap(checkButton);
      await tester.pumpAndSettle();

      expect(find.text('¡Correcto!'), findsOneWidget);
    },
  );

  testWidgets(
    'finishing the last exercise navigates to the summary route with the real score',
    (tester) async {
      await tester.pumpWidget(
        buildExerciseScreen(
          _FakeContentRepository(
            _courseWith([
              const Exercise(
                id: 'e1',
                type: ExerciseType.multipleChoice,
                prompt: 'Única pregunta',
                correctAnswer: 'Sí',
                options: ['Sí', 'No'],
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sí'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Comprobar'));
      await tester.pumpAndSettle();

      // A one-exercise lesson's only button reads "Terminar", not
      // "Siguiente" — there's nothing left to advance to.
      await tester.tap(find.widgetWithText(FilledButton, 'Terminar'));
      await tester.pumpAndSettle();

      expect(find.text('Resumen: 1/1'), findsOneWidget);
      expect(find.byType(ExerciseScreen), findsNothing);
    },
  );

  testWidgets(
    'a course that fails to load shows a friendly message instead of a blank screen',
    (tester) async {
      await tester.pumpWidget(buildExerciseScreen(_FailingContentRepository()));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No se pudo cargar la lección'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
