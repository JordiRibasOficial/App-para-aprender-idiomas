import 'course_unit.dart';

/// A full course teaching [targetLanguage] to a speaker of
/// [sourceLanguage]. Both are ISO 639-1 codes (e.g. `en`, `es`, `pt`).
/// Kept as explicit fields from day one so the content engine supports all
/// 12 planned target languages without a schema change later.
class Course {
  const Course({
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.level,
    required this.units,
  });

  final String sourceLanguage;
  final String targetLanguage;

  /// CEFR level, e.g. `A1`.
  final String level;
  final List<CourseUnit> units;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      level: json['level'] as String,
      units: (json['units'] as List<dynamic>)
          .map((e) => CourseUnit.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'level': level,
        'units': units.map((e) => e.toJson()).toList(),
      };
}
