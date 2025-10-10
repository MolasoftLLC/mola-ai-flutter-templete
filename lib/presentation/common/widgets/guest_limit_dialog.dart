import 'package:flutter/material.dart';

import '../../auth/email_link_auth_page.dart';

class GuestLimitDialog {
  static Future<void> showSavedSakeLimit(BuildContext context,
      {required int maxCount}) async {
    await show(
      context,
      title: '保存枠が上限に達しました',
      message:
          '無料会員登録で保存枠が増えます。\n現在の保存上限は${maxCount}件です。\n解析前に会員登録すると無料で保存がもっとできます！',
    );
  }

  static Future<void> showFavoriteLimit(BuildContext context,
      {required int maxCount}) async {
    await show(
      context,
      title: 'お気に入り枠が上限に達しました',
      message:
          '無料会員登録でお気に入り枠が増えます。\n現在の上限は${maxCount}件です。\n会員登録するとお気に入りを無制限に登録できます！',
    );
  }

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final shouldNavigate = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D3567),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                foregroundColor: const Color(0xFF1D3567),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'メール認証に進む',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (shouldNavigate == true) {
      final navigator = Navigator.of(context);
      if (!navigator.mounted) {
        return;
      }
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => EmailLinkAuthPage.signUp(),
        ),
      );
    }
  }
}
