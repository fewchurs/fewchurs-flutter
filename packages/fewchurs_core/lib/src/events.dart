import 'errors.dart';

/// Something that happened in the SDK, for analytics. See [name].
sealed class FewchursEvent {
  const FewchursEvent();

  /// Stable snake_case event name, e.g. `voted`.
  String get name;
}

/// The board was shown.
final class BoardOpened extends FewchursEvent {
  const BoardOpened();

  @override
  String get name => 'board_opened';
}

/// A request was submitted.
final class FeatureSubmitted extends FewchursEvent {
  const FeatureSubmitted(this.featureId);

  final String featureId;

  @override
  String get name => 'feature_submitted';
}

/// A vote was added or removed.
final class Voted extends FewchursEvent {
  const Voted(this.featureId, {required this.voted});

  final String featureId;
  final bool voted;

  @override
  String get name => voted ? 'voted' : 'unvoted';
}

/// A comment was posted.
final class Commented extends FewchursEvent {
  const Commented(this.featureId, this.commentId);

  final String featureId;
  final String commentId;

  @override
  String get name => 'commented';
}

/// The user followed or unfollowed a request.
final class Followed extends FewchursEvent {
  const Followed(this.featureId, {required this.following});

  final String featureId;
  final bool following;

  @override
  String get name => following ? 'followed' : 'unfollowed';
}

/// A call failed with [error].
final class FewchursErrorEvent extends FewchursEvent {
  const FewchursErrorEvent(this.error);

  final FewchursException error;

  @override
  String get name => 'error';
}
