import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/target_language.dart';
import '../providers/onboarding_providers.dart';
import '../providers/subscription_providers.dart';
import '../theme/app_theme.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingSelectedLanguageProvider);
    final isPremium = ref.watch(entitlementProvider).value?.isActive ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Elige tu idioma')),
      body: RadioGroup<String>(
        groupValue: selected,
        onChanged: (value) {
          if (value != null) {
            ref.read(onboardingSelectedLanguageProvider.notifier).select(value);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          children: [
            for (final language in kLaunchTargetLanguages)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: _LanguageOptionCard(
                  language: language,
                  selected: selected == language.code,
                  locked: language.requiresPremium && !isPremium,
                  onTap: () => ref
                      .read(onboardingSelectedLanguageProvider.notifier)
                      .select(language.code),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: FilledButton(
            onPressed: () {
              final needsPremium =
                  targetLanguageOption(selected).requiresPremium && !isPremium;
              context.push(needsPremium ? '/paywall' : '/onboarding/level');
            },
            child: const Text('Continuar'),
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.language,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final TargetLanguageOption language;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(language.flagEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.displayName, style: textTheme.titleMedium),
                    Text(
                      locked
                          ? 'Requiere Premium'
                          : 'Curso A1 completo disponible',
                      style: textTheme.bodySmall?.copyWith(
                        color: locked
                            ? scheme.tertiary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                Icon(Icons.workspace_premium_outlined, color: scheme.tertiary)
              else
                Radio<String>(value: language.code),
            ],
          ),
        ),
      ),
    );
  }
}
