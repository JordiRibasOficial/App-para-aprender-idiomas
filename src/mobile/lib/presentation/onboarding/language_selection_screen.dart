import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/target_language.dart';
import '../providers/onboarding_providers.dart';
import '../providers/subscription_providers.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingSelectedLanguageProvider);
    final isPremium = ref.watch(entitlementProvider).value?.isActive ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('¿Qué idioma quieres aprender?')),
      body: RadioGroup<String>(
        groupValue: selected,
        onChanged: (value) {
          if (value != null) ref.read(onboardingSelectedLanguageProvider.notifier).select(value);
        },
        child: ListView(
          children: [
            for (final language in kLaunchTargetLanguages)
              RadioListTile<String>(
                value: language.code,
                title: Text('${language.flagEmoji}  ${language.displayName}'),
                subtitle: Text(
                  !language.requiresPremium || isPremium
                      ? 'Curso A1 completo disponible'
                      : 'Requiere Premium',
                ),
                secondary: !language.requiresPremium || isPremium
                    ? null
                    : const Icon(Icons.workspace_premium_outlined),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () {
              final needsPremium = targetLanguageOption(selected).requiresPremium && !isPremium;
              context.push(needsPremium ? '/paywall' : '/onboarding/level');
            },
            child: const Text('Continuar'),
          ),
        ),
      ),
    );
  }
}
