import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/asset_content_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/exercise.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetContentRepository', () {
    test('loads the English course with at least 5 units', () async {
      final repository = AssetContentRepository();

      final course = await repository.loadCourse(
        sourceLanguage: 'es',
        targetLanguage: 'en',
      );

      expect(course.sourceLanguage, 'es');
      expect(course.targetLanguage, 'en');
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

    test('throws when the source language does not match the asset', () async {
      final repository = AssetContentRepository();

      expect(
        () => repository.loadCourse(sourceLanguage: 'fr', targetLanguage: 'en'),
        throwsStateError,
      );
    });
  });
}
