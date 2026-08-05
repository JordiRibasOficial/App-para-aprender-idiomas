import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../domain/models/course.dart';
import '../domain/repositories/content_repository.dart';

/// Loads course content from `assets/content/courses/<targetLanguage>.json`,
/// bundled with the app. One file per target language keeps adding a new
/// language a pure addition — no existing file is touched.
class AssetContentRepository implements ContentRepository {
  AssetContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<Course> loadCourse({
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final raw = await _bundle.loadString('assets/content/courses/$targetLanguage.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final course = Course.fromJson(json);
    if (course.sourceLanguage != sourceLanguage) {
      throw StateError(
        'Course asset for "$targetLanguage" is authored for source '
        'language "${course.sourceLanguage}", not "$sourceLanguage".',
      );
    }
    return course;
  }
}
