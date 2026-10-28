import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/utils/custom_image_picker.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/menu_sake_resolution.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/place_map_repository.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../common/dialogs/ai_data_consent_dialog.dart';
import '../common/widgets/primary_app_bar.dart';
import '../sake_map/sake_master_detail_page.dart';
import 'comparison_item.dart';
import 'comparison_cart_view.dart';
import 'comparison_detail_page.dart';

const _navy = Color(0xFF143861);

class SakeComparisonPage extends StatefulWidget {
  const SakeComparisonPage({super.key});
  @override
  State<SakeComparisonPage> createState() => _SakeComparisonPageState();
}

class _SakeComparisonPageState extends State<SakeComparisonPage>
    with SingleTickerProviderStateMixin {
  final _cartKey = GlobalKey();
  final _readKey = GlobalKey();
  final _scroll = ScrollController();
  late final AnimationController _flight;
  late final SakeMenuRecognitionRepository _repository;
  late final String _owner;
  List<ComparisonItem> _items = [];
  Set<String> _recommended = {};
  bool _ready = false;
  bool _busy = false;
  String? _error;
  String _progress = '';
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
    _repository = context.read<SakeMenuRecognitionRepository>().forkSession();
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

  Future<bool> _store(List<ComparisonItem> next) async {
    if (!_sameOwner) return false;
    final prefs = await SharedPreferences.getInstance();
    if (!_sameOwner) return false;
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
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<void> _capture(ImageSource source) async {
    if (_busy || !_ready || !_sameOwner) return;
    if (_items.length >= 20) {
      _message('比較カートは20件までです。不要な候補を外してください。');
      return;
    }
    if (_owner == 'guest') {
      _message('写真の読み取りにはログインが必要です。マイページからログインしてください。');
      return;
    }
    final session = _repository.forkSession();
    setState(() {
      _busy = true;
      _error = null;
      _progress = '文字を読み取る範囲を選んでください';
    });
    try {
      if (!await ensureAiDataConsent(context) || !_sameOwner) return;
      final picked = await CustomImagePicker.pickImage(source: source);
      if (picked == null || !_sameOwner) return;
      final cropped = await ImageCropperService.cropAndRotateImage(picked.path);
      if (cropped == null || !_sameOwner) return;
      List<Sake>? extracted;
      try {
        setState(() => _progress = '商品名と説明文を読み取り中…');
        extracted = await session
            .extractSakeInfo(cropped)
            .timeout(const Duration(seconds: 90));
      } finally {
        if (cropped.path != picked.path) {
          try {
            await cropped.delete();
          } catch (_) {
            /* OS may already remove its cache. */
          }
        }
      }
      if (!mounted || !_sameOwner) return;
      if (extracted == null || extracted.isEmpty) {
        throw StateError('商品名を読み取れませんでした。範囲を絞って撮り直してください。');
      }
      Sake? selected;
      if (extracted.length == 1) {
        selected = extracted.single;
      } else {
        selected = await showModalBottomSheet<Sake>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * .65,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'どのお酒を追加する？',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final sake in extracted!)
                          ListTile(
                            title: Text(sake.name ?? ''),
                            subtitle: Text(
                              sake.type ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(sheetContext, sake),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (selected == null || !mounted || !_sameOwner) return;
      // One clear recognition goes straight into the cart; only ambiguity needs a choice.
      final reviewed = selected;
      setState(() => _progress = '味わいとマッチ度を確認中…');
      List<MenuSakeResolution> resolved;
      try {
        resolved = await session
            .resolveMenuSakes([reviewed], includeDescription: true)
            .timeout(const Duration(seconds: 90));
      } catch (_) {
        resolved = [];
        _message('味わい情報を取得できなかったため、文字だけを追加します。マッチ度は未算出です。');
      }
      if (!mounted || !_sameOwner) return;
      final resolution = resolved.isEmpty ? null : resolved.first;
      MenuSakeCandidate? candidate;
      if (resolution?.status == MenuSakeResolutionStatus.resolved &&
          resolution!.candidates.length == 1) {
        candidate = resolution.candidates.single;
      } else if (resolution?.candidates.isNotEmpty == true) {
        candidate = await showModalBottomSheet<MenuSakeCandidate>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * .65,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'どのお酒ですか？',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final choice in resolution!.candidates)
                          ListTile(
                            title: Text(choice.sake.name ?? ''),
                            subtitle: Text(choice.sake.type ?? ''),
                            onTap: () => Navigator.pop(sheetContext, choice),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(
                      sheetContext,
                      MenuSakeCandidate(sake: reviewed),
                    ),
                    child: const Text('この中にない・そのまま追加'),
                  ),
                ],
              ),
            ),
          ),
        );
        if (candidate == null) return;
      }
      if (!mounted || !_sameOwner) return;
      final registered = (candidate?.sake.sakeId ?? 0) > 0;
      final fallback = resolution?.fallback;
      var item = ComparisonItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sake: registered
            ? candidate!.sake
            : reviewed.copyWith(
                // The printed explanation is retained separately as OCR evidence.
                description: fallback?.description,
                type: reviewed.type ?? fallback?.type,
                brewery: reviewed.brewery ?? fallback?.brewery,
              ),
        text: reviewed.description ?? '',
        profile:
            candidate?.tasteProfile ??
            (!registered ? resolution?.fallbackTasteProfile : null),
        estimated:
            !registered ||
            (candidate?.tasteProfile?.sourceType?.contains('ai') ?? false),
      );
      if (registered &&
          resolution?.status == MenuSakeResolutionStatus.multiple &&
          (item.profile == null ||
              item.sake.description?.trim().isNotEmpty != true)) {
        item = await _enrichItem(item, session, reviewed);
      }
      if (!mounted || !_sameOwner) return;
      await _add(item);
    } on SakeCandidateResolutionException catch (error) {
      if (_sameOwner) setState(() => _error = error.message);
    } catch (_) {
      if (_sameOwner) {
        setState(() => _error = '読み取りまたは保存ができませんでした。通信状況を確認して、もう一度お試しください。');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = '';
        });
      }
    }
  }

  Future<ComparisonItem> _enrichItem(
    ComparisonItem item,
    SakeMenuRecognitionRepository session,
    Sake input,
  ) async {
    try {
      final results = await session
          .resolveMenuSakes(
            [input],
            includeDescription: true,
            selectedSakeId: (item.sake.sakeId ?? 0) > 0
                ? item.sake.sakeId
                : null,
          )
          .timeout(const Duration(seconds: 90));
      if (results.isEmpty) return item;
      final result = results.first;
      final registered = (item.sake.sakeId ?? 0) > 0;
      MenuSakeCandidate? exact;
      if (registered) {
        for (final candidate in result.candidates) {
          if (candidate.sake.sakeId == item.sake.sakeId) exact = candidate;
        }
      }
      // A selected product must never acquire another candidate's analysis.
      final info = registered ? exact?.sake : result.fallback;
      final profile = registered
          ? exact?.tasteProfile
          : result.fallbackTasteProfile;
      return ComparisonItem(
        id: item.id,
        sake: item.sake.copyWith(
          description: info?.description ?? item.sake.description,
        ),
        text: item.text,
        profile: item.profile ?? profile,
        estimated:
            item.estimated || (profile?.sourceType?.contains('ai') ?? false),
        sample: item.sample,
      );
    } catch (_) {
      return item;
    }
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

  Future<void> _add(ComparisonItem item) async {
    if (_items.any((i) => i.identity == item.identity)) {
      _message('このお酒はすでにカートに入っています。');
      return;
    }
    if (_items.length >= 20) {
      _message('比較カートは20件までです。');
      return;
    }
    if (await _store([..._items, item])) await _animateIntoCart();
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
                  color: const Color(0xFFFFD54F),
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
      await _store(_items.where((i) => i.id != item.id).toList());
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
                'お酒えらび・デモ',
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
                title: Text('説明カードやメニューを1件ずつ撮影'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.shopping_basket_outlined),
                title: Text('気になるお酒を集めて比較'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.auto_awesome),
                title: Text('気分と本数を選んで、おすすめを確認'),
              ),
              SizedBox(height: 16),
              Text(
                '読み取りはメニュー解析の利用回数に含まれます。カートは20本まで。写真はカートに保存しません。',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              SizedBox(height: 12),
              Text(
                'AI推定の説明・味わい・マッチ度は参考情報です。限定品は説明の記載を参考にし、希少性を保証するものではありません。サンプルは架空の商品です。',
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
      onCamera: () => _capture(ImageSource.camera),
      onGallery: () => _capture(ImageSource.gallery),
      onSamples: _samples,
      onRecommend: _chooseRecommendations,
      onReset: () => setState(() => _recommended = {}),
      onHelp: _showHelp,
      onDetail: _openDetail,
      onRemove: _remove,
    );
  }
}
