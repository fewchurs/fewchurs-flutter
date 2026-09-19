import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/material.dart';

import '../l10n/fewchurs_strings.dart';
import '../theme/fewchurs_theme.dart';

typedef StatusChipBuilder = Widget Function(
    BuildContext context, FeatureStatus status);

class FewchursStatusChip extends StatelessWidget {
  const FewchursStatusChip({super.key, required this.status});

  final FeatureStatus status;

  @override
  Widget build(BuildContext context) {
    final t = FewchursThemeData.of(context);
    final color = t.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(0x24),
        borderRadius: BorderRadius.circular(t.chipRadius),
      ),
      child: Text(
        FewchursStrings.of(context).status(status),
        style: t.labelStyle.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
