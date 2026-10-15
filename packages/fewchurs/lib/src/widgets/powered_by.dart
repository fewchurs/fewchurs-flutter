import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/material.dart';

import '../l10n/fewchurs_strings.dart';
import '../runtime.dart';
import '../theme/fewchurs_theme.dart';

/// Shown only when the server says so (`showBranding`). Starter and Pro plans
/// hide it. If `/config` can't be loaded it is shown.
class FewchursPoweredBy extends StatelessWidget {
  const FewchursPoweredBy({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RemoteConfig>(
      valueListenable: FewchursRuntime.instance.remote,
      builder: (context, remote, _) {
        if (!remote.showBranding) return const SizedBox.shrink();
        final t = FewchursThemeData.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              FewchursStrings.of(context).poweredBy,
              style: t.labelStyle.copyWith(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
