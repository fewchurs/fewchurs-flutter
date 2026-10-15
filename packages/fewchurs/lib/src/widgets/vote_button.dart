import 'package:flutter/material.dart';

import '../l10n/fewchurs_strings.dart';
import '../theme/fewchurs_theme.dart';

@immutable
class VoteButtonState {
  const VoteButtonState({
    required this.voted,
    required this.count,
    required this.hideCount,
    required this.onPressed,
  });

  final bool voted;
  final int count;
  final bool hideCount;
  final VoidCallback onPressed;
}

typedef VoteButtonBuilder = Widget Function(
    BuildContext context, VoteButtonState state);

class FewchursVoteButton extends StatelessWidget {
  const FewchursVoteButton({super.key, required this.state});

  final VoteButtonState state;

  @override
  Widget build(BuildContext context) {
    final t = FewchursThemeData.of(context);
    final s = FewchursStrings.of(context);
    final style = t.voteButtonStyle;
    final voted = state.voted;
    final filled = voted && style != VoteButtonStyle.minimal;
    final fg = filled ? t.onPrimary : (voted ? t.primary : t.onSurface);
    final bg = filled
        ? t.primary
        : (style == VoteButtonStyle.minimal ? Colors.transparent : t.fill);
    final radius = style == VoteButtonStyle.pill ? 999.0 : t.buttonRadius;

    final icon = Icon(Icons.keyboard_arrow_up_rounded,
        size: style == VoteButtonStyle.pill ? 20 : 24, color: fg);
    final count = state.hideCount
        ? null
        : Text(
            '${state.count}',
            style: t.labelStyle.copyWith(
                color: fg, fontWeight: FontWeight.w700, fontSize: 13),
          );

    final content = style == VoteButtonStyle.pill
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [icon, if (count != null) ...[const SizedBox(width: 2), count]],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [icon, if (count != null) count],
          );

    final semantics = [
      s.upvote,
      if (!state.hideCount) s.votes(state.count),
      if (voted) s.voted,
    ].join(', ');

    return Semantics(
      button: true,
      toggled: voted,
      label: semantics,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Material(
          color: bg,
          animationDuration: const Duration(milliseconds: 150),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: state.onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: style == VoteButtonStyle.pill ? 12 : 8,
                vertical: 6,
              ),
              child: Center(widthFactor: 1, heightFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
