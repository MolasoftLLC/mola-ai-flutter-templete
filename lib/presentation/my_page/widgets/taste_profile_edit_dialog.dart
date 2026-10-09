import 'package:flutter/material.dart';

import '../../../common/localization/localization_extensions.dart';
import '../../../domain/eintities/preferences/taste_preference_profile.dart';

class TasteProfileEditDialog extends StatefulWidget {
  const TasteProfileEditDialog({
    super.key,
    required this.profile,
    required this.onSave,
  });

  final TastePreferenceProfile profile;
  final Future<bool> Function(TastePreferenceProfile) onSave;

  @override
  State<TasteProfileEditDialog> createState() => _TasteProfileEditDialogState();
}

class _TasteProfileEditDialogState extends State<TasteProfileEditDialog> {
  late final Map<String, double> _values = widget.profile.toJson().map(
    (key, value) => MapEntry(key, (value as num).toDouble()),
  );
  bool _saving = false;
  bool _saveFailed = false;
  static const _ink = Color(0xFF173A60);

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    var saved = false;
    try {
      saved = await widget.onSave(TastePreferenceProfile.fromJson(_values));
    } catch (_) {
      // Keep the draft available when saving fails.
    }
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final axes = [
      ('fruity', l10n.axisFruity, l10n.axisCalm, l10n.axisFruity),
      ('sweetness', l10n.axisSweetness, l10n.axisDry, l10n.axisSweet),
      ('acidity', l10n.axisAcidity, l10n.axisLowAcid, l10n.axisHighAcid),
      ('umami', l10n.axisUmami, l10n.axisLight, l10n.axisRich),
      ('kire', l10n.axisFinish, l10n.axisMellow, l10n.axisSharp),
      ('spiciness', l10n.axisSpiciness, l10n.axisGentle, l10n.axisKick),
    ];
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        backgroundColor: const Color(0xFFF6F7FB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.editTasteProfileTitle,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final axis in axes) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        axis.$2,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_values[axis.$1]! * 100).round()} / 100',
                        style: const TextStyle(color: _ink, fontSize: 12),
                      ),
                    ],
                  ),
                  Slider(
                    value: _values[axis.$1]!,
                    divisions: 100,
                    activeColor: _ink,
                    label: '${(_values[axis.$1]! * 100).round()}',
                    semanticFormatterCallback: (value) =>
                        '${axis.$2}: ${(value * 100).round()} / 100',
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _values[axis.$1] = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          axis.$3,
                          style: const TextStyle(color: _ink, fontSize: 11),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          axis.$4,
                          textAlign: TextAlign.end,
                          style: const TextStyle(color: _ink, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (_saveFailed)
                  Text(
                    l10n.errorSaveToServer,
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.saveAction),
          ),
        ],
      ),
    );
  }
}
