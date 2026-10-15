import 'package:meta/meta.dart';

import 'json.dart';

/// Where a request stands. Unknown server values become [unknown].
enum FeatureStatus {
  open('open'),
  planned('planned'),
  inProgress('in_progress'),
  done('done'),
  declined('declined'),
  unknown('unknown');

  const FeatureStatus(this.wireName);

  /// The value used by the API.
  final String wireName;

  /// Parses an API value, falling back to [unknown].
  static FeatureStatus parse(Object? value) {
    for (final status in values) {
      if (status.wireName == value) return status;
    }
    return unknown;
  }
}

/// Board order: most votes first, or newest first.
enum FeatureSort {
  top('top'),
  newest('new');

  const FeatureSort(this.wireName);

  final String wireName;
}

/// A feature request on the board.
@immutable
class Feature {
  const Feature({
    required this.id,
    required this.title,
    this.description = '',
    this.status = FeatureStatus.open,
    this.upvoteCount = 0,
    this.commentCount = 0,
    this.followerCount = 0,
    this.hasVoted = false,
    this.isFollowing = false,
    this.isMine = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feature.fromJson(Map<String, Object?> json, {String? deviceId}) {
    final isMine = json['isMine'];
    return Feature(
      id: readString(json['id']),
      title: readString(json['title']),
      description: readString(json['description']),
      status: FeatureStatus.parse(json['status']),
      upvoteCount: readInt(json['upvoteCount']),
      commentCount: readInt(json['commentCount']),
      followerCount: readInt(json['followerCount']),
      hasVoted: readBool(json['hasVoted']),
      isFollowing: readBool(json['isFollowing']),
      isMine: isMine is bool
          ? isMine
          : deviceId != null && json['authorDeviceId'] == deviceId,
      createdAt: readDate(json['createdAt']),
      updatedAt: readDate(json['updatedAt']),
    );
  }

  /// Server ID.
  final String id;

  /// Short title, 3–100 characters.
  final String title;

  /// Optional details, up to 1000 characters.
  final String description;

  /// Where the request stands.
  final FeatureStatus status;

  /// Number of votes.
  final int upvoteCount;

  /// Number of comments.
  final int commentCount;

  /// Number of people following by email.
  final int followerCount;

  /// Whether this device has voted.
  final bool hasVoted;

  /// Whether this device follows the request.
  final bool isFollowing;

  /// Whether this device submitted the request.
  final bool isMine;

  /// When it was submitted.
  final DateTime createdAt;

  /// When it last changed.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  Feature copyWith({
    String? title,
    String? description,
    FeatureStatus? status,
    int? upvoteCount,
    int? commentCount,
    int? followerCount,
    bool? hasVoted,
    bool? isFollowing,
    bool? isMine,
    DateTime? updatedAt,
  }) {
    return Feature(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      commentCount: commentCount ?? this.commentCount,
      followerCount: followerCount ?? this.followerCount,
      hasVoted: hasVoted ?? this.hasVoted,
      isFollowing: isFollowing ?? this.isFollowing,
      isMine: isMine ?? this.isMine,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.wireName,
        'upvoteCount': upvoteCount,
        'commentCount': commentCount,
        'followerCount': followerCount,
        'hasVoted': hasVoted,
        'isFollowing': isFollowing,
        'isMine': isMine,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is Feature &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.status == status &&
      other.upvoteCount == upvoteCount &&
      other.commentCount == commentCount &&
      other.followerCount == followerCount &&
      other.hasVoted == hasVoted &&
      other.isFollowing == isFollowing &&
      other.isMine == isMine &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, title, description, status, upvoteCount,
      commentCount, followerCount, hasVoted, isFollowing, isMine, updatedAt);

  @override
  String toString() => 'Feature($id, $title, ${status.wireName})';
}

/// A comment on a [Feature].
@immutable
class Comment {
  const Comment({
    required this.id,
    required this.text,
    required this.authorName,
    this.isDeveloper = false,
    this.isMine = false,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, Object?> json, {String? deviceId}) {
    final isMine = json['isMine'];
    return Comment(
      id: readString(json['id']),
      text: readString(json['text']),
      authorName: readString(json['authorName']),
      isDeveloper: readBool(json['isDeveloper']),
      isMine: isMine is bool
          ? isMine
          : deviceId != null && json['deviceId'] == deviceId,
      createdAt: readDate(json['createdAt']),
    );
  }

  /// Server ID.
  final String id;

  /// Comment text, 1–1000 characters.
  final String text;

  /// Display name; empty when anonymous.
  final String authorName;

  /// Whether the app's developer wrote it.
  final bool isDeveloper;

  /// Whether this device wrote it.
  final bool isMine;

  /// When it was posted.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is Comment &&
      other.id == id &&
      other.text == text &&
      other.authorName == authorName &&
      other.isDeveloper == isDeveloper &&
      other.isMine == isMine &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, text, authorName, isDeveloper, isMine, createdAt);
}

/// One page of [Feature]s. Pass [nextCursor] to get the next page.
@immutable
class FeaturePage {
  const FeaturePage({required this.features, this.nextCursor});

  final List<Feature> features;
  final String? nextCursor;
}

/// One page of [Comment]s. Pass [nextCursor] to get the next page.
@immutable
class CommentPage {
  const CommentPage({required this.comments, this.nextCursor});

  final List<Comment> comments;
  final String? nextCursor;
}

/// The vote count and state after voting or unvoting.
@immutable
class VoteResult {
  const VoteResult({required this.upvoteCount, required this.hasVoted});

  factory VoteResult.fromJson(Map<String, Object?> json) => VoteResult(
        upvoteCount: readInt(json['upvoteCount']),
        hasVoted: readBool(json['hasVoted']),
      );

  final int upvoteCount;
  final bool hasVoted;
}

/// Server settings for the app behind the API key.
///
/// When `/config` can't be loaded the defaults apply, so the
/// "Powered by Fewchurs" line is shown, matching the Kotlin and iOS SDKs.
@immutable
class RemoteConfig {
  const RemoteConfig({
    this.showBranding = true,
    this.hideVoteCounts = false,
    this.appName,
  });

  factory RemoteConfig.fromJson(Map<String, Object?> json) => RemoteConfig(
        showBranding: json['showBranding'] != false,
        hideVoteCounts: readBool(json['hideVoteCounts']),
        appName: readOptionalString(json['appName']),
      );

  /// Whether to show the "Powered by Fewchurs" line (Free plan).
  final bool showBranding;

  /// Whether vote counts are hidden on the board.
  final bool hideVoteCounts;

  /// The app's name in the Fewchurs dashboard.
  final String? appName;
}
