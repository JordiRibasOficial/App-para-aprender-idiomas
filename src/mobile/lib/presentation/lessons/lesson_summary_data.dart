class LessonSummaryData {
  const LessonSummaryData({
    required this.unitId,
    required this.lessonTitle,
    required this.score,
    required this.total,
  });

  final String unitId;
  final String lessonTitle;
  final int score;
  final int total;

  double get ratio => total == 0 ? 0 : score / total;
}
