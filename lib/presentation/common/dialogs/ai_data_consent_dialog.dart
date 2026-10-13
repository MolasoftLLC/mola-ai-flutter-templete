import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/repository/auth_repository.dart';

/// Ask before the first request that can send user content to external AI.
/// This consent is separate from permission to publish label photos.
Future<bool> ensureAiDataConsent(BuildContext context) async {
  if (!context.mounted) return false;
  final owner = Provider.of<AuthRepository?>(
    context,
    listen: false,
  )?.currentUser?.uid;
  final key = 'ai_data_sharing_consent_v1_${owner ?? 'guest'}';
  final english = Localizations.localeOf(context).languageCode == 'en';
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return false;
  if (prefs.getBool(key) == true) return true;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(english ? 'Using AI analysis' : 'AI解析で送信する情報について'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              english
                  ? 'To identify sake and analyze its characteristics, SAKEPEDIA sends the photos you choose, label or menu text, search terms, and taste preferences needed for each feature to our server and, depending on the feature, Google, OpenAI, or Perplexity.\n\nDo not include faces, names, addresses, or other personal information in photos or search terms. You can cancel and continue browsing sake and maps without AI analysis.'
                  : '日本酒の特定や特徴の解析のため、選んだ写真、ラベルやメニューの読み取り文字、検索語、味の好みのうち、その機能に必要な情報を当社サーバーへ送信します。機能に応じてGoogle、OpenAI、Perplexityへも送信して処理します。\n\n写真や検索語に人物の顔、氏名、住所などの個人情報を含めないでください。同意しなくても、お酒や地図の閲覧は利用できます。',
            ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://molasoft-ai-central.com/assets/sakepedia-privacy.html',
                ),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(english ? 'Privacy policy' : 'プライバシーポリシー'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(english ? 'Cancel' : 'キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(english ? 'Agree and continue' : '同意して進む'),
        ),
      ],
    ),
  );
  if (accepted != true || !context.mounted) return false;
  final currentOwner = Provider.of<AuthRepository?>(
    context,
    listen: false,
  )?.currentUser?.uid;
  if (currentOwner != owner) return false;
  // Permission to send is granted by the explicit action, even if the device
  // cannot persist the preference (in that case ask again next time).
  await prefs.setBool(key, true);
  return context.mounted;
}
