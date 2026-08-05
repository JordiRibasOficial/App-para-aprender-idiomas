import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';

void main() {
  test('englishProgressProvider persists lesson completion through the repository', () async {
    final container = ProviderContainer(
      overrides: [progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository())],
    );
    addTearDown(container.dispose);

    // Wait for the initial load (empty progress) to resolve.
    await container.read(englishProgressProvider.future);

    await container
        .read(englishProgressProvider.notifier)
        .completeLesson(lessonId: 'u1_l1', score: 5);

    final state = container.read(englishProgressProvider).requireValue;
    expect(state.completedLessonIds, {'u1_l1'});
    expect(state.totalScore, 5);
  });
}
