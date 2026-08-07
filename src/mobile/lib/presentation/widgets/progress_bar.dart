import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.label});

  /// Progress in the 0.0–1.0 range.
  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: value.clamp(0.0, 1.0), minHeight: 8),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(label!, style: Theme.of(context).textTheme.labelMedium),
        ],
      ],
    );
  }
}
