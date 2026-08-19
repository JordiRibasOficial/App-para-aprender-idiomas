import 'package:app_para_aprender_idiomas/data/supabase_content_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/course.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFreeContentRepository implements ContentRepository {
  final loadCourseCalls = <String>[];

  @override
  Future<Course> loadCourse({
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    loadCourseCalls.add(targetLanguage);
    return Course(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      level: 'A1',
      units: const [],
    );
  }
}

class _FakePremiumCourseFetcher implements PremiumCourseFetcher {
  _FakePremiumCourseFetcher({this.response, this.error});

  Map<String, dynamic>? response;
  Object? error;
  final fetchCalls = <String>[];

  @override
  Future<Map<String, dynamic>> fetch({required String targetLanguage}) async {
    fetchCalls.add(targetLanguage);
    if (error != null) throw error!;
    return response!;
  }
}

void main() {
  group('SupabaseContentRepository', () {
    test(
      'delegates the free language (en) to the free content repository',
      () async {
        final freeRepo = _FakeFreeContentRepository();
        final fetcher = _FakePremiumCourseFetcher();
        final repository = SupabaseContentRepository(
          freeContentRepository: freeRepo,
          premiumCourseFetcher: fetcher,
        );

        final course = await repository.loadCourse(
          sourceLanguage: 'es',
          targetLanguage: 'en',
        );

        expect(course.targetLanguage, 'en');
        expect(freeRepo.loadCourseCalls, ['en']);
        expect(fetcher.fetchCalls, isEmpty);
      },
    );

    test(
      'fetches a Premium language (pt) from the course-content fetcher, never the free repository',
      () async {
        final freeRepo = _FakeFreeContentRepository();
        final fetcher = _FakePremiumCourseFetcher(
          response: {
            'sourceLanguage': 'es',
            'targetLanguage': 'pt',
            'level': 'A1',
            'units': <Map<String, dynamic>>[],
          },
        );
        final repository = SupabaseContentRepository(
          freeContentRepository: freeRepo,
          premiumCourseFetcher: fetcher,
        );

        final course = await repository.loadCourse(
          sourceLanguage: 'es',
          targetLanguage: 'pt',
        );

        expect(course.targetLanguage, 'pt');
        expect(fetcher.fetchCalls, ['pt']);
        expect(freeRepo.loadCourseCalls, isEmpty);
      },
    );

    test(
      'propagates the fetcher error for a Premium language instead of falling back silently',
      () async {
        final repository = SupabaseContentRepository(
          freeContentRepository: _FakeFreeContentRepository(),
          premiumCourseFetcher: _FakePremiumCourseFetcher(
            error: const CourseContentException(
              'get-course-content respondió 403: not premium',
            ),
          ),
        );

        expect(
          () =>
              repository.loadCourse(sourceLanguage: 'es', targetLanguage: 'fr'),
          throwsA(isA<CourseContentException>()),
        );
      },
    );

    test('rejects a targetLanguage outside the known catalogue', () async {
      final repository = SupabaseContentRepository(
        freeContentRepository: _FakeFreeContentRepository(),
        premiumCourseFetcher: _FakePremiumCourseFetcher(),
      );

      expect(
        () => repository.loadCourse(sourceLanguage: 'es', targetLanguage: 'de'),
        throwsStateError,
      );
    });
  });
}
