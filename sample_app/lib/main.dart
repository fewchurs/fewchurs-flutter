import 'package:fewchurs/fewchurs.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'pages/home_shell.dart';

// flutter run --dart-define=FEWCHURS_API_KEY=fr_live_xxx
const _apiKey = String.fromEnvironment('FEWCHURS_API_KEY');

void main() {
  final app = AppState();

  Fewchurs.configure(
    apiKey: _apiKey,
    style: FewchursStyle.adaptive,
    logLevel: FewchursLogLevel.debug,
    isSubscriber: () => app.isPro.value,
    userEmail: () => app.email.value,
    board: const BoardOptions(
      tabs: [BoardTab.top, BoardTab.newest],
      emailField: EmailField.optional,
    ),
    strings: const FewchursStrings(
      boardTitle: 'Ideas for Taskly',
      submitButton: 'Suggest an idea',
      emptyTitle: 'No ideas yet',
    ),
  );

  Fewchurs.events.listen((event) => debugPrint('[analytics] ${event.name}'));

  runApp(TasklyApp(state: app));
}

class TasklyApp extends StatelessWidget {
  const TasklyApp({super.key, required this.state});

  final AppState state;

  static const _brand = Color(0xFF4F46E5);

  static ThemeData _theme(Brightness brightness) => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _brand,
        brightness: brightness,
        extensions: const [
          FewchursThemeData(
            cardRadius: 16,
            voteButtonStyle: VoteButtonStyle.column,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: state.themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Taskly',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: mode,
        localizationsDelegates: const [FewchursLocalizations.delegate],
        home: HomeShell(state: state),
      ),
    );
  }
}
