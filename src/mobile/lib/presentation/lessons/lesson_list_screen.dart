import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/content_providers.dart';
import '../providers/progress_providers.dart';

class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(englishCourseProvider);
    final completedLessonIds =
        ref.watch(englishProgressProvider).value?.completedLessonIds ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inglés · A1'),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            tooltip: 'Hazte Premium',
            onPressed: () => context.push('/paywall'),
          ),
        ],
      ),
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No se pudo cargar el curso: $error'),
          ),
        ),
        data: (course) => ListView(
          children: [
            for (final unit in course.units) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(unit.title, style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final lesson in unit.lessons)
                ListTile(
                  leading: Icon(
                    completedLessonIds.contains(lesson.id)
                        ? Icons.check_circle
                        : Icons.menu_book_outlined,
                    color: completedLessonIds.contains(lesson.id)
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(lesson.title),
                  subtitle: Text('${lesson.exercises.length} ejercicios'),
                  onTap: () => context.go('/lesson/${unit.id}/${lesson.id}'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
