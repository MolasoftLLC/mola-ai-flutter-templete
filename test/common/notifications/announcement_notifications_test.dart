import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/common/notifications/announcement_notifications.dart';

class Messaging extends Fake implements FirebaseMessaging {
  bool allowed = true;
  bool offline = false;
  int permissionRequests = 0;
  int subscriptions = 0;
  int unsubscriptions = 0;
  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    permissionRequests++;
    return getNotificationSettings();
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async =>
      NotificationSettings(
        alert: AppleNotificationSetting.enabled,
        announcement: AppleNotificationSetting.disabled,
        authorizationStatus: allowed
            ? AuthorizationStatus.authorized
            : AuthorizationStatus.denied,
        badge: AppleNotificationSetting.enabled,
        carPlay: AppleNotificationSetting.disabled,
        lockScreen: AppleNotificationSetting.enabled,
        notificationCenter: AppleNotificationSetting.enabled,
        showPreviews: AppleShowPreviewSetting.always,
        timeSensitive: AppleNotificationSetting.disabled,
        criticalAlert: AppleNotificationSetting.disabled,
        sound: AppleNotificationSetting.enabled,
      );
  @override
  Future<void> setAutoInitEnabled(bool enabled) async {}
  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {}
  @override
  Future<void> subscribeToTopic(String topic) async {
    subscriptions++;
    if (offline) throw StateError('offline');
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    unsubscriptions++;
    if (offline) throw StateError('offline');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('initial OFF never registers and never prompts', () async {
    final messaging = Messaging();
    final service = AnnouncementNotifications(messaging: messaging);
    await service.sync();
    expect(messaging.permissionRequests, 0);
    expect(messaging.subscriptions, 0);
    expect(messaging.unsubscriptions, 0);
  });
  test(
    'permission refusal does not subscribe; user can retry without automatic permission popup',
    () async {
      final messaging = Messaging()..allowed = false;
      final service = AnnouncementNotifications(messaging: messaging);
      await service.setEnabled(true);
      expect(service.error, isNotNull);
      expect(messaging.subscriptions, 0);
      messaging.allowed = true;
      await service.sync();
      expect(service.error, isNull);
      expect(messaging.subscriptions, 1);
      expect(messaging.permissionRequests, 1);
    },
  );
  test('offline opt out stays pending and resume can complete it', () async {
    final messaging = Messaging();
    final service = AnnouncementNotifications(messaging: messaging);
    await service.setEnabled(true);
    messaging.offline = true;
    await service.setEnabled(false);
    expect(service.enabled, false);
    expect(service.error, isNotNull);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'announcement_topic_pending',
      ),
      true,
    );
    messaging.offline = false;
    await service.sync();
    expect(service.error, isNull);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'announcement_topic_pending',
      ),
      false,
    );
  });
}
