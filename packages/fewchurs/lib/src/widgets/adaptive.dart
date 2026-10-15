import 'dart:math' as math;

import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/fewchurs_strings.dart';
import '../runtime.dart';
import '../theme/fewchurs_theme.dart';

/// Borderless filled text field. Only focus and errors draw an outline.
InputDecoration fewchursInputDecoration(
  FewchursResolvedTheme t, {
  String? label,
  String? hint,
  String? helper,
  String? error,
  String? counter,
  bool isDense = false,
  EdgeInsetsGeometry? contentPadding,
}) {
  final radius = BorderRadius.circular(t.buttonRadius);
  OutlineInputBorder outline(BorderSide side) =>
      OutlineInputBorder(borderRadius: radius, borderSide: side);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    errorText: error,
    counterText: counter,
    isDense: isDense,
    contentPadding: contentPadding,
    filled: true,
    fillColor: t.fill,
    border: outline(BorderSide.none),
    enabledBorder: outline(BorderSide.none),
    disabledBorder: outline(BorderSide.none),
    focusedBorder: outline(BorderSide(color: t.primary, width: 1.5)),
    errorBorder: outline(BorderSide(color: t.error)),
    focusedErrorBorder: outline(BorderSide(color: t.error, width: 1.5)),
  );
}

/// Makes the package's Material widgets safe to use anywhere: adds Material
/// localizations when the app doesn't provide them (e.g. a `CupertinoApp`),
/// a local [ScaffoldMessenger] for snack bars, and optional Esc-to-close.
class FewchursHost extends StatelessWidget {
  const FewchursHost({
    super.key,
    required this.child,
    this.messengerKey,
    this.closeOnEscape = false,
  });

  final Widget child;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;
  final bool closeOnEscape;

  @override
  Widget build(BuildContext context) {
    Widget result = ScaffoldMessenger(key: messengerKey, child: child);
    if (closeOnEscape) {
      result = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              closeFewchursRoute(context),
        },
        child: Focus(autofocus: true, child: result),
      );
    }
    if (Localizations.of<MaterialLocalizations>(
            context, MaterialLocalizations) ==
        null) {
      result = Localizations.override(
        context: context,
        delegates: const [DefaultMaterialLocalizations.delegate],
        child: result,
      );
    }
    return result;
  }
}

void showFewchursMessage(
  BuildContext context,
  String message, {
  GlobalKey<ScaffoldMessengerState>? messengerKey,
}) {
  final messenger =
      messengerKey?.currentState ?? ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
}

class FewchursSpinner extends StatelessWidget {
  const FewchursSpinner({super.key, this.size = 22, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (FewchursRuntime.instance.useCupertino(context)) {
      return CupertinoActivityIndicator(radius: size / 2, color: color);
    }
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: color ?? FewchursThemeData.of(context).primary,
      ),
    );
  }
}

Route<T> fewchursRoute<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool fullscreenDialog = false,
}) {
  if (FewchursRuntime.instance.useCupertino(context)) {
    return CupertinoPageRoute<T>(
        builder: builder, fullscreenDialog: fullscreenDialog);
  }
  return MaterialPageRoute<T>(
      builder: builder, fullscreenDialog: fullscreenDialog);
}

/// Pops the current route. When it's the first page of a side sheet's own
/// navigator, closes the whole sheet instead.
Future<void> closeFewchursRoute(BuildContext context) async {
  final navigator = Navigator.maybeOf(context);
  if (navigator == null) return;
  if (navigator.canPop()) {
    await navigator.maybePop();
    return;
  }
  if (navigator.widget is _SideSheetNavigator) {
    // Navigator.maybeOf would return this navigator itself; go one up.
    await navigator.context
        .findAncestorStateOfType<NavigatorState>()
        ?.maybePop();
  }
}

/// Slides [child] in from the end edge, full height, with its own navigator
/// so pages opened from it stay inside the sheet.
Future<T?> showFewchursSideSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double width = 440,
}) {
  final rootContext = Navigator.of(context, rootNavigator: true).context;
  final themes = InheritedTheme.capture(from: context, to: rootContext);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (sheetContext, _, __) =>
        themes.wrap(_SideSheet(width: width, builder: builder)),
    transitionBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween<Offset>(
        begin: Offset(rtl ? -1 : 1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      )),
      child: child,
    ),
  );
}

class _SideSheet extends StatelessWidget {
  const _SideSheet({required this.width, required this.builder});

  final double width;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final t = FewchursThemeData.of(context);
    final media = MediaQuery.of(context);
    final w = math.min(width, media.size.width);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: w,
        height: double.infinity,
        child: Material(
          color: t.background,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.horizontal(
              start: Radius.circular(t.sheetRadius),
            ).resolve(Directionality.of(context)),
          ),
          // Report the sheet's width so the content lays out as on a phone.
          child: MediaQuery(
            data: media.copyWith(size: Size(w, media.size.height)),
            child: _SideSheetNavigator(
              onGenerateRoute: (_) => fewchursRoute<void>(context, builder),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideSheetNavigator extends Navigator {
  const _SideSheetNavigator({super.onGenerateRoute});
}

typedef EmailPromptResult = ({String email, bool remember});

Future<EmailPromptResult?> showFewchursEmailDialog(BuildContext context) {
  final cupertino = FewchursRuntime.instance.useCupertino(context);
  const dialog = FewchursHost(child: _EmailDialog());
  return cupertino
      ? showCupertinoDialog<EmailPromptResult>(
          context: context, barrierDismissible: true, builder: (_) => dialog)
      : showDialog<EmailPromptResult>(context: context, builder: (_) => dialog);
}

class _EmailDialog extends StatefulWidget {
  const _EmailDialog();

  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  final _controller = TextEditingController();
  bool _remember = true;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _controller.text.trim();
    if (!FewchursClient.isValidEmail(email)) {
      setState(() => _error = FewchursStrings.of(context).emailInvalid);
      return;
    }
    Navigator.of(context)
        .pop<EmailPromptResult>((email: email, remember: _remember));
  }

  @override
  Widget build(BuildContext context) {
    final s = FewchursStrings.of(context);
    final t = FewchursThemeData.of(context);

    if (FewchursRuntime.instance.useCupertino(context)) {
      return CupertinoAlertDialog(
        title: Text(s.followTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.followMessage),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _controller,
              autofocus: true,
              placeholder: s.emailLabel,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_error!,
                    style: TextStyle(color: t.error, fontSize: 13)),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: Text(s.rememberEmail,
                        style: const TextStyle(fontSize: 13))),
                CupertinoSwitch(
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v),
                ),
              ],
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: _submit,
            child: Text(s.follow),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(s.followTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.followMessage),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              decoration: fewchursInputDecoration(
                FewchursThemeData.of(context),
                label: s.emailLabel,
                error: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _remember,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(s.rememberEmail),
              onChanged: (v) => setState(() => _remember = v ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(s.follow)),
      ],
    );
  }
}

String fewchursRelativeTime(BuildContext context, DateTime time) {
  final diff = DateTime.now().toUtc().difference(time.toUtc());
  if (diff.inMinutes < 1) return FewchursStrings.of(context).justNow;
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return MaterialLocalizations.of(context).formatShortDate(time.toLocal());
}
