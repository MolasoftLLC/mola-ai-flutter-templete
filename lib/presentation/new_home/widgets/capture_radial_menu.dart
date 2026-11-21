import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'capture_sketch_icon.dart';

enum CaptureAction { gallery, label, menu }

/// Opens three actions above the actual capture button, including its safe area.
Future<CaptureAction?> showCaptureRadialMenu(
  BuildContext context, {
  required GlobalKey anchorKey,
}) {
  final box = anchorKey.currentContext?.findRenderObject();
  final size = MediaQuery.sizeOf(context);
  final anchor = box is RenderBox && box.hasSize
      ? box.localToGlobal(box.size.center(Offset.zero))
      : Offset(
          size.width / 2,
          size.height - MediaQuery.paddingOf(context).bottom - 48,
        );
  final english = Localizations.localeOf(context).languageCode == 'en';
  return showGeneralDialog<CaptureAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: english ? 'Close capture menu' : '撮影メニューを閉じる',
    barrierColor: const Color(0x99091625),
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, __) => CaptureRadialMenu(
      anchor: anchor,
      progress: Curves.easeOutCubic.transform(animation.value),
      english: english,
      onSelected: (action) => Navigator.of(context).pop(action),
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}

class CaptureRadialMenu extends StatelessWidget {
  const CaptureRadialMenu({
    super.key,
    required this.anchor,
    required this.progress,
    required this.english,
    required this.onSelected,
    required this.onClose,
  });
  final Offset anchor;
  final double progress;
  final bool english;
  final ValueChanged<CaptureAction> onSelected;
  final VoidCallback onClose;
  static const navy = Color(0xFF143861);
  static const orange = Color(0xFFFF7A1A);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final spread = math.min(116.0, (constraints.maxWidth - 112) / 2);
      final center = Offset(
        constraints.maxWidth / 2,
        anchor.dy.clamp(
          math.min(210.0, constraints.maxHeight - 30),
          constraints.maxHeight - 30,
        ),
      );
      final actions = [
        (
          CaptureAction.gallery,
          Icons.photo_library_outlined,
          english ? 'Choose photo' : '写真から選ぶ',
          Offset(-spread, -94),
        ),
        (
          CaptureAction.label,
          Icons.camera_alt_outlined,
          english ? 'Scan a label' : 'ラベルを撮る',
          const Offset(0, -180),
        ),
        (
          CaptureAction.menu,
          Icons.document_scanner_outlined,
          english ? 'Scan a menu' : 'メニューを撮る',
          Offset(spread, -94),
        ),
      ];
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('capture-menu-backdrop'),
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: const SizedBox.expand(),
              ),
            ),
            for (final (action, icon, label, delta) in actions)
              Positioned(
                left: center.dx + delta.dx * progress - 54,
                top: center.dy + delta.dy * progress - 32,
                width: 108,
                child: Opacity(
                  opacity: progress,
                  child: IgnorePointer(
                    ignoring: progress < .95,
                    child: Semantics(
                      button: true,
                      label: label,
                      onTap: progress >= .95 ? () => onSelected(action) : null,
                      child: ExcludeSemantics(
                        child: GestureDetector(
                          key: ValueKey('capture-action-${action.name}'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelected(action),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                elevation: 6,
                                shadowColor: Colors.black38,
                                color: action == CaptureAction.label
                                    ? orange
                                    : Colors.white,
                                shape: const CircleBorder(),
                                child: SizedBox.square(
                                  dimension: 64,
                                  child: action == CaptureAction.gallery
                                      ? Icon(icon, size: 30, color: navy)
                                      : CaptureSketchIcon(
                                          isMenu: action == CaptureAction.menu,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: anchor.dx - 26,
              top: anchor.dy - 26,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(
                  side: BorderSide(color: orange, width: 3),
                ),
                child: IconButton(
                  key: const ValueKey('capture-menu-close'),
                  tooltip: english ? 'Close' : '閉じる',
                  onPressed: onClose,
                  constraints: const BoxConstraints.tightFor(
                    width: 52,
                    height: 52,
                  ),
                  icon: const Icon(Icons.close, color: orange, size: 30),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
