import 'dart:async';
import 'dart:math' as math;

import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/material.dart';

import '../controllers/feature_detail_controller.dart';
import '../fewchurs.dart';
import '../identity/prefs_device_id_store.dart';
import '../l10n/fewchurs_strings.dart';
import '../runtime.dart';
import '../theme/fewchurs_theme.dart';
import '../widgets/adaptive.dart';
import '../widgets/state_views.dart';
import '../widgets/status_chip.dart';
import '../widgets/vote_button.dart';

class FewchursFeatureDetail extends StatefulWidget {
  const FewchursFeatureDetail({
    super.key,
    required this.feature,
    this.embedded = false,
    this.onChanged,
    this.onRemoved,
    this.voteButtonBuilder,
    this.statusChipBuilder,
  });

  final Feature feature;

  /// `true` when shown beside the list instead of as its own page.
  final bool embedded;
  final ValueChanged<Feature>? onChanged;
  final VoidCallback? onRemoved;
  final VoteButtonBuilder? voteButtonBuilder;
  final StatusChipBuilder? statusChipBuilder;

  @override
  State<FewchursFeatureDetail> createState() => _FewchursFeatureDetailState();
}

class _FewchursFeatureDetailState extends State<FewchursFeatureDetail> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _scroll = ScrollController();
  final _commentText = TextEditingController();
  final _nameText = TextEditingController();
  FeatureDetailController? _controller;
  StreamSubscription<FewchursException>? _errors;
  bool _removedHandled = false;

  FewchursRuntime get _rt => FewchursRuntime.instance;

  @override
  void initState() {
    super.initState();
    if (!Fewchurs.isConfigured) {
      _rt.warnNotConfigured();
      return;
    }
    final c = Fewchurs.detailController(widget.feature,
        onFeatureChanged: (f) => widget.onChanged?.call(f));
    _controller = c;
    c.addListener(_onControllerChanged);
    _errors = c.actionErrors.listen(_showError);
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400 &&
          c.canLoadMoreComments &&
          !c.isLoadingComments &&
          c.commentsError == null) {
        c.loadMoreComments();
      }
    });
    _rt.prefs.get(FewchursPrefs.authorNameKey).then((name) {
      if (name != null && mounted && _nameText.text.isEmpty) {
        _nameText.text = name;
      }
    });
    _rt.loadRemoteConfig();
  }

  @override
  void dispose() {
    _errors?.cancel();
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    _scroll.dispose();
    _commentText.dispose();
    _nameText.dispose();
    super.dispose();
  }

  void _showError(FewchursException e) {
    if (!mounted) return;
    showFewchursMessage(context, FewchursStrings.of(context).error(e),
        messengerKey: _messengerKey);
  }

  void _onControllerChanged() {
    final c = _controller!;
    if (!c.isRemoved || _removedHandled) return;
    _removedHandled = true;
    final message = FewchursStrings.of(context).errorNotFound;
    widget.onRemoved?.call();
    if (!widget.embedded) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text(message), behavior: SnackBarBehavior.floating));
      Navigator.maybePop(context);
    }
  }

  Future<void> _toggleFollow() async {
    final c = _controller!;
    if (c.feature.isFollowing) {
      await c.setFollowing(false);
      return;
    }
    var email = await _rt.knownEmail();
    if (!mounted) return;
    if (email == null) {
      final result = await showFewchursEmailDialog(context);
      if (result == null || !mounted) return;
      email = result.email;
      if (result.remember) {
        unawaited(_rt.prefs.set(FewchursPrefs.emailKey, email));
      }
    }
    final ok = await c.setFollowing(true, email: email);
    if (ok && mounted) {
      showFewchursMessage(context, FewchursStrings.of(context).followConfirmed,
          messengerKey: _messengerKey);
    }
  }

  Future<void> _send() async {
    final c = _controller!;
    final text = _commentText.text.trim();
    if (text.isEmpty || c.isSendingComment) return;
    final name = _nameText.text.trim();
    final comment =
        await c.addComment(text, authorName: name.isEmpty ? null : name);
    if (comment == null || !mounted) return;
    _commentText.clear();
    unawaited(_rt.prefs.set(FewchursPrefs.authorNameKey, name));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients && !c.canLoadMoreComments) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) return const SizedBox.shrink();
    final t = FewchursThemeData.of(context);
    final options = _rt.config?.board;
    final allowComments = options?.allowComments ?? true;

    final content = ValueListenableBuilder<RemoteConfig>(
      valueListenable: _rt.remote,
      builder: (context, remote, _) => ListenableBuilder(
        listenable: c,
        builder: (context, _) => Column(
          children: [
            Expanded(child: _body(c, remote.hideVoteCounts, allowComments)),
            if (allowComments) _composer(c),
          ],
        ),
      ),
    );

    if (widget.embedded) return content;

    return FewchursHost(
      messengerKey: _messengerKey,
      closeOnEscape: true,
      child: Scaffold(
        backgroundColor: t.background,
        appBar: AppBar(),
        body: content,
      ),
    );
  }

  Widget _body(FeatureDetailController c, bool hideVoteCount, bool allowComments) {
    final s = FewchursStrings.of(context);
    final t = FewchursThemeData.of(context);
    final feature = c.feature;
    final allowFollow = _rt.config?.board.allowFollow ?? true;
    final voteState = VoteButtonState(
      voted: feature.hasVoted,
      count: feature.upvoteCount,
      hideCount: hideVoteCount,
      onPressed: c.toggleVote,
    );

    return LayoutBuilder(builder: (context, constraints) {
      final side = math.max(20.0, (constraints.maxWidth - 720) / 2);
      return ListView(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(side, 20, side, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.voteButtonBuilder?.call(context, voteState) ??
                  FewchursVoteButton(state: voteState),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(feature.title,
                          style: t.titleStyle.copyWith(fontSize: 20)),
                    ),
                    if (feature.status != FeatureStatus.open) ...[
                      const SizedBox(height: 8),
                      widget.statusChipBuilder?.call(context, feature.status) ??
                          FewchursStatusChip(status: feature.status),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (feature.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            SelectableText(feature.description,
                style: t.bodyStyle.copyWith(color: t.onSurface, height: 1.45)),
          ],
          if (allowFollow) ...[
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _followButton(c),
            ),
          ],
          if (allowComments) ...[
            const SizedBox(height: 20),
            Divider(color: t.border, height: 1),
            const SizedBox(height: 16),
            Text(
              '${s.comments} (${feature.commentCount})',
              style: t.titleStyle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 4),
            ..._comments(c),
          ],
        ],
      );
    });
  }

  Widget _followButton(FeatureDetailController c) {
    final s = FewchursStrings.of(context);
    final t = FewchursThemeData.of(context);
    final following = c.feature.isFollowing;
    final icon = c.isFollowPending
        ? const FewchursSpinner(size: 16)
        : Icon(following
            ? Icons.notifications_active_rounded
            : Icons.notifications_none_rounded);
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.buttonRadius));
    final onPressed = c.isFollowPending ? null : _toggleFollow;
    return following
        ? FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: t.primary.withAlpha(0x22),
              foregroundColor: t.primary,
              shape: shape,
              minimumSize: const Size(0, 44),
            ),
            onPressed: onPressed,
            icon: icon,
            label: Text(s.following),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: t.onSurface,
              side: BorderSide(color: t.border),
              shape: shape,
              minimumSize: const Size(0, 44),
            ),
            onPressed: onPressed,
            icon: icon,
            label: Text(s.follow),
          );
  }

  List<Widget> _comments(FeatureDetailController c) {
    final s = FewchursStrings.of(context);
    final t = FewchursThemeData.of(context);
    if (!c.commentsLoaded) {
      final error = c.commentsError;
      if (error != null) {
        return [FewchursErrorView(error: error, onRetry: c.loadComments)];
      }
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: FewchursSpinner()),
        ),
      ];
    }
    if (c.comments.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(s.noComments, style: t.bodyStyle),
        ),
      ];
    }
    return [
      for (final comment in c.comments)
        _CommentTile(key: ValueKey(comment.id), comment: comment),
      if (c.isLoadingComments)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: FewchursSpinner()),
        )
      else if (c.commentsError != null)
        Center(
          child: TextButton(
              onPressed: c.loadMoreComments, child: Text(s.retry)),
        ),
    ];
  }

  Widget _composer(FeatureDetailController c) {
    final s = FewchursStrings.of(context);
    final t = FewchursThemeData.of(context);
    InputDecoration decoration(String hint, {String? counter}) =>
        InputDecoration(
          hintText: hint,
          isDense: true,
          counterText: counter ?? '',
          filled: true,
          fillColor: t.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.buttonRadius),
            borderSide: BorderSide(color: t.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.buttonRadius),
            borderSide: BorderSide(color: t.border),
          ),
        );

    return Material(
      color: t.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.border))),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _commentText,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              final length = value.text.length;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasText)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, right: 4),
                      child: TextField(
                        controller: _nameText,
                        maxLength: FewchursClient.authorNameMax,
                        textCapitalization: TextCapitalization.words,
                        decoration: decoration(s.nameHint),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentText,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: FewchursClient.commentMax,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: decoration(
                            s.commentHint,
                            counter: length > 800
                                ? '$length/${FewchursClient.commentMax}'
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox.square(
                        dimension: 48,
                        child: c.isSendingComment
                            ? const Center(child: FewchursSpinner(size: 20))
                            : IconButton(
                                tooltip: s.send,
                                icon: Icon(Icons.send_rounded,
                                    color: hasText ? t.primary : t.muted),
                                onPressed: hasText ? _send : null,
                              ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({super.key, required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final s = FewchursStrings.of(context);
    final t = FewchursThemeData.of(context);
    Widget badge(String text, Color color) => Container(
          margin: const EdgeInsetsDirectional.only(start: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(0x22),
            borderRadius: BorderRadius.circular(t.chipRadius),
          ),
          child: Text(text,
              style: t.labelStyle.copyWith(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  comment.authorName,
                  style: t.titleStyle.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (comment.isDeveloper) badge(s.developerBadge, t.primary),
              if (comment.isMine) badge(s.you, t.muted),
              const SizedBox(width: 8),
              Text(fewchursRelativeTime(context, comment.createdAt),
                  style: t.labelStyle),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(comment.text,
              style: t.bodyStyle.copyWith(color: t.onSurface, height: 1.4)),
        ],
      ),
    );
  }
}
