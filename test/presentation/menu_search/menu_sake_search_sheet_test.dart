import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/menu_sake_search_sheet.dart';

void main() {
  testWidgets('読み取り名で検索し、選択した商品を元画面に返す', (tester) async {
    String? query;
    SakeMapSearchResult? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('検索'),
              onPressed: () async {
                selected = await showModalBottomSheet<SakeMapSearchResult>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MenuSakeSearchSheet(
                    initialQuery: '南部関',
                    search: (value) async {
                      query = value;
                      return [
                        const SakeMapSearchResult(
                          sakeId: 7,
                          name: '南部関 純米',
                          isMaster: true,
                        ),
                      ];
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('検索'));
    await tester.pumpAndSettle();
    expect(query, '南部関');
    expect(find.text('南部関 純米'), findsOneWidget);
    await tester.tap(find.text('南部関 純米'));
    await tester.pumpAndSettle();
    expect(selected?.sakeId, 7);
    expect(find.byType(MenuSakeSearchSheet), findsNothing);
  });

  testWidgets('検索失敗時は再試行できる', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuSakeSearchSheet(
            initialQuery: '七賢',
            search: (_) async {
              calls++;
              if (calls == 1) throw Exception('offline');
              return [];
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('再試行'), findsOneWidget);
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.textContaining('見つかりませんでした'), findsOneWidget);
  });
}
