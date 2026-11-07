import 'dart:async';
import '../../common/journey/sake_journey.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/utils/custom_image_picker.dart';
import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../../domain/repository/place_map_repository.dart';
import '../common/widgets/primary_app_bar.dart';
import '../sake_map/sake_master_detail_page.dart';
import 'comparison_item.dart';
import 'comparison_cart_view.dart';
import 'comparison_detail_page.dart';
import 'live_sake_scanner_page.dart';
import 'live_sake_search.dart';

const _navy = Color(0xFF143861);

class SakeComparisonPage extends StatefulWidget {
  const SakeComparisonPage({super.key, this.startScanning = false});
  final bool startScanning;
  @override
  State<SakeComparisonPage> createState() => _SakeComparisonPageState();
}

class _SakeComparisonPageState extends State<SakeComparisonPage>
    with SingleTickerProviderStateMixin {
  final _cartKey = GlobalKey();
  final _readKey = GlobalKey();
  final _scroll = ScrollController();
  late final AnimationController _flight;
  late final String _owner;
  List<ComparisonItem> _items = [];
  Set<String> _recommended = {};
  bool _ready = false;
  bool _busy = false;
  String? _error;
  final String _progress = '';
  Future<void> _cartWrites = Future.value();
  int _bottles = 1;
  ComparisonMood _mood = ComparisonMood.any;
  bool _limited = false;
  OverlayEntry? _flyingCard;
  bool get _sameOwner =>
      mounted &&
      (context.read<AuthRepository>().currentUser?.uid ?? 'guest') == _owner;
  String get _storageKey => 'sake_comparison_demo_v1_$_owner';
  TastePreferenceProfile? get _preference =>
      context.read<MyPageState>().tasteProfile;

  @override
  void initState() {
    super.initState();
    _owner = context.read<AuthRepository>().currentUser?.uid ?? 'guest';
    _flight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rows = prefs.getStringList(_storageKey) ?? [];
      final loaded = <ComparisonItem>[];
      for (final row in rows.take(20)) {
        try {
          loaded.add(
            ComparisonItem.fromJson(jsonDecode(row) as Map<String, dynamic>),
          );
        } catch (_) {
          /* Keep other readable entries. */
        }
      }
      if (_sameOwner) {
        setState(() {
          _items = loaded;
          _ready = true;
        });
        if (widget.startScanning) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_sameOwner) unawaited(_openTextScanner());
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = true;
          _error = '比較カートを読み込めませんでした。';
        });
      }
    }
  }

  Future<bool> _store(List<ComparisonItem> next) => _changeCart((_) => next);

  Future<bool> _changeCart(
    List<ComparisonItem> Function(List<ComparisonItem>) change,
  ) {
    final job = _cartWrites.then((_) async {
      if (!_sameOwner) return false;
      final prefs = await SharedPreferences.getInstance();
      if (!_sameOwner) return false;
      final next = change(_items);
      final saved = await prefs.setStringList(
        _storageKey,
        next.map((i) => jsonEncode(i.toJson())).toList(),
      );
      if (!saved) throw StateError('保存に失敗しました');
      if (!_sameOwner) return false;
      setState(() {
        _items = next;
        _recommended = {};
        _error = null;
      });
      return true;
    });
    _cartWrites = job.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return job;
  }

  Future<void> _loadCartProfile(int id, SakeScanRepository repository) async {
    try {
      final profiles = await repository
          .fetchTasteProfiles([id])
          .timeout(const Duration(seconds: 6));
      final profile = profiles[id];
      if (profile == null || !_sameOwner) return;
      await _changeCart(
        (items) => items
            .map(
              (item) => item.sake.sakeId == id && item.profile == null
                  ? ComparisonItem(
                      id: item.id,
                      sake: item.sake,
                      text: item.text,
                      profile: profile,
                      estimated:
                          item.estimated ||
                          (profile.sourceType?.contains('ai') ?? false),
                      sample: item.sample,
                    )
                  : item,
            )
            .toList(),
      );
    } catch (_) {
      /* Selection is preserved even when taste data is unavailable. */
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> _openTextScanner({bool fromGallery = false}) async {
    if (_busy || !_ready || !_sameOwner) return;
    if (_items.length >= 20) {
      _message('比較カートは20件までです。不要な候補を外してください。');
      return;
    }
    String? imagePath;
    if (fromGallery) {
      final image = await CustomImagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image == null || !_sameOwner) return;
      imagePath = image.path;
    }
    if (!mounted || !_sameOwner) return;
    final catalog = context.read<PlaceMapRepository>();
    final profiles = context.read<SakeScanRepository>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveSakeScannerPage(
          search: LiveSakeSearch(
            search: (query) => catalog.searchSakeMasters(query, limit: 50),
            loadProfiles: profiles.fetchTasteProfiles,
          ),
          imagePath: imagePath,
          initialIds: _items
              .map((item) => item.sake.sakeId)
              .whereType<int>()
              .toSet(),
          initialCount: _items.length,
          preference: _preference,
          onAdd: (item) async {
            if (!_sameOwner ||
                _items.length >= 20 ||
                _items.any((i) => i.identity == item.identity)) {
              return false;
            }
            final saved = await _changeCart((items) => [...items, item]);
            if (saved)
              unawaited(
                SakeJourneyStore.instance.complete(_owner, JourneyStep.scan),
              );
            if (saved && item.profile == null) {
              unawaited(_loadCartProfile(item.sake.sakeId!, profiles));
            }
            return saved;
          },
        ),
      ),
    );
  }

  void _openDetail(ComparisonItem item) {
    if (!_sameOwner) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => !item.sample && (item.sake.sakeId ?? 0) > 0
            ? SakeMasterDetailPage(
                recordRecentView: true,
                venueSake: VenueSake(
                  sakeId: item.sake.sakeId,
                  name: item.sake.name ?? '',
                  brewery: item.sake.brewery,
                  type: item.sake.type,
                  recordCount: 0,
                ),
              )
            : ComparisonDetailPage(item: item, preference: _preference),
      ),
    );
  }

  Future<void> _animateIntoCart() async {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    final source = _readKey.currentContext?.findRenderObject();
    final target = _cartKey.currentContext?.findRenderObject();
    if (source is! RenderBox || target is! RenderBox) return;
    final from = source.localToGlobal(source.size.center(Offset.zero));
    final to = target.localToGlobal(target.size.center(Offset.zero));
    _flyingCard = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: _flight,
        builder: (_, __) {
          final t = Curves.easeInOut.transform(_flight.value);
          final point =
              Offset.lerp(from, to, t)! +
              Offset(0, -math.sin(t * math.pi) * 60);
          return Positioned(
            left: point.dx - 22,
            top: point.dy - 22,
            child: IgnorePointer(
              child: Transform.scale(
                scale: 1 - t * .5,
                child: Material(
                  elevation: 8,
                  color: const Color(0xFFE6EDF6),
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Icon(Icons.description_outlined, color: _navy),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_flyingCard!);
    try {
      await _flight.forward(from: 0).orCancel;
    } on TickerCanceled {
      /* Page closed during animation. */
    } finally {
      _flyingCard?.remove();
      _flyingCard = null;
    }
  }

  Future<void> _remove(ComparisonItem item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _changeCart(
        (items) => items.where((i) => i.id != item.id).toList(),
      );
    } catch (_) {
      _message('カートを保存できませんでした。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _samples() async {
    if (_busy || !_ready) return;
    setState(() => _busy = true);
    try {
      final remaining = comparisonSamples().where(
        (sample) => !_items.any((i) => i.id == sample.id),
      );
      if (_items.length + remaining.length > 20) {
        _message('カートの空きを作ってください。');
        return;
      }
      if (await _store([..._items, ...remaining])) await _animateIntoCart();
    } catch (_) {
      _message('サンプルを追加できませんでした。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _recommend() {
    if (_items.isEmpty || _busy) return;
    if (_preference == null && _mood == ComparisonMood.any && !_limited) {
      _message('今、飲みたい気分を選んでください。');
      return;
    }
    final sorted = _items
        .where(
          (item) =>
              (item.profile != null &&
                  (_preference != null || _mood != ComparisonMood.any)) ||
              (_limited && item.mentionsLimited),
        )
        .toList();
    if (sorted.isEmpty) {
      _message('今の条件を比較できる情報が足りません。気分を選ぶか、説明のある候補を追加してください。');
      return;
    }
    sorted.sort((a, b) {
      final result = b
          .rank(_preference, _mood, _limited)
          .compareTo(a.rank(_preference, _mood, _limited));
      return result != 0
          ? result
          : _items.indexOf(a).compareTo(_items.indexOf(b));
    });
    setState(
      () => _recommended = sorted.take(_bottles).map((i) => i.id).toSet(),
    );
    _message(
      _recommended.length < _bottles
          ? '条件を比較できる候補から${_recommended.length}本を選びました。残りは情報不足のため選んでいません。'
          : '${_recommended.length}本を選びました',
    );
  }

  @override
  void dispose() {
    _flyingCard?.remove();
    _flyingCard = null;
    _flight.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _chooseRecommendations() async {
    if (_busy || _items.isEmpty || !_sameOwner) return;
    final choice = await showModalBottomSheet<ComparisonChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ComparisonPreferenceSheet(
        initial: (bottles: _bottles, mood: _mood, limited: _limited),
        maxBottles: math.min(10, _items.length),
        hasPreference: _preference != null,
      ),
    );
    if (choice == null || !_sameOwner) return;
    setState(() {
      _bottles = choice.bottles;
      _mood = choice.mood;
      _limited = choice.limited;
    });
    _recommend();
    if (_recommended.isNotEmpty && _scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '文字でお酒えらび',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.document_scanner_outlined),
                title: Text('お酒の名前にカメラをかざす'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.shopping_basket_outlined),
                title: Text('表示された候補をタップして、続けて追加'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.auto_awesome),
                title: Text('気分と本数を選んで、おすすめを確認'),
              ),
              SizedBox(height: 16),
              Text(
                '文字は端末内で読み取り、登録済みの商品から候補を探します。シャッター音は鳴りません。カートは20本まで。',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              SizedBox(height: 12),
              Text(
                'マッチ度は登録されている味わいと好みをもとに計算します。サンプルは架空の商品です。',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preference = context.watch<MyPageState>().tasteProfile;
    final owner = context.watch<AuthRepository>().currentUser?.uid ?? 'guest';
    if (owner != _owner) {
      return const Scaffold(
        appBar: PrimaryAppBar(title: 'お酒えらび'),
        body: Center(child: Text('アカウントが変わりました。画面を開き直してください。')),
      );
    }
    final sorted = [..._items]
      ..sort((a, b) {
        final ar = _recommended.contains(a.id);
        final br = _recommended.contains(b.id);
        return ar == br
            ? _items.indexOf(a).compareTo(_items.indexOf(b))
            : ar
            ? -1
            : 1;
      });
    return ComparisonCartView(
      items: sorted,
      recommended: _recommended,
      preference: preference,
      mood: _mood,
      ready: _ready,
      busy: _busy,
      progress: _progress,
      error: _error,
      scrollController: _scroll,
      cartKey: _cartKey,
      readKey: _readKey,
      onCamera: () => _openTextScanner(),
      onGallery: () => _openTextScanner(fromGallery: true),
      onSamples: _samples,
      onRecommend: _chooseRecommendations,
      onReset: () => setState(() => _recommended = {}),
      onHelp: _showHelp,
      onDetail: _openDetail,
      onRemove: _remove,
    );
  }
}
