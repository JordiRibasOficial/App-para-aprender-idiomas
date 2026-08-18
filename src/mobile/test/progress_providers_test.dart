import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';

void main() {
  test(
    'progressProvider persists lesson completion through the repository',
    () async {
      final container = ProviderContainer(
        overrides: [
          progressRepositoryProvider.overrideWithValue(
            InMemoryProgressRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the initial load (empty progress) to resolve.
      await container.read(progressProvider('en').future);

      await container
          .read(progressProvider('en').notifier)
          .completeLesson(lessonId: 'u1_l1', score: 5);

      final state = container.read(progressProvider('en')).requireValue;
      expect(state.completedLessonIds, {'u1_l1'});
      expect(state.totalScore, 5);
    },
  );

  test('progress is tracked independently per target language', () async {
    final container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(
          InMemoryProgressRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(progressProvider('en').future);
    await container.read(progressProvider('pt').future);

    await container
        .read(progressProvider('en').notifier)
        .completeLesson(lessonId: 'u1_l1', score: 5);

    expect(
      container.read(progressProvider('en')).requireValue.completedLessonIds,
      {'u1_l1'},
    );
    expect(
      container.read(progressProvider('pt')).requireValue.completedLessonIds,
      isEmpty,
    );
  });
}
