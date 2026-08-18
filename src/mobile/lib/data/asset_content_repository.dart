import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../domain/models/course.dart';
import '../domain/models/target_language.dart';
import '../domain/repositories/content_repository.dart';

/// Loads course content from `assets/content/courses/<targetLanguage>.json`,
/// bundled with the app. One file per target language keeps adding a new
/// language a pure addition — no existing file is touched.
class AssetContentRepository implements ContentRepository {
  AssetContentRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<Course> loadCourse({
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    // targetLanguage reaches here from a GoRouter path parameter
    // (see app_router.dart) — not free-typed by the user today, but not an
    // internal constant either. Validating against the known catalogue
    // before it's spliced into an asset path is cheap insurance against a
    // malformed or unexpected value, and against this becoming a real
    // external input boundary if deep linking is ever added.
    if (!kLaunchTargetLanguages.any((l) => l.code == targetLanguage)) {
      throw ArgumentError.value(
        targetLanguage,
        'targetLanguage',
        'Unknown target language code',
      );
    }

    final raw = await _bundle.loadString(
      'assets/content/courses/$targetLanguage.json',
    );
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
