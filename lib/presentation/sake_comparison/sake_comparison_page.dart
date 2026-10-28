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
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../common/dialogs/ai_data_consent_dialog.dart';
import '../common/widgets/primary_app_bar.dart';
import '../common/widgets/sake_taste_match_preview.dart';
import 'comparison_item.dart';

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
                      '今回追加する1件を選んでください',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final sake in extracted!)
                          ListTile(
                            title: Text(sake.name ?? ''),
                            subtitle: Text(sake.description ?? sake.type ?? ''),
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
      final reviewed = await showDialog<Sake>(
        context: context,
        builder: (_) => _TextReviewDialog(sake: selected!),
      );
      if (reviewed == null || !mounted || !_sameOwner) return;
      setState(() => _progress = '味わいとマッチ度を確認中…');
      List<MenuSakeResolution> resolved;
      try {
        resolved = await session
            .resolveMenuSakes([reviewed])
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
                      '同じお酒を選んでください',
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
                    child: const Text('該当なし・読み取った文字のまま追加'),
                  ),
                ],
              ),
            ),
          ),
        );
        if (candidate == null) return;
      }
      if (!mounted || !_sameOwner) return;
      final item = ComparisonItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sake: candidate?.sake ?? reviewed,
        text: reviewed.description ?? '',
        profile:
            candidate?.tasteProfile ??
            (candidate == null ? resolution?.fallbackTasteProfile : null),
        estimated:
            candidate == null ||
            (candidate.tasteProfile?.sourceType?.contains('ai') ?? false),
      );
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
          : '${_recommended.length}本を選びました。おすすめ理由もご覧ください。',
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
            ? 0
            : ar
            ? -1
            : 1;
      });
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: PrimaryAppBar(
        title: 'お酒えらび・デモ',
        actions: [
          IconButton(
            key: _cartKey,
            tooltip: '比較カート',
            onPressed: () {
              if (_scroll.hasClients) {
                _scroll.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
            icon: Badge(
              label: Text('${_items.length}'),
              child: const Icon(
                Icons.shopping_basket_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        '文字で集めて、今の一本を。',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '商品説明カードやメニューの一部分を撮影。文字を確認して1件ずつカートに入れ、まとめて比べられます。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '写真は比較カートに保存しません。読み取りはメニュー解析の利用回数に含まれます。',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _busy ? null : _samples,
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('サンプル3件で試す（架空の商品）'),
                        ),
                      ),
                      _panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '今日は、どう選ぶ？',
                              style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Expanded(child: Text('何本買う？')),
                                IconButton(
                                  onPressed: _bottles > 1
                                      ? () => setState(() {
                                          _bottles--;
                                          _recommended = {};
                                        })
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$_bottles本',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _bottles < 10
                                      ? () => setState(() {
                                          _bottles++;
                                          _recommended = {};
                                        })
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                            const Text('今、飲みたい気分'),
                            Wrap(
                              spacing: 6,
                              children: [
                                for (final mood in ComparisonMood.values)
                                  ChoiceChip(
                                    label: Text(mood.label),
                                    selected: _mood == mood,
                                    onSelected: (_) => setState(() {
                                      _mood = mood;
                                      _recommended = {};
                                    }),
                                  ),
                              ],
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('限定・珍しいものが気になる'),
                              subtitle: const Text(
                                'カードの「限定」などの記載を参考にします。実際の希少性は未確認です。',
                                style: TextStyle(fontSize: 11),
                              ),
                              value: _limited,
                              onChanged: (v) => setState(() {
                                _limited = v;
                                _recommended = {};
                              }),
                            ),
                            if (preference == null)
                              const Text(
                                '好みが未設定です。気分を選ぶと「今日の気分マッチ度」で比較できます。',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.deepOrange),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        '比較カート  ${_items.length}/20',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _navy,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_items.isEmpty)
                        _panel(
                          child: const Column(
                            children: [
                              Icon(
                                Icons.add_shopping_cart,
                                size: 40,
                                color: _navy,
                              ),
                              SizedBox(height: 12),
                              Text(
                                '気になる説明カードを1件撮ってみましょう。\n上のサンプルでも操作を試せます。',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      for (final item in sorted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _itemCard(item, preference),
                        ),
                      const Text(
                        'マッチ度は参考値です。味わいデータがない場合は数値を作らず「未算出」と表示します。おすすめはカート内だけから選びます。',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: _panel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_busy)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _progress.isEmpty ? 'カートを更新中…' : _progress,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                key: _readKey,
                                onPressed: _busy
                                    ? null
                                    : () => _capture(ImageSource.camera),
                                icon: const Icon(
                                  Icons.document_scanner_outlined,
                                ),
                                label: const Text('撮影して追加'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: '写真から読み取る',
                              onPressed: _busy
                                  ? null
                                  : () => _capture(ImageSource.gallery),
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                color: _navy,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _busy || _items.isEmpty
                                ? null
                                : _recommend,
                            icon: const Icon(Icons.auto_awesome),
                            label: Text('この中から$_bottles本、おすすめを選んで'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _itemCard(ComparisonItem item, TastePreferenceProfile? preference) {
    final selected = _recommended.contains(item.id);
    final percent = item.match(preference ?? _mood.preference);
    final reasons = <String>[
      if (item.match(preference) != null) '好みとのマッチ度 ${item.match(preference)}%',
      if (_mood != ComparisonMood.any && item.match(_mood.preference) != null)
        '${_mood.label}の気分に ${item.match(_mood.preference)}%',
      if (_limited && item.mentionsLimited) '説明に限定・季節品などの記載あり',
      if (percent == null) '味わいデータまたは好みが不足しているため、マッチ度は未算出',
    ];
    return _panel(
      color: selected ? const Color(0xFFFFF8E4) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.sake.name ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    color: _navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: '比較カートから外す',
                onPressed: _busy ? null : () => _remove(item),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          if (item.sample)
            const Text(
              '架空の商品・デモデータ',
              style: TextStyle(color: Colors.deepOrange, fontSize: 11),
            ),
          if (selected)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '★ 今回のおすすめ',
                style: TextStyle(fontWeight: FontWeight.bold, color: _navy),
              ),
            ),
          Text(
            [item.sake.brewery, item.sake.type].whereType<String>().join(' / '),
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          if (item.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(item.text),
            ),
          if (preference == null)
            Text(
              '今日の気分マッチ度  ${percent == null ? '未算出' : '$percent%'}',
              style: const TextStyle(color: _navy, fontWeight: FontWeight.bold),
            )
          else
            SakeTasteMatchPreview(
              percent: percent,
              profile: item.profile,
              preference: preference,
            ),
          if (item.estimated)
            const Text(
              '味わいは読み取った説明などをもとにした推定です。',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          if (selected)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                reasons.join('。'),
                style: const TextStyle(fontSize: 12, color: _navy),
              ),
            ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child, Color color = Colors.white}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );
}

class _TextReviewDialog extends StatefulWidget {
  const _TextReviewDialog({required this.sake});
  final Sake sake;
  @override
  State<_TextReviewDialog> createState() => _TextReviewDialogState();
}

class _TextReviewDialogState extends State<_TextReviewDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.sake.name,
  );
  late final TextEditingController _type = TextEditingController(
    text: widget.sake.type,
  );
  late final TextEditingController _brewery = TextEditingController(
    text: widget.sake.brewery,
  );
  late final TextEditingController _text = TextEditingController(
    text: widget.sake.description,
  );
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    for (final c in [_name, _type, _brewery, _text]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('読み取った文字を確認'),
    content: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              maxLength: 160,
              decoration: const InputDecoration(labelText: '商品名'),
              validator: (v) =>
                  !isPlausibleRecognizedSakeName(v) ? '商品名を確認してください' : null,
            ),
            TextFormField(
              controller: _type,
              maxLength: 100,
              decoration: const InputDecoration(labelText: '種類（任意）'),
            ),
            TextFormField(
              controller: _brewery,
              maxLength: 100,
              decoration: const InputDecoration(labelText: '酒蔵（任意）'),
            ),
            TextFormField(
              controller: _text,
              maxLength: 2000,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'カード・メニューの説明文'),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('キャンセル'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              Sake(
                name: _name.text.trim(),
                type: _type.text.trim(),
                brewery: _brewery.text.trim(),
                description: _text.text.trim(),
              ),
            );
          }
        },
        child: const Text('比較カートに追加'),
      ),
    ],
  );
}
