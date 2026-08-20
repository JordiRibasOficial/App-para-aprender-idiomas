import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_onboarding_repository.dart';
import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/data/in_memory_terms_acceptance_repository.dart';
import 'package:app_para_aprender_idiomas/data/mock_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/subscription_repository.dart';
import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/paywall/paywall_screen.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/onboarding_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/subscription_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/terms_acceptance_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/router/app_router.dart';

/// The earlier WCAG 2.2 AA pass was a manual code review, not a
/// measurement — this exercises Flutter's own built-in guideline checkers
/// (real contrast pixel-sampling, real minimum tap-target sizes) against the
/// screens users hit first, so a future regression fails a test instead of
/// only being caught by re-reading the code again.
void main() {
  tearDown(() => appRouter.go('/'));

  testWidgets('welcome screen meets WCAG contrast and tap-target guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressRepositoryProvider.overrideWithValue(
            InMemoryProgressRepository(),
          ),
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(),
          ),
          termsAcceptanceRepositoryProvider.overrideWithValue(
            InMemoryTermsAcceptanceRepository(),
          ),
          subscriptionRepositoryProvider.overrideWithValue(
            MockSubscriptionRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('paywall screen meets WCAG contrast and tap-target guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final SubscriptionRepository repository = MockSubscriptionRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: PaywallScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });
}
