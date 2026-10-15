import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/material.dart';

import '../l10n/fewchurs_strings.dart';
import '../theme/fewchurs_theme.dart';
import 'status_chip.dart';
import 'vote_button.dart';

@immutable
class FeatureActions {
  const FeatureActions({required this.toggleVote, required this.open});

  final VoidCallback toggleVote;
  final VoidCallback open;
}

typedef FeatureCardBuilder = Widget Function(
    BuildContext context, Feature feature, FeatureActions actions);

class FewchursFeatureCard extends StatelessWidget {
  const FewchursFeatureCard({
    super.key,
    required this.feature,
    required this.actions,
    this.hideVoteCount = false,
    this.selected = false,
    this.voteButtonBuilder,
    this.statusChipBuilder,
  });

  final Feature feature;
  final FeatureActions actions;
  final bool hideVoteCount;
  final bool selected;
  final VoteButtonBuilder? voteButtonBuilder;
  final StatusChipBuilder? statusChipBuilder;

  @override
  Widget build(BuildContext context) {
    final t = FewchursThemeData.of(context);
    final s = FewchursStrings.of(context);
    final voteState = VoteButtonState(
      voted: feature.hasVoted,
      count: feature.upvoteCount,
      hideCount: hideVoteCount,
      onPressed: actions.toggleVote,
    );
    final showStatus = feature.status != FeatureStatus.open;

    return Material(
      color: selected
          ? Color.alphaBlend(t.primary.withAlpha(0x1F), t.card)
          : t.card,
      elevation: t.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: actions.open,
        child: Padding(
          padding: EdgeInsets.all(t.spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              voteButtonBuilder?.call(context, voteState) ??
                  FewchursVoteButton(state: voteState),
              SizedBox(width: t.spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(feature.title,
                        style: t.titleStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (feature.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(feature.description,
                          style: t.bodyStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    SizedBox(height: t.compact ? 6 : 10),
                    Row(
                      children: [
                        if (showStatus)
                          statusChipBuilder?.call(context, feature.status) ??
                              FewchursStatusChip(status: feature.status),
                        const Spacer(),
                        Semantics(
                          label: s.commentCount(feature.commentCount),
                          excludeSemantics: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 16, color: t.muted),
                              const SizedBox(width: 4),
                              Text('${feature.commentCount}',
                                  style: t.labelStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
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
