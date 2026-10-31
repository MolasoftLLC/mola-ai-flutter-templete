import '../../common/sake/taste_match.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/analytics/app_analytics.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../common/widgets/primary_app_bar.dart';
import '../common/widgets/sake_list_card.dart';

const _navy = Color(0xFF143861);

enum _ProductOrder {
  newest('新着順'),
  oldest('古い順'),
  match('マッチ度順');

  const _ProductOrder(this.label);
  final String label;
}

/// Uses the same cards and match/radar preview as the recent-sake list.
class SameBrandSakeListPage extends StatefulWidget {
  const SameBrandSakeListPage({
    super.key,
    required this.brandName,
    required this.loadSakes,
    required this.onOpen,
  });
  final String? brandName;
  final Future<List<Sake>> Function() loadSakes;
  final ValueChanged<Sake> onOpen;
  @override
  State<SameBrandSakeListPage> createState() => _SameBrandSakeListPageState();
}

class _SameBrandSakeListPageState extends State<SameBrandSakeListPage> {
  final _controller = ScrollController();
  final Map<String, Future<Map<int, SakeTasteProfileDetails>>> _profiles = {};
  late Future<List<Sake>> _future;
  var _order = _ProductOrder.newest;
  var _visibleCount = 20;
  var _total = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.loadSakes();
    _controller.addListener(_loadMore);
  }

  void _loadMore() {
    if (_controller.hasClients &&
        _controller.position.extentAfter < 400 &&
        _visibleCount < _total) {
      setState(() => _visibleCount = math.min(_visibleCount + 20, _total));
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_loadMore)
      ..dispose();
    super.dispose();
  }

  Future<Map<int, SakeTasteProfileDetails>> _profilesFor(List<Sake> sakes) {
    final ids =
        sakes.map((s) => s.sakeId ?? 0).where((id) => id > 0).toSet().toList()
          ..sort();
    return _profiles.putIfAbsent(ids.join(','), () async {
      final repository = context.read<SakeScanRepository>();
      final result = <int, SakeTasteProfileDetails>{};
      // The profile endpoint accepts at most 50 IDs per request.
      for (var start = 0; start < ids.length; start += 50) {
        result.addAll(
          await repository.fetchTasteProfiles(
            ids.sublist(start, math.min(start + 50, ids.length)),
          ),
        );
      }
      return result;
    });
  }

  Future<void> _refresh() async {
    _profiles.clear();
    setState(() {
      _visibleCount = 20;
      _future = widget.loadSakes();
    });
    try {
      await _future;
    } catch (_) {
      /* The body shows a retry action. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final preference = Provider.of<MyPageState?>(context)?.tasteProfile;
    return AnalyticsScreen(
      name: 'same_brand_products',
      child: PrimaryScrollController(
        automaticallyInheritForPlatforms: const <TargetPlatform>{},
        controller: _controller,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: PrimaryAppBar(
            title: '同じ銘柄の商品',
            actions: [
              PopupMenuButton<_ProductOrder>(
                tooltip: '並び替え：${_order.label}',
                initialValue: _order,
                icon: const Icon(Icons.sort, color: Colors.white),
                onSelected: (order) {
                  if (_order == order) return;
                  AppAnalytics.instance.event(
                    'same_brand_products',
                    'sort_${order.name}',
                  );
                  setState(() {
                    _order = order;
                    _visibleCount = 20;
                  });
                  if (_controller.hasClients) _controller.jumpTo(0);
                },
                itemBuilder: (_) => [
                  for (final order in _ProductOrder.values)
                    CheckedPopupMenuItem(
                      value: order,
                      checked: order == _order,
                      child: Text(order.label),
                    ),
                ],
              ),
            ],
          ),
          body: FutureBuilder<List<Sake>>(
            future: _future,
            builder: (context, catalog) {
              if (catalog.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: _navy),
                );
              }
              if (catalog.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: _refresh,
                    child: const Text('商品を取得できませんでした。再試行'),
                  ),
                );
              }
              final all = catalog.data ?? const <Sake>[];
              _total = all.length;
              return FutureBuilder<Map<int, SakeTasteProfileDetails>>(
                future: _order == _ProductOrder.match
                    ? _profilesFor(all)
                    : null,
                builder: (context, snapshot) {
                  if (_order == _ProductOrder.match && all.isNotEmpty) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: _navy),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: TextButton(
                          onPressed: () => setState(_profiles.clear),
                          child: const Text('マッチ度を取得できませんでした。再試行'),
                        ),
                      );
                    }
                  }
                  final profiles =
                      snapshot.data ?? const <int, SakeTasteProfileDetails>{};
                  final sorted = all.toList()
                    ..sort((a, b) => (b.sakeId ?? 0).compareTo(a.sakeId ?? 0));
                  if (_order == _ProductOrder.oldest) {
                    sorted.setAll(0, sorted.reversed.toList());
                  } else if (_order == _ProductOrder.match) {
                    int score(Sake sake) {
                      final profile = profiles[sake.sakeId];
                      return profile == null || preference == null
                          ? -1
                          : calculateSharedSakeTasteMatchPercent(
                              profile: profile,
                              preference: preference,
                            );
                    }

                    final scores = {
                      for (final sake in all) sake.sakeId: score(sake),
                    };
                    sorted.sort((a, b) {
                      final comparison = scores[b.sakeId]!.compareTo(
                        scores[a.sakeId]!,
                      );
                      return comparison != 0
                          ? comparison
                          : (b.sakeId ?? 0).compareTo(a.sakeId ?? 0);
                    });
                  }
                  final visible = sorted
                      .take(_visibleCount)
                      .toList(growable: false);
                  final profilesFuture = _profilesFor(
                    _order == _ProductOrder.match ? all : visible,
                  );
                  return RefreshIndicator(
                    color: _navy,
                    onRefresh: _refresh,
                    child: ListView.separated(
                      controller: _controller,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
                      itemCount: visible.isEmpty ? 1 : visible.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (visible.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 120),
                            child: Center(child: Text('同じ銘柄のほかの商品はまだありません')),
                          );
                        }
                        if (index == 0) {
                          return Text(
                            widget.brandName ?? '同じ銘柄の商品',
                            style: const TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }
                        final sake = visible[index - 1];
                        return SakeListCard(
                          key: ValueKey(sake.sakeId),
                          sake: sake,
                          profileFuture: profilesFuture.then(
                            (profiles) => profiles[sake.sakeId],
                          ),
                          preference: preference,
                          onOpen: () {
                            AppAnalytics.instance.event(
                              'same_brand_products',
                              'detail',
                            );
                            widget.onOpen(sake);
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
