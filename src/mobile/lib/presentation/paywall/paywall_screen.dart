import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/entitlement.dart';
import '../../domain/models/subscription_plan.dart';
import '../providers/subscription_providers.dart';
import 'plan_card.dart';

/// Required by App Store Review Guideline 3.1.2 (and expected by Google
/// Play's subscriptions policy): auto-renewal terms and links to the legal
/// docs must be visible on the purchase screen itself, not just buried in
/// a settings page.
const _termsUrl = 'https://jordiribasoficial.github.io/App-para-aprender-idiomas/terms.html';
const _privacyUrl = 'https://jordiribasoficial.github.io/App-para-aprender-idiomas/privacy.html';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.annual;
  bool _purchasing = false;

  Future<void> _purchase(SubscriptionPlan plan) async {
    setState(() => _purchasing = true);
    try {
      await ref.read(subscriptionRepositoryProvider).purchase(plan);
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final entitlement = ref.watch(entitlementProvider).value ?? const Entitlement();

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
                      child: Text('Los planes de suscripción no están disponibles todavía.'),
                    ),
                  );
                }
                return _PlansView(
                  plans: plans,
                  selectedPeriod: _selectedPeriod,
                  purchasing: _purchasing,
                  onSelect: (period) => setState(() => _selectedPeriod = period),
                  onPurchase: _purchase,
                );
              },
            ),
    );
  }
}

class _PlansView extends ConsumerWidget {
  const _PlansView({
    required this.plans,
    required this.selectedPeriod,
    required this.purchasing,
    required this.onSelect,
    required this.onPurchase,
  });

  final List<SubscriptionPlan> plans;
  final SubscriptionPeriod selectedPeriod;
  final bool purchasing;
  final ValueChanged<SubscriptionPeriod> onSelect;
  final Future<void> Function(SubscriptionPlan plan) onPurchase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthly = plans.firstWhere((p) => p.period == SubscriptionPeriod.monthly);
    final annual = plans.firstWhere((p) => p.period == SubscriptionPeriod.annual);
    final savingsRatio = SubscriptionPlan.annualSavingsRatio(monthly: monthly, annual: annual);
    final selectedPlan = selectedPeriod == SubscriptionPeriod.monthly ? monthly : annual;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aprende sin límites',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          PlanCard(
            plan: monthly,
            selected: selectedPeriod == SubscriptionPeriod.monthly,
            onTap: () => onSelect(SubscriptionPeriod.monthly),
          ),
          const SizedBox(height: 12),
          PlanCard(
            plan: annual,
            selected: selectedPeriod == SubscriptionPeriod.annual,
            savingsRatio: savingsRatio,
            onTap: () => onSelect(SubscriptionPeriod.annual),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: purchasing ? null : () => onPurchase(selectedPlan),
            child: purchasing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Suscribirse — ${selectedPlan.formattedPrice}'),
          ),
          TextButton(
            onPressed: () => ref.read(subscriptionRepositoryProvider).restorePurchases(),
            child: const Text('Restaurar compras'),
          ),
          const SizedBox(height: 16),
          Text(
            'La suscripción se renueva automáticamente al final de cada periodo '
            '(mensual o anual) salvo que la canceles antes. Se gestiona y se '
            'cancela desde los ajustes de tu cuenta de Google Play o Apple, no '
            'desde la app.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => launchUrl(Uri.parse(_termsUrl)),
                child: const Text('Términos de servicio'),
              ),
              TextButton(
                onPressed: () => launchUrl(Uri.parse(_privacyUrl)),
                child: const Text('Política de privacidad'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveSubscriptionView extends StatelessWidget {
  const _ActiveSubscriptionView({required this.entitlement});

  final Entitlement entitlement;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('¡Ya eres Premium!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Plan activo: ${entitlement.activeProductId}'),
          ],
        ),
      ),
    );
  }
}
