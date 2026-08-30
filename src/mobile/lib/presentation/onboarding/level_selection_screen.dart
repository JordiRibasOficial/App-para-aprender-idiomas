import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/onboarding_providers.dart';
import '../theme/app_theme.dart';

class LevelSelectionScreen extends ConsumerWidget {
  const LevelSelectionScreen({super.key});

  /// Public so [LanguageSelectionScreen] can decide, without duplicating
  /// this list, whether this screen has any real choice to offer — see its
  /// use of [availableLevels].
  static const availableLevels = ['A1'];
  static const _comingSoonLevels = ['A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingSelectedLevelProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('¿Cuál es tu nivel?')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        children: [
          RadioGroup<String>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(onboardingSelectedLevelProvider.notifier)
                    .select(value);
              }
            },
            child: Column(
              children: [
                for (final level in availableLevels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                    child: _LevelCard(
                      level: level,
                      selected: selected == level,
                      onTap: () => ref
                          .read(onboardingSelectedLevelProvider.notifier)
                          .select(level),
                    ),
                  ),
              ],
            ),
          ),
          if (_comingSoonLevels.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
              child: Text(
                'Próximamente',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Wrap(
              spacing: AppTheme.spaceSm,
              runSpacing: AppTheme.spaceSm,
              children: [
                for (final level in _comingSoonLevels)
                  Chip(
                    avatar: Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    label: Text(level),
                    backgroundColor: scheme.surfaceContainerLow,
                    labelStyle: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    side: BorderSide.none,
                  ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: FilledButton(
            onPressed: () => context.push('/onboarding/auth'),
            child: const Text('Continuar'),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final String level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      // excludeSemantics drops the title/subtitle Text and the decorative
      // Radio below from the accessibility tree — otherwise they'd show up
      // as extra, redundant swipe stops alongside this label.
      excludeSemantics: true,
      onTap: onTap,
      label: level,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          excludeFromSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMd,
              vertical: AppTheme.spaceMd,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level,
                        // Selected fill is scheme.primaryContainer — follow
                        // its matching "on container" role rather than the
                        // app's default text color.
                        style: textTheme.titleMedium?.copyWith(
                          color: selected ? scheme.onPrimaryContainer : null,
                        ),
                      ),
                      Text(
                        'Curso completo disponible',
                        style: textTheme.bodySmall?.copyWith(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<String>(value: level),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
