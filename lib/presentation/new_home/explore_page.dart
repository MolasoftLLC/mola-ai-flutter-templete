import 'package:flutter/material.dart';
import '../common/widgets/primary_app_bar.dart';

/// Existing search experiences gathered behind the Explore tab.
class ExplorePage extends StatelessWidget {
  const ExplorePage({
    super.key,
    required this.onSearch,
    required this.onMenu,
    required this.onJapan,
    required this.onMap,
  });
  final VoidCallback onSearch;
  final VoidCallback onMenu;
  final VoidCallback onJapan;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: PrimaryAppBar(
        title: en ? 'Explore' : '探す',
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          _entry(
            Icons.search,
            en ? 'Search sake' : '銘柄・お酒を探す',
            en ? 'Search by name or preferences' : '名前や好みから検索',
            onSearch,
          ),
          _entry(
            Icons.menu_book_outlined,
            en ? 'Analyze a menu' : 'メニュー解析',
            en ? 'Photograph a menu or view past results' : 'メニューを撮影・過去の解析を見る',
            onMenu,
          ),
          _entry(
            Icons.travel_explore,
            en ? 'Travel through sake' : '日本酒を旅する',
            en ? 'Explore brands by prefecture' : '日本地図から県ごとの銘柄を探す',
            onJapan,
          ),
          _entry(
            Icons.place_outlined,
            en ? 'Find places' : 'お店をマップで探す',
            en ? 'Find places to drink or buy sake' : '飲めるお店・買えるお店を探す',
            onMap,
          ),
        ],
      ),
    );
  }

  Widget _entry(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        leading: Icon(icon, color: const Color(0xFF143861), size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF143861),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF143861)),
        onTap: onTap,
      ),
    ),
  );
}
