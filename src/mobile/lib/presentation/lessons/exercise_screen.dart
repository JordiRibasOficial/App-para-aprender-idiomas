import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/exercise.dart';
import '../../domain/models/lesson.dart';
import '../providers/content_providers.dart';
import '../providers/progress_providers.dart';
import '../theme/app_theme.dart';
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

  // Takes the exercise rather than reading a bare _matchSelections.isNotEmpty
  // check: _matchSelections only gains an entry once its dropdown is
  // touched, so a map with 1 of 2 pairs answered was passing
  // `.values.every((v) => v != null)` vacuously — the check needs to know
  // how many pairs the exercise actually has to require all of them.
  bool _canSubmit(Exercise exercise) {
    return switch (exercise.type) {
      ExerciseType.multipleChoice => _selectedOption != null,
      ExerciseType.fillBlank => _fillController.text.trim().isNotEmpty,
      ExerciseType.matching => exercise.pairs.keys.every(
        (key) => _matchSelections[key] != null,
      ),
    };
  }

  void _submit(Exercise exercise) {
    final Object answer = switch (exercise.type) {
      ExerciseType.multipleChoice => _selectedOption ?? '',
      ExerciseType.fillBlank => _fillController.text.trim(),
      ExerciseType.matching => Map<String, String>.from(
        _matchSelections.map((key, value) => MapEntry(key, value ?? '')),
      ),
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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('No se pudo cargar la lección: $error')),
      ),
      data: (course) {
        final matchingUnits = course.units
            .where((u) => u.id == widget.unitId)
            .toList();
        final matchingLessons = matchingUnits.isEmpty
            ? const <Lesson>[]
            : matchingUnits.first.lessons
                  .where((l) => l.id == widget.lessonId)
                  .toList();
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

        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(title: Text(lesson.title)),
          body: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProgressBar(
                  value: _index / lesson.exercises.length,
                  label: '${_index + 1} / ${lesson.exercises.length}',
                ),
                const SizedBox(height: AppTheme.spaceLg),
                Text(
                  exercise.prompt,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.spaceLg),
                Expanded(child: _buildAnswerArea(exercise)),
                if (_answered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                    child: _FeedbackBanner(
                      correct: _wasCorrect,
                      correctAnswer: exercise.correctAnswer,
                    ),
                  ),
                FilledButton(
                  onPressed: _answered
                      ? () => _next(lesson)
                      : (_canSubmit(exercise) ? () => _submit(exercise) : null),
                  style: FilledButton.styleFrom(
                    backgroundColor: _answered
                        ? (_wasCorrect ? scheme.primary : scheme.error)
                        : null,
                    foregroundColor: _answered && !_wasCorrect
                        ? scheme.onError
                        : null,
                  ),
                  child: Text(
                    _answered
                        ? (_index + 1 < lesson.exercises.length
                              ? 'Siguiente'
                              : 'Terminar')
                        : 'Comprobar',
                  ),
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
      ExerciseType.multipleChoice => ListView(
        children: [
          for (final option in exercise.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
              child: _OptionCard(
                label: option,
                selected: _selectedOption == option,
                state: !_answered
                    ? _OptionState.neutral
                    : _optionCorrect(exercise, option)
                    ? _OptionState.correct
                    : (_selectedOption == option
                          ? _OptionState.incorrect
                          : _OptionState.neutral),
                onTap: _answered
                    ? null
                    : () => setState(() => _selectedOption = option),
              ),
            ),
        ],
      ),
      ExerciseType.fillBlank => TextField(
        controller: _fillController,
        enabled: !_answered,
        decoration: const InputDecoration(
          labelText: 'Tu respuesta',
          hintText: 'Escribe tu respuesta',
        ),
        onChanged: (_) => setState(() {}),
      ),
      ExerciseType.matching => ListView(
        children: [
          for (final key in exercise.pairs.keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
              child: Row(
                children: [
                  Expanded(child: Text(key)),
                  const SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _matchSelections[key],
                      decoration: InputDecoration(
                        labelText: 'Traducción de "$key"',
                      ),
                      items: [
                        for (final option in _shuffledMatchOptions(exercise))
                          DropdownMenuItem(value: option, child: Text(option)),
                      ],
                      onChanged: _answered
                          ? null
                          : (value) =>
                                setState(() => _matchSelections[key] = value),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    };
  }

  bool _optionCorrect(Exercise exercise, String option) =>
      option.trim().toLowerCase() ==
      exercise.correctAnswer.trim().toLowerCase();
}

enum _OptionState { neutral, correct, incorrect }

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.state,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Text color follows the fill's matching M3 "on container" role rather
    // than the app's default black87/white — those are only guaranteed to
    // contrast against the default surface, not against primaryContainer/
    // errorContainer tones (see PlanCard's onTertiaryContainer badge for
    // the same pattern). null keeps the default textTheme color for the
    // unselected/neutral case, which sits on the default surface.
    final (
      Color fill,
      Color border,
      Color? onFill,
      IconData? icon,
    ) = switch (state) {
      _OptionState.correct => (
        scheme.primaryContainer,
        scheme.primary,
        scheme.onPrimaryContainer,
        Icons.check_circle,
      ),
      _OptionState.incorrect => (
        scheme.errorContainer,
        scheme.error,
        scheme.onErrorContainer,
        Icons.cancel,
      ),
      _OptionState.neutral => (
        selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        selected ? scheme.primary : Colors.transparent,
        selected ? scheme.onPrimaryContainer : null,
        null,
      ),
    };

    return Semantics(
      button: true,
      enabled: onTap != null,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      // excludeSemantics: true drops the Text/Icon descendants' own
      // semantics nodes — without it a screen reader visits this label AND
      // the child Text separately ("Madrid, respuesta correcta, Madrid").
      // InkWell's excludeFromSemantics only removes its own tap-target
      // node, so this Semantics node must carry onTap itself, or
      // screen reader/switch users cannot activate the option at all.
      excludeSemantics: true,
      onTap: onTap,
      label: state == _OptionState.correct
          ? '$label (respuesta correcta)'
          : state == _OptionState.incorrect
          ? '$label (respuesta incorrecta)'
          : label,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          excludeFromSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMd,
              vertical: AppTheme.spaceMd,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: border, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.titleMedium?.copyWith(color: onFill),
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    color: state == _OptionState.correct
                        ? scheme.primary
                        : scheme.error,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.correct, required this.correctAnswer});

  final bool correct;
  final String correctAnswer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = correct ? scheme.primary : scheme.error;
    final background = correct
        ? scheme.primaryContainer
        : scheme.errorContainer;

    final message = correct
        ? '¡Correcto!'
        : 'Incorrecto${correctAnswer.isNotEmpty ? " — respuesta: $correctAnswer" : ""}';

    // liveRegion: true makes screen readers announce this banner as soon as
    // it appears, instead of requiring the user to navigate to it manually
    // — the pass/fail result must not depend on the user finding it (WCAG
    // 4.1.3 Status Messages).
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: AppTheme.spaceSm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(correct ? Icons.check_circle : Icons.cancel, color: color),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
