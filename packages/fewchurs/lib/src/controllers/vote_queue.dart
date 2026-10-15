import 'dart:math' as math;

import 'package:fewchurs_core/fewchurs_core.dart';

typedef FeatureUpdate = Feature Function(Feature current);

/// Optimistic voting shared by every controller. Rapid taps on the same
/// feature collapse into one request per state change, and failures roll
/// back to the last server state.
class VoteQueue {
  VoteQueue(this.client);

  final FewchursClient client;
  final _desired = <String, bool>{};
  final _base = <String, Feature>{};
  final _running = <String>{};

  Future<void> toggle(
    Feature feature,
    void Function(FeatureUpdate update) apply,
  ) async {
    final id = feature.id;
    final want = !feature.hasVoted;
    _base.putIfAbsent(id, () => feature);
    _desired[id] = want;
    apply((f) => f.copyWith(
          hasVoted: want,
          upvoteCount: math.max(0, f.upvoteCount + (want ? 1 : -1)),
        ));
    if (!_running.add(id)) return;

    try {
      while (true) {
        final target = _desired[id]!;
        final result = target ? await client.vote(id) : await client.unvote(id);
        if (_desired[id] == target) {
          apply((f) => f.copyWith(
              hasVoted: result.hasVoted, upvoteCount: result.upvoteCount));
          return;
        }
      }
    } catch (_) {
      final base = _base[id]!;
      apply((f) =>
          f.copyWith(hasVoted: base.hasVoted, upvoteCount: base.upvoteCount));
      rethrow;
    } finally {
      _running.remove(id);
      _desired.remove(id);
      _base.remove(id);
    }
  }
}
