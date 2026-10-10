import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:mola_gemini_flutter_template/common/analytics/app_analytics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'SAKEPEDIA',
      packageName: 'test',
      version: '5.0.22',
      buildNumber: '137',
      buildSignature: '',
    );
  });
  test(
    'offline queue survives restart; resend keeps event IDs and clears only after acceptance',
    () async {
      final requests = <Map<String, dynamic>>[];
      final offline = AppAnalytics(
        enabled: true,
        tokenReader: () async => null,
        client: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://example.com/api/app-usage/events',
          );
          requests.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response('{}', 503);
        }),
      );
      await offline.initialize('example.com');
      await Future<void>.delayed(Duration.zero);
      offline.event('scan', 'camera_front');
      await offline.flush();
      await offline.close();
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('usage_queue_v1')!;
      expect(pending, hasLength(2));
      final originalIds = pending.map((e) => jsonDecode(e)['eventId']).toSet();
      final restored = AppAnalytics(
        enabled: true,
        tokenReader: () async => null,
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['installationId'], requests.first['installationId']);
          expect(
            (body['events'] as List)
                .map((e) => e['eventId'])
                .toSet()
                .containsAll(originalIds),
            true,
          );
          return http.Response('{}', 200);
        }),
      );
      await restored.initialize('example.com');
      await Future<void>.delayed(Duration.zero);
      await restored.flush();
      await restored.close();
      expect(prefs.getStringList('usage_queue_v1'), isEmpty);
    },
  );
  test(
    'home exposure is once per visit and never from an inactive screen',
    () async {
      final events = <dynamic>[];
      final analytics = AppAnalytics(
        enabled: true,
        tokenReader: () async => null,
        client: MockClient((r) async {
          events.addAll(jsonDecode(r.body)['events'] as List);
          return http.Response('{}', 200);
        }),
      );
      await analytics.initialize('example.com');
      await Future<void>.delayed(Duration.zero);
      analytics.view('home');
      analytics.impression('home_recent');
      analytics.impression('home_recent');
      analytics.view('map');
      analytics.impression('home_recent');
      analytics.view('home');
      analytics.impression('home_recent');
      await analytics.flush();
      await analytics.close();
      expect(events.where((e) => e['kind'] == 'impression'), hasLength(2));
    },
  );
  testWidgets('active tab only; detail pop restores home screen', (
    tester,
  ) async {
    var index = 0;
    late StateSetter change;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [analyticsRouteObserver],
        home: StatefulBuilder(
          builder: (context, setState) {
            change = setState;
            return Scaffold(
              body: IndexedStack(
                index: index,
                children: [
                  AnalyticsScreen(
                    name: 'home',
                    active: index == 0,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AnalyticsScreen(
                            name: 'detail',
                            child: Scaffold(body: Text('Detail')),
                          ),
                        ),
                      ),
                      child: const Text('Open'),
                    ),
                  ),
                  AnalyticsScreen(
                    name: 'map',
                    active: index == 1,
                    child: const Text('Map'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    expect(AppAnalytics.instance.screen, 'home');
    change(() => index = 1);
    await tester.pump();
    expect(AppAnalytics.instance.screen, 'map');
    change(() => index = 0);
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(AppAnalytics.instance.screen, 'detail');
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(AppAnalytics.instance.screen, 'home');
  });
  testWidgets('only a rail actually visible on home creates an exposure', (
    tester,
  ) async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    final events = <dynamic>[];
    final analytics = AppAnalytics(
      enabled: true,
      tokenReader: () async => null,
      client: MockClient((r) async {
        events.addAll(jsonDecode(r.body)['events'] as List);
        return http.Response('{}', 200);
      }),
    );
    await tester.runAsync(() async {
      await analytics.initialize('example.com');
      await Future<void>.delayed(Duration.zero);
    });
    analytics.view('home');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IndexedStack(
            index: 0,
            children: [
              const Text('Visible'),
              AnalyticsExposure(
                target: 'home_recent',
                analytics: analytics,
                child: const SizedBox(
                  width: 200,
                  height: 200,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => analytics.flush());
    expect(events.where((e) => e['kind'] == 'impression'), isEmpty);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnalyticsExposure(
            target: 'home_recent',
            analytics: analytics,
            child: const SizedBox(
              width: 200,
              height: 200,
              child: ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => analytics.flush());
    expect(events.where((e) => e['kind'] == 'impression'), hasLength(1));
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => analytics.close());
  });
}
