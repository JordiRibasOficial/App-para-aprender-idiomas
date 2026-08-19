enum ExerciseType { multipleChoice, fillBlank, matching }

class Exercise {
  const Exercise({
    required this.id,
    required this.type,
    required this.prompt,
    required this.correctAnswer,
    this.options = const [],
    this.pairs = const {},
  });

  final String id;
  final ExerciseType type;
  final String prompt;

  /// Multiple choice: the correct option text. Fill blank: the correct word.
  /// Matching: unused, see [pairs].
  final String correctAnswer;

  /// Multiple choice only: the full set of selectable options (includes
  /// [correctAnswer]).
  final List<String> options;

  /// Matching only: left-hand term -> right-hand term.
  final Map<String, String> pairs;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final type = ExerciseType.values.byName(json['type'] as String);
    return Exercise(
      id: json['id'] as String,
      type: type,
      prompt: json['prompt'] as String,
      correctAnswer: json['correctAnswer'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      pairs: (json['pairs'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key, value as String),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'prompt': prompt,
    if (correctAnswer.isNotEmpty) 'correctAnswer': correctAnswer,
    if (options.isNotEmpty) 'options': options,
    if (pairs.isNotEmpty) 'pairs': pairs,
  };

  bool isCorrect(Object answer) {
    return switch (type) {
      ExerciseType.multipleChoice || ExerciseType.fillBlank =>
        answer is String &&
            answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase(),
      ExerciseType.matching =>
        answer is Map<String, String> &&
            answer.length == pairs.length &&
            pairs.entries.every((e) => answer[e.key] == e.value),
    };
  }
}
