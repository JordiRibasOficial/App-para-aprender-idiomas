import '../domain/models/user_progress.dart';
import '../domain/repositories/progress_repository.dart';

/// Session-only [ProgressRepository] used in tests and as a fallback where a
/// real database isn't available (e.g. widget tests without platform
/// channels).
class InMemoryProgressRepository implements ProgressRepository {
  final Map<String, UserProgress> _byLanguage = {};

  @override
  Future<UserProgress> load(String targetLanguage) async {
    return _byLanguage[targetLanguage] ??
        UserProgress(targetLanguage: targetLanguage);
  }

  @override
  Future<UserProgress> recordLessonCompletion({
    required String targetLanguage,
    required String lessonId,
    required int score,
    DateTime? completedAt,
  }) async {
    final now = completedAt ?? DateTime.now();
    final current = await load(targetLanguage);

    final updated = current.copyWith(
      completedLessonIds: {...current.completedLessonIds, lessonId},
      totalScore: current.totalScore + score,
      currentStreakDays: UserProgress.nextStreak(
        previousActivityDate: current.lastActivityDate,
        completedAt: now,
        previousStreak: current.currentStreakDays,
      ),
      lastActivityDate: UserProgress.dateOnly(now),
    );

    _byLanguage[targetLanguage] = updated;
    return updated;
  }
}
