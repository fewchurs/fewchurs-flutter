import 'package:fewchurs_core/fewchurs_core.dart';

// dart run example/main.dart fr_live_xxx
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run example/main.dart <api key>');
    return;
  }
  final client = FewchursClient(apiKey: args.first);
  try {
    final page = await client.listFeatures(sort: FeatureSort.top, limit: 5);
    for (final feature in page.features) {
      print('${feature.upvoteCount.toString().padLeft(4)}  ${feature.title}');
    }
  } on FewchursException catch (e) {
    print(e.userMessage);
  } finally {
    client.close();
  }
}
