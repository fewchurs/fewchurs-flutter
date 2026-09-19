import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../fewchurs.dart';
import '../l10n/fewchurs_strings.dart';
import '../runtime.dart';
import '../theme/fewchurs_theme.dart';
import '../widgets/adaptive.dart';

/// Opens the submit form in a bottom sheet. Returns the new feature, or
/// `null` if the sheet was dismissed. The draft survives accidental dismissal.
Future<Feature?> showFewchursSubmitSheet(BuildContext context) {
  final t = FewchursThemeData.of(context);
  return showModalBottomSheet<Feature>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.surface,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(t.sheetRadius)),
    ),
    builder: (_) => const FewchursHost(child: FewchursSubmitForm()),
  );
}

class FewchursSubmitForm extends StatefulWidget {
  const FewchursSubmitForm({super.key, this.onSubmitted});

  /// Called with the created feature. When null, the form pops its route
  /// with the feature as the result.
  final ValueChanged<Feature>? onSubmitted;

  @override
  State<FewchursSubmitForm> createState() => _FewchursSubmitFormState();
}

class _FewchursSubmitFormState extends State<FewchursSubmitForm> {
  final _rt = FewchursRuntime.instance;
  late final _title = TextEditingController(text: _rt.draftTitle);
  late final _description = TextEditingController(text: _rt.draftDescription);
  final _email = TextEditingController();
  final _descriptionFocus = FocusNode();
  final _emailFocus = FocusNode();
  bool _submitting = false;
  bool _attempted = false;
  bool _done = false;
  String? _error;

  EmailField get _emailMode =>
      _rt.config?.board.emailField ?? EmailField.optional;

  @override
  void initState() {
    super.initState();
    if (_emailMode != EmailField.hidden) {
      _rt.knownEmail().then((email) {
        if (email != null && mounted && _email.text.isEmpty) {
          _email.text = email;
        }
      });
    }
  }

  @override
  void dispose() {
    if (!_done) {
      _rt.draftTitle = _title.text;
      _rt.draftDescription = _description.text;
    }
    _title.dispose();
    _description.dispose();
    _email.dispose();
    _descriptionFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String? _titleError(FewchursStrings s) {
    if (!_attempted) return null;
    final length = _title.text.trim().length;
    if (length < FewchursClient.titleMin) return s.titleTooShort;
    if (length > FewchursClient.titleMax) {
      return s.maxLength(FewchursClient.titleMax);
    }
    return null;
  }

  String? _emailError(FewchursStrings s) {
    if (!_attempted || _emailMode == EmailField.hidden) return null;
    final email = _email.text.trim();
    if (email.isEmpty) {
      return _emailMode == EmailField.required ? s.emailRequired : null;
    }
    return FewchursClient.isValidEmail(email) ? null : s.emailInvalid;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final s = FewchursStrings.of(context);
    setState(() {
      _attempted = true;
      _error = null;
    });
    if (_titleError(s) != null || _emailError(s) != null) return;

    setState(() => _submitting = true);
    try {
      final email =
          _emailMode == EmailField.hidden ? '' : _email.text.trim();
      final feature = await Fewchurs.submitFeature(
        title: _title.text,
        description: _description.text,
        email: email.isEmpty ? null : email,
      );
      _done = true;
      _rt.draftTitle = '';
      _rt.draftDescription = '';
      if (!mounted) return;
      final onSubmitted = widget.onSubmitted;
      if (onSubmitted != null) {
        onSubmitted(feature);
      } else {
        Navigator.of(context).pop(feature);
      }
    } on FewchursException catch (e) {
      if (mounted) setState(() => _error = s.error(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(
    FewchursResolvedTheme t,
    String label, {
    String? hint,
    String? helper,
    String? error,
  }) {
    final radius = BorderRadius.circular(t.buttonRadius);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      errorText: error,
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: t.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: t.primary, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = FewchursStrings.of(context);
    final t = FewchursThemeData.of(context);
    final emailMode = _emailMode;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(s.submitTitle,
                            style: t.titleStyle.copyWith(fontSize: 18)),
                      ),
                    ),
                    IconButton(
                      tooltip: s.close,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _title,
                  autofocus: _title.text.isEmpty,
                  maxLength: FewchursClient.titleMax,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_attempted) setState(() {});
                  },
                  onSubmitted: (_) => _descriptionFocus.requestFocus(),
                  decoration: _decoration(t, s.titleLabel,
                      hint: s.titleHint, error: _titleError(s)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _description,
                  focusNode: _descriptionFocus,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: FewchursClient.descriptionMax,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration(t, s.descriptionLabel,
                      hint: s.descriptionHint),
                ),
                if (emailMode != EmailField.hidden) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _email,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_attempted) setState(() {});
                    },
                    onSubmitted: (_) => _submit(),
                    decoration: _decoration(
                      t,
                      emailMode == EmailField.required
                          ? s.emailLabel
                          : s.emailOptionalLabel,
                      helper: s.emailHelper,
                      error: _emailError(s),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(_error!,
                        style: t.bodyStyle.copyWith(color: t.error)),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: t.primary,
                      foregroundColor: t.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(t.buttonRadius)),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? FewchursSpinner(size: 20, color: t.onPrimary)
                        : Text(s.submit),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
