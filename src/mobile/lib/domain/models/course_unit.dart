import 'lesson.dart';

/// A thematic group of lessons within a [Course]. Named `CourseUnit` rather
/// than `Unit` to avoid ambiguity with unrelated `Unit` types.
class CourseUnit {
  const CourseUnit({
    required this.id,
    required this.title,
    required this.lessons,
  });

  final String id;
  final String title;
  final List<Lesson> lessons;

  factory CourseUnit.fromJson(Map<String, dynamic> json) {
    return CourseUnit(
      id: json['id'] as String,
      title: json['title'] as String,
      lessons: (json['lessons'] as List<dynamic>)
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lessons': lessons.map((e) => e.toJson()).toList(),
  };
}
