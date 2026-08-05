import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/progress_bar.dart';
import 'lesson_summary_data.dart';

class LessonSummaryScreen extends StatelessWidget {
  const LessonSummaryScreen({super.key, required this.data});

  final LessonSummaryData data;

  @override
  Widget build(BuildContext context) {
    final percent = (data.ratio * 100).round();

    return Scaffold(
      appBar: AppBar(title: Text(data.lessonTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              data.ratio >= 0.8 ? Icons.emoji_events : Icons.check_circle_outline,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '$percent%',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${data.score} de ${data.total} correctas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ProgressBar(value: data.ratio),
            const SizedBox(height: 32),
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
