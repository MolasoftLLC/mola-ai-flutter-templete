import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';

import '../../common/localization/localization_extensions.dart';
import '../../common/localization/sake_filter_localizations.dart';
import '../../common/prefecture.dart';
import '../../common/sake/master.dart';
import '../../domain/repository/place_map_repository.dart';
import '../common/widgets/primary_app_bar.dart';
import '../sake_map/sake_master_detail_page.dart';
import 'favorite_search_page_notifier.dart';

class FavoriteSearchPage extends StatefulWidget {
  const FavoriteSearchPage._({super.key});

  static Widget wrapped() => MultiProvider(
    providers: [
      StateNotifierProvider<
        FavoriteSearchPageNotifier,
        FavoriteSearchPageState
      >(create: (context) => FavoriteSearchPageNotifier(context: context)),
    ],
    child: const FavoriteSearchPage._(),
  );

  @override
  State<FavoriteSearchPage> createState() => _FavoriteSearchPageState();
}

class _FavoriteSearchPageState extends State<FavoriteSearchPage> {
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;
  List<SakeMapSearchResult> _results = const [];

  Future<void> _search(FavoriteSearchPageState state) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });
    try {
      final results = await context
          .read<PlaceMapRepository>()
          .discoverSakeMasters(
            prefecture: state.selectedPrefecture,
            flavors: state.selectedFlavors,
            tastes: state.selectedTastes,
            designs: state.selectedDesigns,
          );
      if (!mounted) return;
      setState(() {
        _results = results;
        _hasSearched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _hasSearched = true;
        _errorMessage = '検索に失敗しました。通信状況を確認してもう一度お試しください。';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<FavoriteSearchPageNotifier>();
    final state = context.watch<FavoriteSearchPageState>();
    final selectedFlavors = state.selectedFlavors ?? const <String>[];
    final selectedTastes = state.selectedTastes ?? const <String>[];
    final selectedDesigns = state.selectedDesigns ?? const <String>[];

    return Scaffold(
      appBar: PrimaryAppBar(
        title: context.l10n.searchByRegion,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ColoredBox(
        color: const Color(0xFF1D3567),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              const Text(
                '産地と味わいから、日本酒マスターを絞り込みます。',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 28),
              _SectionLabel(label: context.l10n.region),
              const SizedBox(height: 10),
              _PrefectureDropdown(
                value: state.selectedPrefecture,
                onChanged: notifier.setPrefecture,
              ),
              const SizedBox(height: 28),
              _FilterGrid(
                label: context.l10n.flavorGroupOne,
                choices: Sake.flavors,
                selected: selectedFlavors,
                onTap: notifier.toggleSelectedFlavor,
              ),
              const SizedBox(height: 28),
              _FilterGrid(
                label: context.l10n.flavorGroupTwo,
                choices: Sake.tastes,
                selected: selectedTastes,
                onTap: notifier.toggleSelectedTaste,
              ),
              const SizedBox(height: 28),
              _FilterGrid(
                label: context.l10n.specificDesignation,
                choices: Sake.designs,
                selected: selectedDesigns,
                onTap: notifier.toggleSelectedDesigns,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isSearching ? null : () => _search(state),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFFFF7A1A),
                  foregroundColor: Colors.white,
                ),
                icon: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isSearching ? '検索中…' : 'この条件で検索'),
              ),
              if (_hasSearched) ...[
                const SizedBox(height: 32),
                _SearchResults(results: _results, errorMessage: _errorMessage),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  );
}

class _PrefectureDropdown extends StatelessWidget {
  const _PrefectureDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        hint: Text(context.l10n.selectRegion),
        underline: const SizedBox(),
        items: prefectures
            .map(
              (prefecture) => DropdownMenuItem<String>(
                value: prefecture,
                child: Text(localizeSakeFilterLabel(context, prefecture)),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    ),
  );
}

class _FilterGrid extends StatelessWidget {
  const _FilterGrid({
    required this.label,
    required this.choices,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final List<String> choices;
  final List<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionLabel(label: label),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: choices
            .map(
              (choice) => FilterChip(
                label: Text(localizeSakeFilterLabel(context, choice)),
                selected: selected.contains(choice),
                onSelected: (_) => onTap(choice),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF4F90E6),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected.contains(choice)
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
            .toList(growable: false),
      ),
    ],
  );
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.errorMessage});
  final List<SakeMapSearchResult> results;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Text(errorMessage!, style: const TextStyle(color: Colors.white));
    }
    if (results.isEmpty) {
      return const Text(
        '条件に合う日本酒が見つかりませんでした。条件を少しゆるめてお試しください。',
        style: TextStyle(color: Colors.white),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${results.length}件見つかりました',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...results.map(
          (result) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                onTap: result.sakeId == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SakeMasterDetailPage(
                            venueSake: VenueSake(
                              sakeId: result.sakeId,
                              name: result.name,
                              brewery: result.brewery,
                              type: result.type,
                              recordCount: 0,
                              primaryImageUrl: result.primaryImageUrl,
                            ),
                          ),
                        ),
                      ),
                leading: result.primaryImageUrl == null
                    ? const CircleAvatar(child: Icon(Icons.local_bar_outlined))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          result.primaryImageUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const CircleAvatar(
                            child: Icon(Icons.local_bar_outlined),
                          ),
                        ),
                      ),
                title: Text(result.name),
                subtitle: Text(
                  [result.brewery, result.type]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' / '),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
