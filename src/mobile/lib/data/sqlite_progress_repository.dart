import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/models/user_progress.dart';
import '../domain/repositories/progress_repository.dart';

/// SQLite-backed [ProgressRepository]. Requires platform channels, so it
/// only runs on a real device/emulator or in `integration_test` — plain
/// `flutter test` runs use [InMemoryProgressRepository] instead.
class SqliteProgressRepository implements ProgressRepository {
  Database? _database;

  Future<Database> _open() async {
    final existing = _database;
    if (existing != null) return existing;

    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'progress.db');

    final database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_progress (
            target_language TEXT PRIMARY KEY,
            current_streak_days INTEGER NOT NULL,
            total_score INTEGER NOT NULL,
            last_activity_date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE completed_lessons (
            target_language TEXT NOT NULL,
            lesson_id TEXT NOT NULL,
            PRIMARY KEY (target_language, lesson_id)
          )
        ''');
      },
    );

    _database = database;
    return database;
  }

  @override
  Future<UserProgress> load(String targetLanguage) async {
    final db = await _open();

    final progressRows = await db.query(
      'user_progress',
      where: 'target_language = ?',
      whereArgs: [targetLanguage],
      limit: 1,
    );
    final lessonRows = await db.query(
      'completed_lessons',
      columns: ['lesson_id'],
      where: 'target_language = ?',
      whereArgs: [targetLanguage],
    );
    final completedLessonIds = lessonRows.map((row) => row['lesson_id'] as String).toSet();

    if (progressRows.isEmpty) {
      return UserProgress(
        targetLanguage: targetLanguage,
        completedLessonIds: completedLessonIds,
      );
    }

    final row = progressRows.first;
    final lastActivityDate = row['last_activity_date'] as String?;
    return UserProgress(
      targetLanguage: targetLanguage,
      completedLessonIds: completedLessonIds,
      currentStreakDays: row['current_streak_days'] as int,
      totalScore: row['total_score'] as int,
      lastActivityDate: lastActivityDate == null ? null : DateTime.parse(lastActivityDate),
    );
  }

  @override
  Future<UserProgress> recordLessonCompletion({
    required String targetLanguage,
    required String lessonId,
    required int score,
    DateTime? completedAt,
  }) async {
    final db = await _open();
    final now = completedAt ?? DateTime.now();
    final current = await load(targetLanguage);

    final updated = current.copyWith(
      completedLessonIds: {...current.completedLessonIds, lessonId},
      totalScore: current.totalScore + score,
      currentStreakDays: UserProgress.nextStreak(
        previousActivityDate: current.lastActivityDate,
        completedAt: now,
        previousStreak: current.currentStreakDays,
      ),
      lastActivityDate: UserProgress.dateOnly(now),
    );

    await db.transaction((txn) async {
      await txn.insert(
        'user_progress',
        {
          'target_language': targetLanguage,
          'current_streak_days': updated.currentStreakDays,
          'total_score': updated.totalScore,
          'last_activity_date': updated.lastActivityDate!.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'completed_lessons',
        {'target_language': targetLanguage, 'lesson_id': lessonId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });

    return updated;
  }
}
