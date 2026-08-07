import '../models/user_progress.dart';

abstract interface class ProgressRepository {
  /// Returns the stored progress for [targetLanguage], or an empty
  /// [UserProgress] if nothing has been saved yet.
  Future<UserProgress> load(String targetLanguage);

  /// Records that [lessonId] was completed with [score] points, updating the
  /// streak based on [completedAt] (defaults to now), and persists the
  /// result. Completing the same lesson again still counts toward the
  /// streak/score — the caller decides whether to allow replays.
  Future<UserProgress> recordLessonCompletion({
    required String targetLanguage,
    required String lessonId,
    required int score,
    DateTime? completedAt,
  });
}
