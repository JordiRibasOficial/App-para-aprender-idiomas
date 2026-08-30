import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/course.dart';
import '../domain/models/target_language.dart';
import '../domain/repositories/content_repository.dart';
import 'asset_content_repository.dart';
import 'supabase_session.dart';

/// Thrown when a Premium course can't be fetched — network failure, a
/// non-2xx response (including "not Premium"), or a malformed body. The
/// caller sees this the same as any other load failure: no course, no
/// silent fallback to stale or partial content.
class CourseContentException implements Exception {
  const CourseContentException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches one Premium course's raw JSON from the `get-course-content`
/// Edge Function. Abstracted so [SupabaseContentRepository] doesn't depend
/// on [SupabaseClient] directly, and so tests can inject a fake instead of
/// hitting a real backend — same pattern as [PurchaseVerifier].
abstract interface class PremiumCourseFetcher {
  Future<Map<String, dynamic>> fetch({required String targetLanguage});
}

class SupabasePremiumCourseFetcher implements PremiumCourseFetcher {
  const SupabasePremiumCourseFetcher(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> fetch({required String targetLanguage}) async {
    final accessToken = await requireAccountAccessToken(_client);

    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'get-course-content',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {'targetLanguage': targetLanguage},
      );
    } on FunctionException catch (e) {
      throw CourseContentException(
        'get-course-content respondió ${e.status}: ${e.details}',
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const CourseContentException(
        'get-course-content devolvió una respuesta con formato inesperado.',
      );
    }
    return data;
  }
}

/// [ContentRepository] that delegates the free course (English — still
/// bundled in the app, see [AssetContentRepository]) to the asset loader,
/// and fetches every Premium-gated course (pt/fr/ja) from the
/// `get-course-content` Edge Function instead of bundling it client-side.
///
/// See [SupabasePremiumCourseFetcher] and the Edge Function's own doc
/// comment for why: bundling Premium content in the APK/IPA meant it sat on
/// every device regardless of payment status, gated only by a client-side
/// boolean a patched build (no root required) could flip. The content
/// itself now never reaches a device until the backend has verified an
/// active subscription for the caller.
class SupabaseContentRepository implements ContentRepository {
  SupabaseContentRepository({
    ContentRepository? freeContentRepository,
    PremiumCourseFetcher? premiumCourseFetcher,
  }) : _freeContentRepository =
           freeContentRepository ?? AssetContentRepository(),
       // ignore: prefer_initializing_formals
       _premiumCourseFetcher = premiumCourseFetcher;

  final ContentRepository _freeContentRepository;

  // Built lazily (not in the constructor) so constructing this repository
  // never requires Supabase.initialize() to have run yet — only actually
  // loading a Premium course does. Every test in this codebase that
  // exercises the real provider chain uses the free (English) course.
  final PremiumCourseFetcher? _premiumCourseFetcher;

  @override
  Future<Course> loadCourse({
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final language = targetLanguageOption(targetLanguage);
    if (!language.requiresPremium) {
      return _freeContentRepository.loadCourse(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    }

    final fetcher =
        _premiumCourseFetcher ??
        SupabasePremiumCourseFetcher(Supabase.instance.client);
    final json = await fetcher.fetch(targetLanguage: targetLanguage);
    return Course.fromJson(json);
  }
}
