import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/starz_source.dart';

const accentGreen = Color(0xFF3DDC97);
const deepGreen = Color(0xFF113C32);
const mutedText = Color(0xFF8FA39C);

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});
  @override State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  final source = StarzSource();
  final searchController = TextEditingController();
  Timer? refreshTimer;
  List<StarzManga> mangas = [];
  List<StarzManga> history = [];
  Set<String> favorites = {};
  bool loading = true;
  bool searching = false;
  String? error;
  int tab = 0;
  String language = 'ar';
  String readerMode = 'webtoon';

  bool get isArabic => language == 'ar';
  String t(String ar, String en) => isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _load();
    refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) => _loadLatest(silent: true));
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    language = prefs.getString('language') ?? 'ar';
    readerMode = prefs.getString('reader_mode') ?? 'webtoon';
    favorites = (prefs.getStringList('favorites') ?? []).toSet();
    history = (prefs.getStringList('history') ?? []).map((e) => StarzManga.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
    if (mounted) setState(() {});
    await _loadLatest();
  }

  Future<void> _loadLatest({bool silent = false}) async {
    if (!silent && mounted) setState(() { loading = true; error = null; });
    try {
      final result = await source.latest();
      if (mounted) setState(() { mangas = result; loading = false; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  Future<void> _search(String value) async {
    if (value.trim().isEmpty) return _loadLatest();
    setState(() { searching = true; error = null; });
    try {
      final result = await source.search(value.trim());
      if (mounted) setState(() { mangas = result; searching = false; });
    } catch (e) {
      if (mounted) setState(() { searching = false; error = e.toString(); });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
    await prefs.setStringList('history', history.take(100).map((e) => jsonEncode(e.toJson())).toList());
    await prefs.setString('language', language);
    await prefs.setString('reader_mode', readerMode);
  }

  Future<void> _open(StarzManga manga) async {
    if (!history.any((e) => e.id == manga.id)) history.insert(0, manga);
    else { history.removeWhere((e) => e.id == manga.id); history.insert(0, manga); }
    await _save();
    if (!mounted) return;
    final full = await Navigator.push<StarzManga>(context, MaterialPageRoute(builder: (_) => MangaDetailsPage(source: source, manga: manga, isFavorite: favorites.contains(manga.id), language: language, readerMode: readerMode, onToggleFavorite: (id) async { setState(() { if (favorites.contains(id)) { favorites.remove(id); } else { favorites.add(id); } }); await _save(); })));
    if (full != null) {
      history.removeWhere((e) => e.id == full.id);
      history.insert(0, full);
      if (mounted) setState(() {});
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (tab) {
      0 => _home(),
      1 => _library(),
      _ => _more(),
    };
    return Scaffold(body: body, bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (value) => setState(() => tab = value), destinations: [NavigationDestination(icon: const Icon(Icons.explore_outlined), selectedIcon: const Icon(Icons.explore), label: t('اكتشاف', 'Discover')), NavigationDestination(icon: const Icon(Icons.favorite_border), selectedIcon: const Icon(Icons.favorite), label: t('مكتبتي', 'Library')), NavigationDestination(icon: const Icon(Icons.more_horiz), label: t('المزيد', 'More'))]));
  }

  Widget _home() => RefreshIndicator(onRefresh: _loadLatest, child: CustomScrollView(slivers: [SliverAppBar(pinned: true, expandedHeight: 116, title: Text(t('Manga Starz', 'Manga Starz'), style: const TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: _loadLatest, icon: const Icon(Icons.refresh))]), SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 8), child: TextField(controller: searchController, onSubmitted: _search, textInputAction: TextInputAction.search, decoration: InputDecoration(hintText: t('ابحث في Manga Starz...', 'Search Manga Starz...'), prefixIcon: const Icon(Icons.search), suffixIcon: searching ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(onPressed: () => _search(searchController.text), icon: const Icon(Icons.arrow_forward)), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))))), SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(searchController.text.isEmpty ? t('أحدث الفصول', 'Latest updates') : t('نتائج البحث', 'Search results'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('${mangas.length}', style: const TextStyle(color: mutedText))]))), if (loading) const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: accentGreen))) else if (error != null && mangas.isEmpty) SliverFillRemaining(child: _StateCard(icon: Icons.cloud_off, title: t('تعذر الاتصال بالمصدر', 'Source unavailable'), message: error!)) else if (mangas.isEmpty) SliverFillRemaining(child: _StateCard(icon: Icons.search_off, title: t('لا توجد نتائج', 'No results'), message: t('جرّب كلمة بحث أخرى.', 'Try a different search.'))) else SliverPadding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 24), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((_, i) => MangaCard(manga: mangas[i], language: language, onTap: () => _open(mangas[i])), childCount: mangas.length), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: .57))) ]));

  Widget _library() {
    final items = history.where((e) => favorites.contains(e.id)).toList();
    return CustomScrollView(slivers: [SliverAppBar(pinned: true, title: Text(t('مكتبتي', 'My library'), style: const TextStyle(fontWeight: FontWeight.w900))), SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(18), child: Text(t('المفضلات', 'Favorites'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))), if (items.isEmpty) SliverFillRemaining(child: _StateCard(icon: Icons.favorite_border, title: t('لا توجد مفضلات', 'No favorites yet'), message: t('أضف المانجا إلى مفضلاتك من صفحة التفاصيل.', 'Add manga to your favorites from its details page.'))) else SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 18), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((_, i) => MangaCard(manga: items[i], language: language, onTap: () => _open(items[i])), childCount: items.length), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: .57))), SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 28, 18, 10), child: Text(t('السجل', 'History'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))), if (history.isEmpty) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(18), child: Text(t('السجل فارغ.', 'History is empty.'), style: const TextStyle(color: mutedText)))) else SliverList(delegate: SliverChildBuilderDelegate((_, i) => ListTile(onTap: () => _open(history[i]), leading: _Cover(manga: history[i], size: const Size(46, 62)), title: Text(history[i].title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('${history[i].chapters.length} ${t('فصل', 'chapters')}'), trailing: const Icon(Icons.chevron_right),), childCount: history.length))]);
  }

  Widget _more() => ListView(padding: const EdgeInsets.fromLTRB(18, 55, 18, 24), children: [Text(t('المزيد', 'More'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 24), _SettingTile(icon: Icons.language, title: t('اللغة', 'Language'), subtitle: isArabic ? 'العربية' : 'English', onTap: _chooseLanguage), _SettingTile(icon: Icons.menu_book, title: t('نمط القارئ', 'Reader mode'), subtitle: _modeLabel(), onTap: _chooseReaderMode), _SettingTile(icon: Icons.sync, title: t('تحديث الفصول', 'Chapter updates'), subtitle: t('يتم التحديث تلقائيًا كل 10 دقائق أثناء تشغيل التطبيق', 'Automatically refreshed every 10 minutes while the app is open'), onTap: _loadLatest), _SettingTile(icon: Icons.source, title: t('مصدر المانجا', 'Manga source'), subtitle: StarzSource.sourceName, onTap: () => showAboutDialog(context: context, applicationName: StarzSource.sourceName, applicationVersion: '1.0.0')), _SettingTile(icon: Icons.info_outline, title: t('إصدار التطبيق', 'App version'), subtitle: 'MangaLord 0.0.22', onTap: () => showAboutDialog(context: context, applicationName: 'MangaLord', applicationVersion: '0.0.22')), _SettingTile(icon: Icons.delete_sweep, title: t('مسح السجل', 'Clear history'), subtitle: t('حذف سجل القراءة المحلي', 'Delete local reading history'), onTap: () async { history.clear(); await _save(); setState(() {}); }), const SizedBox(height: 20), Text(t('المصدر يعرض محتوى الموقع الأصلي وروابط صوره كما هي، وقد تتغير بنيته أو توفره.', 'The source displays content and image links from the original website and may change availability or structure.'), style: const TextStyle(color: mutedText, height: 1.5))]);

  String _modeLabel() => readerMode == 'webtoon' ? t('ويب تون عمودي', 'Vertical webtoon') : readerMode == 'gallery' ? t('معرض الصفحات', 'Page gallery') : t('صفحة بصفحة', 'Paged');
  Future<void> _chooseLanguage() async { final value = await showDialog<String>(context: context, builder: (_) => SimpleDialog(title: Text(t('اختر اللغة', 'Choose language')), children: [SimpleDialogOption(onPressed: () => Navigator.pop(context, 'ar'), child: const Text('العربية')), SimpleDialogOption(onPressed: () => Navigator.pop(context, 'en'), child: const Text('English'))])); if (value != null) { setState(() => language = value); await _save(); } }
  Future<void> _chooseReaderMode() async { final value = await showDialog<String>(context: context, builder: (_) => SimpleDialog(title: Text(t('نمط القارئ', 'Reader mode')), children: [SimpleDialogOption(onPressed: () => Navigator.pop(context, 'webtoon'), child: Text(t('ويب تون عمودي', 'Vertical webtoon'))), SimpleDialogOption(onPressed: () => Navigator.pop(context, 'gallery'), child: Text(t('معرض الصفحات', 'Page gallery'))), SimpleDialogOption(onPressed: () => Navigator.pop(context, 'paged'), child: Text(t('صفحة بصفحة', 'Paged')))])); if (value != null) { setState(() => readerMode = value); await _save(); } }
}

class MangaDetailsPage extends StatefulWidget { const MangaDetailsPage({required this.source, required this.manga, required this.isFavorite, required this.language, required this.readerMode, this.onToggleFavorite, super.key}); final StarzSource source; final StarzManga manga; final bool isFavorite; final String language, readerMode; final Future<void> Function(String id)? onToggleFavorite; @override State<MangaDetailsPage> createState() => _MangaDetailsPageState(); }
class _MangaDetailsPageState extends State<MangaDetailsPage> {
  late StarzManga manga; late bool favorite; bool loading = true; String? error;
  bool get ar => widget.language == 'ar'; String t(String a, String e) => ar ? a : e;
  @override void initState() { super.initState(); manga = widget.manga; favorite = widget.isFavorite; _fetch(); }
  Future<void> _fetch() async { try { final full = await widget.source.details(manga.url); if (mounted) setState(() { manga = full.copyWith(cover: full.cover.isEmpty ? manga.cover : full.cover); loading = false; }); } catch (e) { if (mounted) setState(() { loading = false; error = e.toString(); }); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(StarzSource.sourceName), actions: [IconButton(onPressed: () async { setState(() => favorite = !favorite); await widget.onToggleFavorite?.call(manga.id); }, icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? Colors.redAccent : null))]), body: RefreshIndicator(onRefresh: () async { setState(() => loading = true); await _fetch(); }, child: ListView(padding: const EdgeInsets.all(18), children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [_Cover(manga: manga, size: const Size(132, 190)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(manga.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(StarzSource.sourceName, style: const TextStyle(color: accentGreen, fontWeight: FontWeight.w700)), if (manga.author.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(manga.author, style: const TextStyle(color: mutedText))), if (manga.status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(manga.status, style: const TextStyle(color: mutedText))) ]))]), const SizedBox(height: 18), if (manga.genres.isNotEmpty) Text(manga.genres, style: const TextStyle(color: mutedText)), const SizedBox(height: 18), if (manga.description.isNotEmpty) Text(manga.description, style: const TextStyle(height: 1.55)), const SizedBox(height: 22), if (loading) const Center(child: CircularProgressIndicator(color: accentGreen)) else if (error != null) _StateCard(icon: Icons.error_outline, title: t('تعذر تحميل التفاصيل', 'Could not load details'), message: error!) else ...[Text('${t('الفصول', 'Chapters')} (${manga.chapters.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 10), ...manga.chapters.map((chapter) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.menu_book_outlined, color: accentGreen), title: Text(chapter.title), trailing: const Icon(Icons.chevron_right), onTap: () async { final loaded = await widget.source.chapter(chapter.url, mangaTitle: manga.title); if (context.mounted) await Navigator.push(context, MaterialPageRoute(builder: (_) => StarzReaderPage(source: widget.source, manga: manga, chapter: loaded, mode: widget.readerMode, language: widget.language))); }))]]))); }
}

class StarzReaderPage extends StatefulWidget { const StarzReaderPage({required this.source, required this.manga, required this.chapter, required this.mode, required this.language, super.key}); final StarzSource source; final StarzManga manga; final StarzChapter chapter; final String mode, language; @override State<StarzReaderPage> createState() => _StarzReaderPageState(); }
class _StarzReaderPageState extends State<StarzReaderPage> { late StarzChapter chapter; bool controls = true; late String mode; @override void initState() { super.initState(); chapter = widget.chapter; mode = widget.mode; }
  @override Widget build(BuildContext context) { final pages = chapter.images; final body = mode == 'webtoon' ? ListView.builder(itemCount: pages.length, itemBuilder: (_, i) => Image.network(pages[i], headers: const {'Referer': 'https://starzmanga.com/'}, fit: BoxFit.fitWidth, errorBuilder: (_, __, ___) => const SizedBox(height: 220, child: Center(child: Icon(Icons.broken_image, color: Colors.white54))))) : mode == 'gallery' ? GridView.builder(padding: const EdgeInsets.all(8), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 6, mainAxisSpacing: 6), itemCount: pages.length, itemBuilder: (_, i) => InteractiveViewer(child: Image.network(pages[i], headers: const {'Referer': 'https://starzmanga.com/'}, fit: BoxFit.cover))) : PageView.builder(itemCount: pages.length, itemBuilder: (_, i) => InteractiveViewer(child: Center(child: Image.network(pages[i], headers: const {'Referer': 'https://starzmanga.com/'}, fit: BoxFit.contain)))); return Scaffold(backgroundColor: Colors.black, appBar: controls ? AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text('${widget.manga.title} • ${chapter.title}', maxLines: 1, overflow: TextOverflow.ellipsis), actions: [PopupMenuButton<String>(onSelected: (v) => setState(() => mode = v), itemBuilder: (_) => [const PopupMenuItem(value: 'webtoon', child: Text('Webtoon')), const PopupMenuItem(value: 'gallery', child: Text('Gallery')), const PopupMenuItem(value: 'paged', child: Text('Paged'))])]) : null, body: GestureDetector(onTap: () => setState(() => controls = !controls), child: body)); }
}

class MangaCard extends StatelessWidget { const MangaCard({required this.manga, required this.language, required this.onTap, super.key}); final StarzManga manga; final String language; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_Cover(manga: manga, size: const Size.fromHeight(220)), const SizedBox(height: 8), Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(StarzSource.sourceName, style: const TextStyle(color: accentGreen, fontSize: 11))])); }
class _Cover extends StatelessWidget { const _Cover({required this.manga, required this.size}); final StarzManga manga; final Size size; @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(15), child: manga.cover.isEmpty ? Container(width: size.width > 0 ? size.width : double.infinity, height: size.height.isFinite ? size.height : null, color: deepGreen, child: const Icon(Icons.menu_book, color: accentGreen, size: 38)) : Image.network(manga.cover, width: size.width > 0 ? size.width : double.infinity, height: size.height.isFinite ? size.height : null, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: double.infinity, height: size.height, color: deepGreen, child: const Icon(Icons.broken_image, color: accentGreen)))); }
class _SettingTile extends StatelessWidget { const _SettingTile({required this.icon, required this.title, required this.subtitle, required this.onTap}); final IconData icon; final String title, subtitle; final VoidCallback onTap; @override Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, leading: Icon(icon, color: accentGreen), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right))); }
class _StateCard extends StatelessWidget { const _StateCard({required this.icon, required this.title, required this.message}); final IconData icon; final String title, message; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 48, color: accentGreen), const SizedBox(height: 14), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: mutedText, height: 1.5))]))); }
