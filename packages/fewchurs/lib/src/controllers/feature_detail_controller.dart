import 'dart:async';
import 'dart:math' as math;

import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/foundation.dart';

import 'vote_queue.dart';

class FeatureDetailController extends ChangeNotifier {
  FeatureDetailController({
    required FewchursClient client,
    required Feature feature,
    this.pageSize = 20,
    this.onFeatureChanged,
    VoteQueue? votes,
    bool autoLoad = true,
  })  : _client = client,
        _feature = feature,
        _votes = votes ?? VoteQueue(client) {
    if (autoLoad) loadComments();
  }

  static const _maxEmptyPages = 10;

  final FewchursClient _client;
  final VoteQueue _votes;
  final int pageSize;
  final ValueChanged<Feature>? onFeatureChanged;
  final _actionErrors = StreamController<FewchursException>.broadcast();

  Feature _feature;
  List<Comment> _comments = const [];
  String? _cursor;
  bool _commentsLoaded = false;
  bool _loadingComments = false;
  FewchursException? _commentsError;
  bool _followPending = false;
  bool _sendingComment = false;
  bool _removed = false;
  bool _disposed = false;

  Feature get feature => _feature;
  List<Comment> get comments => _comments;
  bool get commentsLoaded => _commentsLoaded;
  bool get isLoadingComments => _loadingComments;
  bool get canLoadMoreComments => _cursor != null;
  FewchursException? get commentsError => _commentsError;
  bool get isFollowPending => _followPending;
  bool get isSendingComment => _sendingComment;

  /// True once the server reports the feature no longer exists.
  bool get isRemoved => _removed;

  Stream<FewchursException> get actionErrors => _actionErrors.stream;

  Future<void> loadComments() => _loadComments(reset: true);

  Future<void> loadMoreComments() {
    if (!_commentsLoaded || _cursor == null) return Future.value();
    return _loadComments(reset: false);
  }

  Future<void> _loadComments({required bool reset}) async {
    if (_loadingComments) return;
    _loadingComments = true;
    _commentsError = null;
    _notify();
    try {
      final loaded = <Comment>[];
      var next = reset ? null : _cursor;
      var pages = 0;
      do {
        final page =
            await _client.listComments(_feature.id, limit: pageSize, cursor: next);
        loaded.addAll(page.comments);
        next = page.nextCursor;
        pages++;
      } while (loaded.isEmpty && next != null && pages < _maxEmptyPages);
      final seen = reset ? <String>{} : _comments.map((c) => c.id).toSet();
      _comments = [
        if (!reset) ..._comments,
        ...loaded.where((c) => seen.add(c.id)),
      ];
      _cursor = next;
      _commentsLoaded = true;
    } on FewchursException catch (e) {
      _commentsError = e;
      _handleNotFound(e);
    } finally {
      _loadingComments = false;
      _notify();
    }
  }

  Future<void> toggleVote() async {
    try {
      await _votes.toggle(_feature, _apply);
    } on FewchursException catch (e) {
      _handleNotFound(e);
      _reportError(e);
    }
  }

  /// Following always needs an [email]; unfollowing doesn't.
  Future<bool> setFollowing(bool follow, {String? email}) async {
    if (_followPending || follow == _feature.isFollowing) return true;
    if (follow && (email == null || email.trim().isEmpty)) return false;
    _followPending = true;
    _notify();
    try {
      if (follow) {
        await _client.follow(_feature.id, email: email!);
      } else {
        await _client.unfollow(_feature.id);
      }
      _apply((f) => f.copyWith(
            isFollowing: follow,
            followerCount: math.max(0, f.followerCount + (follow ? 1 : -1)),
          ));
      return true;
    } on FewchursException catch (e) {
      _handleNotFound(e);
      _reportError(e);
      return false;
    } finally {
      _followPending = false;
      _notify();
    }
  }

  Future<Comment?> addComment(String text, {String? authorName}) async {
    if (_sendingComment) return null;
    _sendingComment = true;
    _notify();
    try {
      final comment = await _client.addComment(_feature.id,
          text: text, authorName: authorName);
      if (_cursor == null) _comments = [..._comments, comment];
      _apply((f) => f.copyWith(commentCount: f.commentCount + 1));
      return comment;
    } on FewchursException catch (e) {
      _handleNotFound(e);
      _reportError(e);
      return null;
    } finally {
      _sendingComment = false;
      _notify();
    }
  }

  void _apply(Feature Function(Feature) update) {
    final next = update(_feature);
    if (next == _feature) return;
    _feature = next;
    _notify();
    if (!_disposed) onFeatureChanged?.call(next);
  }

  void _handleNotFound(FewchursException e) {
    if (e is FewchursNotFoundException) _removed = true;
  }

  void _reportError(FewchursException e) {
    if (!_disposed) _actionErrors.add(e);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _actionErrors.close();
    super.dispose();
  }
}
