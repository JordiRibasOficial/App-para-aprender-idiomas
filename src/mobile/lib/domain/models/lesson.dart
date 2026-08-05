import 'exercise.dart';

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.exercises,
  });

  final String id;
  final String title;
  final List<Exercise> exercises;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}
