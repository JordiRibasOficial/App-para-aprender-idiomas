import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_content_repository.dart';
import '../../domain/models/course.dart';
import '../../domain/repositories/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return AssetContentRepository();
});

/// Loads the course for whichever target language onboarding selected
/// (`en`/`pt`/`fr`/`ja`).
final courseProvider = FutureProvider.family<Course, String>((ref, targetLanguage) {
  final repository = ref.watch(contentRepositoryProvider);
  return repository.loadCourse(sourceLanguage: 'es', targetLanguage: targetLanguage);
});
