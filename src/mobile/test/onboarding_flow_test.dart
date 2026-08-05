import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_onboarding_repository.dart';
import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/data/mock_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/entitlement.dart';
import 'package:app_para_aprender_idiomas/domain/models/subscription_plan.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/subscription_repository.dart';
import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/onboarding_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/subscription_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/router/app_router.dart';

/// Already has an active Premium entitlement the moment anything subscribes
/// to [entitlementStream] — unlike [MockSubscriptionRepository], which stays
/// silent until a purchase happens, so it can't represent "already
/// subscribed before this screen ever loads".
class _AlreadyPremiumSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<SubscriptionPlan>> loadPlans() async => SubscriptionPlan.placeholderPlans;

  @override
  Stream<Entitlement> get entitlementStream => Stream.value(
        const Entitlement(status: EntitlementStatus.active, activeProductId: 'annual_sub'),
      );

  @override
  Stream<String> get purchaseErrorStream => const Stream.empty();

  @override
  Future<void> purchase(SubscriptionPlan plan) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  void dispose() {}
}

void main() {
  // `appRouter` (app_router.dart) is a module-level singleton, so its
  // navigation stack survives across pumpWidget calls within this file —
  // reset it so a test that ends mid-flow (e.g. pushed onto the paywall)
  // doesn't leak its location into the next test's fresh widget tree.
  tearDown(() => appRouter.go('/'));

  testWidgets('a new install shows the welcome screen, not the lesson list',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
        onboardingRepositoryProvider.overrideWithValue(InMemoryOnboardingRepository()),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('App para Aprender Idiomas'), findsOneWidget);
    expect(find.text('Inglés · A1'), findsNothing);
  });

  testWidgets(
      'completing onboarding as a guest reaches the lesson list and persists the choice',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
        onboardingRepositoryProvider.overrideWithValue(InMemoryOnboardingRepository()),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tu idioma'), findsOneWidget);

    // English is preselected as the default target language.
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cuál es tu nivel?'), findsOneWidget);

    // A1 is preselected and the only available level.
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo quieres continuar?'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Continuar como invitado'));
    await tester.pumpAndSettle();

    expect(find.text('Inglés · A1'), findsOneWidget);
  });

  testWidgets(
      'choosing a Premium language without an active subscription is sent to the paywall',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
        onboardingRepositoryProvider.overrideWithValue(InMemoryOnboardingRepository()),
        subscriptionRepositoryProvider.overrideWithValue(MockSubscriptionRepository()),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Portugués'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Hazte Premium'), findsOneWidget);
    expect(find.text('¿Cuál es tu nivel?'), findsNothing);
  });

  testWidgets(
      'choosing a Premium language with an active subscription reaches its lesson list',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
        onboardingRepositoryProvider.overrideWithValue(InMemoryOnboardingRepository()),
        subscriptionRepositoryProvider.overrideWithValue(_AlreadyPremiumSubscriptionRepository()),
      ],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Portugués'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cuál es tu nivel?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Continuar como invitado'));
    await tester.pumpAndSettle();

    expect(find.text('Portugués · A1'), findsOneWidget);
  });
}
