import 'dart:async';
import 'package:flutter/material.dart';
import '../../../common/localization/localization_extensions.dart';

/// Temporary search evidence, never a confirmed product or selectable result.
class LensProgressToasts extends StatefulWidget {
  const LensProgressToasts({super.key, required this.titles});
  final List<String> titles;

  @override
  State<LensProgressToasts> createState() => _LensProgressToastsState();
}

class _LensProgressToastsState extends State<LensProgressToasts> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _index = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 1300), (timer) {
      if (!mounted) return;
      setState(() => _index++);
      if (_index >= widget.titles.length) timer.cancel();
    });
  }

  @override
  void didUpdateWidget(covariant LensProgressToasts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.titles != widget.titles) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        child: _index >= widget.titles.length
            ? const SizedBox.shrink()
            : Container(
                key: ValueKey(_index),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xEE14233C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.scanLensPreviewNotice,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.titles[_index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
