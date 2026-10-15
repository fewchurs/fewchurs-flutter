import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../runtime.dart';

/// All user-facing text. Pass an instance to `Fewchurs.configure(strings:)`
/// to change any of it. `{count}` and `{max}` are replaced at runtime.
@immutable
class FewchursStrings {
  const FewchursStrings({
    this.boardTitle = 'Feature requests',
    this.tabTop = 'Top',
    this.tabNew = 'New',
    this.tabRoadmap = 'Roadmap',
    this.submitButton = 'Suggest a feature',
    this.emptyTitle = 'No requests yet',
    this.emptyMessage = 'Be the first to suggest something.',
    this.roadmapEmptyMessage = 'Nothing on the roadmap yet.',
    this.retry = 'Try again',
    this.close = 'Close',
    this.loadMoreFailed = "Couldn't load more.",
    this.poweredBy = 'Powered by Fewchurs',
    this.selectFeature = 'Select a request to see the details.',
    this.statusOpen = 'Open',
    this.statusPlanned = 'Planned',
    this.statusInProgress = 'In progress',
    this.statusDone = 'Done',
    this.statusDeclined = 'Declined',
    this.statusUnknown = 'Other',
    this.upvote = 'Upvote',
    this.voted = 'voted',
    this.votesCount = '{count} votes',
    this.oneVote = '1 vote',
    this.commentsCount = '{count} comments',
    this.comments = 'Comments',
    this.noComments = 'No comments yet. Start the conversation.',
    this.commentHint = 'Add a comment…',
    this.nameHint = 'Your name (optional)',
    this.send = 'Send',
    this.developerBadge = 'Developer',
    this.you = 'You',
    this.follow = 'Follow',
    this.following = 'Following',
    this.followTitle = 'Get updates',
    this.followMessage = "We'll email you when this ships.",
    this.followConfirmed = "You'll get an email when this ships.",
    this.emailLabel = 'Email',
    this.emailOptionalLabel = 'Email (optional)',
    this.emailHelper = 'Email me when it ships',
    this.emailInvalid = 'Enter a valid email address.',
    this.emailRequired = 'Email is required.',
    this.rememberEmail = 'Remember my email on this device',
    this.cancel = 'Cancel',
    this.submitTitle = 'Suggest a feature',
    this.titleLabel = 'Title',
    this.titleHint = 'Add dark mode',
    this.titleTooShort = 'Use at least 3 characters.',
    this.descriptionLabel = 'Description (optional)',
    this.descriptionHint = 'What would this help you do?',
    this.submit = 'Submit',
    this.submitSuccess = 'Thanks! Your request was submitted.',
    this.tooLong = 'Keep it under {max} characters.',
    this.errorGeneric = 'Something went wrong. Try again.',
    this.errorOffline = "You're offline.",
    this.errorRateLimited = "You've reached today's limit. Try again tomorrow.",
    this.errorLimitReached = "This board isn't accepting requests right now.",
    this.errorNotFound = 'This request no longer exists.',
    this.justNow = 'just now',
  });

  final String boardTitle;
  final String tabTop;
  final String tabNew;
  @Deprecated('The Roadmap tab was removed. This text is unused.')
  final String tabRoadmap;
  final String submitButton;
  final String emptyTitle;
  final String emptyMessage;
  @Deprecated('The Roadmap tab was removed. This text is unused.')
  final String roadmapEmptyMessage;
  final String retry;
  final String close;
  final String loadMoreFailed;
  final String poweredBy;
  final String selectFeature;
  final String statusOpen;
  final String statusPlanned;
  final String statusInProgress;
  final String statusDone;
  final String statusDeclined;
  final String statusUnknown;
  final String upvote;
  final String voted;
  final String votesCount;
  final String oneVote;
  final String commentsCount;
  final String comments;
  final String noComments;
  final String commentHint;
  final String nameHint;
  final String send;
  final String developerBadge;
  final String you;
  final String follow;
  final String following;
  final String followTitle;
  final String followMessage;
  final String followConfirmed;
  final String emailLabel;
  final String emailOptionalLabel;
  final String emailHelper;
  final String emailInvalid;
  final String emailRequired;
  final String rememberEmail;
  final String cancel;
  final String submitTitle;
  final String titleLabel;
  final String titleHint;
  final String titleTooShort;
  final String descriptionLabel;
  final String descriptionHint;
  final String submit;
  final String submitSuccess;
  final String tooLong;
  final String errorGeneric;
  final String errorOffline;
  final String errorRateLimited;
  final String errorLimitReached;
  final String errorNotFound;
  final String justNow;

  /// Strings from `Fewchurs.configure(strings:)`, then
  /// [FewchursLocalizations], then English.
  static FewchursStrings of(BuildContext context) =>
      FewchursRuntime.instance.config?.strings ??
      Localizations.of<FewchursStrings>(context, FewchursStrings) ??
      const FewchursStrings();

  String status(FeatureStatus status) => switch (status) {
        FeatureStatus.open => statusOpen,
        FeatureStatus.planned => statusPlanned,
        FeatureStatus.inProgress => statusInProgress,
        FeatureStatus.done => statusDone,
        FeatureStatus.declined => statusDeclined,
        FeatureStatus.unknown => statusUnknown,
      };

  String votes(int count) =>
      count == 1 ? oneVote : votesCount.replaceAll('{count}', '$count');

  String commentCount(int count) =>
      commentsCount.replaceAll('{count}', '$count');

  String maxLength(int max) => tooLong.replaceAll('{max}', '$max');

  String error(FewchursException e) => switch (e) {
        FewchursValidationException() => e.message,
        FewchursRateLimitedException() => errorRateLimited,
        FewchursLimitReachedException() => errorLimitReached,
        FewchursNotFoundException() => errorNotFound,
        FewchursNetworkException() => errorOffline,
        FewchursInvalidApiKeyException() ||
        FewchursServerException() ||
        FewchursUnknownException() =>
          errorGeneric,
      };
}

class FewchursLocalizations {
  const FewchursLocalizations._();

  static const LocalizationsDelegate<FewchursStrings> delegate =
      _FewchursLocalizationsDelegate();

  static const supportedLocales = [Locale('en')];

  static const Map<String, FewchursStrings> _byLanguage = {
    'en': FewchursStrings(),
  };
}

class _FewchursLocalizationsDelegate
    extends LocalizationsDelegate<FewchursStrings> {
  const _FewchursLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      FewchursLocalizations._byLanguage.containsKey(locale.languageCode);

  @override
  Future<FewchursStrings> load(Locale locale) => SynchronousFuture(
      FewchursLocalizations._byLanguage[locale.languageCode] ??
          const FewchursStrings());

  @override
  bool shouldReload(_FewchursLocalizationsDelegate old) => false;
}
