import 'package:flutter/material.dart';

import '../../../domain/eintities/sake_label_scan.dart';

class SakeScanCandidateOrigin extends StatelessWidget {
  const SakeScanCandidateOrigin({super.key, required this.candidate});

  final SakeScanCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final registered = candidate.isRegisteredProduct;
    final label = registered
        ? 'マスター'
        : candidate.isTemporary
        ? '未登録・追加候補'
        : '照合候補';
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: registered ? const Color(0xFFEAF0F7) : const Color(0xFFFFF1DE),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            label,
            style: TextStyle(
              color: registered
                  ? const Color(0xFF1D3567)
                  : const Color(0xFF8A4B0F),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
