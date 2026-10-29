import 'package:flutter/material.dart';
import '../../../common/localization/localization_extensions.dart';

Widget buildMenuSakeInfoRow(
  String key,
  String value,
  IconData icon, {
  bool dark = false,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: dark ? Colors.white24 : Colors.grey.shade200),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: dark ? Colors.white : const Color(0xFF1D3567),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: dark ? Colors.white : const Color(0xFF1D3567),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: dark ? Colors.white : null,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildMenuSakeTypesRow(
  BuildContext context,
  List<String> types, {
  bool dark = false,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: dark ? Colors.white24 : Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_bar,
              color: dark ? Colors.white : const Color(0xFF1D3567),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: dark ? Colors.white : const Color(0xFF1D3567),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: types.map((type) {
            return Chip(
              label: Text(type),
              backgroundColor: dark
                  ? const Color(0xFFEAF0F7)
                  : const Color(0xFF1D3567).withValues(alpha: 0.1),
              labelStyle: const TextStyle(
                color: Color(0xFF1D3567),
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            );
          }).toList(),
        ),
      ],
    ),
  );
}
