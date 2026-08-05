import 'package:go_router/go_router.dart';

import '../lessons/exercise_screen.dart';
import '../lessons/lesson_summary_data.dart';
import '../lessons/lesson_summary_screen.dart';
import '../onboarding/auth_choice_screen.dart';
import '../onboarding/level_selection_screen.dart';
import '../paywall/paywall_screen.dart';
import '../root_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RootScreen(),
    ),
    GoRoute(
      path: '/onboarding/level',
      builder: (context, state) => const LevelSelectionScreen(),
    ),
    GoRoute(
      path: '/onboarding/auth',
      builder: (context, state) => const AuthChoiceScreen(),
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const PaywallScreen(),
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
