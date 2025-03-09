import 'package:flutter/material.dart';

class AdConsentDialog extends StatelessWidget {
  const AdConsentDialog({
    Key? key,
    this.title = '広告視聴の確認',
    this.description = '広告を視聴すると、特別な機能が利用できます。',
    this.icon = Icons.video_collection,
    this.iconColor,
    this.acceptButtonText = '同意する',
    this.declineButtonText = 'キャンセル',
  }) : super(key: key);

  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final String acceptButtonText;
  final String declineButtonText;

  static Future<bool?> show(
    BuildContext context, {
    String title = '広告視聴の確認',
    String description = '広告を視聴すると、特別な機能が利用できます。',
    IconData icon = Icons.video_collection,
    Color? iconColor,
    String acceptButtonText = '同意する',
    String declineButtonText = 'キャンセル',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AdConsentDialog(
        title: title,
        description: description,
        icon: icon,
        iconColor: iconColor,
        acceptButtonText: acceptButtonText,
        declineButtonText: declineButtonText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // アイコン
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.amber.withOpacity(0.8),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            // タイトル
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // 説明文
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // キャンセルボタン
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    declineButtonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 同意ボタン
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    acceptButtonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
