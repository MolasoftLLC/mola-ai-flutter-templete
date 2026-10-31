import 'package:flutter/material.dart';
import '../../../common/localization/localization_extensions.dart';

class SakeBottomNavigation extends StatelessWidget {
  const SakeBottomNavigation({
    super.key,
    required this.currentPageIndex,
    required this.onPageSelected,
    required this.onScanTap,
    required this.scanKey,
    required this.menuAnalysisKey,
    required this.mapKey,
    required this.myPageKey,
  });

  static const _backgroundColor = Color(0xFF143861);

  final int currentPageIndex;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onScanTap;
  final GlobalKey scanKey;
  final GlobalKey menuAnalysisKey;
  final GlobalKey mapKey;
  final GlobalKey myPageKey;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height:
          78 +
          bottomPadding +
          (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(0, 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: _backgroundColor,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Row(
                  children: [
                    _NavigationItem(
                      icon: Icons.home_outlined,
                      label: context.l10n.navigationHome,
                      selected: currentPageIndex == 0 || currentPageIndex == 3,
                      onTap: () => onPageSelected(0),
                    ),
                    _NavigationItem(
                      focusKey: menuAnalysisKey,
                      icon: Icons.menu_book_outlined,
                      label:
                          Localizations.localeOf(context).languageCode == 'en'
                          ? 'Stamps'
                          : '朱印帳',
                      selected: currentPageIndex == 6,
                      onTap: () => onPageSelected(6),
                    ),
                    const Expanded(child: SizedBox()),
                    _NavigationItem(
                      focusKey: mapKey,
                      icon: Icons.public,
                      label:
                          Localizations.localeOf(context).languageCode == 'en'
                          ? 'Map'
                          : 'マップ',
                      selected: currentPageIndex == 2,
                      onTap: () => onPageSelected(2),
                    ),
                    _NavigationItem(
                      focusKey: myPageKey,
                      icon: Icons.person_outline,
                      label: context.l10n.navigationMyPage,
                      selected: currentPageIndex == 4,
                      onTap: () => onPageSelected(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            child: Column(
              children: [
                Material(
                  key: scanKey,
                  color: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(
                    side: BorderSide(color: Color(0xFFFF914D), width: 3),
                  ),
                  child: InkWell(
                    onTap: onScanTap,
                    customBorder: const CircleBorder(),
                    child: const SizedBox.square(
                      dimension: 52,
                      child: Icon(
                        Icons.camera_alt,
                        color: Color(0xFFFF7A1A),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Analyze'
                      : '解析',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    this.focusKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final GlobalKey? focusKey;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _selectedColor = Color(0xFFFFD166);

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _selectedColor
        : Colors.white.withValues(alpha: 0.78);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          key: focusKey,
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 31),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
