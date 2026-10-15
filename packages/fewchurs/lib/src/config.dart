import 'dart:async';

import 'package:flutter/foundation.dart';

import 'l10n/fewchurs_strings.dart';

enum FewchursStyle { material, cupertino, adaptive }

enum BoardTab {
  top,
  newest,

  /// No longer shown. The board ignores it and shows Top and New only.
  @Deprecated('The Roadmap tab was removed. The board ignores it.')
  roadmap,
}

enum EmailField { hidden, optional, required }

enum SubmitButtonPlacement { fab, bottomBar, appBarAction }

/// Where `Fewchurs.showBoardSheet` opens the board.
enum FewchursSheetPosition {
  /// A side sheet on wide screens (web, desktop, tablets in landscape) and a
  /// bottom sheet on phones.
  adaptive,

  /// Always a bottom sheet.
  bottom,

  /// Always a side sheet on the end edge (right, or left in RTL).
  side,
}

@immutable
class BoardOptions {
  const BoardOptions({
    this.tabs = const [BoardTab.top, BoardTab.newest],
    this.defaultTab = BoardTab.top,
    this.showDeclined = false,
    this.allowSubmissions = true,
    this.allowComments = true,
    this.allowFollow = true,
    this.emailField = EmailField.optional,
    this.submitButton = SubmitButtonPlacement.fab,
    this.pageSize = 20,
    this.maxContentWidth = 720,
    this.wideLayoutBreakpoint = 840,
  });

  final List<BoardTab> tabs;
  final BoardTab defaultTab;
  final bool showDeclined;
  final bool allowSubmissions;
  final bool allowComments;
  final bool allowFollow;
  final EmailField emailField;
  final SubmitButtonPlacement submitButton;
  final int pageSize;
  final double maxContentWidth;

  /// Width at which the board switches to a side-by-side list and detail.
  final double wideLayoutBreakpoint;
}

@immutable
class FewchursConfig {
  const FewchursConfig({
    required this.apiKey,
    this.style = FewchursStyle.material,
    this.board = const BoardOptions(),
    this.strings,
    this.isSubscriber,
    this.userEmail,
  });

  final String apiKey;
  final FewchursStyle style;
  final BoardOptions board;
  final FewchursStrings? strings;
  final FutureOr<bool> Function()? isSubscriber;
  final FutureOr<String?> Function()? userEmail;
}
