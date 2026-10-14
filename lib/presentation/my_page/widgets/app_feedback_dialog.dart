import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/analytics/app_analytics.dart' show analyticsId;
import '../../../common/utils/snack_bar_utils.dart';
import '../../../domain/repository/app_feedback_repository.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../infrastructure/api_client/api_client.dart';

const _navy = Color(0xFF1D3567);

Future<void> showAppFeedbackDialog(BuildContext context) async {
  final sent = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _AppFeedbackDialog(),
  );
  if (sent == true && context.mounted) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    SnackBarUtils.showInfoSnackBar(
      context,
      message: english
          ? 'Thank you for your feedback!'
          : 'フィードバックを送信しました。ありがとうございます！',
    );
  }
}

class _AppFeedbackDialog extends StatefulWidget {
  const _AppFeedbackDialog();
  @override
  State<_AppFeedbackDialog> createState() => _AppFeedbackDialogState();
}

class _AppFeedbackDialogState extends State<_AppFeedbackDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AppFeedbackIdentity? _identity;
  String _requestId = analyticsId();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    try {
      final identity = await AppFeedbackIdentity.load(
        context.read<AuthRepository>(),
      );
      if (mounted) setState(() => _identity = identity);
    } catch (_) {
      if (mounted) setState(() => _error = 'ユーザー情報を確認できませんでした。画面を開き直してください。');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || _identity == null || !_formKey.currentState!.validate()) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AppFeedbackRepository(context.read<ApiClient>()).submit(
        identity: _identity!,
        requestId: _requestId,
        content: _controller.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final english = Localizations.localeOf(context).languageCode == 'en';
      setState(
        () => _error = english
            ? 'Could not send your feedback. Your text is still here; please try again.'
            : error is AppFeedbackException
            ? error.message
            : '送信できませんでした。入力内容はそのままで、もう一度お試しください。',
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openContact() async {
    try {
      if (await launchUrl(
        Uri.parse('https://molasoft.jp/contact/'),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(
        () => _error = Localizations.localeOf(context).languageCode == 'en'
            ? 'Could not open the contact form.'
            : 'お問い合わせフォームを開けませんでした。',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return PopScope(
      canPop: !_sending,
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        scrollable: true,
        title: Text(
          english ? 'Feedback' : 'フィードバック',
          style: const TextStyle(color: _navy, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                '${english ? 'User ID' : 'ユーザーID'}: ${_identity?.userId ?? (english ? 'Loading…' : '確認中…')}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF647184)),
              ),
              const SizedBox(height: 20),
              Text(
                english ? 'Your feedback' : 'フィードバック内容',
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('app-feedback-content'),
                controller: _controller,
                enabled: !_sending,
                minLines: 4,
                maxLines: 7,
                maxLength: 2000,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                onChanged: (_) {
                  _requestId = analyticsId();
                  if (_error != null) setState(() => _error = null);
                },
                validator: (value) => value == null || value.trim().isEmpty
                    ? (english
                          ? 'Please enter your feedback.'
                          : 'フィードバック内容を入力してください。')
                    : null,
                decoration: InputDecoration(
                  hintText: english
                      ? 'Tell us about improvements or issues with the app!'
                      : 'アプリの改善点や不具合などを教えてください！',
                  hintStyle: const TextStyle(color: Color(0xFF8B96A6)),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              FilledButton.icon(
                key: const Key('app-feedback-send'),
                onPressed: _sending || _identity == null ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _sending
                      ? (english ? 'Sending…' : '送信中…')
                      : (english ? 'Send feedback' : '送信する'),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    english ? 'For inquiries, ' : '※お問い合わせの場合は',
                    style: const TextStyle(
                      color: Color(0xFF647184),
                      fontSize: 11,
                    ),
                  ),
                  TextButton(
                    onPressed: _sending ? null : _openContact,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 40),
                      foregroundColor: _navy,
                    ),
                    child: Text(
                      english ? 'contact us' : 'こちら',
                      style: const TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  if (!english)
                    const Text(
                      'まで',
                      style: TextStyle(color: Color(0xFF647184), fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.pop(context),
            child: Text(english ? 'Close' : '閉じる'),
          ),
        ],
      ),
    );
  }
}
