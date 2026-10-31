import 'package:mola_gemini_flutter_template/common/analytics/app_analytics.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../common/utils/async_action_gate.dart';
import 'package:provider/provider.dart';

import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/sake_community_repository.dart';
import '../auth/email_link_auth_page.dart';
import '../common/dialogs/ai_data_consent_dialog.dart';
import 'sake_scan_page.dart';

final _scannerEntryGate = AsyncActionGate();

Future<Object?> openSakeLabelScanner(
  BuildContext context, {
  bool startWithGallery = false,
}) => _scannerEntryGate.run(
  'open',
  () => _openSakeLabelScanner(context, startWithGallery: startWithGallery),
);

Future<Object?> _openSakeLabelScanner(
  BuildContext context, {
  bool startWithGallery = false,
}) async {
  AppAnalytics.instance.event('app', 'scan');
  final authRepository = context.read<AuthRepository>();
  if (authRepository.currentUser == null) {
    AppAnalytics.instance.event('scan', 'login', kind: 'blocked');
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

  final checkedUserId = authRepository.currentUser?.uid;
  if (checkedUserId == null || !context.mounted) return null;
  if (!await _checkScanCapacity(context, checkedUserId) || !context.mounted) {
    return null;
  }

  final repository = context.read<SakeCommunityRepository>();
  if (!await ensureAiDataConsent(context) || !context.mounted) return null;
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
                  'この機能で撮影した酒瓶のラベル画像は、次の用途で必ず利用されます。',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('・このお酒の詳細画面で、他のユーザーにも表示'),
                const Text('・AIラベル照合機能の学習・精度向上'),
                const SizedBox(height: 12),
                const Text(
                  '人物の顔、氏名、住所、伝票などの個人情報が写らないよう、酒瓶のラベルだけを撮影してください。投稿後は、お酒の詳細画面から自分の画像を削除できます。ただし、削除前にAIの学習・精度向上に利用された結果を取り消すことはできません。',
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
    AppAnalytics.instance.event(
      'scan',
      'consent',
      kind: accepted == true ? 'success' : 'cancel',
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
  if (authRepository.currentUser?.uid != checkedUserId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('アカウントが変わりました。もう一度スキャンを開いてください。')),
    );
    return null;
  }
  return Navigator.of(context).push<Object>(
    PageRouteBuilder<Object>(
      pageBuilder: (_, __, ___) =>
          SakeScanPage.wrapped(startWithGallery: startWithGallery),
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

Future<bool> _checkScanCapacity(BuildContext context, String userId) async {
  final notifier = context.read<SavedSakeNotifier>();
  final navigator = Navigator.of(context, rootNavigator: true);
  final loadingRoute = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox.square(dimension: 24, child: CircularProgressIndicator()),
            SizedBox(width: 16),
            Expanded(child: Text('保存件数を確認しています…')),
          ],
        ),
      ),
    ),
  );
  unawaited(navigator.push(loadingRoute));
  Object? failure;
  try {
    await notifier.ensureNewScanCapacity(userId);
  } catch (error) {
    failure = error;
  } finally {
    if (navigator.mounted && loadingRoute.isActive) {
      navigator.removeRoute(loadingRoute);
    }
  }
  if (!context.mounted) return false;
  if (failure == null) return true;
  final atLimit = failure is SavedSakeMemberLimitReachedException;
  if (atLimit) {
    AppAnalytics.instance.event('scan', 'saved_limit', kind: 'blocked');
  }
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(atLimit ? '保存酒が上限に達しています' : '保存件数を確認できませんでした'),
      content: Text(
        atLimit
            ? '保存酒は${SavedSakeNotifier.memberSavedLimit}件まで登録できます。マイページで保存を解除してから、もう一度お試しください。'
            : '通信状況とログイン中のアカウントを確認して、もう一度お試しください。',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
  return false;
}
