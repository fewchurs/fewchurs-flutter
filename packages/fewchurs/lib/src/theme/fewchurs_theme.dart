import 'dart:ui' show lerpDouble;

import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/material.dart';

enum VoteButtonStyle { column, pill, minimal }

enum FewchursDensity { comfortable, compact }

/// Design tokens for the board. Every value is optional; anything left null
/// comes from the app's [ThemeData]. Add it to `ThemeData.extensions` or wrap
/// the board in a [FewchursTheme].
@immutable
class FewchursThemeData extends ThemeExtension<FewchursThemeData> {
  const FewchursThemeData({
    this.primary,
    this.onPrimary,
    this.background,
    this.surface,
    this.onSurface,
    this.muted,
    this.border,
    this.error,
    this.statusColors,
    this.cardRadius,
    this.buttonRadius,
    this.chipRadius,
    this.sheetRadius,
    this.titleStyle,
    this.bodyStyle,
    this.labelStyle,
    this.fontFamily,
    this.density,
    this.voteButtonStyle,
    this.cardElevation,
  });

  final Color? primary;
  final Color? onPrimary;
  final Color? background;
  final Color? surface;
  final Color? onSurface;
  final Color? muted;
  final Color? border;
  final Color? error;
  final Map<FeatureStatus, Color>? statusColors;
  final double? cardRadius;
  final double? buttonRadius;
  final double? chipRadius;
  final double? sheetRadius;
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;
  final TextStyle? labelStyle;
  final String? fontFamily;
  final FewchursDensity? density;
  final VoteButtonStyle? voteButtonStyle;
  final double? cardElevation;

  static FewchursResolvedTheme of(BuildContext context) =>
      FewchursResolvedTheme._resolve(context);

  @override
  FewchursThemeData copyWith({
    Color? primary,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? onSurface,
    Color? muted,
    Color? border,
    Color? error,
    Map<FeatureStatus, Color>? statusColors,
    double? cardRadius,
    double? buttonRadius,
    double? chipRadius,
    double? sheetRadius,
    TextStyle? titleStyle,
    TextStyle? bodyStyle,
    TextStyle? labelStyle,
    String? fontFamily,
    FewchursDensity? density,
    VoteButtonStyle? voteButtonStyle,
    double? cardElevation,
  }) {
    return FewchursThemeData(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      error: error ?? this.error,
      statusColors: statusColors ?? this.statusColors,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      sheetRadius: sheetRadius ?? this.sheetRadius,
      titleStyle: titleStyle ?? this.titleStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      density: density ?? this.density,
      voteButtonStyle: voteButtonStyle ?? this.voteButtonStyle,
      cardElevation: cardElevation ?? this.cardElevation,
    );
  }

  /// Values set on [other] win.
  FewchursThemeData merge(FewchursThemeData? other) {
    if (other == null) return this;
    return copyWith(
      primary: other.primary,
      onPrimary: other.onPrimary,
      background: other.background,
      surface: other.surface,
      onSurface: other.onSurface,
      muted: other.muted,
      border: other.border,
      error: other.error,
      statusColors: other.statusColors == null
          ? null
          : {...?statusColors, ...other.statusColors!},
      cardRadius: other.cardRadius,
      buttonRadius: other.buttonRadius,
      chipRadius: other.chipRadius,
      sheetRadius: other.sheetRadius,
      titleStyle: other.titleStyle,
      bodyStyle: other.bodyStyle,
      labelStyle: other.labelStyle,
      fontFamily: other.fontFamily,
      density: other.density,
      voteButtonStyle: other.voteButtonStyle,
      cardElevation: other.cardElevation,
    );
  }

  @override
  FewchursThemeData lerp(
      covariant ThemeExtension<FewchursThemeData>? other, double t) {
    if (other is! FewchursThemeData) return this;
    Color? c(Color? a, Color? b) => Color.lerp(a, b, t);
    double? d(double? a, double? b) =>
        a == null || b == null ? (t < 0.5 ? a : b) : lerpDouble(a, b, t);
    T pick<T>(T a, T b) => t < 0.5 ? a : b;
    return FewchursThemeData(
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      onSurface: c(onSurface, other.onSurface),
      muted: c(muted, other.muted),
      border: c(border, other.border),
      error: c(error, other.error),
      statusColors: pick(statusColors, other.statusColors),
      cardRadius: d(cardRadius, other.cardRadius),
      buttonRadius: d(buttonRadius, other.buttonRadius),
      chipRadius: d(chipRadius, other.chipRadius),
      sheetRadius: d(sheetRadius, other.sheetRadius),
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t),
      bodyStyle: TextStyle.lerp(bodyStyle, other.bodyStyle, t),
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      fontFamily: pick(fontFamily, other.fontFamily),
      density: pick(density, other.density),
      voteButtonStyle: pick(voteButtonStyle, other.voteButtonStyle),
      cardElevation: d(cardElevation, other.cardElevation),
    );
  }
}

/// Scopes a [FewchursThemeData] to part of the tree. Wins over the
/// `ThemeData.extensions` entry.
class FewchursTheme extends InheritedTheme {
  const FewchursTheme({super.key, required this.data, required super.child});

  final FewchursThemeData data;

  static FewchursThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FewchursTheme>()?.data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FewchursTheme(data: data, child: child);

  @override
  bool updateShouldNotify(FewchursTheme oldWidget) => data != oldWidget.data;
}

/// Fully resolved tokens with no nulls, what the widgets actually paint with.
@immutable
class FewchursResolvedTheme {
  const FewchursResolvedTheme({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.border,
    required this.error,
    required this.statusColors,
    required this.cardRadius,
    required this.buttonRadius,
    required this.chipRadius,
    required this.sheetRadius,
    required this.titleStyle,
    required this.bodyStyle,
    required this.labelStyle,
    required this.density,
    required this.voteButtonStyle,
    required this.cardElevation,
  });

  factory FewchursResolvedTheme._resolve(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final d = (theme.extension<FewchursThemeData>() ?? const FewchursThemeData())
        .merge(FewchursTheme.maybeOf(context));

    final onSurface = d.onSurface ?? scheme.onSurface;
    final primary = d.primary ?? scheme.primary;
    final onPrimary = d.onPrimary ??
        (d.primary == null ? scheme.onPrimary : _contrastOn(primary));
    final text = theme.textTheme;

    TextStyle style(TextStyle? custom, TextStyle? base, TextStyle fallback,
        Color color) {
      final s = (base ?? fallback).merge(custom).copyWith(color: custom?.color ?? color);
      return d.fontFamily == null ? s : s.copyWith(fontFamily: d.fontFamily);
    }

    final muted = d.muted ?? onSurface.withAlpha(0xA6);
    return FewchursResolvedTheme(
      primary: primary,
      onPrimary: onPrimary,
      background: d.background ?? theme.scaffoldBackgroundColor,
      surface: d.surface ?? theme.cardTheme.color ?? scheme.surface,
      onSurface: onSurface,
      muted: muted,
      border: d.border ?? scheme.outlineVariant,
      error: d.error ?? scheme.error,
      statusColors: {..._defaultStatusColors(dark), ...?d.statusColors},
      cardRadius: d.cardRadius ?? 14,
      buttonRadius: d.buttonRadius ?? 10,
      chipRadius: d.chipRadius ?? 999,
      sheetRadius: d.sheetRadius ?? 20,
      titleStyle: style(d.titleStyle, text.titleMedium,
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), onSurface),
      bodyStyle: style(
          d.bodyStyle, text.bodyMedium, const TextStyle(fontSize: 14), muted),
      labelStyle: style(d.labelStyle, text.labelMedium,
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), muted),
      density: d.density ?? FewchursDensity.comfortable,
      voteButtonStyle: d.voteButtonStyle ?? VoteButtonStyle.column,
      cardElevation: d.cardElevation ?? 0,
    );
  }

  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color muted;
  final Color border;
  final Color error;
  final Map<FeatureStatus, Color> statusColors;
  final double cardRadius;
  final double buttonRadius;
  final double chipRadius;
  final double sheetRadius;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final TextStyle labelStyle;
  final FewchursDensity density;
  final VoteButtonStyle voteButtonStyle;
  final double cardElevation;

  bool get compact => density == FewchursDensity.compact;

  double get spacing => compact ? 10 : 14;

  /// Subtle translucent fill for borderless controls such as text fields and
  /// the vote button.
  Color get fill => onSurface.withAlpha(0x0F);

  /// Card color. Cards have no outline, so when [surface] matches the
  /// background (the Material 3 default) they get a light tint instead.
  Color get card =>
      surface == background ? Color.alphaBlend(fill, background) : surface;

  Color statusColor(FeatureStatus status) =>
      statusColors[status] ?? statusColors[FeatureStatus.unknown]!;

  static Color _contrastOn(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : Colors.black;

  static Map<FeatureStatus, Color> _defaultStatusColors(bool dark) => dark
      ? const {
          FeatureStatus.open: Color(0xFF9CA3AF),
          FeatureStatus.planned: Color(0xFF60A5FA),
          FeatureStatus.inProgress: Color(0xFFFBBF24),
          FeatureStatus.done: Color(0xFF4ADE80),
          FeatureStatus.declined: Color(0xFFF87171),
          FeatureStatus.unknown: Color(0xFF9CA3AF),
        }
      : const {
          FeatureStatus.open: Color(0xFF6B7280),
          FeatureStatus.planned: Color(0xFF2563EB),
          FeatureStatus.inProgress: Color(0xFFB45309),
          FeatureStatus.done: Color(0xFF15803D),
          FeatureStatus.declined: Color(0xFFDC2626),
          FeatureStatus.unknown: Color(0xFF6B7280),
        };
}
