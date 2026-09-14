import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/sake_community_repository.dart';
import '../auth/email_link_auth_page.dart';
import 'sake_scan_page.dart';

Future<Object?> openSakeLabelScanner(BuildContext context) async {
  final authRepository = context.read<AuthRepository>();
  if (authRepository.currentUser == null) {
    final login = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ラベル撮影にはログインが必要です'),
        content: const Text('撮影画像の利用同意と、画像・評価の管理のためログインしてください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ログイン'),
          ),
        ],
      ),
    );
    if (login != true || !context.mounted) return null;
    final signedIn = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => EmailLinkAuthPage.signIn()));
    if (signedIn != true || !context.mounted) return null;
  }

  final repository = context.read<SakeCommunityRepository>();
  bool agreed;
  try {
    agreed = await repository.hasAcceptedLabelConsent();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('撮影画像の利用条件を確認できませんでした。')));
    }
    return null;
  }

  if (!agreed && context.mounted) {
    var checked = false;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('撮影画像の利用について'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'この機能で撮影した酒瓶の表ラベル画像は、次の用途で必ず利用されます。',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('・このお酒の詳細画面で、他のユーザーにも表示'),
                const Text(
                  '・AIラベル照合機能の学習・精度向上のため、Google Cloud Vision Product Searchへ参照画像として登録',
                ),
                const SizedBox(height: 12),
                const Text(
                  '人物の顔、氏名、住所、伝票などの個人情報が写らないよう、酒瓶のラベルだけを撮影してください。投稿後は自分の画像を削除できます。',
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: checked,
                  onChanged: (value) =>
                      setDialogState(() => checked = value == true),
                  title: const Text('上記に同意してラベルを撮影する'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: checked
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text('同意して進む'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !context.mounted) return null;
    try {
      await repository.acceptLabelConsent();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同意を保存できませんでした。もう一度お試しください。')),
        );
      }
      return null;
    }
  }

  if (!context.mounted) return null;
  return Navigator.of(context).push<Object>(
    PageRouteBuilder<Object>(
      pageBuilder: (_, __, ___) => SakeScanPage.wrapped(),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            ),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
    ),
  );
}
