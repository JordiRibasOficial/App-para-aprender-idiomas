import '../models/course.dart';

abstract interface class ContentRepository {
  /// Loads the course teaching [targetLanguage] to a speaker of
  /// [sourceLanguage]. Throws if no matching course asset exists.
  Future<Course> loadCourse({
    required String sourceLanguage,
    required String targetLanguage,
  });
}
