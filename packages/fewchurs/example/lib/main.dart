import 'package:fewchurs/fewchurs.dart';
import 'package:flutter/material.dart';

// flutter run --dart-define=FEWCHURS_API_KEY=fr_live_xxx
const apiKey = String.fromEnvironment('FEWCHURS_API_KEY');
const baseUrl = String.fromEnvironment('FEWCHURS_BASE_URL');

void configure({FewchursStyle style = FewchursStyle.material}) {
  Fewchurs.configure(
    apiKey: apiKey,
    baseUrl: baseUrl.isEmpty ? null : baseUrl,
    style: style,
    logLevel: FewchursLogLevel.debug,
    board: const BoardOptions(
      tabs: [BoardTab.top, BoardTab.newest, BoardTab.roadmap],
    ),
  );
}

void main() {
  configure();
  Fewchurs.events.listen((event) => debugPrint('fewchurs event: ${event.name}'));
  runApp(const ExampleApp());
}

const _seed = Color(0xFFED5F18);

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fewchurs example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: _seed),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seed,
        brightness: Brightness.dark,
      ),
      localizationsDelegates: const [FewchursLocalizations.delegate],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _cupertino = false;

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fewchurs example')),
      body: ListView(
        children: [
          if (apiKey.isEmpty)
            const ListTile(
              leading: Icon(Icons.warning_amber_rounded),
              title: Text('No API key'),
              subtitle: Text(
                  'Run with --dart-define=FEWCHURS_API_KEY=fr_live_xxx'),
            ),
          SwitchListTile(
            title: const Text('Cupertino style'),
            value: _cupertino,
            onChanged: (value) {
              setState(() => _cupertino = value);
              configure(
                  style: value ? FewchursStyle.cupertino : FewchursStyle.material);
            },
          ),
          ListTile(
            title: const Text('Board as a page'),
            onTap: () => Fewchurs.showBoard(context),
          ),
          ListTile(
            title: const Text('Board as a bottom sheet'),
            onTap: () => Fewchurs.showBoardSheet(context),
          ),
          ListTile(
            title: const Text('Themed board'),
            onTap: () => _push(const ThemedBoardPage()),
          ),
          ListTile(
            title: const Text('Custom builders'),
            onTap: () => _push(const CustomBuildersPage()),
          ),
          ListTile(
            title: const Text('Headless (your own UI)'),
            onTap: () => _push(const HeadlessPage()),
          ),
          ListTile(
            title: const Text('Submit from your own UI'),
            onTap: () => _push(const OwnSubmitPage()),
          ),
        ],
      ),
    );
  }
}

class ThemedBoardPage extends StatelessWidget {
  const ThemedBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FewchursTheme(
      data: FewchursThemeData(
        primary: Colors.teal,
        cardRadius: 20,
        voteButtonStyle: VoteButtonStyle.pill,
        density: FewchursDensity.compact,
        statusColors: {FeatureStatus.done: Color(0xFF16A34A)},
      ),
      child: FewchursBoard(
        title: 'Ideas & roadmap',
        options: BoardOptions(
          tabs: [BoardTab.top, BoardTab.newest],
          submitButton: SubmitButtonPlacement.bottomBar,
        ),
      ),
    );
  }
}

class CustomBuildersPage extends StatelessWidget {
  const CustomBuildersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FewchursBoard(
      headerBuilder: (context) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text('Vote for what we build next.'),
      ),
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Nothing here yet 🌱')),
      ),
      featureCardBuilder: (context, feature, actions) => Card(
        child: ListTile(
          onTap: actions.open,
          title: Text(feature.title),
          subtitle: Text(
            feature.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: TextButton.icon(
            onPressed: actions.toggleVote,
            icon: Icon(feature.hasVoted ? Icons.thumb_up : Icons.thumb_up_outlined),
            label: Text('${feature.upvoteCount}'),
          ),
        ),
      ),
    );
  }
}

class HeadlessPage extends StatefulWidget {
  const HeadlessPage({super.key});

  @override
  State<HeadlessPage> createState() => _HeadlessPageState();
}

class _HeadlessPageState extends State<HeadlessPage> {
  late final BoardController _board =
      Fewchurs.boardController(sort: FeatureSort.newest);

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Headless')),
      body: ListenableBuilder(
        listenable: _board,
        builder: (context, _) => switch (_board.state) {
          BoardLoading() => const Center(child: CircularProgressIndicator()),
          BoardError(:final error) => Center(
              child: TextButton(
                onPressed: _board.refresh,
                child: Text('${error.userMessage} Tap to retry.'),
              ),
            ),
          BoardContent(:final features, :final canLoadMore) => ListView(
              children: [
                for (final f in features)
                  ListTile(
                    leading: IconButton(
                      icon: Icon(
                          f.hasVoted ? Icons.favorite : Icons.favorite_border),
                      onPressed: () => _board.toggleVote(f.id),
                    ),
                    title: Text(f.title),
                    subtitle: Text(f.status.name),
                    trailing: Text('${f.upvoteCount}'),
                  ),
                if (canLoadMore)
                  TextButton(
                      onPressed: _board.loadMore,
                      child: const Text('Load more')),
              ],
            ),
        },
      ),
    );
  }
}

class OwnSubmitPage extends StatefulWidget {
  const OwnSubmitPage({super.key});

  @override
  State<OwnSubmitPage> createState() => _OwnSubmitPageState();
}

class _OwnSubmitPageState extends State<OwnSubmitPage> {
  final _title = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final feature = await Fewchurs.submitFeature(title: _title.text);
      messenger.showSnackBar(
          SnackBar(content: Text('Submitted ${feature.id} (${feature.status.name})')));
      _title.clear();
    } on FewchursException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.userMessage)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your own form')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
