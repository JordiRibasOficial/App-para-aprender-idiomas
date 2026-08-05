import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/onboarding_providers.dart';

class LevelSelectionScreen extends ConsumerWidget {
  const LevelSelectionScreen({super.key});

  static const _availableLevels = ['A1'];
  static const _comingSoonLevels = ['A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingSelectedLevelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('¿Cuál es tu nivel?')),
      body: ListView(
        children: [
          RadioGroup<String>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) ref.read(onboardingSelectedLevelProvider.notifier).select(value);
            },
            child: Column(
              children: [
                for (final level in _availableLevels)
                  RadioListTile<String>(
                    value: level,
                    title: Text(level),
                    subtitle: const Text('Curso completo disponible'),
                  ),
              ],
            ),
          ),
          for (final level in _comingSoonLevels)
            ListTile(
              enabled: false,
              leading: const Icon(Icons.lock_outline),
              title: Text(level),
              subtitle: const Text('Próximamente'),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => context.push('/onboarding/auth'),
            child: const Text('Continuar'),
          ),
        ),
      ),
    );
  }
}
