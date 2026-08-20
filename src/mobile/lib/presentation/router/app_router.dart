import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../about_screen.dart';
import '../data_export_screen.dart';
import '../lessons/exercise_screen.dart';
import '../lessons/lesson_summary_data.dart';
import '../lessons/lesson_summary_screen.dart';
import '../onboarding/auth_choice_screen.dart';
import '../onboarding/language_selection_screen.dart';
import '../onboarding/level_selection_screen.dart';
import '../paywall/paywall_screen.dart';
import '../root_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const RootScreen()),
    GoRoute(
      path: '/data-export',
      builder: (context, state) => const DataExportScreen(),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    GoRoute(
      path: '/onboarding/language',
      builder: (context, state) => const LanguageSelectionScreen(),
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
      path: '/lesson/:targetLanguage/:unitId/:lessonId',
      builder: (context, state) => ExerciseScreen(
        targetLanguage: state.pathParameters['targetLanguage']!,
        unitId: state.pathParameters['unitId']!,
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
    GoRoute(
      path: '/lesson/:targetLanguage/:unitId/:lessonId/summary',
      // `extra` only survives in-app navigation (context.go(..., extra:
      // ...)) — it's never set when this route is reached any other way
      // (e.g. a future deep link, or Android restoring the route after the
      // process was killed). A forced cast would crash the app in that
      // case, so fall back to a friendly message instead, same pattern as
      // ExerciseScreen's unknown-lesson branch.
      builder: (context, state) {
        final data = state.extra;
        if (data is! LessonSummaryData) {
          return const Scaffold(
            body: Center(child: Text('Este resumen ya no está disponible.')),
          );
        }
        return LessonSummaryScreen(data: data);
      },
    ),
  ],
);
