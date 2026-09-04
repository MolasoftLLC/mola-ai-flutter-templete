import 'package:flutter/material.dart';

import '../../../common/localization/localization_extensions.dart';
import '../../auth/email_link_auth_page.dart';

class GuestLimitDialog {
  static Future<void> showSavedSakeLimit(
    BuildContext context, {
    required int maxCount,
  }) async {
    await show(
      context,
      title: context.l10n.savedLimitTitle,
      message: context.l10n.savedLimitMessage(maxCount),
    );
  }

  static Future<void> showFavoriteLimit(
    BuildContext context, {
    required int maxCount,
  }) async {
    await show(
      context,
      title: context.l10n.favoriteLimitTitle,
      message: context.l10n.favoriteLimitMessage(maxCount),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                context.l10n.cancel,
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
              child: Text(
                context.l10n.goToLoginOrRegister,
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
        MaterialPageRoute(builder: (_) => EmailLinkAuthPage.signUp()),
      );
    }
  }
}
