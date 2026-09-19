import 'dart:async';

import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/foundation.dart';

import 'vote_queue.dart';

sealed class BoardState {
  const BoardState();
}

final class BoardLoading extends BoardState {
  const BoardLoading();
}

final class BoardError extends BoardState {
  const BoardError(this.error);

  final FewchursException error;
}

final class BoardContent extends BoardState {
  const BoardContent({
    required this.features,
    required this.canLoadMore,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.loadMoreError,
  });

  final List<Feature> features;
  final bool canLoadMore;
  final bool isLoadingMore;
  final bool isRefreshing;
  final FewchursException? loadMoreError;
}

/// Holds one sorted, paginated list of features. A plain [ChangeNotifier],
/// so it works with `setState`, Provider, Riverpod, Bloc or anything else.
class BoardController extends ChangeNotifier {
  BoardController({
    required FewchursClient client,
    this.sort = FeatureSort.top,
    this.statuses,
    this.showDeclined = false,
    this.pageSize = 20,
    VoteQueue? votes,
    bool autoLoad = true,
  })  : _client = client,
        _votes = votes ?? VoteQueue(client) {
    if (autoLoad) refresh();
  }

  static const _maxEmptyPages = 10;

  final FewchursClient _client;
  final VoteQueue _votes;
  final FeatureSort sort;
  final Set<FeatureStatus>? statuses;
  final bool showDeclined;
  final int pageSize;

  final _actionErrors = StreamController<FewchursException>.broadcast();
  BoardState _state = const BoardLoading();
  List<Feature> _features = const [];
  String? _cursor;
  bool _loaded = false;
  bool _loadingMore = false;
  bool _refreshing = false;
  FewchursException? _error;
  FewchursException? _loadMoreError;
  int _generation = 0;
  bool _disposed = false;

  BoardState get state => _state;

  List<Feature> get features => _features;

  /// Errors from refreshes and votes that happen while content is visible.
  Stream<FewchursException> get actionErrors => _actionErrors.stream;

  Feature? featureById(String id) {
    for (final f in _features) {
      if (f.id == id) return f;
    }
    return null;
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    _refreshing = _loaded;
    _loadingMore = false;
    _error = null;
    _loadMoreError = null;
    _emit();
    try {
      final (items, cursor) = await _fetch(null);
      if (generation != _generation) return;
      _features = items;
      _cursor = cursor;
      _loaded = true;
    } on FewchursException catch (e) {
      if (generation != _generation) return;
      if (_loaded) {
        _reportError(e);
      } else {
        _error = e;
      }
    } finally {
      if (generation == _generation) {
        _refreshing = false;
        _emit();
      }
    }
  }

  Future<void> loadMore() async {
    if (!_loaded || _cursor == null || _loadingMore || _refreshing) return;
    final generation = _generation;
    _loadingMore = true;
    _loadMoreError = null;
    _emit();
    try {
      final (items, cursor) = await _fetch(_cursor);
      if (generation != _generation) return;
      final seen = _features.map((f) => f.id).toSet();
      _features = [..._features, ...items.where((f) => seen.add(f.id))];
      _cursor = cursor;
    } on FewchursException catch (e) {
      if (generation == _generation) _loadMoreError = e;
    } finally {
      if (generation == _generation) {
        _loadingMore = false;
        _emit();
      }
    }
  }

  Future<void> toggleVote(String featureId) async {
    final feature = featureById(featureId);
    if (feature == null) return;
    try {
      await _votes.toggle(feature, (update) => _update(featureId, update));
    } on FewchursException catch (e) {
      if (e is FewchursNotFoundException) remove(featureId);
      _reportError(e);
    }
  }

  /// Replaces a feature if it's in the list, e.g. after changes on its
  /// detail screen.
  void replace(Feature feature) => _update(feature.id, (_) => feature);

  void insertAtTop(Feature feature) {
    if (!_visible(feature)) return;
    _features = [feature, ..._features.where((f) => f.id != feature.id)];
    _loaded = true;
    _error = null;
    _emit();
  }

  void remove(String featureId) {
    final before = _features.length;
    _features = _features.where((f) => f.id != featureId).toList();
    if (_features.length != before) _emit();
  }

  void _update(String id, Feature Function(Feature) update) {
    final index = _features.indexWhere((f) => f.id == id);
    if (index < 0) return;
    _features = [..._features]..[index] = update(_features[index]);
    _emit();
  }

  Future<(List<Feature>, String?)> _fetch(String? cursor) async {
    final out = <Feature>[];
    var next = cursor;
    var pages = 0;
    do {
      final page = await _client.listFeatures(
          sort: sort, limit: pageSize, cursor: next, statuses: statuses);
      out.addAll(page.features.where(_visible));
      next = page.nextCursor;
      pages++;
    } while (out.isEmpty && next != null && pages < _maxEmptyPages);
    return (out, next);
  }

  bool _visible(Feature f) {
    if (!showDeclined && f.status == FeatureStatus.declined) return false;
    final filter = statuses;
    return filter == null || filter.isEmpty || filter.contains(f.status);
  }

  void _reportError(FewchursException e) {
    if (!_disposed) _actionErrors.add(e);
  }

  void _emit() {
    if (_disposed) return;
    _state = _loaded
        ? BoardContent(
            features: List.unmodifiable(_features),
            canLoadMore: _cursor != null,
            isLoadingMore: _loadingMore,
            isRefreshing: _refreshing,
            loadMoreError: _loadMoreError,
          )
        : _error != null
            ? BoardError(_error!)
            : const BoardLoading();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _actionErrors.close();
    super.dispose();
  }
}
