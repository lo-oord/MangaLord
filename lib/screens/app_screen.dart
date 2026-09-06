import 'dart:async';

import 'package:flutter/material.dart';

import '../services/starz_source.dart';

const accentGreen = Color(0xFF3DDC97);
const deepGreen = Color(0xFF113C32);
const mutedText = Color(0xFF8FA39C);

class Manga {
  const Manga({required this.title, required this.url, required this.author, required this.genre, required this.cover, required this.description, required this.chapters, this.chapterItems = const [], this.status = 'Ongoing'});
  final String title, url, author, genre, cover, description, status;
  final int chapters;
  final List<StarzChapter> chapterItems;
  factory Manga.fromStarz(StarzManga manga) => Manga(title: manga.title, url: manga.url, author: manga.author, genre: manga.genres, cover: manga.cover, description: manga.description, chapters: manga.chapters.length, chapterItems: manga.chapters, status: manga.status);
}

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});
  @override State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  final source = StarzSource();
  int index = 0;
  String query = '';
  List<Manga> manga = [];
  final favorites = <String>{};
  final history = <Manga>[];
  bool loading = true;
  bool searching = false;
  String? error;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLatest();
    refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) => _loadLatest(silent: true));
  }

  @override
  void dispose() { refreshTimer?.cancel(); super.dispose(); }

  Future<void> _loadLatest({bool silent = false}) async {
    if (!silent && mounted) setState(() { loading = true; error = null; });
    try {
      final result = await source.latest();
      if (mounted) setState(() { manga = result.map(Manga.fromStarz).toList(); loading = false; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> _search(String value) async {
    query = value.trim();
    if (query.isEmpty) return _loadLatest();
    setState(() { searching = true; error = null; });
    try {
      final result = await source.search(query);
      if (mounted) setState(() { manga = result.map(Manga.fromStarz).toList(); searching = false; });
    } catch (e) {
      if (mounted) setState(() { searching = false; error = e.toString(); });
    }
  }

  void openManga(Manga item) {
    history.removeWhere((entry) => entry.url == item.url);
    history.insert(0, item);
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(source: source, manga: item, isFavorite: favorites.contains(item.url), onFavorite: (value) => setState(() { if (value) { favorites.add(item.url); } else { favorites.remove(item.url); } }))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: [HomePage(items: manga, loading: loading, searching: searching, error: error, query: query, onQuery: _search, onRefresh: _loadLatest, onOpen: openManga), HistoryPage(items: history, onOpen: openManga), SettingsPage(favorites: favorites, allItems: [...manga, ...history], onOpen: openManga)]),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: FloatingNavigation(index: index, onChanged: (value) => setState(() => index = value)))),
    );
  }
}

class FloatingNavigation extends StatelessWidget {
  const FloatingNavigation({required this.index, required this.onChanged, super.key});
  final int index;
  final ValueChanged<int> onChanged;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 8))]), child: Row(children: [NavItem(icon: Icons.home_rounded, label: 'Home', active: index == 0, onTap: () => onChanged(0)), NavItem(icon: Icons.history_rounded, label: 'History', active: index == 1, onTap: () => onChanged(1)), NavItem(icon: Icons.settings_rounded, label: 'Settings', active: index == 2, onTap: () => onChanged(2))]));
}
class NavItem extends StatelessWidget {
  const NavItem({required this.icon, required this.label, required this.active, required this.onTap, super.key});
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: AnimatedContainer(duration: const Duration(milliseconds: 220), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? accentGreen.withOpacity(.16) : Colors.transparent, borderRadius: BorderRadius.circular(18)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: active ? accentGreen : mutedText, size: 21), const SizedBox(height: 3), Text(label, style: TextStyle(color: active ? accentGreen : mutedText, fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500))]))));
}

class HomePage extends StatelessWidget {
  const HomePage({required this.items, required this.loading, required this.searching, required this.error, required this.query, required this.onQuery, required this.onRefresh, required this.onOpen, super.key});
  final List<Manga> items; final bool loading, searching; final String? error; final String query; final ValueChanged<String> onQuery; final Future<void> Function({bool silent}) onRefresh; final ValueChanged<Manga> onOpen;
  @override Widget build(BuildContext context) {
    final slivers = <Widget>[SliverAppBar(pinned: true, expandedHeight: 112, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, flexibleSpace: const FlexibleSpaceBar(titlePadding: EdgeInsetsDirectional.only(start: 20, bottom: 16), title: Text('Discover', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800))), actions: [IconButton(onPressed: () => onRefresh(), icon: const Icon(Icons.refresh))]), SliverPadding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), sliver: SliverToBoxAdapter(child: TextField(onSubmitted: onQuery, textInputAction: TextInputAction.search, decoration: InputDecoration(hintText: 'Search manga...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: searching ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null, filled: true, fillColor: Theme.of(context).colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))))), SliverPadding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 14), sliver: SliverToBoxAdapter(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(query.isEmpty ? 'Latest manga' : 'Search results', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('${items.length} titles', style: const TextStyle(color: mutedText, fontSize: 12))])))];
    if (loading) { slivers.add(const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: accentGreen)))); } else if (items.isEmpty) { slivers.add(SliverFillRemaining(hasScrollBody: false, child: StateCard(icon: error == null ? Icons.search_off_rounded : Icons.cloud_off_rounded, title: error == null ? 'No manga found' : 'Could not load Manga Starz', message: error ?? 'Try another title or search again.'))); } else { slivers.add(SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((context, i) => MangaCard(manga: items[i], onTap: () => onOpen(items[i])), childCount: items.length), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 22, crossAxisSpacing: 16, childAspectRatio: .57)))); }
    return RefreshIndicator(onRefresh: () => onRefresh(), child: CustomScrollView(slivers: slivers));
  }
}

class MangaCard extends StatelessWidget {
  const MangaCard({required this.manga, required this.onTap, super.key});
  final Manga manga; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Hero(tag: manga.url, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(manga.cover, headers: const {'Referer': 'https://starzmanga.com/'}, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Container(color: deepGreen, child: const Icon(Icons.menu_book_rounded, color: accentGreen, size: 42)))))), const SizedBox(height: 9), Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), const SizedBox(height: 3), Text(manga.genre.isEmpty ? 'Manga' : manga.genre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: mutedText, fontSize: 12))]));
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.items, required this.onOpen, super.key}); final List<Manga> items; final ValueChanged<Manga> onOpen;
  @override Widget build(BuildContext context) => CustomScrollView(slivers: [SliverAppBar(pinned: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, title: const Text('Reading history', style: TextStyle(fontWeight: FontWeight.w800))), if (items.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: StateCard(icon: Icons.history_rounded, title: 'Your history is empty', message: 'Open a manga and your reading journey will appear here.')) else SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverList(delegate: SliverChildBuilderDelegate((context, i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: HistoryTile(manga: items[i], onTap: () => onOpen(items[i]))), childCount: items.length))) ]);
}
class HistoryTile extends StatelessWidget {
  const HistoryTile({required this.manga, required this.onTap, super.key}); final Manga manga; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(manga.cover, headers: const {'Referer': 'https://starzmanga.com/'}, width: 64, height: 82, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 64, height: 82, color: deepGreen))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text('${manga.chapters} chapters', style: const TextStyle(color: accentGreen, fontWeight: FontWeight.w600)), const SizedBox(height: 4), const Text('Opened recently', style: TextStyle(color: mutedText, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: mutedText)])));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.favorites, required this.allItems, required this.onOpen, super.key}); final Set<String> favorites; final List<Manga> allItems; final ValueChanged<Manga> onOpen;
  @override Widget build(BuildContext context) => CustomScrollView(slivers: [SliverAppBar(pinned: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800))), SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverList(delegate: SliverChildListDelegate([const Text('Your library', style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 12), SettingTile(title: 'Account', subtitle: 'Manage your profile', icon: Icons.person_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'Account', icon: Icons.person_rounded, message: 'Sign in to sync your library across devices.')))), SettingTile(title: 'Favorites', subtitle: '${favorites.length} saved manga', icon: Icons.favorite_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesPage(favorites: favorites, items: allItems, onOpen: onOpen)))), SettingTile(title: 'Downloads', subtitle: 'Offline reading queue', icon: Icons.download_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'Downloads', icon: Icons.download_rounded, message: 'Your downloaded chapters will be available offline here.', action: 'No downloads yet')))), SettingTile(title: 'Manga sources', subtitle: 'Manage sources', icon: Icons.language_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'Manga sources', icon: Icons.language_rounded, message: 'Manga Starz', action: 'Manga Starz')))), SettingTile(title: 'More', subtitle: 'Appearance and preferences', icon: Icons.tune_rounded, onTap: () {})])))]);
}
class SettingTile extends StatelessWidget { const SettingTile({required this.title, required this.subtitle, required this.icon, required this.onTap, super.key}); final String title, subtitle; final IconData icon; final VoidCallback onTap; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(icon, color: accentGreen), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: mutedText, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: mutedText)]))))); }

class DetailsPage extends StatefulWidget {
  const DetailsPage({required this.source, required this.manga, required this.isFavorite, required this.onFavorite, super.key}); final StarzSource source; final Manga manga; final bool isFavorite; final ValueChanged<bool> onFavorite;
  @override State<DetailsPage> createState() => _DetailsPageState();
}
class _DetailsPageState extends State<DetailsPage> {
  late Manga manga; late bool favorite; bool loading = true; String? error;
  @override void initState() { super.initState(); manga = widget.manga; favorite = widget.isFavorite; _fetch(); }
  Future<void> _fetch() async { try { final data = await widget.source.details(manga.url); if (mounted) setState(() { manga = Manga.fromStarz(data); loading = false; }); } catch (e) { if (mounted) setState(() { loading = false; error = e.toString(); }); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Manga details'), actions: [IconButton(onPressed: () { setState(() => favorite = !favorite); widget.onFavorite(favorite); }, icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? Colors.redAccent : null))]), body: RefreshIndicator(onRefresh: _fetch, child: ListView(padding: const EdgeInsets.all(20), children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Hero(tag: manga.url, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(manga.cover, headers: const {'Referer': 'https://starzmanga.com/'}, width: 130, height: 190, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 130, height: 190, color: deepGreen)))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(manga.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 8), if (manga.author.isNotEmpty) Text('by ${manga.author}', style: const TextStyle(color: mutedText)), const SizedBox(height: 12), Text('${manga.chapters} chapters', style: const TextStyle(color: accentGreen, fontWeight: FontWeight.w700))]))]), const SizedBox(height: 28), const Text('Synopsis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(manga.description.isEmpty ? 'No description available.' : manga.description, style: const TextStyle(color: mutedText, height: 1.6)), const SizedBox(height: 24), if (loading) const Center(child: CircularProgressIndicator(color: accentGreen)) else if (error != null) StateCard(icon: Icons.error_outline, title: 'Could not load chapters', message: error!) else ...[const Text('Chapters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 12), ...manga.chapterItems.map((chapter) => ChapterTile(chapter: chapter, onTap: () async { final loaded = await widget.source.chapter(chapter.url, mangaTitle: manga.title); if (context.mounted) await Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(manga: manga, chapter: loaded))); }))]])));
}
class ChapterTile extends StatelessWidget { const ChapterTile({required this.chapter, required this.onTap, super.key}); final StarzChapter chapter; final VoidCallback onTap; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [const Icon(Icons.menu_book_outlined, color: accentGreen), const SizedBox(width: 12), Expanded(child: Text(chapter.title, style: const TextStyle(fontWeight: FontWeight.w700))), const Icon(Icons.chevron_right_rounded, color: mutedText)]))))); }
class ReaderPage extends StatefulWidget { const ReaderPage({required this.manga, required this.chapter, super.key}); final Manga manga; final StarzChapter chapter; @override State<ReaderPage> createState() => _ReaderPageState(); }
class _ReaderPageState extends State<ReaderPage> { String mode = 'webtoon'; @override Widget build(BuildContext context) { final pages = widget.chapter.images; final body = mode == 'webtoon' ? ListView.builder(itemCount: pages.length, itemBuilder: (_, i) => Image.network(pages[i], headers: const {'Referer': 'https://starzmanga.com/'}, fit: BoxFit.fitWidth)) : PageView.builder(itemCount: pages.length, itemBuilder: (_, i) => InteractiveViewer(child: Image.network(pages[i], headers: const {'Referer': 'https://starzmanga.com/'}, fit: BoxFit.contain))); return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text('${widget.manga.title} • Reader'), actions: [PopupMenuButton<String>(onSelected: (value) => setState(() => mode = value), itemBuilder: (_) => const [PopupMenuItem(value: 'webtoon', child: Text('Webtoon')), PopupMenuItem(value: 'paged', child: Text('Paged'))])]), body: body); } }
class FavoritesPage extends StatelessWidget { const FavoritesPage({required this.favorites, required this.items, required this.onOpen, super.key}); final Set<String> favorites; final List<Manga> items; final ValueChanged<Manga> onOpen; @override Widget build(BuildContext context) { final selected = items.where((manga) => favorites.contains(manga.url)).toList(); return Scaffold(appBar: AppBar(title: const Text('Favorites')), body: GridView.builder(padding: const EdgeInsets.all(20), itemCount: selected.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 22, crossAxisSpacing: 16, childAspectRatio: .57), itemBuilder: (_, i) => MangaCard(manga: selected[i], onTap: () => onOpen(selected[i])))); } }
class SimplePage extends StatelessWidget { const SimplePage({required this.title, required this.icon, required this.message, this.action, super.key}); final String title, message; final IconData icon; final String? action; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: StateCard(icon: icon, title: action ?? title, message: message)); }
class StateCard extends StatelessWidget { const StateCard({required this.icon, required this.title, required this.message, super.key}); final IconData icon; final String title, message; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: accentGreen, size: 48), const SizedBox(height: 18), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: mutedText, height: 1.5))]))); }
