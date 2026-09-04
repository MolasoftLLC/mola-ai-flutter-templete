import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/localization/localization_extensions.dart';
import '../../../domain/notifier/my_page/my_page_notifier.dart';

class _SakePreferenceOption {
  const _SakePreferenceOption(this.value, this.label);

  final String value;
  final String label;
}

Future<bool> showSakePreferencesSelectionDialog({
  required BuildContext context,
  required MyPageNotifier myPageNotifier,
}) async {
  final options = <_SakePreferenceOption>[
    _SakePreferenceOption('甘口', context.l10n.preferenceSweet),
    _SakePreferenceOption('辛口', context.l10n.preferenceDry),
    _SakePreferenceOption('スッキリ', context.l10n.preferenceClean),
    _SakePreferenceOption('フルーティ', context.l10n.preferenceFruity),
    _SakePreferenceOption('にごり', context.l10n.preferenceNigori),
    _SakePreferenceOption('微発泡', context.l10n.preferenceSparkling),
    _SakePreferenceOption('酸味', context.l10n.preferenceAcidic),
  ];
  final Iterable<String> existing =
      myPageNotifier.state.preferences
          ?.split('、')
          .map((String e) => e.trim())
          .where((String element) => element.isNotEmpty) ??
      <String>[];
  final List<String> selectedPreferences = List<String>.from(existing);

  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder:
            (
              BuildContext dialogContext,
              void Function(void Function()) setState,
            ) {
              return AlertDialog(
                title: Text(
                  context.l10n.favoriteSakeQuestion,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D3567),
                  ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        context.l10n.selectPreferenceFeatures,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: options.map((_SakePreferenceOption option) {
                          final bool isSelected = selectedPreferences.contains(
                            option.value,
                          );
                          return FilterChip(
                            label: Text(option.label),
                            selected: isSelected,
                            selectedColor: const Color(
                              0xFF1D3567,
                            ).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF1D3567),
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF1D3567)
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  if (!selectedPreferences.contains(
                                    option.value,
                                  )) {
                                    selectedPreferences.add(option.value);
                                  }
                                } else {
                                  selectedPreferences.remove(option.value);
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
                            SnackBar(
                              content: Text(context.l10n.selectAtLeastOne),
                              duration: const Duration(seconds: 2),
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
                          SnackBar(
                            content: Text(
                              context.l10n.preferencesChangeAnytime,
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }

                      Navigator.of(dialogContext).pop(true);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1D3567),
                    ),
                    child: Text(context.l10n.done),
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
  final String? updated = (await SharedPreferences.getInstance()).getString(
    'sake_preferences',
  );
  return updated != null && updated.trim().isNotEmpty;
}
