import 'package:mola_gemini_flutter_template/common/analytics/app_analytics.dart';
import 'package:flutter/material.dart';

import '../../../common/localization/localization_extensions.dart';
import '../../../domain/eintities/menu_analysis_history.dart';
import '../../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../my_page/widgets/place_picker_sheet.dart';

class MenuResultPlaceField extends StatefulWidget {
  const MenuResultPlaceField({
    super.key,
    required this.history,
    required this.onSave,
  });

  final MenuAnalysisHistoryItem? history;
  final Future<void> Function(DrinkingPlace) onSave;

  @override
  State<MenuResultPlaceField> createState() => _MenuResultPlaceFieldState();
}

class _MenuResultPlaceFieldState extends State<MenuResultPlaceField> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _pickPlace() async {
    AppAnalytics.instance.event('menu', 'place');
    if (_saving || widget.history == null) return;
    final place = await PlacePickerSheet.show(
      context,
      initialPlace:
          widget.history!.drinkingPlace?.displayName ??
          widget.history!.storeName,
    );
    if (!mounted || place == null) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(place);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.history?.drinkingPlace?.displayName ?? widget.history?.storeName;
    final enabled = !_saving && widget.history != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? _pickPlace : null,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          isEmpty: name?.trim().isNotEmpty != true,
          decoration: InputDecoration(
            labelText: context.l10n.placeConsumed,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            errorText: _failed ? context.l10n.errorSaveToServer : null,
            errorMaxLines: 3,
            suffixIcon: _saving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: context.l10n.addConsumedPlace,
                    onPressed: enabled ? _pickPlace : null,
                    icon: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white70,
                    ),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          child: Text(
            name?.trim().isNotEmpty == true
                ? name!
                : context.l10n.placeConsumedHint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: name?.trim().isNotEmpty == true
                  ? Colors.white
                  : Colors.white54,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
