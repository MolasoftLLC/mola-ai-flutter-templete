import 'package:flutter/material.dart';

class MenuActionButton extends StatelessWidget {
  const MenuActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.trailing = Icons.chevron_right,
    this.dark = false,
  });
  final String label;
  final IconData icon;
  final IconData trailing;
  final VoidCallback onPressed;
  final bool dark;

  static ButtonStyle style(
    bool dark, {
    String? fontFamily,
    bool compact = false,
  }) => OutlinedButton.styleFrom(
    foregroundColor: dark ? const Color(0xFFE6EDF5) : const Color(0xFF143861),
    backgroundColor: dark ? const Color(0xFF1A3958) : const Color(0xFFF0F4F8),
    side: BorderSide(
      color: dark ? const Color(0xFF647E98) : const Color(0xFFCBD6E0),
    ),
    minimumSize: Size(48, compact ? 40 : 48),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 8 : 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: TextStyle(
      fontSize: compact ? 13 : 14,
      fontWeight: FontWeight.w600,
      fontFamily: fontFamily,
    ),
  );

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: .8,
    alignment: Alignment.centerLeft,
    child: OutlinedButton(
      style: style(
        dark,
        compact: true,
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Icon(trailing, size: 18),
        ],
      ),
    ),
  );
}
