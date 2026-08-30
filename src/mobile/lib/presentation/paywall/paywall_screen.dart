import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/entitlement.dart';
import '../../domain/models/subscription_plan.dart';
import '../account/require_account.dart';
import '../legal_urls.dart';
import '../providers/account_providers.dart';
import '../providers/subscription_providers.dart';
import '../theme/app_theme.dart';
import 'plan_card.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.annual;
  bool _purchasing = false;
  bool _restoring = false;
  // Not pre-checked, same rationale as the onboarding terms checkbox: an
  // explicit tick is the evidence of the "prior express consent" art.
  // 103.m TRLGDCU / art. 16.m Directiva 2011/83 requires before a digital
  // subscription can start immediately and the 14-day withdrawal right can
  // be excluded — see the clause added to terms-of-service-draft.md § 4.
  bool _withdrawalConsent = false;

  Future<void> _purchase(SubscriptionPlan plan) async {
    if (!await requireAccount(context, ref)) return;
    if (!mounted) return;

    setState(() => _purchasing = true);
    try {
      await ref.read(subscriptionRepositoryProvider).purchase(plan);
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    if (!await requireAccount(context, ref)) return;
    if (!mounted) return;

    setState(() => _restoring = true);
    try {
      await ref.read(subscriptionRepositoryProvider).restorePurchases();
      // restorePurchases() only confirms the store request was issued, not
      // that a restored entitlement (if any) has arrived on
      // entitlementStream yet — give it a moment before concluding there was
      // nothing to restore. Best-effort: the exact delivery timing isn't
      // independently verified against a real store here (Paso 9's known
      // limitation, see InAppPurchaseSubscriptionRepository's class doc).
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final isActive = ref.read(entitlementProvider).value?.isActive ?? false;
      if (!isActive) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('No se encontraron compras anteriores.'),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final entitlement =
        ref.watch(entitlementProvider).value ?? const Entitlement();
    // Keeps accountSessionProvider actively subscribed and resolved well
    // before a user can tap "Suscribirse"/"Restaurar compras" — see
    // requireAccount's doc comment for why this matters.
    ref.watch(accountSessionProvider);

    ref.listen(purchaseErrorProvider, (previous, next) {
      final message = next.value;
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Hazte Premium')),
      body: entitlement.isActive
          ? _ActiveSubscriptionView(entitlement: entitlement)
          : plansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No se pudieron cargar los planes: $error'),
                ),
              ),
              data: (plans) {
                if (plans.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Los planes de suscripción no están disponibles todavía.',
                      ),
                    ),
                  );
                }
                return _PlansView(
                  plans: plans,
                  selectedPeriod: _selectedPeriod,
                  purchasing: _purchasing,
                  restoring: _restoring,
                  withdrawalConsent: _withdrawalConsent,
                  onSelect: (period) =>
                      setState(() => _selectedPeriod = period),
                  onPurchase: _purchase,
                  onRestore: _restore,
                  onWithdrawalConsentChanged: (value) =>
                      setState(() => _withdrawalConsent = value ?? false),
                );
              },
            ),
    );
  }
}

class _PlansView extends StatelessWidget {
  const _PlansView({
    required this.plans,
    required this.selectedPeriod,
    required this.purchasing,
    required this.restoring,
    required this.withdrawalConsent,
    required this.onSelect,
    required this.onPurchase,
    required this.onRestore,
    required this.onWithdrawalConsentChanged,
  });

  final List<SubscriptionPlan> plans;
  final SubscriptionPeriod selectedPeriod;
  final bool purchasing;
  final bool restoring;
  final bool withdrawalConsent;
  final ValueChanged<SubscriptionPeriod> onSelect;
  final Future<void> Function(SubscriptionPlan plan) onPurchase;
  final Future<void> Function() onRestore;
  final ValueChanged<bool?> onWithdrawalConsentChanged;

  @override
  Widget build(BuildContext context) {
    final monthly = plans.firstWhere(
      (p) => p.period == SubscriptionPeriod.monthly,
    );
    final annual = plans.firstWhere(
      (p) => p.period == SubscriptionPeriod.annual,
    );
    final savingsRatio = SubscriptionPlan.annualSavingsRatio(
      monthly: monthly,
      annual: annual,
    );
    final selectedPlan = selectedPeriod == SubscriptionPeriod.monthly
        ? monthly
        : annual;

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.tertiaryContainer,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 36,
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          Text(
            'Aprende sin límites',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spaceLg),
          const _BenefitRow(
            text:
                'Los 4 idiomas completos: inglés, portugués, francés y japonés',
          ),
          const SizedBox(height: AppTheme.spaceSm),
          const _BenefitRow(text: 'Sin anuncios, en toda la app'),
          const SizedBox(height: AppTheme.spaceXl),
          PlanCard(
            plan: monthly,
            selected: selectedPeriod == SubscriptionPeriod.monthly,
            onTap: () => onSelect(SubscriptionPeriod.monthly),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          PlanCard(
            plan: annual,
            selected: selectedPeriod == SubscriptionPeriod.annual,
            savingsRatio: savingsRatio,
            onTap: () => onSelect(SubscriptionPeriod.annual),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          // Explicit clickwrap, not just ToS text: art. 103.m TRLGDCU / art.
          // 16.m Directiva 2011/83 requires the consumer's prior express
          // consent to start a digital service immediately, plus their
          // express acknowledgment of losing the 14-day withdrawal right —
          // both conditions, satisfied by a single unchecked-by-default box
          // the user must tick themselves before the button becomes active.
          CheckboxListTile(
            value: withdrawalConsent,
            onChanged: onWithdrawalConsentChanged,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Entiendo que el acceso empieza de inmediato y renuncio a mi '
              'derecho de desistimiento de 14 días para este contenido '
              'digital.',
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          FilledButton(
            onPressed: (purchasing || !withdrawalConsent)
                ? null
                : () => onPurchase(selectedPlan),
            child: purchasing
                ? Semantics(
                    label: 'Procesando compra',
                    child: const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Text('Suscribirse — ${selectedPlan.formattedPrice}'),
          ),
          TextButton(
            onPressed: restoring ? null : onRestore,
            child: restoring
                ? Semantics(
                    label: 'Restaurando compras',
                    child: const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Text('Restaurar compras'),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            'La suscripción se renueva automáticamente al final de cada periodo '
            '(mensual o anual) salvo que la canceles antes. Se gestiona y se '
            'cancela desde los ajustes de tu cuenta de Google Play o Apple, no '
            'desde la app.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => launchUrl(Uri.parse(kTermsUrl)),
                child: const Text('Términos de servicio'),
              ),
              TextButton(
                onPressed: () => launchUrl(Uri.parse(kPrivacyUrl)),
                child: const Text('Política de privacidad'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.check_circle, size: 20, color: scheme.primary),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ActiveSubscriptionView extends StatelessWidget {
  const _ActiveSubscriptionView({required this.entitlement});

  final Entitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.tertiaryContainer,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 48,
                color: scheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text('¡Ya eres Premium!', style: textTheme.headlineSmall),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              'Plan activo: ${entitlement.activeProductId}',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
