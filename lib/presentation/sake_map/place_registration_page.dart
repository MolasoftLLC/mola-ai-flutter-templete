import '../../common/review/review_request_coordinator.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import '../../common/map/place_registration_inbox.dart';
import '../../domain/notifier/auth/auth_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../menu_search/menu_search_page_notifier.dart';
import '../my_page/widgets/place_picker_sheet.dart';
import '../common/widgets/primary_app_bar.dart';

Future<void> openPlaceRegistrationInbox(BuildContext context) async {
  final owner =
      Provider.of<AuthState?>(context, listen: false)?.user?.uid ?? 'guest';
  final menus = context.read<MenuSearchPageNotifier>();
  final saved = context.read<SavedSakeNotifier>();
  final store = PlaceRegistrationDismissals(owner);
  try {
    await store.load();
    if (!context.mounted ||
        (Provider.of<AuthState?>(context, listen: false)?.user?.uid ??
                'guest') !=
            owner)
      return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            StateNotifierProvider<
              MenuSearchPageNotifier,
              MenuSearchPageState
            >.value(value: menus),
            StateNotifierProvider<SavedSakeNotifier, SavedSakeState>.value(
              value: saved,
            ),
          ],
          child: PlaceRegistrationPage(store: store),
        ),
      ),
    );
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('記録を読み込めませんでした。もう一度お試しください。')),
      );
  } finally {
    store.dispose();
  }
}

const _navy = Color(0xFF143861);

class PlaceRegistrationAction extends StatefulWidget {
  const PlaceRegistrationAction({super.key, this.onClosed});
  final VoidCallback? onClosed;
  @override
  State<PlaceRegistrationAction> createState() =>
      _PlaceRegistrationActionState();
}

class _PlaceRegistrationActionState extends State<PlaceRegistrationAction> {
  PlaceRegistrationDismissals? _store;
  @override
  void initState() {
    super.initState();
    PlaceRegistrationDismissals.revision.addListener(_reload);
  }

  void _reload() {
    unawaited(_store?.load().catchError((Object _) {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owner = Provider.of<AuthState?>(context)?.user?.uid ?? 'guest';
    if (_store?.owner == owner) return;
    _store?.dispose();
    _store = PlaceRegistrationDismissals(owner);
    _reload();
  }

  @override
  void dispose() {
    PlaceRegistrationDismissals.revision.removeListener(_reload);
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottles = context.watch<SavedSakeState>().savedSakeList;
    final menus = context.watch<MenuSearchPageState>().menuAnalysisHistory;
    return ListenableBuilder(
      listenable: _store!,
      builder: (context, _) {
        final count = _store!.ready
            ? pendingPlaceRegistrations(
                bottles: bottles,
                menus: menus,
                dismissed: _store!.ids,
              ).length
            : 0;
        return IconButton(
          tooltip: '場所を登録していない記録（$count件）',
          onPressed: () async {
            await openPlaceRegistrationInbox(context);
            if (mounted) widget.onClosed?.call();
          },
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: const Color(0xFFE54B4B),
            label: Text(count > 99 ? '99+' : '$count'),
            child: const SizedBox(
              width: 30,
              height: 28,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 2,
                    child: Icon(
                      Icons.map_outlined,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.add_circle,
                      color: Color(0xFFFFCC32),
                      size: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PlaceRegistrationPage extends StatefulWidget {
  const PlaceRegistrationPage({super.key, required this.store, this.pickPlace});
  final PlaceRegistrationDismissals store;
  final Future<DrinkingPlace?> Function(BuildContext, String?)? pickPlace;
  @override
  State<PlaceRegistrationPage> createState() => _PlaceRegistrationPageState();
}

class _PlaceRegistrationPageState extends State<PlaceRegistrationPage> {
  String? _busy;
  bool get _sameOwner =>
      (Provider.of<AuthState?>(context, listen: false)?.user?.uid ?? 'guest') ==
      widget.store.owner;
  void _error() {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存できませんでした。もう一度お試しください。')));
  }

  Future<void> _register(PlaceRegistrationItem item) async {
    if (_busy != null || !_sameOwner) return;
    final saved = context.read<SavedSakeNotifier>();
    final menus = context.read<MenuSearchPageNotifier>();
    setState(() => _busy = item.key);
    var savedSuccessfully = false;
    try {
      final place = widget.pickPlace != null
          ? await widget.pickPlace!(context, item.initialPlace)
          : await PlacePickerSheet.show(
              context,
              initialPlace: item.initialPlace,
            );
      if (!mounted || place == null || !_sameOwner) return;
      if (!hasMapPlace(place)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('地図に表示できるお店を選んでください。')));
        return;
      }
      if (item.isMenu) {
        await menus.setHistoryPlace(item.menu!.id, place);
      } else {
        final current = saved.savedSakes
            .where((s) => s.savedId == item.sake!.savedId)
            .firstOrNull;
        if (current == null) return;
        await saved.setSavedSakePlace(current.savedId!, place);
        if (_sameOwner && widget.store.owner != 'guest') {
          final result = await saved.syncSavedSakeToServer(current.savedId!);
          if (result == null && mounted && _sameOwner) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('端末に保存しました。同期は記録画面から再試行できます。')),
            );
          }
          if (result == null) return;
        }
      }
      savedSuccessfully = true;
    } catch (_) {
      _error();
    } finally {
      if (mounted) setState(() => _busy = null);
    }
    if (savedSuccessfully && mounted && _sameOwner) {
      unawaited(
        ReviewRequestCoordinator.instance.afterSuccessfulRecord(
          context,
          recordKey: item.isMenu
              ? 'menu:${item.menu!.id}'
              : 'record:${item.sake!.savedId}',
          owner: widget.store.owner,
          isIdle: () => _busy == null && _sameOwner,
        ),
      );
    }
  }

  Future<void> _forget(PlaceRegistrationItem item) async {
    if (_busy != null || !_sameOwner) return;
    setState(() => _busy = item.key);
    try {
      await widget.store.setDismissed(item.key, true);
      if (!mounted || !_sameOwner) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('この案内を外しました。記録は残っています。'),
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: () async {
              if (!mounted || !_sameOwner) return;
              try {
                await widget.store.setDismissed(item.key, false);
              } catch (_) {
                _error();
              }
            },
          ),
        ),
      );
    } catch (_) {
      _error();
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = Provider.of<AuthState?>(context)?.user?.uid ?? 'guest';
    final bottles = context.watch<SavedSakeState>().savedSakeList;
    final menus = context.watch<MenuSearchPageState>().menuAnalysisHistory;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const PrimaryAppBar(title: '場所を登録する'),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final items = owner == widget.store.owner && widget.store.ready
              ? pendingPlaceRegistrations(
                  bottles: bottles,
                  menus: menus,
                  dismissed: widget.store.ids,
                )
              : <PlaceRegistrationItem>[];
          if (!widget.store.ready)
            return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '飲んだお酒や見つけたメニューを、地図に残してみませんか。',
                style: TextStyle(color: _navy, fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 6),
              const Text(
                '覚えていない記録は、写真や履歴を残したまま一覧から外せます。',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 70),
                  child: Column(
                    children: [
                      Icon(Icons.map_outlined, color: _navy, size: 40),
                      SizedBox(height: 12),
                      Text('場所を登録できる記録はありません', style: TextStyle(color: _navy)),
                    ],
                  ),
                ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _busy == null ? () => _register(item) : null,
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 58,
                                    height: 72,
                                    child: _RecordImage(item: item),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.isMenu ? 'メニュー' : '酒瓶',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: _navy,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (item.menu != null)
                                        Text(
                                          '${item.menu!.sakes.length}種類のお酒',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: _navy),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _busy == null
                                      ? () => _register(item)
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFD84D),
                                    foregroundColor: _navy,
                                    minimumSize: const Size(0, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: _busy == item.key
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.add_location_alt_outlined,
                                          size: 18,
                                        ),
                                  label: const Text('場所を登録'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _busy == null
                                    ? () => _forget(item)
                                    : null,
                                child: const Text(
                                  '覚えていない',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RecordImage extends StatelessWidget {
  const _RecordImage({required this.item});
  final PlaceRegistrationItem item;
  @override
  Widget build(BuildContext context) {
    final path = item.imagePath;
    Widget fallback() => ColoredBox(
      color: const Color(0xFFEDF1F5),
      child: Icon(
        item.isMenu ? Icons.restaurant_menu : Icons.wine_bar_outlined,
        color: _navy,
      ),
    );
    if (path == null || path.isEmpty) return fallback();
    if (!path.startsWith('http') && !File(path).existsSync()) return fallback();
    return path.startsWith('http')
        ? Image.network(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback(),
          )
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback(),
          );
  }
}
