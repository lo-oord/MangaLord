import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/team_x_source.dart';
import '../services/azora_source.dart';
import '../services/additional_manga_sources.dart';
import '../services/manga_source.dart';
import '../services/notification_service.dart';
import '../services/download_manager.dart';
import 'anime_screen.dart';
import '../services/anime_source.dart';
import '../services/anime_sources.dart';
import '../configs/app_locale.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

const accentGreen = Color(0xFF3DDC97);
const deepGreen = Color(0xFF113C32);
const mutedText = Color(0xFF8FA39C);
const appVersion = 'v0.0.22';

Map<String, String> _headersForManga(Manga manga) => {
  'Referer': manga.sourceKey == 'azora_fly' ? 'https://azorafly.com/' : 'https://olympustaff.com/',
};

class Manga {
  const Manga({required this.title, required this.url, required this.author, required this.genre, required this.cover, required this.description, required this.chapters, this.chapterItems = const [], this.status = 'Ongoing', this.lastChapterNumber = '', this.lastChapterAt = '', this.lastNotifiedChapterNumber = '', this.sourceKey = 'team_x', this.sourceName = 'Team X', this.sourceLogo = TeamXSource.teamXSourceLogo});
  final String title, url, author, genre, cover, description, status, lastChapterNumber, lastChapterAt, lastNotifiedChapterNumber, sourceKey, sourceName, sourceLogo;
  final int chapters;
  final List<TeamXChapter> chapterItems;
  factory Manga.fromTeamX(TeamXManga manga, {String? sourceKey, String? sourceName, String? sourceLogo}) => Manga(title: manga.title, url: manga.url, author: manga.author, genre: manga.genres, cover: manga.cover, description: manga.description, chapters: manga.chapters.length, chapterItems: manga.chapters, status: manga.status, sourceKey: sourceKey ?? 'team_x', sourceName: sourceName ?? 'Team X', sourceLogo: sourceLogo ?? TeamXSource.teamXSourceLogo);
  Manga copyWith({String? lastChapterNumber, String? lastChapterAt, String? lastNotifiedChapterNumber, List<TeamXChapter>? chapterItems, int? chapters}) => Manga(title: title, url: url, author: author, genre: genre, cover: cover, description: description, chapters: chapters ?? this.chapters, chapterItems: chapterItems ?? this.chapterItems, status: status, lastChapterNumber: lastChapterNumber ?? this.lastChapterNumber, lastChapterAt: lastChapterAt ?? this.lastChapterAt, lastNotifiedChapterNumber: lastNotifiedChapterNumber ?? this.lastNotifiedChapterNumber, sourceKey: sourceKey, sourceName: sourceName, sourceLogo: sourceLogo);
  Map<String, dynamic> toJson() => {'title': title, 'url': url, 'author': author, 'genre': genre, 'cover': cover, 'description': description, 'chapters': chapters, 'status': status, 'lastChapterNumber': lastChapterNumber, 'lastChapterAt': lastChapterAt, 'lastNotifiedChapterNumber': lastNotifiedChapterNumber, 'sourceKey': sourceKey, 'sourceName': sourceName, 'sourceLogo': sourceLogo, 'chapterItems': chapterItems.map((chapter) => chapter.toJson()).toList()};
  factory Manga.fromJson(Map<String, dynamic> json) => Manga(title: json['title'] as String? ?? '', url: json['url'] as String? ?? '', author: json['author'] as String? ?? '', genre: json['genre'] as String? ?? '', cover: json['cover'] as String? ?? '', description: json['description'] as String? ?? '', chapters: (json['chapters'] as num?)?.toInt() ?? 0, status: json['status'] as String? ?? 'Ongoing', sourceKey: json['sourceKey'] as String? ?? 'team_x', sourceName: json['sourceName'] as String? ?? 'Team X', sourceLogo: json['sourceLogo'] as String? ?? TeamXSource.teamXSourceLogo, lastChapterNumber: json['lastChapterNumber'] as String? ?? '', lastChapterAt: json['lastChapterAt'] as String? ?? '', lastNotifiedChapterNumber: json['lastNotifiedChapterNumber'] as String? ?? '', chapterItems: ((json['chapterItems'] as List?) ?? const []).whereType<Map>().map((item) => TeamXChapter.fromJson(Map<String, dynamic>.from(item))).toList());
}

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});
  @override State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  final allSources = <MangaSource>[TeamXSource(), AzoraSource(), ...additionalMangaSources];
  final _defaultMangaSourceKeys = {'team_x', 'azora_fly', 'manga_swat'};
  final enabledMangaKeys = <String>{};
  List<MangaSource> get sources => allSources.where((source) => enabledMangaKeys.contains(source.sourceKey)).toList();
  final downloads = DownloadManager();
  int index = 0;
  String query = '';
  List<Manga> manga = [];
  final favorites = <String>{};
  final history = <Manga>[];
  final library = <String, Manga>{};
  bool loading = true;
  bool searching = false;
  bool loadingMore = false;
  bool canLoadMore = true;
  int latestPage = 1;
  String? error;
  Timer? refreshTimer;
  MangaSource get _primarySource => sources.isNotEmpty ? sources.first : allSources.first;
  Manga _map(TeamXManga item, MangaSource source) => Manga.fromTeamX(item, sourceKey: source.sourceKey, sourceName: source.sourceName, sourceLogo: source.sourceLogo);
  MangaSource _sourceFor(Manga item) => allSources.firstWhere((source) => source.sourceKey == item.sourceKey, orElse: () => _primarySource);
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
    refreshTimer = Timer.periodic(const Duration(hours: 1), (_) { if (query.isEmpty) { _loadLatest(silent: true); _checkFavoriteUpdates(); } });
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKeys = prefs.getStringList('mangalord.enabled_manga_sources');
    final validSavedKeys = savedKeys?.where((key) => allSources.any((source) => source.sourceKey == key)).toSet();
    enabledMangaKeys
      ..clear()
      ..addAll(validSavedKeys == null || validSavedKeys.isEmpty ? _defaultMangaSourceKeys : validSavedKeys);
    await downloads.restore();
    await _restoreLibrary();
    if (mounted) _loadLatest();
  }

  Future<void> _setMangaSource(String key, bool enabled) async {
    setState(() { if (enabled) { enabledMangaKeys.add(key); } else if (enabledMangaKeys.length > 1) { enabledMangaKeys.remove(key); } });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('mangalord.enabled_manga_sources', enabledMangaKeys.toList());
    if (query.isEmpty) _loadLatest(); else _search(query);
  }

  @override
  void dispose() { refreshTimer?.cancel(); super.dispose(); }

  Future<void> _restoreLibrary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHistory = jsonDecode(prefs.getString('mangalord.history') ?? '[]') as List;
      final savedFavorites = jsonDecode(prefs.getString('mangalord.favorites') ?? '{}') as Map;
      if (!mounted) return;
      setState(() {
        history
          ..clear()
          ..addAll(savedHistory.whereType<Map>().map((item) => Manga.fromJson(Map<String, dynamic>.from(item))));
        library
          ..clear()
          ..addAll(savedFavorites.map((key, value) => MapEntry(key.toString(), Manga.fromJson(Map<String, dynamic>.from(value as Map)))));
        favorites
          ..clear()
          ..addAll(library.keys);
      });
      await _restoreCloudData();
    } catch (_) {
      // Corrupt or unavailable storage must not prevent the app from starting.
    }
  }

  Future<void> _restoreCloudData() async {
    if (AuthService.instance.currentUser == null) return;
    try {
      final cloudFavorites = await AuthService.instance.getCollection('favorites');
      final cloudHistory = await AuthService.instance.getCollection('history');
      if (!mounted) return;
      setState(() {
        for (final data in cloudFavorites) { final item = Manga.fromJson(data); if (item.url.isNotEmpty) { library[item.url] = item; favorites.add(item.url); } }
        for (final data in cloudHistory) { final item = Manga.fromJson(data); if (item.url.isNotEmpty) { history.removeWhere((entry) => entry.url == item.url); history.add(item); } }
      });
      await _saveLibrary();
    } catch (_) {}
  }

  Future<void> _syncFavoriteCloud(Manga item, bool value) async {
    if (AuthService.instance.currentUser == null) return;
    try { if (value) { await AuthService.instance.setFavorite(item.url, item.toJson()); } else { await AuthService.instance.removeFavorite(item.url); } } catch (_) {}
  }

  Future<void> _syncHistoryCloud(Manga item) async {
    if (AuthService.instance.currentUser == null) return;
    try { await AuthService.instance.setHistory(item.url, item.toJson()); } catch (_) {}
  }

  Future<void> _saveLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mangalord.history', jsonEncode(history.map((item) => item.toJson()).toList()));
    await prefs.setString('mangalord.favorites', jsonEncode(library.map((key, value) => MapEntry(key, value.toJson()))));
  }

  Future<void> _loadLatest({bool silent = false}) async {
    if (!silent && mounted) setState(() { loading = true; error = null; latestPage = 1; canLoadMore = true; });
    try {
      var failures = 0;
      final results = await Future.wait(sources.map((source) async {
        try {
          return await source.latest(page: 1);
        } catch (_) {
          failures++;
          return <TeamXManga>[];
        }
      }));
      final merged = <String, Manga>{};
      for (var i = 0; i < results.length; i++) {
        for (final item in results[i]) {
          merged[item.url] = _map(item, sources[i]);
        }
      }
      if (mounted) setState(() { manga = merged.values.toList(); loading = false; latestPage = 1; canLoadMore = manga.isNotEmpty; error = manga.isEmpty && failures == sources.length ? 'All manga sources failed to respond.' : null; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> _loadMore() async {
    if (loadingMore || !canLoadMore || query.isNotEmpty) return;
    setState(() => loadingMore = true);
    try {
      final results = await Future.wait(sources.map((source) async {
        try {
          return await source.latest(page: latestPage + 1);
        } catch (_) {
          return <TeamXManga>[];
        }
      }));
      if (mounted) setState(() {
        final existing = {for (final item in manga) item.url: item};
        for (var i = 0; i < results.length; i++) {
          for (final item in results[i]) existing[item.url] = _map(item, sources[i]);
        }
        manga = existing.values.toList();
        latestPage += 1;
        canLoadMore = results.any((result) => result.isNotEmpty);
        loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  Future<void> _checkFavoriteBaseline(Manga item) async {
    try {
      final source = _sourceFor(item);
      final fresh = await source.details(item.url);
      final newest = fresh.chapters.isEmpty ? '' : fresh.chapters.first.number;
      library[item.url] = _map(fresh, source).copyWith(lastNotifiedChapterNumber: newest, lastChapterNumber: item.lastChapterNumber, lastChapterAt: item.lastChapterAt);
      await _saveLibrary();
    } catch (_) {}
  }

  Future<void> _checkFavoriteUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('mangalord.notifications') ?? true)) return;
    for (final entry in library.entries.toList()) {
      final saved = entry.value;
      try {
        final source = _sourceFor(saved);
        final fresh = await source.details(saved.url);
        if (fresh.chapters.isEmpty) continue;
        final newest = fresh.chapters.first;
        if (saved.lastNotifiedChapterNumber.isNotEmpty && saved.lastNotifiedChapterNumber != newest.number) {
          await MangaNotificationService.instance.newChapter(mangaTitle: fresh.title, chapterNumber: newest.number, coverUrl: fresh.cover, referer: source.imageReferer);
        }
        library[entry.key] = _map(fresh, source).copyWith(lastNotifiedChapterNumber: newest.number, lastChapterNumber: saved.lastChapterNumber, lastChapterAt: saved.lastChapterAt);
        await _saveLibrary();
      } catch (_) {}
    }
  }

  Future<void> _search(String value) async {
    query = value.trim();
    final generation = ++_searchGeneration;
    if (query.isEmpty) return _loadLatest();
    setState(() { searching = true; error = null; });
    try {
      var failures = 0;
      final results = await Future.wait(sources.map((source) async {
        try {
          return await source.search(query);
        } catch (_) {
          failures++;
          return <TeamXManga>[];
        }
      }));
      final merged = <String, Manga>{};
      for (var i = 0; i < results.length; i++) {
        for (final item in results[i]) merged[item.url] = _map(item, sources[i]);
      }
      if (mounted && generation == _searchGeneration && query == value.trim()) setState(() { manga = merged.values.toList(); searching = false; error = manga.isEmpty && failures == sources.length ? 'All manga sources failed to respond.' : null; });
    } catch (e) {
      if (mounted && generation == _searchGeneration) setState(() { searching = false; error = e.toString(); });
    }
  }

  void openManga(Manga item) {
    history.removeWhere((entry) => entry.url == item.url);
    history.insert(0, item);
    unawaited(_saveLibrary());
    unawaited(_syncHistoryCloud(item));
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(source: _sourceFor(item), manga: item, isFavorite: favorites.contains(item.url), onFavorite: (value) { setState(() { if (value) { favorites.add(item.url); library[item.url] = item.copyWith(lastNotifiedChapterNumber: 'pending'); } else { favorites.remove(item.url); library.remove(item.url); } }); if (value) _checkFavoriteBaseline(item); unawaited(_syncFavoriteCloud(item, value)); unawaited(_saveLibrary()); }, downloads: downloads, onChapterOpened: (updated) { setState(() { history.removeWhere((entry) => entry.url == updated.url); history.insert(0, updated); if (library.containsKey(updated.url)) library[updated.url] = updated; }); unawaited(_saveLibrary()); unawaited(_syncHistoryCloud(updated)); })));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: [HomePage(items: manga, loading: loading, loadingMore: loadingMore, searching: searching, error: error, query: query, onQuery: _search, onRefresh: _loadLatest, onLoadMore: _loadMore, favorites: favorites, onOpen: openManga), const AnimeScreen(), HistoryPage(items: history, favorites: favorites, onOpen: openManga), SettingsPage(favorites: favorites, allItems: [...manga, ...history, ...library.values], downloads: downloads, onOpen: openManga, sourceForKey: (key) => allSources.firstWhere((source) => source.sourceKey == key, orElse: () => _primarySource), mangaSources: allSources, animeSources: enabledAnimeSources, onMangaSourceChanged: _setMangaSource)]),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: FloatingNavigation(index: index, onChanged: (value) => setState(() => index = value)))),
    );
  }
}

class FloatingNavigation extends StatelessWidget {
  const FloatingNavigation({required this.index, required this.onChanged, super.key});
  final int index;
  final ValueChanged<int> onChanged;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 8))]), child: Row(children: [NavItem(icon: Icons.menu_book_rounded, label: 'Manga', active: index == 0, onTap: () => onChanged(0)), NavItem(icon: Icons.movie_rounded, label: 'Anime', active: index == 1, onTap: () => onChanged(1)), NavItem(icon: Icons.history_rounded, label: 'History', active: index == 2, onTap: () => onChanged(2)), NavItem(icon: Icons.settings_rounded, label: 'Settings', active: index == 3, onTap: () => onChanged(3))]));
}
class NavItem extends StatelessWidget {
  const NavItem({required this.icon, required this.label, required this.active, required this.onTap, super.key});
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: AnimatedContainer(duration: const Duration(milliseconds: 220), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? accentGreen.withOpacity(.16) : Colors.transparent, borderRadius: BorderRadius.circular(18)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: active ? accentGreen : mutedText, size: 21), const SizedBox(height: 3), Text(label, style: TextStyle(color: active ? accentGreen : mutedText, fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500))]))));
}

class HomePage extends StatefulWidget {
  const HomePage({required this.items, required this.loading, required this.loadingMore, required this.searching, required this.error, required this.query, required this.onQuery, required this.onRefresh, required this.onLoadMore, required this.favorites, required this.onOpen, super.key});
  final List<Manga> items;
  final bool loading, loadingMore, searching;
  final String? error;
  final String query;
  final ValueChanged<String> onQuery;
  final Future<void> Function({bool silent}) onRefresh;
  final Future<void> Function() onLoadMore;
  final Set<String> favorites;
  final ValueChanged<Manga> onOpen;
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool requestedMore = false;
  @override Widget build(BuildContext context) {
    final slivers = <Widget>[SliverAppBar(pinned: true, expandedHeight: 112, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, flexibleSpace: const FlexibleSpaceBar(titlePadding: EdgeInsetsDirectional.only(start: 20, bottom: 16), title: Text('Manga', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800))), actions: [IconButton(onPressed: () => widget.onRefresh(), icon: const Icon(Icons.refresh))]), SliverPadding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), sliver: SliverToBoxAdapter(child: TextField(onSubmitted: widget.onQuery, textInputAction: TextInputAction.search, decoration: InputDecoration(hintText: 'Search manga...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: widget.searching ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null, filled: true, fillColor: Theme.of(context).colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))))), SliverPadding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 14), sliver: SliverToBoxAdapter(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(widget.query.isEmpty ? 'Latest' : 'Search results', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('${widget.items.length} titles', style: const TextStyle(color: mutedText, fontSize: 12))])))];
    if (widget.loading) { slivers.add(const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: accentGreen)))); }
    else if (widget.items.isEmpty) { slivers.add(SliverFillRemaining(hasScrollBody: false, child: StateCard(icon: widget.error == null ? Icons.search_off_rounded : Icons.cloud_off_rounded, title: widget.error == null ? 'No manga found' : 'Could not load manga', message: widget.error ?? 'Try another title or search again.'))); }
    else { slivers.add(SliverPadding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 28), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((context, i) => MangaCard(manga: widget.items[i], isFavorite: widget.favorites.contains(widget.items[i].url), onTap: () => widget.onOpen(widget.items[i])), childCount: widget.items.length), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 18, crossAxisSpacing: 10, childAspectRatio: .48)))); if (widget.loadingMore) slivers.add(const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: accentGreen))))); }
    return NotificationListener<ScrollNotification>(onNotification: (notification) { if (widget.query.isEmpty && notification.metrics.extentAfter < 700 && !requestedMore && !widget.loadingMore) { requestedMore = true; widget.onLoadMore().whenComplete(() { if (mounted) setState(() => requestedMore = false); }); } return false; }, child: RefreshIndicator(onRefresh: () => widget.onRefresh(), child: CustomScrollView(slivers: slivers)));
  }
}

class MangaCard extends StatelessWidget {
  const MangaCard({required this.manga, required this.isFavorite, required this.onTap, super.key});
  final Manga manga;
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Hero(tag: manga.url, child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            manga.cover,
            headers: _headersForManga(manga),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            cacheWidth: 720,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(color: deepGreen, child: const Icon(Icons.menu_book_rounded, color: accentGreen, size: 42)),
          ),
        ),
        if (isFavorite) Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.red.withOpacity(.72), shape: BoxShape.circle),
            child: const Icon(Icons.favorite, color: Colors.white, size: 17),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            width: 26,
            height: 26,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.black.withOpacity(.72), borderRadius: BorderRadius.circular(8)),
            child: Image.network(manga.sourceLogo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.language, color: Colors.white, size: 16)),
          ),
        ),
      ]))),
      const SizedBox(height: 9),
      Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 3),
      Text(manga.genre.isEmpty ? 'Manga' : manga.genre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: mutedText, fontSize: 12)),
    ]),
  );
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.items, required this.favorites, required this.onOpen, super.key}); final List<Manga> items; final Set<String> favorites; final ValueChanged<Manga> onOpen;
  @override Widget build(BuildContext context) => CustomScrollView(slivers: [SliverAppBar(pinned: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, title: const Text('Reading history', style: TextStyle(fontWeight: FontWeight.w800))), if (items.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: StateCard(icon: Icons.history_rounded, title: 'Your history is empty', message: 'Open a manga and your reading journey will appear here.')) else SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverList(delegate: SliverChildBuilderDelegate((context, i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: HistoryTile(manga: items[i], isFavorite: favorites.contains(items[i].url), onTap: () => onOpen(items[i]))), childCount: items.length))) ]);
}
class HistoryTile extends StatelessWidget {
  const HistoryTile({required this.manga, required this.isFavorite, required this.onTap, super.key}); final Manga manga; final bool isFavorite; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)), child: Row(children: [Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(manga.cover, headers: _headersForManga(manga), width: 64, height: 82, fit: BoxFit.cover, filterQuality: FilterQuality.high, cacheWidth: 256, errorBuilder: (_, __, ___) => Container(width: 64, height: 82, color: deepGreen))), if (isFavorite) Positioned(top: 5, right: 5, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red.withOpacity(.72), shape: BoxShape.circle), child: const Icon(Icons.favorite, color: Colors.white, size: 13))) ]), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(manga.lastChapterNumber.isEmpty ? '${manga.chapters} chapters' : 'Last opened: ${manga.lastChapterNumber}', style: const TextStyle(color: accentGreen, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(manga.lastChapterAt.isEmpty ? 'Opened recently' : manga.lastChapterAt, style: const TextStyle(color: mutedText, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: mutedText)])));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.favorites, required this.allItems, required this.downloads, required this.onOpen, required this.sourceForKey, required this.mangaSources, required this.animeSources, required this.onMangaSourceChanged, super.key});
  final Set<String> favorites;
  final List<Manga> allItems;
  final DownloadManager downloads;
  final ValueChanged<Manga> onOpen;
  final MangaSource Function(String) sourceForKey;
  final List<MangaSource> mangaSources;
  final List<AnimeSource> animeSources;
  final Future<void> Function(String key, bool enabled) onMangaSourceChanged;

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    SliverAppBar(pinned: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800))),
    SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverList(delegate: SliverChildListDelegate([
      const Text('Your library', style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      SettingTile(title: 'Account', subtitle: AuthService.instance.currentUser == null ? 'Sign in to sync your library' : 'Profile and account', icon: Icons.person_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuthService.instance.currentUser == null ? const LoginScreen() : const AccountScreen()))),
      SettingTile(title: 'Favorites', subtitle: '${favorites.length} saved manga', icon: Icons.favorite_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesPage(favorites: favorites, items: allItems, onOpen: onOpen)))),
      SettingTile(title: 'Storage', subtitle: 'Downloaded manga and offline chapters', icon: Icons.storage_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoragePage(manager: downloads, sourceForKey: sourceForKey)))),
      SettingTile(title: 'Downloads', subtitle: 'Offline reading queue', icon: Icons.download_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DownloadsPage(manager: downloads)))),
      const SizedBox(height: 18),
      const Text('Sources', style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      SettingTile(title: 'Manga sources', subtitle: '${mangaSources.length} available sources', icon: Icons.menu_book_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SourceSettingsPage(mangaSources: mangaSources, animeSources: const [], onMangaSourceChanged: onMangaSourceChanged)))),
      SettingTile(title: 'Anime sources', subtitle: '${animeSources.length} available sources', icon: Icons.movie_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SourceSettingsPage(mangaSources: const [], animeSources: animeSources, onMangaSourceChanged: onMangaSourceChanged)))),
      const SizedBox(height: 12),
      SettingTile(title: 'More', subtitle: 'Language, notifications and version', icon: Icons.tune_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoreSettingsPage()))),
    ]))),
  ]);
}

class SourceSettingsPage extends StatefulWidget {
  const SourceSettingsPage({required this.mangaSources, required this.animeSources, required this.onMangaSourceChanged, super.key});
  final List<MangaSource> mangaSources;
  final List<AnimeSource> animeSources;
  final Future<void> Function(String key, bool enabled) onMangaSourceChanged;
  @override State<SourceSettingsPage> createState() => _SourceSettingsPageState();
}

class _SourceSettingsPageState extends State<SourceSettingsPage> {
  final enabled = <String>{};
  bool get isManga => widget.mangaSources.isNotEmpty;
  List<dynamic> get items => isManga ? widget.mangaSources : widget.animeSources;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = isManga ? 'mangalord.enabled_manga_sources' : 'mangalord.enabled_anime_sources';
    final defaults = items.map<String>((item) => item.sourceKey as String).toSet().toList();
    final saved = prefs.getStringList(key)?.where((value) => defaults.contains(value)).toSet();
    enabled..clear()..addAll(saved == null || saved.isEmpty ? defaults : saved);
    if (mounted) setState(() {});
  }

  Future<void> _set(dynamic source, bool value) async {
    if (!value && enabled.length <= 1) return;
    setState(() { if (value) enabled.add(source.sourceKey); else enabled.remove(source.sourceKey); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(isManga ? 'mangalord.enabled_manga_sources' : 'mangalord.enabled_anime_sources', enabled.toList());
    if (isManga) await widget.onMangaSourceChanged(source.sourceKey, value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(isManga ? 'Manga sources' : 'Anime sources')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Text(isManga ? 'Choose which manga sources appear in search and latest updates.' : 'Choose which anime sources appear in Anime search.', style: const TextStyle(color: mutedText)),
      const SizedBox(height: 12),
      ...items.map((source) => Card(child: SwitchListTile(secondary: _logo(source.sourceLogo), value: enabled.contains(source.sourceKey), onChanged: (value) => _set(source, value), title: Text(source.sourceName), subtitle: Text(source.sourceKey)))),
    ]),
  );

  Widget _logo(String url) => SizedBox(width: 38, height: 38, child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.language)));
}

class MoreSettingsPage extends StatefulWidget {
  const MoreSettingsPage({super.key});
  @override State<MoreSettingsPage> createState() => _MoreSettingsPageState();
}

class _MoreSettingsPageState extends State<MoreSettingsPage> {
  String language = 'English';
  bool notifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { language = prefs.getString('mangalord.language') ?? 'English'; notifications = prefs.getBool('mangalord.notifications') ?? true; appLocale.value = language == 'العربية' ? const Locale('ar') : const Locale('en'); });
  }

  Future<void> _setLanguage(String value) async {
    setState(() { language = value; appLocale.value = value == 'العربية' ? const Locale('ar') : const Locale('en'); });
    await (await SharedPreferences.getInstance()).setString('mangalord.language', value);
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => notifications = value);
    await (await SharedPreferences.getInstance()).setBool('mangalord.notifications', value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('More')), body: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Language', style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w700)),
    const SizedBox(height: 10),
    Card(child: Column(children: [RadioListTile<String>(value: 'English', groupValue: language, title: const Text('English'), onChanged: (value) { if (value != null) _setLanguage(value); }), RadioListTile<String>(value: 'العربية', groupValue: language, title: const Text('العربية'), onChanged: (value) { if (value != null) _setLanguage(value); })])),
    const SizedBox(height: 22),
    const Text('Notifications', style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w700)),
    const SizedBox(height: 10),
    Card(child: SwitchListTile(value: notifications, onChanged: _setNotifications, title: const Text('Chapter notifications'), subtitle: const Text('Enable or disable update notifications'))),
    const SizedBox(height: 22),
    const Text('Application', style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w700)),
    const SizedBox(height: 10),
    Card(child: ListTile(leading: const Icon(Icons.info_outline, color: accentGreen), title: const Text('App version'), subtitle: Text(appVersion))),
  ]));
}

class SettingTile extends StatelessWidget { const SettingTile({required this.title, required this.subtitle, required this.icon, required this.onTap, super.key}); final String title, subtitle; final IconData icon; final VoidCallback onTap; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(icon, color: accentGreen), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: mutedText, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: mutedText)]))))); }

class DetailsPage extends StatefulWidget {
  const DetailsPage({required this.source, required this.manga, required this.isFavorite, required this.onFavorite, required this.onChapterOpened, required this.downloads, super.key});
  final MangaSource source;
  final Manga manga;
  final bool isFavorite;
  final ValueChanged<bool> onFavorite;
  final ValueChanged<Manga> onChapterOpened;
  final DownloadManager downloads;
  @override State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Manga manga;
  late bool favorite;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    manga = widget.manga;
    favorite = widget.isFavorite;
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await widget.source.details(manga.url);
      if (mounted) setState(() { manga = Manga.fromTeamX(data, sourceKey: widget.source.sourceKey, sourceName: widget.source.sourceName, sourceLogo: widget.source.sourceLogo); loading = false; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> _downloadChapter(TeamXChapter chapter) async {
    if (widget.downloads.isCompleted(chapter, manga.title, sourceKey: widget.source.sourceKey)) return;
    final loaded = await widget.source.chapter(chapter.url, mangaTitle: manga.title);
    await widget.downloads.enqueue(mangaTitle: manga.title, cover: manga.cover, chapter: loaded, sourceKey: widget.source.sourceKey, sourceName: widget.source.sourceName, sourceLogo: widget.source.sourceLogo, referer: widget.source.imageReferer);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading chapter ${chapter.number}')));
  }

  Future<TeamXChapter> _chapterForReading(TeamXChapter chapter) async {
    final local = await widget.downloads.localImagesFor(chapter, manga.title, sourceKey: widget.source.sourceKey);
    if (local.isNotEmpty) return TeamXChapter(id: chapter.id, number: chapter.number, title: chapter.title, publishedAt: chapter.publishedAt, url: chapter.url, images: local);
    return widget.source.chapter(chapter.url, mangaTitle: manga.title);
  }
  Future<void> _downloadAll() async { for (final chapter in manga.chapterItems) { await _downloadChapter(chapter); } }

  TeamXChapter? _nextChapter(TeamXChapter current) { for (final candidate in manga.chapterItems) { if (candidate.numberValue > current.numberValue) return candidate; } return null; }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(manga.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [IconButton(onPressed: () { setState(() => favorite = !favorite); widget.onFavorite(favorite); }, icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? Colors.redAccent : null))],
    ),
    body: RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: Hero(tag: manga.url, child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(manga.cover, headers: _headersForManga(manga), width: 220, height: 310, fit: BoxFit.contain, filterQuality: FilterQuality.high, cacheWidth: 880, errorBuilder: (_, __, ___) => Container(width: 220, height: 310, color: deepGreen, child: const Icon(Icons.menu_book_rounded, color: accentGreen, size: 48))),
        ))),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: manga.chapterItems.isEmpty ? null : () => _downloadAll(), icon: const Icon(Icons.download_rounded), label: const Text('Download all')),
        const SizedBox(height: 18),
        Text(manga.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        if (manga.author.isNotEmpty) ...[const SizedBox(height: 7), Text('by ${manga.author}', textAlign: TextAlign.center, style: const TextStyle(color: mutedText))],
        const SizedBox(height: 18),
        const Text('Synopsis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(manga.description.isEmpty ? 'No description available.' : manga.description, style: const TextStyle(color: mutedText, height: 1.6)),
        const SizedBox(height: 20),
        Text('${manga.chapters} chapters', style: const TextStyle(color: accentGreen, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        if (loading) const Center(child: CircularProgressIndicator(color: accentGreen))
        else if (error != null) StateCard(icon: Icons.error_outline, title: 'Could not load chapters', message: error!)
        else ...[const Text('Chapters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 12), ...manga.chapterItems.map((chapter) => ChapterTile(chapter: chapter, isLastOpened: chapter.number == manga.lastChapterNumber, isDownloaded: widget.downloads.isCompleted(chapter, manga.title, sourceKey: widget.source.sourceKey), onDownload: () => _downloadChapter(chapter), onTap: () async { final chapterForReader = await _chapterForReading(chapter); if (context.mounted) { final reading = manga.copyWith(lastChapterNumber: chapter.number, lastChapterAt: chapter.publishedAt); widget.onChapterOpened(reading); await Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(source: widget.source, downloads: widget.downloads, manga: reading, chapter: chapterForReader, chapters: manga.chapterItems, nextChapter: _nextChapter(chapter), onChapterOpened: widget.onChapterOpened))); }; }))],
      ]),
    ),
  );
}

class ChapterTile extends StatelessWidget {
  const ChapterTile({required this.chapter, required this.isLastOpened, required this.isDownloaded, required this.onDownload, required this.onTap, super.key});
  final TeamXChapter chapter;
  final bool isLastOpened;
  final bool isDownloaded;
  final VoidCallback onDownload;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(children: [
        const Icon(Icons.menu_book_outlined, color: accentGreen),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(chapter.number.isEmpty ? chapter.title : chapter.number, style: TextStyle(fontWeight: FontWeight.w800, color: isLastOpened ? Colors.redAccent : null)),
          if (chapter.publishedAt.isNotEmpty) ...[const SizedBox(height: 4), Text(chapter.publishedAt, style: const TextStyle(color: mutedText, fontSize: 12))],
        ])),
        AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: isDownloaded ? const Icon(Icons.check_circle_rounded, key: ValueKey('downloaded'), color: accentGreen) : IconButton(key: const ValueKey('download'), onPressed: onDownload, icon: const Icon(Icons.download_rounded, color: accentGreen))),
        const Icon(Icons.chevron_right_rounded, color: mutedText),
      ]),
    ))),
  );
}

class ReaderPage extends StatefulWidget {
  final MangaSource source;
  final DownloadManager downloads;
  const ReaderPage({required this.source, required this.downloads, required this.manga, required this.chapter, required this.chapters, required this.nextChapter, required this.onChapterOpened, super.key});
  final Manga manga;
  final TeamXChapter chapter;
  final List<TeamXChapter> chapters;
  final TeamXChapter? nextChapter;
  final ValueChanged<Manga> onChapterOpened;
  @override State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  String mode = 'webtoon';
  bool immersive = true;

  TeamXChapter? _nextAfter(TeamXChapter current) {
    for (final candidate in widget.chapters) {
      if (candidate.numberValue > current.numberValue) return candidate;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _setImmersive(true);
  }

  @override
  void dispose() {
    _setImmersive(false);
    super.dispose();
  }

  void _setImmersive(bool value) {
    immersive = value;
    SystemChrome.setEnabledSystemUIMode(value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  Future<void> _openNext() async {
    final next = widget.nextChapter;
    if (next == null) return;
    final local = await widget.downloads.localImagesFor(next, widget.manga.title, sourceKey: widget.source.sourceKey);
    final chapterForReader = local.isNotEmpty ? TeamXChapter(id: next.id, number: next.number, title: next.title, publishedAt: next.publishedAt, url: next.url, images: local) : await widget.source.chapter(next.url, mangaTitle: widget.manga.title);
    final updated = widget.manga.copyWith(lastChapterNumber: next.number, lastChapterAt: next.publishedAt);
    widget.onChapterOpened(updated);
    if (!mounted) return;
    await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReaderPage(source: widget.source, downloads: widget.downloads, manga: updated, chapter: chapterForReader, chapters: widget.chapters, nextChapter: _nextAfter(next), onChapterOpened: widget.onChapterOpened)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.chapter.images;
    final body = mode == 'webtoon'
      ? ListView.builder(itemCount: pages.length, itemBuilder: (_, i) => _pageImage(pages[i], fit: BoxFit.fitWidth))
      : PageView.builder(itemCount: pages.length, itemBuilder: (_, i) => InteractiveViewer(child: _pageImage(pages[i], fit: BoxFit.contain)));
    return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text('${widget.manga.title} • الفصل ${widget.chapter.number}'), actions: [if (widget.nextChapter != null) IconButton(tooltip: 'Next chapter', onPressed: _openNext, icon: const Icon(Icons.skip_next_rounded)), _readerActions()]), body: GestureDetector(onTap: () { setState(() => immersive = !immersive); _setImmersive(immersive); }, child: body));
  }

  Widget _pageImage(String path, {required BoxFit fit}) {
    final local = path.startsWith('/') || path.startsWith('file:');
    final image = local ? Image.file(File(path.replaceFirst('file://', '')), fit: fit, filterQuality: FilterQuality.high, gaplessPlayback: true) : Image.network(path, headers: _headersForManga(widget.manga), fit: fit, filterQuality: FilterQuality.high, gaplessPlayback: true);
    return image is Image ? image : image;
  }

  Widget _readerActions() => PopupMenuButton<String>(onSelected: (value) { if (value == 'fullscreen') { setState(() => immersive = !immersive); _setImmersive(immersive); } else { setState(() => mode = value); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'webtoon', child: Text('Webtoon')), PopupMenuItem(value: 'paged', child: Text('Paged')), PopupMenuItem(value: 'fullscreen', child: Text('Fullscreen'))]);
}
class FavoritesPage extends StatelessWidget { const FavoritesPage({required this.favorites, required this.items, required this.onOpen, super.key}); final Set<String> favorites; final List<Manga> items; final ValueChanged<Manga> onOpen; @override Widget build(BuildContext context) { final selected = <String, Manga>{for (final manga in items) if (favorites.contains(manga.url)) manga.url: manga}.values.toList(); return Scaffold(appBar: AppBar(title: const Text('Favorites')), body: GridView.builder(padding: const EdgeInsets.all(20), itemCount: selected.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 22, crossAxisSpacing: 16, childAspectRatio: .57), itemBuilder: (_, i) => MangaCard(manga: selected[i], isFavorite: true, onTap: () => onOpen(selected[i])))); } }
class DownloadsPage extends StatelessWidget {
  const DownloadsPage({required this.manager, super.key});
  final DownloadManager manager;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Downloads')), body: AnimatedBuilder(animation: manager, builder: (context, _) { if (manager.items.isEmpty) return const StateCard(icon: Icons.download_rounded, title: 'No downloads', message: 'Download chapters to read them offline.'); return ListView.builder(padding: const EdgeInsets.all(16), itemCount: manager.items.length, itemBuilder: (_, index) { final item = manager.items[index]; final percent = (item.progress * 100).round(); return Card(child: ListTile(leading: const Icon(Icons.menu_book_rounded, color: accentGreen), title: Text('${item.mangaTitle} • الفصل ${item.chapter.number}'), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 8), LinearProgressIndicator(value: item.progress), const SizedBox(height: 5), Text('${item.status.name} • $percent%')]), trailing: PopupMenuButton<String>(onSelected: (value) { if (value == 'pause') manager.pause(item.id); if (value == 'resume') manager.resume(item.id); if (value == 'delete') manager.remove(item.id); }, itemBuilder: (_) => [if (item.status == DownloadStatus.downloading) const PopupMenuItem(value: 'pause', child: Text('Pause')) else const PopupMenuItem(value: 'resume', child: Text('Resume')), const PopupMenuItem(value: 'delete', child: Text('Delete'))]))); }); }));
}

class StoragePage extends StatelessWidget {
  const StoragePage({required this.manager, required this.sourceForKey, super.key});
  final DownloadManager manager;
  final MangaSource Function(String) sourceForKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage')),
      body: AnimatedBuilder(
        animation: manager,
        builder: (context, _) {
          final completed = manager.items.where((item) => item.status == DownloadStatus.completed).toList();
          final groups = <String, List<DownloadItem>>{};
          for (final item in completed) groups.putIfAbsent('${item.sourceKey}:${item.mangaTitle}', () => []).add(item);
          if (groups.isEmpty) return const StateCard(icon: Icons.storage_rounded, title: 'Storage is empty', message: 'Downloaded chapters will appear here for offline reading.');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: groups.entries.map((entry) {
              final items = entry.value;
              final first = items.first;
              return Card(
                child: ExpansionTile(
                  leading: Image.network(first.cover, width: 48, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.menu_book_rounded)),
                  title: Text(first.mangaTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${items.length} downloaded chapters • ${first.sourceName}'),
                  children: items.map((item) => ListTile(
                    leading: const Icon(Icons.menu_book_outlined, color: accentGreen),
                    title: Text('Chapter ${item.chapter.number}'),
                    trailing: const Icon(Icons.play_circle_outline_rounded),
                    onTap: () async {
                      final images = await manager.localImagesFor(item.chapter, item.mangaTitle, sourceKey: item.sourceKey);
                      if (!context.mounted || images.isEmpty) return;
                      final source = sourceForKey(item.sourceKey);
                      final manga = Manga(title: item.mangaTitle, url: item.chapter.url, author: '', genre: '', cover: item.cover, description: '', chapters: 1, chapterItems: [item.chapter], sourceKey: item.sourceKey, sourceName: item.sourceName, sourceLogo: item.sourceLogo);
                      final chapter = TeamXChapter(id: item.chapter.id, number: item.chapter.number, title: item.chapter.title, publishedAt: item.chapter.publishedAt, url: item.chapter.url, images: images);
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(source: source, downloads: manager, manga: manga, chapter: chapter, chapters: [chapter], nextChapter: null, onChapterOpened: (_) {})));
                    },
                  )).toList(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class SimplePage extends StatelessWidget { const SimplePage({required this.title, required this.icon, required this.message, this.action, super.key}); final String title, message; final IconData icon; final String? action; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: StateCard(icon: icon, title: action ?? title, message: message)); }
class StateCard extends StatelessWidget { const StateCard({required this.icon, required this.title, required this.message, super.key}); final IconData icon; final String title, message; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: accentGreen, size: 48), const SizedBox(height: 18), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: mutedText, height: 1.5))]))); }
