import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/asset_content_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/exercise.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetContentRepository', () {
    for (final targetLanguage in ['en', 'pt', 'fr', 'ja']) {
      test('loads the $targetLanguage course with at least 5 well-formed units', () async {
        final repository = AssetContentRepository();

        final course = await repository.loadCourse(
          sourceLanguage: 'es',
          targetLanguage: targetLanguage,
        );

        expect(course.sourceLanguage, 'es');
        expect(course.targetLanguage, targetLanguage);
        expect(course.level, 'A1');
        expect(course.units.length, greaterThanOrEqualTo(5));

        for (final unit in course.units) {
          expect(unit.id, isNotEmpty);
          expect(unit.title, isNotEmpty);
          expect(unit.lessons, isNotEmpty);

          for (final lesson in unit.lessons) {
            expect(lesson.id, isNotEmpty);
            expect(lesson.title, isNotEmpty);
            expect(lesson.exercises, isNotEmpty);

            for (final exercise in lesson.exercises) {
              expect(exercise.id, isNotEmpty);
              expect(exercise.prompt, isNotEmpty);

              switch (exercise.type) {
                case ExerciseType.multipleChoice:
                  expect(exercise.options, isNotEmpty);
                  expect(exercise.options, contains(exercise.correctAnswer));
                case ExerciseType.fillBlank:
                  expect(exercise.correctAnswer, isNotEmpty);
                case ExerciseType.matching:
                  expect(exercise.pairs, isNotEmpty);
              }
            }
          }
        }
      });
    }

    test('all exercise ids are unique within each course (no copy-paste id collisions)', () async {
      final repository = AssetContentRepository();

      for (final targetLanguage in ['en', 'pt', 'fr', 'ja']) {
        final course = await repository.loadCourse(
          sourceLanguage: 'es',
          targetLanguage: targetLanguage,
        );

        final allExerciseIds = [
          for (final unit in course.units)
            for (final lesson in unit.lessons)
              for (final exercise in lesson.exercises) exercise.id,
        ];

        expect(
          allExerciseIds.toSet().length,
          allExerciseIds.length,
          reason: 'Duplicate exercise id found in $targetLanguage.json',
        );
      }
    });

    test('throws when the source language does not match the asset', () async {
      final repository = AssetContentRepository();

      expect(
        () => repository.loadCourse(sourceLanguage: 'fr', targetLanguage: 'en'),
        throwsStateError,
      );
    });
  });
}
