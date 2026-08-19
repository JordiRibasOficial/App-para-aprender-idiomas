import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_content_repository.dart';
import '../../data/supabase_content_repository.dart';
import '../../domain/models/course.dart';
import '../../domain/repositories/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  // Web has no Premium purchase path today (see subscriptionRepositoryProvider),
  // so there's no session to gate Premium content behind — fall back to
  // asset-only, same as it always worked before get-course-content existed.
  if (kIsWeb) {
    return AssetContentRepository();
  }
  return SupabaseContentRepository();
});

/// Loads the course for whichever target language onboarding selected
/// (`en`/`pt`/`fr`/`ja`).
final courseProvider = FutureProvider.family<Course, String>((
  ref,
  targetLanguage,
) {
  final repository = ref.watch(contentRepositoryProvider);
  return repository.loadCourse(
    sourceLanguage: 'es',
    targetLanguage: targetLanguage,
  );
});
