import 'package:go_router/go_router.dart';

import '../lessons/exercise_screen.dart';
import '../lessons/lesson_list_screen.dart';
import '../lessons/lesson_summary_data.dart';
import '../lessons/lesson_summary_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LessonListScreen(),
    ),
    GoRoute(
      path: '/lesson/:unitId/:lessonId',
      builder: (context, state) => ExerciseScreen(
        unitId: state.pathParameters['unitId']!,
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
    GoRoute(
      path: '/lesson/:unitId/:lessonId/summary',
      builder: (context, state) => LessonSummaryScreen(
        data: state.extra as LessonSummaryData,
      ),
    ),
  ],
);
