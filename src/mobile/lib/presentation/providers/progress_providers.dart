import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sqlite_progress_repository.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/repositories/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return SqliteProgressRepository();
});

class ProgressNotifier extends AsyncNotifier<UserProgress> {
  ProgressNotifier(this.targetLanguage);

  final String targetLanguage;

  @override
  Future<UserProgress> build() {
    return ref.watch(progressRepositoryProvider).load(targetLanguage);
  }

  Future<void> completeLesson({
    required String lessonId,
    required int score,
  }) async {
    final repository = ref.read(progressRepositoryProvider);
    final updated = await repository.recordLessonCompletion(
      targetLanguage: targetLanguage,
      lessonId: lessonId,
      score: score,
    );
    state = AsyncData(updated);
  }
}

final progressProvider =
    AsyncNotifierProvider.family<ProgressNotifier, UserProgress, String>(
      ProgressNotifier.new,
    );
