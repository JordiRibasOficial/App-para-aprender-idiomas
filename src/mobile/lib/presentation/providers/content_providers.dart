import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_content_repository.dart';
import '../../domain/models/course.dart';
import '../../domain/repositories/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return AssetContentRepository();
});

/// The MVP launch course a Spanish speaker learns first. Will grow into a
/// `family`-based provider once Paso 10 (onboarding) lets the user pick a
/// target language among the launch trio (pt/fr/ja) plus English.
final englishCourseProvider = FutureProvider<Course>((ref) {
  final repository = ref.watch(contentRepositoryProvider);
  return repository.loadCourse(sourceLanguage: 'es', targetLanguage: 'en');
});
