import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

String analyticsId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// First-party usage events. No photos, free text, location, advertising ID or raw user ID.
class AppAnalytics with WidgetsBindingObserver {
  static final instance = AppAnalytics();
  AppAnalytics({
    bool enabled = kReleaseMode,
    http.Client? client,
    Future<String?> Function()? tokenReader,
  }) : _enabled = enabled,
       _client = client ?? http.Client(),
       _tokenReader = tokenReader ?? _firebaseToken;
  static Future<String?> _firebaseToken() async =>
      FirebaseAuth.instance.currentUser?.getIdToken();
  final bool _enabled;
  final http.Client _client;
  final Future<String?> Function() _tokenReader;
  Timer? _timer;
  bool _initialized = false;
  Future<void> close() async {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    await _writes;
    _client.close();
  }

  SharedPreferences? _prefs;
  PackageInfo? _info;
  Uri? _endpoint;
  final List<Map<String, dynamic>> _queue = [];
  Future<void> _writes = Future.value();
  bool _sending = false;
  DateTime? _retryAfter;
  String _installation = '';
  String session = analyticsId();
  String screen = 'app';
  final homeVisit = ValueNotifier<String>(analyticsId());
  DateTime? _pausedAt;
  bool _foreground = true;
  final Set<String> _impressions = {};

  Future<void> initialize(String apiBase) async {
    if (!_enabled || _initialized) return;
    _initialized = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      _info = await PackageInfo.fromPlatform();
      _installation =
          _prefs!.getString('usage_installation_v1') ?? analyticsId();
      await _prefs!.setString('usage_installation_v1', _installation);
      _endpoint = apiBase.contains('://')
          ? Uri.parse(apiBase).replace(path: '/api/app-usage/events')
          : Uri(
              scheme: apiBase == '127.0.0.1' || apiBase == '10.0.2.2'
                  ? 'http'
                  : 'https',
              host: apiBase,
              port: apiBase == '127.0.0.1' || apiBase == '10.0.2.2'
                  ? 8080
                  : null,
              path: '/api/app-usage/events',
            );
      for (final line
          in _prefs!.getStringList('usage_queue_v1') ?? <String>[]) {
        try {
          final event = Map<String, dynamic>.from(jsonDecode(line) as Map);
          final time = DateTime.tryParse(event['occurredAt'] as String? ?? '');
          if (time != null && DateTime.now().difference(time).inDays < 7) {
            _queue.add(event);
          }
        } catch (_) {}
      }
      WidgetsBinding.instance.addObserver(this);
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_foreground) unawaited(flush());
      });
      view('app');
      unawaited(flush());
    } catch (_) {
      _endpoint = null;
    }
  }

  void event(
    String screen,
    String target, {
    String kind = 'tap',
    String? source,
    String? flowId,
  }) {
    if (_endpoint == null || _info == null) return;
    _queue.add({
      'eventId': analyticsId(),
      'sessionId': session,
      'flowId': flowId,
      'kind': kind,
      'screen': screen,
      'target': target,
      'source': source ?? this.screen,
      'occurredAt': DateTime.now().toUtc().toIso8601String(),
      'version': _info!.version,
      'build': _info!.buildNumber,
      'platform': Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
          ? 'android'
          : 'other',
    });
    if (_queue.length > 500) _queue.removeRange(0, _queue.length - 500);
    _persist();
    if (_queue.length >= 20) unawaited(flush());
  }

  void view(String next) {
    final previous = screen;
    screen = next;
    if (next == 'home') homeVisit.value = analyticsId();
    event(next, 'screen', kind: 'screen_view', source: previous);
  }

  void impression(String target) {
    if (_endpoint == null || !_foreground || screen != 'home') return;
    if (_impressions.add('${homeVisit.value}:$target')) {
      event('home', target, kind: 'impression', source: 'home');
      if (_impressions.length > 100) _impressions.remove(_impressions.first);
    }
  }

  void _persist() {
    final snapshot = _queue.map(jsonEncode).toList();
    _writes = _writes
        .then((_) async {
          await _prefs?.setStringList('usage_queue_v1', snapshot);
        })
        .catchError((_) {});
  }

  Future<void> flush() async {
    if (_sending ||
        _endpoint == null ||
        _queue.isEmpty ||
        (_retryAfter != null && DateTime.now().isBefore(_retryAfter!))) {
      return;
    }
    _sending = true;
    try {
      for (var i = 0; i < 10 && _queue.isNotEmpty; i++) {
        final batch = _queue.take(50).toList();
        final headers = <String, String>{'Content-Type': 'application/json'};
        final token = await _tokenReader().timeout(const Duration(seconds: 5));
        if (token != null) headers['Authorization'] = 'Bearer $token';
        final response = await _client
            .post(
              _endpoint!,
              headers: headers,
              body: jsonEncode({
                'installationId': _installation,
                'events': batch,
              }),
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200 && response.statusCode != 400) {
          _retryAfter = DateTime.now().add(const Duration(seconds: 30));
          break;
        }
        _retryAfter = null;
        final ids = batch.map((e) => e['eventId']).toSet();
        _queue.removeWhere((e) => ids.contains(e['eventId']));
        _persist();
      }
    } catch (_) {
      _retryAfter = DateTime.now().add(const Duration(seconds: 30));
      // Analytics must never interrupt a user action; retry on the next flush.
    } finally {
      _sending = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
      unawaited(flush());
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null &&
          DateTime.now().difference(_pausedAt!) > const Duration(minutes: 30)) {
        session = analyticsId();
        homeVisit.value = analyticsId();
        _impressions.clear();
        event(screen, 'screen', kind: 'screen_view', source: 'app');
      }
      _pausedAt = null;
      unawaited(flush());
    }
  }
}

class AnalyticsExposure extends StatefulWidget {
  const AnalyticsExposure({
    super.key,
    required this.target,
    required this.child,
    this.analytics,
  });
  final String target;
  final Widget child;
  final AppAnalytics? analytics;
  @override
  State<AnalyticsExposure> createState() => _AnalyticsExposureState();
}

class _AnalyticsExposureState extends State<AnalyticsExposure> {
  double _visibleFraction = 0;
  AppAnalytics get _analytics => widget.analytics ?? AppAnalytics.instance;
  @override
  void initState() {
    super.initState();
    _analytics.homeVisit.addListener(_onHomeVisit);
  }

  void _onHomeVisit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _record();
    });
  }

  void _record() {
    if (!mounted) return;
    if (_visibleFraction >= .25 && ModalRoute.of(context)?.isCurrent == true) {
      _analytics.impression(widget.target);
    }
  }

  @override
  void dispose() {
    _analytics.homeVisit.removeListener(_onHomeVisit);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: ValueKey('usage-exposure-${widget.target}'),
    onVisibilityChanged: (info) {
      _visibleFraction = info.visibleFraction;
      _record();
    },
    child: widget.child,
  );
}

final analyticsRouteObserver = RouteObserver<PageRoute<dynamic>>();

/// Restores the underlying screen after a detail route is popped. Inactive tabs
/// remain mounted but must never record views or impressions.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.name,
    required this.child,
    this.active = true,
  });
  final String name;
  final Widget child;
  final bool active;
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with RouteAware {
  PageRoute<dynamic>? _route;
  void _view() {
    if (widget.active && _route?.isCurrent == true) {
      AppAnalytics.instance.view(widget.name);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      analyticsRouteObserver.unsubscribe(this);
      _route = route;
      analyticsRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!oldWidget.active && widget.active) || oldWidget.name != widget.name) {
      _view();
    }
  }

  @override
  void didPush() => _view();
  @override
  void didPopNext() => _view();
  @override
  void dispose() {
    analyticsRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
