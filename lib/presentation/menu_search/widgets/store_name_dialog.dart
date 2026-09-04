import 'package:flutter/material.dart';

import '../../../common/localization/localization_extensions.dart';

class StoreNameDialog extends StatefulWidget {
  final String? initialStoreName;
  final Function(String) onSave;

  const StoreNameDialog({Key? key, this.initialStoreName, required this.onSave})
    : super(key: key);

  @override
  _StoreNameDialogState createState() => _StoreNameDialogState();
}

class _StoreNameDialogState extends State<StoreNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialStoreName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.enterStoreName),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: context.l10n.enterStoreNameHint,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final storeName = _controller.text.trim();
            if (storeName.isNotEmpty) {
              widget.onSave(storeName);
            }
            Navigator.of(context).pop();
          },
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
}

// 店舗名ダイアログを表示する関数
Future<void> showStoreNameDialog({
  required BuildContext context,
  String? initialStoreName,
  required Function(String) onSave,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StoreNameDialog(
        initialStoreName: initialStoreName,
        onSave: onSave,
      );
    },
  );
}
