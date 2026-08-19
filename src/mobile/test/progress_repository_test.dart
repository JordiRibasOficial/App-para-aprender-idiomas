import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';

void main() {
  group('InMemoryProgressRepository', () {
    test('load returns empty progress when nothing was saved', () async {
      final repository = InMemoryProgressRepository();

      final progress = await repository.load('en');

      expect(progress.targetLanguage, 'en');
      expect(progress.completedLessonIds, isEmpty);
      expect(progress.currentStreakDays, 0);
      expect(progress.totalScore, 0);
      expect(progress.lastActivityDate, isNull);
    });

    test(
      'recordLessonCompletion saves and accumulates score across lessons',
      () async {
        final repository = InMemoryProgressRepository();
        final day = DateTime(2026, 1, 10);

        await repository.recordLessonCompletion(
          targetLanguage: 'en',
          lessonId: 'u1_l1',
          score: 5,
          completedAt: day,
        );
        final progress = await repository.recordLessonCompletion(
          targetLanguage: 'en',
          lessonId: 'u1_l2',
          score: 4,
          completedAt: day,
        );

        expect(progress.completedLessonIds, {'u1_l1', 'u1_l2'});
        expect(progress.totalScore, 9);
      },
    );

    test('does not mix progress between different target languages', () async {
      final repository = InMemoryProgressRepository();

      await repository.recordLessonCompletion(
        targetLanguage: 'en',
        lessonId: 'u1_l1',
        score: 5,
        completedAt: DateTime(2026, 1, 10),
      );
      final ptProgress = await repository.load('pt');

      expect(ptProgress.completedLessonIds, isEmpty);
      expect(ptProgress.totalScore, 0);
    });

    test('streak extends on the next calendar day', () async {
      final repository = InMemoryProgressRepository();

      await repository.recordLessonCompletion(
        targetLanguage: 'en',
        lessonId: 'u1_l1',
        score: 1,
        completedAt: DateTime(2026, 1, 10),
      );
      final progress = await repository.recordLessonCompletion(
        targetLanguage: 'en',
        lessonId: 'u1_l2',
        score: 1,
        completedAt: DateTime(2026, 1, 11),
      );

      expect(progress.currentStreakDays, 2);
    });

    test('streak stays the same within the same calendar day', () async {
      final repository = InMemoryProgressRepository();
      final day = DateTime(2026, 1, 10, 9);

      await repository.recordLessonCompletion(
        targetLanguage: 'en',
        lessonId: 'u1_l1',
        score: 1,
        completedAt: day,
      );
      final progress = await repository.recordLessonCompletion(
        targetLanguage: 'en',
        lessonId: 'u1_l2',
        score: 1,
        completedAt: DateTime(2026, 1, 10, 20),
      );

      expect(progress.currentStreakDays, 1);
    });

    test('streak resets to 1 after a gap of more than one day', () async {
      final repository = InMemoryProgressRepository();

      await repository.recordLessonCompletion(
        targetLanguage: 'en',
        lessonId: 'u1_l1',
        score: 1,
        completedAt: DateTime(2026, 1, 1),
      );
      final progress = await repository.recordLessonCompletion(
        targetLanguage: 'en',
        lessonId: 'u1_l2',
        score: 1,
        completedAt: DateTime(2026, 1, 10),
      );

      expect(progress.currentStreakDays, 1);
    });
  });
}
