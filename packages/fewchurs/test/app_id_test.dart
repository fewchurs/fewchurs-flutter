import 'package:fewchurs/fewchurs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String?> appIdSentOn(TargetPlatform platform) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    late http.Request captured;
    Fewchurs.configure(
      apiKey: 'fr_test',
      deviceId: () => 'device',
      logLevel: FewchursLogLevel.none,
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response('{}', 200);
      }),
    );
    await Fewchurs.client.getConfig();
    return captured.headers['X-Fewchurs-App-Id'];
  } finally {
    debugDefaultTargetPlatformOverride = null;
    Fewchurs.reset();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'App',
      packageName: 'com.company.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('sends the package name on Android and iOS', () async {
    expect(await appIdSentOn(TargetPlatform.android), 'com.company.app');
    expect(await appIdSentOn(TargetPlatform.iOS), 'com.company.app');
  });

  test('sends no app ID on other platforms', () async {
    expect(await appIdSentOn(TargetPlatform.macOS), isNull);
    expect(await appIdSentOn(TargetPlatform.windows), isNull);
    expect(await appIdSentOn(TargetPlatform.linux), isNull);
  });
}
