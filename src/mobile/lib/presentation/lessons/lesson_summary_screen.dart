import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'lesson_summary_data.dart';

class LessonSummaryScreen extends StatelessWidget {
  const LessonSummaryScreen({super.key, required this.data});

  final LessonSummaryData data;

  @override
  Widget build(BuildContext context) {
    final percent = (data.ratio * 100).round();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (
      String headline,
      String subline,
      IconData icon,
    ) = switch (data.ratio) {
      >= 0.8 => ('¡Excelente!', 'Dominas esta lección.', Icons.emoji_events),
      >= 0.5 => (
        '¡Buen trabajo!',
        'Vas por buen camino.',
        Icons.thumb_up_alt_rounded,
      ),
      _ => (
        'Sigue practicando',
        'Repasa esta lección cuando quieras.',
        Icons.replay_rounded,
      ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(data.lessonTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: data.ratio,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 32, color: scheme.primary),
                      const SizedBox(height: AppTheme.spaceXs),
                      Text('$percent%', style: textTheme.headlineMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              subline,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              '${data.score} de ${data.total} correctas',
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXxl),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver a las lecciones'),
            ),
          ],
        ),
      ),
    );
  }
}
