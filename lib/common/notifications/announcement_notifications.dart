import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementNotifications extends ChangeNotifier
    with WidgetsBindingObserver {
  AnnouncementNotifications({FirebaseMessaging? messaging})
    : _injectedMessaging = messaging;
  static final instance = AnnouncementNotifications();
  final FirebaseMessaging? _injectedMessaging;
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static const topic = String.fromEnvironment('FLAVOR') == 'production'
      ? 'sakepedia_announcements_v1'
      : 'sakepedia_announcements_dev_v1';
  FirebaseMessaging get _messaging =>
      _injectedMessaging ?? FirebaseMessaging.instance;
  bool enabled = false;
  bool busy = false;
  String? error;
  bool _initialized = false;
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      enabled =
          (await SharedPreferences.getInstance()).getBool(
            'announcement_notifications',
          ) ??
          false;
      FirebaseMessaging.onMessage.listen((message) {
        if (!enabled || Platform.isIOS) return;
        final notification = message.notification;
        if (notification != null)
          messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                [
                  notification.title,
                  notification.body,
                ].whereType<String>().join('\n'),
              ),
              duration: const Duration(seconds: 6),
            ),
          );
      });
      _messaging.onTokenRefresh.listen(
        (_) => unawaited(sync()),
        onError: (_) {},
      );
      await sync();
    } catch (_) {
      error = '通知を準備できませんでした。設定から再試行できます。';
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(sync());
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    await (await SharedPreferences.getInstance()).setBool(
      'announcement_notifications',
      value,
    );
    await sync(requestPermission: value);
  }

  Future<void> sync({bool requestPermission = false}) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: enabled,
        badge: false,
        sound: enabled,
      );
      if (enabled) {
        final settings = requestPermission
            ? await _messaging.requestPermission()
            : await _messaging.getNotificationSettings();
        if (settings.authorizationStatus != AuthorizationStatus.authorized &&
            settings.authorizationStatus != AuthorizationStatus.provisional) {
          throw StateError('permission');
        }
        await _messaging.setAutoInitEnabled(true);
        if (Platform.isIOS && await _messaging.getAPNSToken() == null)
          throw StateError('apns');
        await prefs.setBool('announcement_topic_pending', true);
        await _messaging
            .subscribeToTopic(topic)
            .timeout(const Duration(seconds: 15));
      } else {
        if (!(prefs.getBool('announcement_topic_pending') ?? false)) {
          await _messaging.setAutoInitEnabled(false);
          return;
        }
        // Keep the desired OFF state if offline; resume retries unsubscription.
        if (Platform.isIOS && await _messaging.getAPNSToken() == null) {
          throw StateError('apns-unsubscribe-pending');
        }
        await _messaging
            .unsubscribeFromTopic(topic)
            .timeout(const Duration(seconds: 15));
        await _messaging.setAutoInitEnabled(false);
        await prefs.setBool('announcement_topic_pending', false);
      }
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: enabled,
        badge: false,
        sound: enabled,
      );
    } catch (_) {
      error = enabled
          ? '通知の登録が完了していません。端末の通知許可を確認して再試行してください。'
          : '受信停止の反映を確認できません。通信できる場所で再試行してください。';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> testToken() async {
    if (!enabled || busy || error != null) return null;
    return _messaging.getToken();
  }
}
