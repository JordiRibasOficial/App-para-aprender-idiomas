import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app_para_aprender_idiomas/data/sqlite_progress_repository.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  // sqflite_common_ffi drives real SQLite through the system libsqlite3 via
  // FFI, so this exercises the real repository — not a mock — without
  // needing an Android/iOS platform channel. path_provider needs the same
  // treatment: fake the documents directory to a real temp dir on disk.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // A fresh temp dir (and therefore a fresh database file) per test keeps
  // tests isolated from each other.
  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp(
      'progress_repository_test',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  group('SqliteProgressRepository', () {
    test('load returns empty progress when nothing was saved', () async {
      final repository = SqliteProgressRepository();

      final progress = await repository.load('en');

      expect(progress.targetLanguage, 'en');
      expect(progress.completedLessonIds, isEmpty);
      expect(progress.totalScore, 0);
      expect(progress.currentStreakDays, 0);
    });

    test(
      'recordLessonCompletion persists across repository instances',
      () async {
        final repository = SqliteProgressRepository();

        await repository.recordLessonCompletion(
          targetLanguage: 'en',
          lessonId: 'u1_l1',
          score: 5,
          completedAt: DateTime(2026, 1, 10),
        );
        final updated = await repository.recordLessonCompletion(
          targetLanguage: 'en',
          lessonId: 'u1_l2',
          score: 4,
          completedAt: DateTime(2026, 1, 11),
        );

        expect(updated.completedLessonIds, {'u1_l1', 'u1_l2'});
        expect(updated.totalScore, 9);
        expect(updated.currentStreakDays, 2);
      },
    );

    test('does not mix progress between different target languages', () async {
      final repository = SqliteProgressRepository();

      await repository.recordLessonCompletion(
        targetLanguage: 'en',
        lessonId: 'u1_l1',
        score: 5,
        completedAt: DateTime(2026, 1, 10),
      );
      final ptProgress = await repository.load('pt');

      expect(ptProgress.completedLessonIds, isEmpty);
      expect(ptProgress.totalScore, 0);
    });
  });
}
