/// Progress for a single user against a single course, keyed by
/// `targetLanguage`. Persistence lands in Paso 7 — this is the pure data
/// shape only.
class UserProgress {
  const UserProgress({
    required this.targetLanguage,
    this.completedLessonIds = const {},
    this.currentStreakDays = 0,
    this.totalScore = 0,
  });

  final String targetLanguage;
  final Set<String> completedLessonIds;
  final int currentStreakDays;
  final int totalScore;

  UserProgress copyWith({
    Set<String>? completedLessonIds,
    int? currentStreakDays,
    int? totalScore,
  }) {
    return UserProgress(
      targetLanguage: targetLanguage,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      totalScore: totalScore ?? this.totalScore,
    );
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      targetLanguage: json['targetLanguage'] as String,
      completedLessonIds: (json['completedLessonIds'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toSet(),
      currentStreakDays: json['currentStreakDays'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetLanguage': targetLanguage,
        'completedLessonIds': completedLessonIds.toList(),
        'currentStreakDays': currentStreakDays,
        'totalScore': totalScore,
      };
}
