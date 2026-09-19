import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/material.dart';

import '../l10n/fewchurs_strings.dart';
import '../theme/fewchurs_theme.dart';

class FewchursLoadingView extends StatelessWidget {
  const FewchursLoadingView({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = FewchursThemeData.of(context);
    final block = t.onSurface.withAlpha(0x14);
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
                color: block, borderRadius: BorderRadius.circular(6)),
          ),
        );

    return ExcludeSemantics(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          padding: EdgeInsets.all(t.spacing),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(t.cardRadius),
            border: Border.all(color: t.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 52,
                decoration: BoxDecoration(
                    color: block,
                    borderRadius: BorderRadius.circular(t.buttonRadius)),
              ),
              SizedBox(width: t.spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(0.7, 16),
                    const SizedBox(height: 8),
                    bar(0.95, 12),
                    const SizedBox(height: 6),
                    bar(0.5, 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FewchursMessageView extends StatelessWidget {
  const FewchursMessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = FewchursThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: t.muted),
          const SizedBox(height: 12),
          Text(title, style: t.titleStyle, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, style: t.bodyStyle, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class FewchursErrorView extends StatelessWidget {
  const FewchursErrorView({super.key, required this.error, this.onRetry});

  final FewchursException error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final s = FewchursStrings.of(context);
    return FewchursMessageView(
      icon: error is FewchursNetworkException
          ? Icons.wifi_off_rounded
          : Icons.error_outline_rounded,
      title: s.error(error),
      action: onRetry == null
          ? null
          : OutlinedButton(onPressed: onRetry, child: Text(s.retry)),
    );
  }
}
