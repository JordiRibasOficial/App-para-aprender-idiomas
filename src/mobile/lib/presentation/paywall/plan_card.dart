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

    final label = savingsRatio != null && savingsRatio! > 0
        ? '${plan.title}, ${plan.formattedPrice}, ahorras ${(savingsRatio! * 100).round()}%'
        : '${plan.title}, ${plan.formattedPrice}';

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      // Without excludeSemantics, the title/price/badge Text children below
      // merge their own labels into this node, so screen readers would
      // narrate "Mensual, €14.99. Mensual. €14.99." — the explicit label
      // already says everything needed once.
      excludeSemantics: true,
      onTap: onTap,
      label: label,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          excludeFromSemantics: true,
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
                      Text(
                        plan.title,
                        // Selected fill is scheme.primaryContainer — follow
                        // its matching "on container" role rather than the
                        // app's default text color, which is only
                        // guaranteed to contrast against the default
                        // surface (same pattern as the savings badge below).
                        style: textTheme.titleMedium?.copyWith(
                          color: selected ? scheme.onPrimaryContainer : null,
                        ),
                      ),
                      Text(
                        plan.formattedPrice,
                        style: textTheme.bodyMedium?.copyWith(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
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
      ),
    );
  }
}
