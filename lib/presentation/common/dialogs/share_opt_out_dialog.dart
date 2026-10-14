import 'package:flutter/material.dart';

/// Keep both sharing confirmations vertical at every screen/text size.
Future<bool> showShareOptOutDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String keepLabel,
  required String disableLabel,
}) async {
  var resolved = false;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      void finish(bool value) {
        if (resolved) return;
        resolved = true;
        Navigator.of(dialogContext).pop(value);
      }

      return AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: () => finish(false),
                  child: Text(keepLabel),
                ),
                TextButton(
                  onPressed: () => finish(true),
                  child: Text(disableLabel),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
