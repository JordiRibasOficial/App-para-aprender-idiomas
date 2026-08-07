import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/domain/models/course.dart';
import 'package:app_para_aprender_idiomas/domain/models/course_unit.dart';
import 'package:app_para_aprender_idiomas/domain/models/exercise.dart';
import 'package:app_para_aprender_idiomas/domain/models/lesson.dart';
import 'package:app_para_aprender_idiomas/domain/models/user_progress.dart';

void main() {
  group('Exercise JSON round-trip', () {
    test('multipleChoice', () {
      const exercise = Exercise(
        id: 'e1',
        type: ExerciseType.multipleChoice,
        prompt: 'prompt',
        correctAnswer: 'Hello',
        options: ['Hello', 'Goodbye'],
      );

      final roundTripped = Exercise.fromJson(exercise.toJson());

      expect(roundTripped.id, exercise.id);
      expect(roundTripped.type, ExerciseType.multipleChoice);
      expect(roundTripped.correctAnswer, 'Hello');
      expect(roundTripped.options, ['Hello', 'Goodbye']);
    });

    test('matching', () {
      const exercise = Exercise(
        id: 'e2',
        type: ExerciseType.matching,
        prompt: 'prompt',
        correctAnswer: '',
        pairs: {'Hola': 'Hello'},
      );

      final roundTripped = Exercise.fromJson(exercise.toJson());

      expect(roundTripped.type, ExerciseType.matching);
      expect(roundTripped.pairs, {'Hola': 'Hello'});
    });

    test('fromJson defaults missing optional fields to empty', () {
      final exercise = Exercise.fromJson({
        'id': 'e3',
        'type': 'fillBlank',
        'prompt': 'prompt',
      });

      expect(exercise.correctAnswer, '');
      expect(exercise.options, isEmpty);
      expect(exercise.pairs, isEmpty);
    });
  });

  test('Lesson and CourseUnit JSON round-trip', () {
    const lesson = Lesson(
      id: 'l1',
      title: 'Lesson 1',
      exercises: [
        Exercise(id: 'e1', type: ExerciseType.fillBlank, prompt: 'p', correctAnswer: 'a'),
      ],
    );
    const unit = CourseUnit(id: 'u1', title: 'Unit 1', lessons: [lesson]);

    final roundTripped = CourseUnit.fromJson(unit.toJson());

    expect(roundTripped.id, 'u1');
    expect(roundTripped.lessons, hasLength(1));
    expect(roundTripped.lessons.single.exercises.single.correctAnswer, 'a');
  });

  test('Course JSON round-trip', () {
    const course = Course(
      sourceLanguage: 'es',
      targetLanguage: 'en',
      level: 'A1',
      units: [
        CourseUnit(id: 'u1', title: 'Unit 1', lessons: []),
      ],
    );

    final roundTripped = Course.fromJson(course.toJson());

    expect(roundTripped.sourceLanguage, 'es');
    expect(roundTripped.targetLanguage, 'en');
    expect(roundTripped.level, 'A1');
    expect(roundTripped.units, hasLength(1));
  });

  group('UserProgress', () {
    test('JSON round-trip preserves every field, including lastActivityDate', () {
      final progress = UserProgress(
        targetLanguage: 'en',
        completedLessonIds: const {'u1_l1', 'u1_l2'},
        currentStreakDays: 3,
        totalScore: 42,
        lastActivityDate: DateTime(2026, 1, 10),
      );

      final roundTripped = UserProgress.fromJson(progress.toJson());

      expect(roundTripped.targetLanguage, 'en');
      expect(roundTripped.completedLessonIds, {'u1_l1', 'u1_l2'});
      expect(roundTripped.currentStreakDays, 3);
      expect(roundTripped.totalScore, 42);
      expect(roundTripped.lastActivityDate, DateTime(2026, 1, 10));
    });

    test('toJson omits lastActivityDate when null, fromJson tolerates that', () {
      const progress = UserProgress(targetLanguage: 'en');

      final json = progress.toJson();
      expect(json.containsKey('lastActivityDate'), isFalse);

      final roundTripped = UserProgress.fromJson(json);
      expect(roundTripped.lastActivityDate, isNull);
    });

    test('copyWith only overrides the fields passed', () {
      const progress = UserProgress(targetLanguage: 'en', totalScore: 10);

      final updated = progress.copyWith(totalScore: 20);

      expect(updated.targetLanguage, 'en');
      expect(updated.totalScore, 20);
      expect(updated.currentStreakDays, progress.currentStreakDays);
    });

    test('nextStreak treats a corrupt 0 previous streak on the same day as 1', () {
      final streak = UserProgress.nextStreak(
        previousActivityDate: DateTime(2026, 1, 10),
        completedAt: DateTime(2026, 1, 10),
        previousStreak: 0,
      );

      expect(streak, 1);
    });

    // nextStreak computes the gap via UTC calendar-day arithmetic
    // (_daysSinceEpoch), not DateTime.difference().inDays on local
    // midnights — the latter floors to 0 instead of 1 across a DST
    // spring-forward day (23 wall-clock hours long), wrongly flatlining the
    // streak. This sandbox's system timezone is fixed to UTC (no DST ever
    // occurs here), so a real spring-forward transition can't be
    // constructed and verified in this test; these cases instead lock down
    // the calendar-day math at the boundaries most likely to expose an
    // off-by-one in that kind of rewrite.
    test('nextStreak extends across a month boundary', () {
      final streak = UserProgress.nextStreak(
        previousActivityDate: DateTime(2026, 1, 31),
        completedAt: DateTime(2026, 2, 1),
        previousStreak: 5,
      );

      expect(streak, 6);
    });

    test('nextStreak extends across a year boundary', () {
      final streak = UserProgress.nextStreak(
        previousActivityDate: DateTime(2025, 12, 31),
        completedAt: DateTime(2026, 1, 1),
        previousStreak: 5,
      );

      expect(streak, 6);
    });

    test('nextStreak extends across a leap day', () {
      final streak = UserProgress.nextStreak(
        previousActivityDate: DateTime(2024, 2, 29),
        completedAt: DateTime(2024, 3, 1),
        previousStreak: 5,
      );

      expect(streak, 6);
    });

    test('nextStreak resets when the gap spans a month boundary', () {
      final streak = UserProgress.nextStreak(
        previousActivityDate: DateTime(2026, 1, 29),
        completedAt: DateTime(2026, 2, 1),
        previousStreak: 5,
      );

      expect(streak, 1);
    });
  });
}
