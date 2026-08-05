import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sqlite_progress_repository.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/repositories/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return SqliteProgressRepository();
});

class EnglishProgressNotifier extends AsyncNotifier<UserProgress> {
  @override
  Future<UserProgress> build() {
    return ref.watch(progressRepositoryProvider).load('en');
  }

  Future<void> completeLesson({required String lessonId, required int score}) async {
    final repository = ref.read(progressRepositoryProvider);
    final updated = await repository.recordLessonCompletion(
      targetLanguage: 'en',
      lessonId: lessonId,
      score: score,
    );
    state = AsyncData(updated);
  }
}

final englishProgressProvider = AsyncNotifierProvider<EnglishProgressNotifier, UserProgress>(
  EnglishProgressNotifier.new,
);
