import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/app_theme_mode.dart';
import '../../domain/models/target_language.dart';
import '../providers/content_providers.dart';
import '../providers/progress_providers.dart';
import '../providers/theme_mode_providers.dart';
import '../widgets/premium_gated_banner_ad.dart';

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
        data: (course) => ListView(
          children: [
            for (final unit in course.units) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  unit.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                  onTap: () => context.go(
                    '/lesson/$targetLanguage/${unit.id}/${lesson.id}',
                  ),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const PremiumGatedBannerAd(),
    );
  }
}
