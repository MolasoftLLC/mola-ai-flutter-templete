import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/repository/place_map_repository.dart';

/// Select a replacement without leaving the menu or changing other rows.
class MenuSakeSearchSheet extends StatefulWidget {
  const MenuSakeSearchSheet({
    super.key,
    required this.initialQuery,
    required this.search,
  });
  final String initialQuery;
  final Future<List<SakeMapSearchResult>> Function(String) search;

  @override
  State<MenuSakeSearchSheet> createState() => _MenuSakeSearchSheetState();
}

class _MenuSakeSearchSheetState extends State<MenuSakeSearchSheet> {
  late final TextEditingController _controller;
  Timer? _debounce;
  int _request = 0;
  bool _loading = false;
  bool _error = false;
  List<SakeMapSearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _search();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _request++;
    setState(() {
      _results = [];
      _error = false;
      _loading = value.trim().isNotEmpty;
    });
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final request = ++_request;
    final query = _controller.text.trim();
    setState(() {
      _loading = query.isNotEmpty;
      _error = false;
      _results = [];
    });
    if (query.isEmpty) return;
    try {
      final results = await widget.search(query);
      if (!mounted || request != _request) return;
      setState(() {
        _results = results.where((s) => (s.sakeId ?? 0) > 0).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _request++;
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom) *
            .65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '名前で探して選ぶ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: '閉じる',
                ),
              ],
            ),
            const Text('選んだお酒を、このメニューの結果に反映します。'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              onChanged: _changed,
              onSubmitted: (_) => _search(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '銘柄・商品名で検索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error) ...[
              const Text('検索できませんでした。もう一度お試しください。'),
              TextButton(onPressed: _search, child: const Text('再試行')),
            ],
            if (!_loading && !_error && _results.isEmpty)
              Text(
                _controller.text.trim().isEmpty
                    ? '名前を入力してください。'
                    : '見つかりませんでした。名前を短くするか、読み取り間違いを直して検索してください。',
              ),
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final sake = _results[index];
                  final image = sake.thumbnailImageUrl ?? sake.primaryImageUrl;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: image == null
                        ? const Icon(Icons.local_bar, size: 40)
                        : Image.network(
                            image,
                            width: 48,
                            height: 64,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.local_bar, size: 40),
                          ),
                    title: Text(sake.name),
                    subtitle: Text(
                      [sake.brewery, sake.type].whereType<String>().join('・'),
                    ),
                    trailing: const Text(
                      '選択',
                      style: TextStyle(
                        color: Color(0xFF143861),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, sake),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
