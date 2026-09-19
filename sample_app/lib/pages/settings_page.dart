import 'package:fewchurs/fewchurs.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.state});

  final AppState state;

  Future<void> _quickFeedback(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick idea'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(hintText: 'What should we build?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null) return;

    // Example: submitting from your own UI.
    try {
      await Fewchurs.submitFeature(title: title, email: state.email.value);
      messenger.showSnackBar(const SnackBar(content: Text('Thanks! Idea sent.')));
    } on FewchursException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Header('Feedback'),
          ListTile(
            leading: const Icon(Icons.forum_outlined),
            title: const Text('Feature requests'),
            subtitle: const Text('Vote on what we build next'),
            onTap: () => Fewchurs.showBoard(context),
          ),
          ListTile(
            leading: const Icon(Icons.add_comment_outlined),
            title: const Text('Suggest a feature'),
            onTap: () => showFewchursSubmitSheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.bolt_outlined),
            title: const Text('Quick idea (custom form)'),
            onTap: () => _quickFeedback(context),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Branded board'),
            subtitle: const Text('Scoped FewchursTheme + builders'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const _BrandedBoard()),
            ),
          ),
          const _Header('Account'),
          ValueListenableBuilder<bool>(
            valueListenable: state.isPro,
            builder: (context, pro, _) => SwitchListTile(
              secondary: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Taskly Pro'),
              subtitle: const Text('Sent as isSubscriber with new ideas'),
              value: pro,
              onChanged: (v) => state.isPro.value = v,
            ),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: state.email,
            builder: (context, email, _) => ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Signed-in email'),
              subtitle: Text(email ?? 'Not signed in'),
              trailing: TextButton(
                onPressed: () => state.email.value =
                    email == null ? 'sam@example.com' : null,
                child: Text(email == null ? 'Sign in' : 'Sign out'),
              ),
            ),
          ),
          const _Header('Appearance'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: state.themeMode,
            builder: (context, mode, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {mode},
                onSelectionChanged: (s) => state.themeMode.value = s.first,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _BrandedBoard extends StatelessWidget {
  const _BrandedBoard();

  @override
  Widget build(BuildContext context) {
    return FewchursTheme(
      data: const FewchursThemeData(
        primary: Color(0xFF0D9488),
        cardRadius: 22,
        voteButtonStyle: VoteButtonStyle.pill,
        density: FewchursDensity.compact,
      ),
      child: FewchursBoard(
        title: 'Taskly roadmap',
        options: const BoardOptions(
          tabs: [BoardTab.roadmap, BoardTab.top],
          defaultTab: BoardTab.roadmap,
          submitButton: SubmitButtonPlacement.bottomBar,
        ),
        headerBuilder: (context) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Here is what we are working on. Vote to move things up.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        statusChipBuilder: (context, status) => Text(
          switch (status) {
            FeatureStatus.planned => '🗓 Planned',
            FeatureStatus.inProgress => '🚧 Building',
            FeatureStatus.done => '✅ Shipped',
            _ => status.name,
          },
        ),
      ),
    );
  }
}
