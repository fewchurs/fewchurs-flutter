import 'dart:async';
import 'dart:math' as math;

import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../controllers/board_controller.dart';
import '../fewchurs.dart';
import '../l10n/fewchurs_strings.dart';
import '../runtime.dart';
import '../theme/fewchurs_theme.dart';
import '../widgets/adaptive.dart';
import '../widgets/feature_card.dart';
import '../widgets/powered_by.dart';
import '../widgets/state_views.dart';
import '../widgets/status_chip.dart';
import '../widgets/vote_button.dart';
import 'detail_screen.dart';
import 'submit_sheet.dart';

/// The full feature-request board. Use it as a page, a tab, or inside a
/// sheet. Builders replace individual pieces while keeping paging, optimistic
/// votes and error handling.
class FewchursBoard extends StatefulWidget {
  const FewchursBoard({
    super.key,
    this.options,
    this.initialFeatureId,
    this.title,
    this.showAppBar = true,
    this.showCloseButton,
    this.headerBuilder,
    this.emptyBuilder,
    this.featureCardBuilder,
    this.voteButtonBuilder,
    this.statusChipBuilder,
  });

  /// Overrides the `board` options passed to `Fewchurs.configure`.
  final BoardOptions? options;

  /// Opens this request once the board is shown, e.g. from a deep link or a
  /// notification. Shows "This request no longer exists." if it can't be
  /// loaded, which includes requests hidden by the board's plan.
  final String? initialFeatureId;
  final String? title;
  final bool showAppBar;

  /// `true` shows a close button and closes on Esc, `false` hides the
  /// leading button, `null` lets the app bar decide.
  final bool? showCloseButton;
  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? emptyBuilder;
  final FeatureCardBuilder? featureCardBuilder;
  final VoteButtonBuilder? voteButtonBuilder;
  final StatusChipBuilder? statusChipBuilder;

  @override
  State<FewchursBoard> createState() => _FewchursBoardState();
}

class _FewchursBoardState extends State<FewchursBoard>
    with SingleTickerProviderStateMixin {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _controllers = <BoardTab, BoardController>{};
  final _subscriptions = <StreamSubscription<Object?>>[];
  List<BoardTab> _tabs = const [];
  TabController? _tabController;
  Feature? _selected;
  bool _isWide = false;

  FewchursRuntime get _rt => FewchursRuntime.instance;

  BoardOptions get _options =>
      widget.options ?? _rt.config?.board ?? const BoardOptions();

  @override
  void initState() {
    super.initState();
    if (!Fewchurs.isConfigured) {
      _rt.warnNotConfigured();
      return;
    }
    final options = _options;
    // Only Top and New are shown; anything else (the old Roadmap tab) is
    // ignored.
    _tabs = options.tabs
        .where((t) => t == BoardTab.top || t == BoardTab.newest)
        .toSet()
        .toList();
    if (_tabs.isEmpty) _tabs = const [BoardTab.top];

    for (final tab in _tabs) {
      final controller = Fewchurs.boardController(
        sort: tab == BoardTab.newest ? FeatureSort.newest : FeatureSort.top,
        showDeclined: options.showDeclined,
        pageSize: options.pageSize,
      );
      _controllers[tab] = controller;
      _subscriptions.add(controller.actionErrors.listen(_showError));
    }
    if (_tabs.length > 1) {
      _tabController = TabController(
        length: _tabs.length,
        vsync: this,
        initialIndex: math.max(0, _tabs.indexOf(options.defaultTab)),
      );
    }
    _subscriptions.add(_rt.submitted.stream.listen(_onSubmitted));
    _rt.loadRemoteConfig();
    _rt.emit(const BoardOpened());
    final initial = widget.initialFeatureId;
    if (initial != null) _openById(initial);
  }

  @override
  void didUpdateWidget(FewchursBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.initialFeatureId;
    if (id != null &&
        id != oldWidget.initialFeatureId &&
        Fewchurs.isConfigured) {
      _openById(id);
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    for (final c in _controllers.values) {
      c.dispose();
    }
    _tabController?.dispose();
    super.dispose();
  }

  void _showError(FewchursException e) {
    if (!mounted) return;
    showFewchursMessage(context, FewchursStrings.of(context).error(e),
        messengerKey: _messengerKey);
  }

  void _onSubmitted(Feature feature) {
    final target = _controllers[BoardTab.newest] ?? _controllers[_tabs.first];
    target?.insertAtTop(feature);
    final index = _tabs.indexOf(BoardTab.newest);
    if (index >= 0) _tabController?.animateTo(index);
  }

  void _syncFeature(Feature feature) {
    for (final c in _controllers.values) {
      c.replace(feature);
    }
  }

  void _removeFeature(String id) {
    for (final c in _controllers.values) {
      c.remove(id);
    }
    if (_selected?.id == id) setState(() => _selected = null);
  }

  Future<void> _openById(String id) async {
    try {
      final feature = await Fewchurs.client.getFeature(id);
      // Wait for a laid-out frame so the wide/narrow layout is known.
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) _open(feature);
    } on FewchursException catch (e) {
      _showError(e);
    }
  }

  void _open(Feature feature) {
    if (_isWide) {
      setState(() => _selected = feature);
      return;
    }
    final themes = InheritedTheme.capture(
        from: context, to: Navigator.of(context).context);
    Navigator.of(context).push<void>(fewchursRoute(
      context,
      (_) => themes.wrap(FewchursFeatureDetail(
        feature: feature,
        onChanged: _syncFeature,
        onRemoved: () => _removeFeature(feature.id),
        voteButtonBuilder: widget.voteButtonBuilder,
        statusChipBuilder: widget.statusChipBuilder,
      )),
    ));
  }

  Future<void> _openSubmit() async {
    final feature = await showFewchursSubmitSheet(context);
    if (feature != null && mounted) {
      showFewchursMessage(context, FewchursStrings.of(context).submitSuccess,
          messengerKey: _messengerKey);
    }
  }

  String _tabLabel(FewchursStrings s, BoardTab tab) =>
      tab == BoardTab.newest ? s.tabNew : s.tabTop;

  @override
  Widget build(BuildContext context) {
    if (!Fewchurs.isConfigured) {
      return _NotConfigured(showAppBar: widget.showAppBar);
    }
    final s = FewchursStrings.of(context);
    final t = FewchursThemeData.of(context);
    final options = _options;
    final placement = options.allowSubmissions ? options.submitButton : null;

    final tabBar = _tabController == null
        ? null
        : TabBar(
            controller: _tabController,
            isScrollable: _tabs.length > 3,
            labelColor: widget.showAppBar ? null : t.primary,
            indicatorColor: widget.showAppBar ? null : t.primary,
            dividerColor: Colors.transparent,
            tabs: [for (final tab in _tabs) Tab(text: _tabLabel(s, tab))],
          );

    final body = LayoutBuilder(builder: (context, constraints) {
      _isWide = constraints.maxWidth >= options.wideLayoutBreakpoint;
      final lists = _tabController == null
          ? _buildTab(_tabs.first, placement)
          : TabBarView(
              controller: _tabController,
              children: [for (final tab in _tabs) _buildTab(tab, placement)],
            );
      if (!_isWide) return lists;

      final selected = _selected;
      return Row(
        children: [
          SizedBox(
            width: math.min(480.0, constraints.maxWidth * 0.45),
            child: lists,
          ),
          Expanded(
            child: selected == null
                ? Center(
                    child: FewchursMessageView(
                      icon: Icons.touch_app_outlined,
                      title: s.selectFeature,
                    ),
                  )
                : FewchursFeatureDetail(
                    key: ValueKey(selected.id),
                    feature: selected,
                    embedded: true,
                    onChanged: _syncFeature,
                    onRemoved: () => _removeFeature(selected.id),
                    voteButtonBuilder: widget.voteButtonBuilder,
                    statusChipBuilder: widget.statusChipBuilder,
                  ),
          ),
        ],
      );
    });

    final scaffold = Scaffold(
      backgroundColor: t.background,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(widget.title ?? s.boardTitle),
              automaticallyImplyLeading: widget.showCloseButton == null,
              leading: widget.showCloseButton == true
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: s.close,
                      onPressed: () => Navigator.maybePop(context),
                    )
                  : null,
              actions: [
                if (placement == SubmitButtonPlacement.appBarAction)
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: s.submitButton,
                    onPressed: _openSubmit,
                  ),
              ],
              bottom: tabBar,
            )
          : null,
      body: widget.showAppBar || tabBar == null
          ? body
          : Column(children: [tabBar, Expanded(child: body)]),
      floatingActionButton: placement == SubmitButtonPlacement.fab
          ? FloatingActionButton.extended(
              onPressed: _openSubmit,
              backgroundColor: t.primary,
              foregroundColor: t.onPrimary,
              icon: const Icon(Icons.add_rounded),
              label: Text(s.submitButton),
            )
          : null,
      floatingActionButtonLocation:
          MediaQuery.sizeOf(context).width >= options.wideLayoutBreakpoint
              ? FloatingActionButtonLocation.startFloat
              : null,
      bottomNavigationBar: placement == SubmitButtonPlacement.bottomBar
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: t.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(t.buttonRadius)),
                  ),
                  onPressed: _openSubmit,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(s.submitButton),
                ),
              ),
            )
          : null,
    );

    return FewchursHost(
      messengerKey: _messengerKey,
      closeOnEscape: widget.showCloseButton == true,
      child: scaffold,
    );
  }

  Widget _buildTab(BoardTab tab, SubmitButtonPlacement? placement) {
    return _BoardTabView(
      key: PageStorageKey<String>('fewchurs-${tab.name}'),
      tab: tab,
      controller: _controllers[tab]!,
      maxContentWidth: _isWide ? double.infinity : _options.maxContentWidth,
      bottomPadding: placement == SubmitButtonPlacement.fab ? 80 : 0,
      selectedId: _isWide ? _selected?.id : null,
      onOpen: _open,
      headerBuilder: widget.headerBuilder,
      emptyBuilder: widget.emptyBuilder,
      featureCardBuilder: widget.featureCardBuilder,
      voteButtonBuilder: widget.voteButtonBuilder,
      statusChipBuilder: widget.statusChipBuilder,
    );
  }
}

class _BoardTabView extends StatefulWidget {
  const _BoardTabView({
    super.key,
    required this.tab,
    required this.controller,
    required this.maxContentWidth,
    required this.bottomPadding,
    required this.selectedId,
    required this.onOpen,
    this.headerBuilder,
    this.emptyBuilder,
    this.featureCardBuilder,
    this.voteButtonBuilder,
    this.statusChipBuilder,
  });

  final BoardTab tab;
  final BoardController controller;
  final double maxContentWidth;
  final double bottomPadding;
  final String? selectedId;
  final ValueChanged<Feature> onOpen;
  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? emptyBuilder;
  final FeatureCardBuilder? featureCardBuilder;
  final VoteButtonBuilder? voteButtonBuilder;
  final StatusChipBuilder? statusChipBuilder;

  @override
  State<_BoardTabView> createState() => _BoardTabViewState();
}

class _BoardTabViewState extends State<_BoardTabView>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _maybeLoadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    final state = widget.controller.state;
    if (state is BoardContent &&
        state.canLoadMore &&
        !state.isLoadingMore &&
        state.loadMoreError == null) {
      widget.controller.loadMore();
    }
  }

  void _fillViewportIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent <= 0) _maybeLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<RemoteConfig>(
      valueListenable: FewchursRuntime.instance.remote,
      builder: (context, remote, _) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final side = math.max(
                16.0, (constraints.maxWidth - widget.maxContentWidth) / 2);
            final padding = EdgeInsets.fromLTRB(
                side, 12, side, 16 + widget.bottomPadding);
            final state = widget.controller.state;
            switch (state) {
              case BoardLoading():
                return FewchursLoadingView(padding: padding);
              case BoardError(:final error):
                return _refreshable(padding, [
                  FewchursErrorView(
                      error: error, onRetry: widget.controller.refresh),
                ]);
              case BoardContent(:final features) when features.isEmpty:
                final s = FewchursStrings.of(context);
                return _refreshable(padding, [
                  widget.emptyBuilder?.call(context) ??
                      FewchursMessageView(
                        icon: Icons.lightbulb_outline_rounded,
                        title: s.emptyTitle,
                        message: s.emptyMessage,
                      ),
                  const FewchursPoweredBy(),
                ]);
              case BoardContent():
                _fillViewportIfNeeded();
                return _list(state, padding, remote.hideVoteCounts);
            }
          },
        ),
      ),
    );
  }

  Widget _refreshable(EdgeInsets padding, List<Widget> children) {
    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      color: FewchursThemeData.of(context).primary,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          if (widget.headerBuilder != null) widget.headerBuilder!(context),
          ...children,
        ],
      ),
    );
  }

  Widget _list(BoardContent state, EdgeInsets padding, bool hideVoteCount) {
    final header = widget.headerBuilder?.call(context);
    final offset = header == null ? 0 : 1;
    final features = state.features;

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      color: FewchursThemeData.of(context).primary,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: offset + features.length + 1,
        itemBuilder: (context, index) {
          if (header != null && index == 0) return header;
          final i = index - offset;
          if (i == features.length) return _footer(state);
          final feature = features[i];
          final actions = FeatureActions(
            toggleVote: () => widget.controller.toggleVote(feature.id),
            open: () => widget.onOpen(feature),
          );
          return Padding(
            key: ValueKey(feature.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: widget.featureCardBuilder?.call(context, feature, actions) ??
                FewchursFeatureCard(
                  feature: feature,
                  actions: actions,
                  hideVoteCount: hideVoteCount,
                  selected: feature.id == widget.selectedId,
                  voteButtonBuilder: widget.voteButtonBuilder,
                  statusChipBuilder: widget.statusChipBuilder,
                ),
          );
        },
      ),
    );
  }

  Widget _footer(BoardContent state) {
    final s = FewchursStrings.of(context);
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: FewchursSpinner()),
      );
    }
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(s.loadMoreFailed,
                style: FewchursThemeData.of(context).bodyStyle),
            TextButton(
                onPressed: widget.controller.loadMore, child: Text(s.retry)),
          ],
        ),
      );
    }
    if (!state.canLoadMore) return const FewchursPoweredBy();
    return const SizedBox(height: 56);
  }
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured({required this.showAppBar});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return FewchursHost(
      child: Scaffold(
        appBar: showAppBar ? AppBar() : null,
        body: kDebugMode
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Fewchurs.configure(apiKey: ...) must be called before '
                    'showing the board.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFB45309)),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
