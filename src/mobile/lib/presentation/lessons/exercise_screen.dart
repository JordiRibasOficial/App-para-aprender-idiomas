import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/exercise.dart';
import '../../domain/models/lesson.dart';
import '../providers/content_providers.dart';
import '../widgets/progress_bar.dart';
import 'lesson_summary_data.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key, required this.unitId, required this.lessonId});

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

  void _next(Lesson lesson) {
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

    context.go(
      '/lesson/${widget.unitId}/${widget.lessonId}/summary',
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
    final courseAsync = ref.watch(englishCourseProvider);

    return courseAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('No se pudo cargar la lección: $error')),
      ),
      data: (course) {
        final unit = course.units.firstWhere((u) => u.id == widget.unitId);
        final lesson = unit.lessons.firstWhere((l) => l.id == widget.lessonId);
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
                        color: _wasCorrect ? Colors.green : Theme.of(context).colorScheme.error,
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
