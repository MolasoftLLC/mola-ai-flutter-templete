import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_scan/widgets/sake_scan_candidate_origin.dart';

void main() {
  testWidgets('追加候補を先に表示しても登録済みと混同しない', (tester) async {
    const candidates = [
      SakeScanCandidate(
        sakeId: 0,
        name: 'W 純米 出羽燦々 無濾過生原酒',
        candidateSource: 'lens_discovery',
        candidateKey: 'isobe',
      ),
      SakeScanCandidate(
        sakeId: 8488,
        name: 'W 出羽燦々50 純米無濾過生原酒',
        candidateSource: 'master',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final candidate in candidates)
                SakeScanCandidateOrigin(candidate: candidate),
            ],
          ),
        ),
      ),
    );
    expect(find.text('未登録・追加候補'), findsOneWidget);
    expect(find.text('マスター'), findsOneWidget);
    expect(candidates.first.candidateKey, 'isobe');
    expect(candidates.last.sakeId, 8488);
  });
}
