import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/notifier/my_page/my_page_notifier.dart';

const List<String> _sakePreferenceOptions = <String>[
  '甘口',
  '辛口',
  'スッキリ',
  'フルーティ',
  'にごり',
  '微発泡',
  '酸味',
];

Future<bool> showSakePreferencesSelectionDialog({
  required BuildContext context,
  required MyPageNotifier myPageNotifier,
}) async {
  final Iterable<String> existing = myPageNotifier.state.preferences
          ?.split('、')
          .map((String e) => e.trim())
          .where(
            (String element) => element.isNotEmpty,
          ) ??
      <String>[];
  final List<String> selectedPreferences = List<String>.from(existing);

  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext dialogContext,
            void Function(void Function()) setState) {
          return AlertDialog(
            title: const Text(
              'どんな日本酒が好き？',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D3567),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    '好みの特徴を選んでください（複数選択可）',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sakePreferenceOptions.map((String option) {
                      final bool isSelected =
                          selectedPreferences.contains(option);
                      return FilterChip(
                        label: Text(option),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1D3567).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF1D3567),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF1D3567)
                              : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              if (!selectedPreferences.contains(option)) {
                                selectedPreferences.add(option);
                              }
                            } else {
                              selectedPreferences.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  if (selectedPreferences.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('少なくとも1つは選択してください'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    return;
                  }

                  final String preferences = selectedPreferences.join('、');
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setString('sake_preferences', preferences);

                  myPageNotifier.setPreferences(preferences);
                  await myPageNotifier.savePreferences();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('MyPageからいつでも変更できるよ！'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }

                  Navigator.of(dialogContext).pop(true);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1D3567),
                ),
                child: const Text('完了'),
              ),
            ],
          );
        },
      );
    },
  );

  return result ?? false;
}

Future<bool> ensureSakePreferences({
  required BuildContext context,
  required MyPageNotifier myPageNotifier,
}) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? current = prefs.getString('sake_preferences');
  if (current != null && current.trim().isNotEmpty) {
    await myPageNotifier.reloadPreferencesFromLocal();
    return true;
  }

  final bool saved = await showSakePreferencesSelectionDialog(
    context: context,
    myPageNotifier: myPageNotifier,
  );

  if (!saved) {
    return false;
  }

  await myPageNotifier.reloadPreferencesFromLocal();
  final String? updated =
      (await SharedPreferences.getInstance()).getString('sake_preferences');
  return updated != null && updated.trim().isNotEmpty;
}
