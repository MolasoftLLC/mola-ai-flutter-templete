import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/access_url.dart';
import '../../../common/utils/snack_bar_utils.dart';

const _navy = Color(0xFF1D3567);

enum _ReviewAction { review, feedback }

Future<void> showAppReviewDialog(BuildContext context) async {
  final english = Localizations.localeOf(context).languageCode == 'en';
  final action = await showDialog<_ReviewAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      icon: const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 40),
      title: Text(
        english ? 'How is SAKEPEDIA?' : 'SAKEPEDIAはいかがですか？',
        style: const TextStyle(
          color: _navy,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            english
                ? 'Share a rating or your feedback to help us improve the app.'
                : '評価やご意見をお聞かせください。今後の改善に役立てます。',
            style: const TextStyle(color: Color(0xFF647184), height: 1.6),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, _ReviewAction.review),
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.star_outline_rounded),
            label: Text(english ? 'Rate the app' : 'アプリを評価する'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pop(dialogContext, _ReviewAction.feedback),
            style: OutlinedButton.styleFrom(
              foregroundColor: _navy,
              side: const BorderSide(color: _navy),
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.feedback_outlined),
            label: Text(english ? 'Send feedback' : 'フィードバックを送る'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(english ? 'Close' : '閉じる'),
        ),
      ],
    ),
  );
  if (action == null || !context.mounted) return;
  // A user-initiated review link opens the store's review page reliably;
  // the system's discretionary review prompt may not appear on a button tap.
  final uri = action == _ReviewAction.feedback
      ? Uri.parse('https://molasoft.jp/contact/')
      : Platform.isAndroid
      ? Uri.parse(PLAY_STORE_URL)
      : Uri.parse(
          APP_STORE_URL,
        ).replace(queryParameters: {'action': 'write-review'});
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Keep the user on My Page and show a recoverable launch error below.
  }
  if (!context.mounted) return;
  SnackBarUtils.showWarningSnackBar(
    context,
    message: english
        ? 'Could not open the page. Please try again.'
        : 'ページを開けませんでした。もう一度お試しください。',
  );
}
