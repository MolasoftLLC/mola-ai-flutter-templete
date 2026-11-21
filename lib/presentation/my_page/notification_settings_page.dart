import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../common/notifications/announcement_notifications.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final service = AnnouncementNotifications.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ通知'),
        backgroundColor: const Color(0xFF173B63),
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('SAKEPEDIAのお知らせを受け取る'),
              subtitle: const Text('新機能やサービスのお知らせをお届けします。いつでも変更できます。'),
              value: service.enabled,
              onChanged: service.busy ? null : service.setEnabled,
            ),
            if (service.busy) const LinearProgressIndicator(),
            if (service.error != null) ...[
              const SizedBox(height: 16),
              Text(service.error!),
              TextButton(
                onPressed: service.busy ? null : () => service.sync(),
                child: const Text('再試行'),
              ),
              TextButton(
                onPressed: Geolocator.openAppSettings,
                child: const Text('端末の設定を開く'),
              ),
            ],
            const SizedBox(height: 24),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('通知のテスト'),
              children: [
                const Text('管理画面から自分の端末にテスト送信する場合に使います。コピーした情報は公開しないでください。'),
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('テスト用トークンをコピー'),
                  onPressed:
                      !service.enabled || service.busy || service.error != null
                      ? null
                      : () async {
                          try {
                            final token = await service.testToken();
                            if (token == null) throw StateError('unavailable');
                            await Clipboard.setData(ClipboardData(text: token));
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('コピーしました')),
                              );
                          } catch (_) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('取得できませんでした。再試行してください。'),
                                ),
                              );
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
