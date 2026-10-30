import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_catalog_browse.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/prefecture_stamp_link.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_stamp_collection_label.dart';

class _Catalog extends PlaceMapRepository {
  _Catalog({this.fail = false}) : super(ApiClient.create());
  final bool fail;
  int calls = 0;
  @override
  Future<SakeCatalogPage<SakeBrandSummary>> fetchPrefectureBrands(
    int code, {
    int? afterId,
  }) async {
    calls++;
    if (fail) throw StateError('offline');
    return SakeCatalogPage(
      items: [
        for (final id in afterId == null ? [1, 2] : [2, 3])
          SakeBrandSummary(
            brandId: id,
            name: '銘柄$id',
            brewery: '蔵',
            productCount: 5,
          ),
      ],
      nextCursor: afterId == null ? 2 : null,
    );
  }
}

void main() {
  Widget app(_Catalog repo, int? code) => Provider<PlaceMapRepository>.value(
    value: repo,
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: PrefectureStampLink(prefectureCode: code),
        ),
      ),
    ),
  );
  testWidgets('counts unique brands across pages and reuses count', (
    tester,
  ) async {
    final repo = _Catalog();
    await tester.pumpWidget(app(repo, 35));
    await tester.pumpAndSettle();
    final label = tester.widget<SakeStampCollectionLabel>(
      find.byType(SakeStampCollectionLabel),
    );
    expect(label.prefecture, '山口県');
    expect(label.count, 3);
    expect(label.ready, isTrue);
    expect(label.catalogLink, isTrue);
    expect(repo.calls, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(repo, 35));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
  });
  testWidgets('unknown prefecture hides link without fetching', (tester) async {
    final repo = _Catalog();
    await tester.pumpWidget(app(repo, null));
    expect(find.byType(SakeStampCollectionLabel), findsNothing);
    expect(repo.calls, 0);
  });
  testWidgets('failed count keeps link without displaying false zero', (
    tester,
  ) async {
    final repo = _Catalog(fail: true);
    await tester.pumpWidget(app(repo, 35));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SakeStampCollectionLabel>(
            find.byType(SakeStampCollectionLabel),
          )
          .ready,
      isFalse,
    );
    expect(find.byType(InkWell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
