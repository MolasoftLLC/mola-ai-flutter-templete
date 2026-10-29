import 'package:flutter/material.dart';

import '../../my_page/widgets/app_feedback_dialog.dart';

/// Catalog suggestions use the same identity and delivery as My Page feedback.
class JapanSakeFeedbackButton extends StatelessWidget {
  const JapanSakeFeedbackButton({super.key});

  Future<void> _open(BuildContext context) async {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final topic = await showModalBottomSheet<AppFeedbackTopic>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                english ? 'Help improve the sake catalog' : '銘柄情報を教える',
                style: const TextStyle(
                  color: Color(0xFF1D3567),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final topic in [
              AppFeedbackTopic.sakeCorrection,
              AppFeedbackTopic.sakeBrandAddition,
            ])
              ListTile(
                leading: Icon(
                  topic == AppFeedbackTopic.sakeCorrection
                      ? Icons.edit_note_outlined
                      : Icons.add_circle_outline,
                  color: const Color(0xFF1D3567),
                ),
                title: Text(topic.title(english)),
                onTap: () => Navigator.pop(sheetContext, topic),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(english ? 'Cancel' : 'キャンセル'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
    if (topic != null && context.mounted) {
      await showAppFeedbackDialog(context, topic: topic);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('japan-sake-feedback-menu'),
    tooltip: Localizations.localeOf(context).languageCode == 'en'
        ? 'Help improve the sake catalog'
        : '銘柄情報を教える',
    onPressed: () => _open(context),
    icon: const Icon(Icons.add, color: Colors.white),
  );
}
