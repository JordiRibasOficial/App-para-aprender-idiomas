import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/exercise.dart';
import '../../domain/models/lesson.dart';
import '../providers/content_providers.dart';
import '../providers/progress_providers.dart';
import '../widgets/progress_bar.dart';
import 'lesson_summary_data.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({
    super.key,
    required this.targetLanguage,
    required this.unitId,
    required this.lessonId,
  });

  final String targetLanguage;
  final String unitId;
  final String lessonId;

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  int _index = 0;
  int _score = 0;
  bool _answered = false;
  bool _wasCorrect = false;

  String? _selectedOption;
  final _fillController = TextEditingController();
  Map<String, String?> _matchSelections = {};
  final Map<String, List<String>> _shuffledOptionsCache = {};

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  List<String> _shuffledMatchOptions(Exercise exercise) {
    return _shuffledOptionsCache.putIfAbsent(exercise.id, () {
      final options = exercise.pairs.values.toList();
      options.shuffle(Random(exercise.id.hashCode));
      return options;
    });
  }

  bool get _canSubmit {
    return _selectedOption != null ||
        _fillController.text.trim().isNotEmpty ||
        _matchSelections.values.every((v) => v != null) && _matchSelections.isNotEmpty;
  }

  void _submit(Exercise exercise) {
    final Object answer = switch (exercise.type) {
      ExerciseType.multipleChoice => _selectedOption ?? '',
      ExerciseType.fillBlank => _fillController.text.trim(),
      ExerciseType.matching => Map<String, String>.from(_matchSelections.map(
          (key, value) => MapEntry(key, value ?? ''),
        )),
    };

    final correct = exercise.isCorrect(answer);
    setState(() {
      _answered = true;
      _wasCorrect = correct;
      if (correct) _score++;
    });
  }

  Future<void> _next(Lesson lesson) async {
    if (_index + 1 < lesson.exercises.length) {
      setState(() {
        _index++;
        _answered = false;
        _wasCorrect = false;
        _selectedOption = null;
        _fillController.clear();
        _matchSelections = {};
      });
      return;
    }

    await ref
        .read(progressProvider(widget.targetLanguage).notifier)
        .completeLesson(lessonId: lesson.id, score: _score);
    if (!mounted) return;

    context.go(
      '/lesson/${widget.targetLanguage}/${widget.unitId}/${widget.lessonId}/summary',
      extra: LessonSummaryData(
        unitId: widget.unitId,
        lessonTitle: lesson.title,
        score: _score,
        total: lesson.exercises.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseProvider(widget.targetLanguage));

    return courseAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('No se pudo cargar la lección: $error')),
      ),
      data: (course) {
        final matchingUnits = course.units.where((u) => u.id == widget.unitId).toList();
        final matchingLessons = matchingUnits.isEmpty
            ? const <Lesson>[]
            : matchingUnits.first.lessons.where((l) => l.id == widget.lessonId).toList();
        final lesson = matchingLessons.isEmpty ? null : matchingLessons.first;

        // widget.unitId/lessonId come from the route path — a system
        // boundary, even though today only in-app navigation (always with
        // valid IDs pulled from this same course) reaches this screen. Not
        // crashing keeps this screen safe against stale/malformed links if
        // deep linking is ever added later.
        if (lesson == null) {
          return const Scaffold(
            body: Center(child: Text('Esta lección ya no está disponible.')),
          );
        }

        final exercise = lesson.exercises[_index];

        return Scaffold(
          appBar: AppBar(title: Text(lesson.title)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProgressBar(
                  value: _index / lesson.exercises.length,
                  label: '${_index + 1} / ${lesson.exercises.length}',
                ),
                const SizedBox(height: 24),
                Text(exercise.prompt, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                Expanded(child: _buildAnswerArea(exercise)),
                if (_answered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _wasCorrect
                          ? '¡Correcto!'
                          : 'Incorrecto${exercise.correctAnswer.isNotEmpty ? " — respuesta: ${exercise.correctAnswer}" : ""}',
                      style: TextStyle(
                        // Plain Colors.green (#4CAF50) is ~2.75:1 against a
                        // light surface — below WCAG AA's 3:1 floor even for
                        // bold text. These shades keep >=4.5:1 in both
                        // themes (colorScheme.error is already M3-calibrated
                        // for contrast, so the incorrect branch needs no
                        // adjustment).
                        color: _wasCorrect
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.green.shade300
                                : Colors.green.shade800)
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: _answered
                      ? () => _next(lesson)
                      : (_canSubmit ? () => _submit(exercise) : null),
                  child: Text(_answered
                      ? (_index + 1 < lesson.exercises.length ? 'Siguiente' : 'Terminar')
                      : 'Comprobar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerArea(Exercise exercise) {
    return switch (exercise.type) {
      ExerciseType.multipleChoice => RadioGroup<String>(
          groupValue: _selectedOption,
          onChanged: (value) {
            if (!_answered) setState(() => _selectedOption = value);
          },
          child: ListView(
            children: [
              for (final option in exercise.options)
                RadioListTile<String>(title: Text(option), value: option),
            ],
          ),
        ),
      ExerciseType.fillBlank => TextField(
          controller: _fillController,
          enabled: !_answered,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Escribe tu respuesta',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ExerciseType.matching => ListView(
          children: [
            for (final key in exercise.pairs.keys)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(key)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _matchSelections[key],
                        items: [
                          for (final option in _shuffledMatchOptions(exercise))
                            DropdownMenuItem(value: option, child: Text(option)),
                        ],
                        onChanged: _answered
                            ? null
                            : (value) => setState(() => _matchSelections[key] = value),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
    };
  }
}
