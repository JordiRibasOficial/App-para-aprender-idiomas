import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/app_theme_mode.dart';
import '../../domain/models/course.dart';
import '../../domain/models/target_language.dart';
import '../../domain/models/user_progress.dart';
import '../providers/content_providers.dart';
import '../providers/progress_providers.dart';
import '../providers/theme_mode_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_gated_banner_ad.dart';
import '../widgets/progress_bar.dart';

/// icon/tooltip pairs for the app bar toggle — the button always shows the
/// *current* mode (not the mode a tap would switch to), same convention as
/// a play/pause icon.
(IconData, String) _themeModeIconAndLabel(AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => (
    Icons.brightness_auto_outlined,
    'Tema: automático (sigue el sistema)',
  ),
  AppThemeMode.light => (Icons.light_mode_outlined, 'Tema: claro'),
  AppThemeMode.dark => (Icons.dark_mode_outlined, 'Tema: oscuro'),
};

class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key, required this.targetLanguage});

  final String targetLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseProvider(targetLanguage));
    final completedLessonIds =
        ref.watch(progressProvider(targetLanguage)).value?.completedLessonIds ??
        const {};
    final themeMode = ref.watch(themeModeProvider).value ?? AppThemeMode.system;
    final (themeIcon, themeLabel) = _themeModeIconAndLabel(themeMode);

    return Scaffold(
      appBar: AppBar(
        title: Text('${targetLanguageDisplayName(targetLanguage)} · A1'),
        actions: [
          IconButton(
            icon: Icon(themeIcon),
            tooltip: themeLabel,
            onPressed: () => ref.read(themeModeProvider.notifier).cycle(),
          ),
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
        data: (course) {
          final progress = ref.watch(progressProvider(targetLanguage)).value;
          return ListView(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
            children: [
              _CourseStatsHeader(course: course, progress: progress),
              for (final unit in course.units) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    AppTheme.spaceLg,
                    AppTheme.spaceMd,
                    AppTheme.spaceSm,
                  ),
                  child: Text(
                    unit.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final lesson in unit.lessons)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                      vertical: AppTheme.spaceXs,
                    ),
                    child: _LessonCard(
                      title: lesson.title,
                      exerciseCount: lesson.exercises.length,
                      completed: completedLessonIds.contains(lesson.id),
                      onTap: () => context.go(
                        '/lesson/$targetLanguage/${unit.id}/${lesson.id}',
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: const PremiumGatedBannerAd(),
    );
  }
}

class _CourseStatsHeader extends StatelessWidget {
  const _CourseStatsHeader({required this.course, required this.progress});

  final Course course;
  final UserProgress? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalLessons = course.units.fold<int>(
      0,
      (sum, unit) => sum + unit.lessons.length,
    );
    final completed = progress?.completedLessonIds.length ?? 0;
    final streak = progress?.currentStreakDays ?? 0;
    final score = progress?.totalScore ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatPill(
                  icon: Icons.local_fire_department,
                  iconColor: streak > 0
                      ? scheme.tertiary
                      : scheme.onSurfaceVariant,
                  label: streak == 1 ? '1 día' : '$streak días',
                ),
                const SizedBox(width: AppTheme.spaceMd),
                _StatPill(
                  icon: Icons.star_rounded,
                  iconColor: scheme.primary,
                  label: '$score pts',
                ),
              ],
            ),
            if (totalLessons > 0) ...[
              const SizedBox(height: AppTheme.spaceMd),
              ProgressBar(
                value: completed / totalLessons,
                label: '$completed de $totalLessons lecciones completadas',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: AppTheme.spaceXs),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.title,
    required this.exerciseCount,
    required this.completed,
    required this.onTap,
  });

  final String title;
  final int exerciseCount;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                ),
                child: Icon(
                  completed ? Icons.check_rounded : Icons.menu_book_outlined,
                  color: completed ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    Text(
                      '$exerciseCount ejercicios',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
