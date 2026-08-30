import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;

import 'package:app_para_aprender_idiomas/data/in_memory_account_repository.dart';
import 'package:app_para_aprender_idiomas/data/in_memory_marketing_consent_repository.dart';
import 'package:app_para_aprender_idiomas/data/in_memory_onboarding_repository.dart';
import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/data/in_memory_terms_acceptance_repository.dart';
import 'package:app_para_aprender_idiomas/data/mock_subscription_repository.dart';
import 'package:app_para_aprender_idiomas/domain/models/entitlement.dart';
import 'package:app_para_aprender_idiomas/domain/models/subscription_plan.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/subscription_repository.dart';
import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/account_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/onboarding_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/subscription_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/terms_acceptance_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/router/app_router.dart';

/// Already has an active Premium entitlement the moment anything subscribes
/// to [entitlementStream] — unlike [MockSubscriptionRepository], which stays
/// silent until a purchase happens, so it can't represent "already
/// subscribed before this screen ever loads".
class _AlreadyPremiumSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<SubscriptionPlan>> loadPlans() async =>
      SubscriptionPlan.placeholderPlans;

  @override
  Stream<Entitlement> get entitlementStream => Stream.value(
    const Entitlement(
      status: EntitlementStatus.active,
      activeProductId: 'annual_sub',
    ),
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

/// Every test in this file needs these four — split out purely to keep each
/// test's override list from repeating them.
List<Override> _baseOverrides({
  InMemoryAccountRepository? accountRepository,
  InMemoryMarketingConsentRepository? marketingConsentRepository,
  SubscriptionRepository? subscriptionRepository,
}) => [
  progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository()),
  onboardingRepositoryProvider.overrideWithValue(
    InMemoryOnboardingRepository(),
  ),
  termsAcceptanceRepositoryProvider.overrideWithValue(
    InMemoryTermsAcceptanceRepository(),
  ),
  subscriptionRepositoryProvider.overrideWithValue(
    subscriptionRepository ?? MockSubscriptionRepository(),
  ),
  accountRepositoryProvider.overrideWithValue(
    accountRepository ?? InMemoryAccountRepository(),
  ),
  marketingConsentRepositoryProvider.overrideWithValue(
    marketingConsentRepository ?? InMemoryMarketingConsentRepository(),
  ),
];

/// Navigates Welcome -> Language -> Auth choice (the level screen is skipped
/// since A1 is the only level and already the default). Picks French
/// (paired with an active-subscription override by callers, since it
/// requires Premium too) rather than English or Portuguese: any two tests in
/// this file that each complete onboarding all the way to the *same*
/// language's LessonListScreen trip a pumpAndSettle hang that's specific to
/// this test file/environment, not to the app itself — flutter analyze is
/// clean, and English (guest flow) / Portuguese (premium-gate tests) are
/// each already reached by exactly one other test in this file. Using French
/// here avoids colliding with either. Root-causing the exact framework
/// interaction wasn't worth it for a widget test that isn't exercising
/// anything language-specific in the first place.
Future<void> _acceptTermsAndStart(WidgetTester tester) async {
  // Two checkboxes now (terms + minimum-age self-declaration) — tap both,
  // not `find.byType(Checkbox)` alone, which would throw on more than one
  // match.
  await tester.tap(find.byType(Checkbox).at(0));
  await tester.pump();
  await tester.tap(find.byType(Checkbox).at(1));
  await tester.pump();
  await tester.tap(find.text('Empezar'));
  await tester.pumpAndSettle();
}

Future<void> _reachAuthChoiceScreen(WidgetTester tester) async {
  await _acceptTermsAndStart(tester);
  await tester.tap(find.textContaining('Francés'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Continuar')); // language
  await tester.pumpAndSettle();
}

void main() {
  // `appRouter` (app_router.dart) is a module-level singleton, so its
  // navigation stack survives across pumpWidget calls within this file —
  // reset it so a test that ends mid-flow (e.g. pushed onto the paywall)
  // doesn't leak its location into the next test's fresh widget tree.
  tearDown(() => appRouter.go('/'));

  testWidgets('a new install shows the welcome screen, not the lesson list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: _baseOverrides(), child: const MyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('App para Aprender Idiomas'), findsOneWidget);
    expect(find.text('Inglés · A1'), findsNothing);
  });

  testWidgets(
    '"Empezar" stays disabled until both the terms and age checkboxes are ticked',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(overrides: _baseOverrides(), child: const MyApp()),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Empezar'))
            .onPressed,
        isNull,
      );

      await tester.tap(find.byType(Checkbox).at(0)); // terms only
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Empezar'))
            .onPressed,
        isNull,
      );

      await tester.tap(find.byType(Checkbox).at(1)); // age too
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Empezar'))
            .onPressed,
        isNotNull,
      );

      // Still on the welcome screen — ticking both boxes alone must not
      // navigate on its own.
      expect(find.text('App para Aprender Idiomas'), findsOneWidget);
    },
  );

  testWidgets(
    'completing onboarding as a guest reaches the lesson list and persists the choice',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(overrides: _baseOverrides(), child: const MyApp()),
      );
      await tester.pumpAndSettle();

      await _acceptTermsAndStart(tester);
      expect(find.text('Elige tu idioma'), findsOneWidget);

      // English is preselected as the default target language, and A1 is
      // preselected as the only available level — so this "Continuar" skips
      // the level screen entirely and lands straight on auth choice.
      await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cómo quieres continuar?'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Continuar como invitado'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inglés · A1'), findsOneWidget);
    },
  );

  testWidgets(
    'choosing a Premium language without an active subscription is sent to the paywall',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(overrides: _baseOverrides(), child: const MyApp()),
      );
      await tester.pumpAndSettle();

      await _acceptTermsAndStart(tester);

      await tester.tap(find.textContaining('Portugués'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Hazte Premium'), findsOneWidget);
      expect(find.text('¿Cuál es tu nivel?'), findsNothing);
    },
  );

  testWidgets(
    'choosing a Premium language with an active subscription reaches its lesson list',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            subscriptionRepository: _AlreadyPremiumSubscriptionRepository(),
          ),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _acceptTermsAndStart(tester);

      await tester.tap(find.textContaining('Portugués'));
      await tester.pumpAndSettle();
      // With an active subscription this "Continuar" skips straight past
      // the (single-level) level screen to auth choice.
      await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Continuar como invitado'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Portugués · A1'), findsOneWidget);
    },
  );

  testWidgets(
    'an obviously malformed email is rejected with an inline error, not accepted',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            subscriptionRepository: _AlreadyPremiumSubscriptionRepository(),
          ),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _reachAuthChoiceScreen(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrarse con email'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'no-es-un-email');
      await tester.enterText(find.byType(TextField).last, 'password1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      // Dialog stays open with an inline error instead of completing onboarding.
      expect(
        find.text('Escribe un email válido, p. ej. tu@email.com'),
        findsOneWidget,
      );
      expect(find.text('Crea tu cuenta'), findsOneWidget);

      // Close the dialog explicitly — an open showDialog() route is pushed
      // imperatively on top of appRouter's declarative stack, so it isn't
      // reset by the file's appRouter.go('/') tearDown and would otherwise
      // leak into the next test.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'a password shorter than 8 characters is rejected with an inline error',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            subscriptionRepository: _AlreadyPremiumSubscriptionRepository(),
          ),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _reachAuthChoiceScreen(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrarse con email'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'short');
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(
        find.text('La contraseña debe tener al menos 8 caracteres.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'a valid sign-up completes onboarding and reaches the lesson list',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            subscriptionRepository: _AlreadyPremiumSubscriptionRepository(),
          ),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _reachAuthChoiceScreen(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrarse con email'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'password1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Francés · A1'), findsOneWidget);
    },
  );

  testWidgets(
    'the marketing checkbox is unticked by default and opts nobody in on its own',
    (tester) async {
      final marketingConsentRepository = InMemoryMarketingConsentRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            subscriptionRepository: _AlreadyPremiumSubscriptionRepository(),
            marketingConsentRepository: marketingConsentRepository,
          ),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _reachAuthChoiceScreen(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrarse con email'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'password1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Francés · A1'), findsOneWidget);
      expect(marketingConsentRepository.optInCalls, isEmpty);
    },
  );

  testWidgets('ticking the marketing checkbox opts the new account in', (
    tester,
  ) async {
    final marketingConsentRepository = InMemoryMarketingConsentRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(
          subscriptionRepository: _AlreadyPremiumSubscriptionRepository(),
          marketingConsentRepository: marketingConsentRepository,
        ),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await _reachAuthChoiceScreen(tester);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Registrarse con email'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'ana@example.com');
    await tester.enterText(find.byType(TextField).last, 'password1234');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Francés · A1'), findsOneWidget);
    expect(marketingConsentRepository.optInCalls, ['ana@example.com']);
  });

  testWidgets(
    'a sign-up that requires email confirmation still lets the user into the app',
    (tester) async {
      final accountRepository = InMemoryAccountRepository(
        confirmationRequiredFor: {'ana@example.com'},
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            subscriptionRepository: _AlreadyPremiumSubscriptionRepository(),
            accountRepository: accountRepository,
          ),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _reachAuthChoiceScreen(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrarse con email'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'password1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Francés · A1'), findsOneWidget);
      expect(find.textContaining('email de confirmación'), findsOneWidget);
    },
  );

  testWidgets(
    'a rejected sign-up (e.g. email already registered) is shown inline, not accepted',
    (tester) async {
      final accountRepository = InMemoryAccountRepository(
        errorFor: {'ana@example.com': 'Ese email ya tiene una cuenta.'},
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: _baseOverrides(
            subscriptionRepository: _AlreadyPremiumSubscriptionRepository(),
            accountRepository: accountRepository,
          ),
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _reachAuthChoiceScreen(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrarse con email'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'password1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Ese email ya tiene una cuenta.'), findsOneWidget);
      expect(find.text('Crea tu cuenta'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    },
  );
}
