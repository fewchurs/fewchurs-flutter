import 'package:meta/meta.dart';

import 'json.dart';

enum FeatureStatus {
  open('open'),
  planned('planned'),
  inProgress('in_progress'),
  done('done'),
  declined('declined'),
  unknown('unknown');

  const FeatureStatus(this.wireName);

  final String wireName;

  static FeatureStatus parse(Object? value) {
    for (final status in values) {
      if (status.wireName == value) return status;
    }
    return unknown;
  }
}

enum FeatureSort {
  top('top'),
  newest('new');

  const FeatureSort(this.wireName);

  final String wireName;
}

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

  final String id;
  final String title;
  final String description;
  final FeatureStatus status;
  final int upvoteCount;
  final int commentCount;
  final int followerCount;
  final bool hasVoted;
  final bool isFollowing;
  final bool isMine;
  final DateTime createdAt;
  final DateTime updatedAt;

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

  final String id;
  final String text;
  final String authorName;
  final bool isDeveloper;
  final bool isMine;
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

@immutable
class FeaturePage {
  const FeaturePage({required this.features, this.nextCursor});

  final List<Feature> features;
  final String? nextCursor;
}

@immutable
class CommentPage {
  const CommentPage({required this.comments, this.nextCursor});

  final List<Comment> comments;
  final String? nextCursor;
}

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

@immutable
class RemoteConfig {
  const RemoteConfig({
    this.showBranding = false,
    this.hideVoteCounts = false,
    this.appName,
  });

  factory RemoteConfig.fromJson(Map<String, Object?> json) => RemoteConfig(
        showBranding: json['showBranding'] != false,
        hideVoteCounts: readBool(json['hideVoteCounts']),
        appName: readOptionalString(json['appName']),
      );

  final bool showBranding;
  final bool hideVoteCounts;
  final String? appName;
}
