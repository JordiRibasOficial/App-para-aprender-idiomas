import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/domain/models/exercise.dart';

void main() {
  group('Exercise.isCorrect', () {
    test('multipleChoice matches case-insensitively and trims whitespace', () {
      final exercise = Exercise(
        id: 'e1',
        type: ExerciseType.multipleChoice,
        prompt: 'prompt',
        correctAnswer: 'Hello',
        options: const ['Hello', 'Goodbye'],
      );

      expect(exercise.isCorrect('Hello'), isTrue);
      expect(exercise.isCorrect(' hello '), isTrue);
      expect(exercise.isCorrect('Goodbye'), isFalse);
    });

    test('fillBlank matches case-insensitively and trims whitespace', () {
      final exercise = Exercise(
        id: 'e2',
        type: ExerciseType.fillBlank,
        prompt: 'prompt',
        correctAnswer: 'night',
      );

      expect(exercise.isCorrect('Night'), isTrue);
      expect(exercise.isCorrect(' night '), isTrue);
      expect(exercise.isCorrect('day'), isFalse);
    });

    test('matching requires every pair to be matched correctly', () {
      final exercise = Exercise(
        id: 'e3',
        type: ExerciseType.matching,
        prompt: 'prompt',
        correctAnswer: '',
        pairs: const {'Hola': 'Hello', 'Adiós': 'Goodbye'},
      );

      expect(exercise.isCorrect({'Hola': 'Hello', 'Adiós': 'Goodbye'}), isTrue);
      expect(
        exercise.isCorrect({'Hola': 'Goodbye', 'Adiós': 'Hello'}),
        isFalse,
      );
      expect(exercise.isCorrect({'Hola': 'Hello'}), isFalse);
    });
  });
}
