/// Progress for a single user against a single course, keyed by
/// `targetLanguage`.
class UserProgress {
  const UserProgress({
    required this.targetLanguage,
    this.completedLessonIds = const {},
    this.currentStreakDays = 0,
    this.totalScore = 0,
    this.lastActivityDate,
  });

  final String targetLanguage;
  final Set<String> completedLessonIds;
  final int currentStreakDays;
  final int totalScore;

  /// Date-only (time components discarded) of the last completed lesson,
  /// used to compute [currentStreakDays].
  final DateTime? lastActivityDate;

  UserProgress copyWith({
    Set<String>? completedLessonIds,
    int? currentStreakDays,
    int? totalScore,
    DateTime? lastActivityDate,
  }) {
    return UserProgress(
      targetLanguage: targetLanguage,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      totalScore: totalScore ?? this.totalScore,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final lastActivity = json['lastActivityDate'] as String?;
    return UserProgress(
      targetLanguage: json['targetLanguage'] as String,
      completedLessonIds:
          (json['completedLessonIds'] as List<dynamic>? ?? const [])
              .map((e) => e as String)
              .toSet(),
      currentStreakDays: json['currentStreakDays'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      lastActivityDate: lastActivity == null
          ? null
          : DateTime.parse(lastActivity),
    );
  }

  Map<String, dynamic> toJson() => {
    'targetLanguage': targetLanguage,
    'completedLessonIds': completedLessonIds.toList(),
    'currentStreakDays': currentStreakDays,
    'totalScore': totalScore,
    if (lastActivityDate != null)
      'lastActivityDate': lastActivityDate!.toIso8601String(),
  };

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Calendar-day count since the epoch, computed in UTC regardless of the
  /// input's timezone. Deliberately NOT `localDate.difference(other).inDays`
  /// — on a DST spring-forward day the local calendar day is only 23 wall-
  /// clock hours long, so that would floor to 0 instead of 1 and wrongly
  /// flatline the streak the day after the transition. Building the
  /// comparison dates in UTC (which has no DST) sidesteps that entirely.
  static int _daysSinceEpoch(DateTime date) {
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    return utcDate.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  /// Streak rule: same calendar day as [previousActivityDate] keeps the
  /// streak, the very next calendar day extends it by one, any other gap
  /// (including going backwards) resets it to 1.
  static int nextStreak({
    required DateTime? previousActivityDate,
    required DateTime completedAt,
    required int previousStreak,
  }) {
    if (previousActivityDate == null) return 1;

    final gapDays =
        _daysSinceEpoch(completedAt) - _daysSinceEpoch(previousActivityDate);

    if (gapDays == 0) return previousStreak == 0 ? 1 : previousStreak;
    if (gapDays == 1) return previousStreak + 1;
    return 1;
  }
}
