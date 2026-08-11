import 'package:flutter/material.dart';

import '../../domain/models/subscription_plan.dart';
import '../theme/app_theme.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
    this.savingsRatio,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  /// If set, renders a "-N%" badge (e.g. the annual plan's saving over 12
  /// months of the monthly plan).
  final double? savingsRatio;

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
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title, style: textTheme.titleMedium),
                    Text(
                      plan.formattedPrice,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (savingsRatio != null && savingsRatio! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSm,
                    vertical: AppTheme.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    '-${(savingsRatio! * 100).round()}%',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
