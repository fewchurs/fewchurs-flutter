import 'errors.dart';

sealed class FewchursEvent {
  const FewchursEvent();

  String get name;
}

final class BoardOpened extends FewchursEvent {
  const BoardOpened();

  @override
  String get name => 'board_opened';
}

final class FeatureSubmitted extends FewchursEvent {
  const FeatureSubmitted(this.featureId);

  final String featureId;

  @override
  String get name => 'feature_submitted';
}

final class Voted extends FewchursEvent {
  const Voted(this.featureId, {required this.voted});

  final String featureId;
  final bool voted;

  @override
  String get name => voted ? 'voted' : 'unvoted';
}

final class Commented extends FewchursEvent {
  const Commented(this.featureId, this.commentId);

  final String featureId;
  final String commentId;

  @override
  String get name => 'commented';
}

final class Followed extends FewchursEvent {
  const Followed(this.featureId, {required this.following});

  final String featureId;
  final bool following;

  @override
  String get name => following ? 'followed' : 'unfollowed';
}

final class FewchursErrorEvent extends FewchursEvent {
  const FewchursErrorEvent(this.error);

  final FewchursException error;

  @override
  String get name => 'error';
}
