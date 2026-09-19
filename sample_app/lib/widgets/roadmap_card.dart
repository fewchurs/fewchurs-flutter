import 'package:fewchurs/fewchurs.dart';
import 'package:flutter/material.dart';

/// Example: headless usage. A compact "coming soon" card built from a
/// [BoardController], with the app's own widgets.
class RoadmapCard extends StatefulWidget {
  const RoadmapCard({super.key});

  @override
  State<RoadmapCard> createState() => _RoadmapCardState();
}

class _RoadmapCardState extends State<RoadmapCard> {
  late final BoardController _roadmap = Fewchurs.boardController(
    statuses: {FeatureStatus.planned, FeatureStatus.inProgress},
    pageSize: 10,
  );

  @override
  void dispose() {
    _roadmap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _roadmap,
      builder: (context, _) {
        final state = _roadmap.state;
        if (state is! BoardContent || state.features.isEmpty) {
          return const SizedBox.shrink();
        }
        final items = state.features.take(3).toList();
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rocket_launch_outlined, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text('Coming soon',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Fewchurs.showBoard(context),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                for (final f in items)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(f.title)),
                        FewchursStatusChip(status: f.status),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
