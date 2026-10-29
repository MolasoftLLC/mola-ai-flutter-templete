import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class MenuPhotoStyle {
  static const blue = Color(0xFF203864);
  static const ink = Color(0xFF17395F);
  static const deep = Color(0xFF112B4B);
  static const pale = Color(0xFFEAF0F7);
  static const yellow = Color(0xFFFFD54F);
  // Matches the border of the center scan button in the app navigation.
  static const scanOrange = Color(0xFFFF914D);

  static TextStyle text(
    double size, {
    bool bold = false,
    Color color = Colors.white,
  }) => TextStyle(
    fontSize: size,
    height: 1.55,
    color: color,
    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
  );

  static PreferredSizeWidget appBar(String title, {VoidCallback? onBack}) =>
      AppBar(
        backgroundColor: blue,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 60,
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: '戻る',
                onPressed: onBack,
                icon: const MenuPhotoIcon('back', size: 24),
              ),
        title: Text(title, style: text(20, bold: true)),
        actions: const [SizedBox(width: 60)],
      );
}

class MenuPhotoIcon extends StatelessWidget {
  const MenuPhotoIcon(this.name, {super.key, this.size = 20, this.color});
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/menu_analysis/$name.svg',
    width: size,
    height: size,
    excludeFromSemantics: true,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

class MenuPhotoButton extends StatelessWidget {
  const MenuPhotoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = MenuPhotoStyle.pale,
    this.height = 44,
    this.fontSize = 15,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final Color color;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: height),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size(0, height),
        foregroundColor: MenuPhotoStyle.ink,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle:
            MenuPhotoStyle.text(
              fontSize,
              bold: true,
              color: MenuPhotoStyle.ink,
            ).copyWith(
              fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
            ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[MenuPhotoIcon(icon!), const SizedBox(width: 8)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}
