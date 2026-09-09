import 'package:flutter/material.dart';

import '../services/anime_models.dart';
import '../services/anime_sources.dart';
import 'anime_player_screen.dart';

class AnimeScreen extends StatefulWidget {
  const AnimeScreen({this.loadLatestOnStart = true, super.key});
  final bool loadLatestOnStart;
  @override State<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends State<AnimeScreen> {
  final query = TextEditingController();
  final _scrollController = ScrollController();
  List<AnimeModel> items = [];
  bool loading = false;
  bool loadingMore = false;
  bool reachedEnd = false;
  String? error;
  int request = 0;
  int page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.loadLatestOnStart) _loadLatest();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    query.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 600 && !loading && !loadingMore && !reachedEnd && query.text.trim().isEmpty) {
      _loadNextPage();
    }
  }

  List<AnimeModel> _unique(List<AnimeModel> values) {
    final result = <String, AnimeModel>{};
    for (final item in values) {
      if (item.url.isEmpty || item.title.trim().isEmpty) continue;
      final key = item.sourceKey.isEmpty ? item.url : '${item.sourceKey}:${item.url}';
      result.putIfAbsent(key, () => item);
    }
    return result.values.toList();
  }

  Future<void> _loadLatest() async {
    final token = ++request;
    setState(() { loading = true; error = null; page = 1; reachedEnd = false; });
    try {
      final result = _unique(await latestAnimeFromAllSources(page: 1));
      if (!mounted || token != request) return;
      setState(() { items = result; loading = false; reachedEnd = result.isEmpty; error = result.isEmpty ? 'No anime was returned.' : null; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = '$e'; });
    }
  }

  Future<void> _loadNextPage() async {
    if (loadingMore || reachedEnd || query.text.trim().isNotEmpty) return;
    setState(() { loadingMore = true; error = null; });
    try {
      final result = _unique(await latestAnimeFromAllSources(page: page + 1));
      if (!mounted) return;
      final previousLength = items.length;
      final combined = _unique([...items, ...result]);
      setState(() {
        page++;
        items = combined;
        loadingMore = false;
        reachedEnd = result.isEmpty || combined.length == previousLength;
      });
    } catch (e) {
      if (mounted) setState(() { loadingMore = false; error = 'Unable to load more anime: $e'; });
    }
  }

  Future<void> _search() async {
    final value = query.text.trim();
    if (value.isEmpty) return _loadLatest();
    final token = ++request;
    setState(() { loading = true; error = null; reachedEnd = true; });
    try {
      final result = _unique(await searchAllAnimeSources(value));
      if (!mounted || token != request) return;
      setState(() { items = result; loading = false; error = result.isEmpty ? 'No results found.' : null; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = '$e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anime')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Search anime...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(onPressed: _search, icon: const Icon(Icons.search)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null) Padding(padding: const EdgeInsets.all(12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLatest,
            child: items.isEmpty && !loading
                ? ListView(children: const [SizedBox(height: 240), Center(child: Text('No anime available'))])
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 10, childAspectRatio: .65),
                    itemCount: items.length + (loadingMore ? 1 : 0),
                    itemBuilder: (_, index) => index == items.length ? const Center(child: CircularProgressIndicator(strokeWidth: 2)) : _AnimeCard(item: items[index]),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _AnimeCard extends StatelessWidget {
  const _AnimeCard({required this.item});
  final AnimeModel item;

  @override
  Widget build(BuildContext context) {
    final source = animeSourceByKey(item.sourceKey);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnimeDetailsScreen(item: item))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: item.cover.isEmpty ? const _CoverFallback() : Image.network(item.cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _CoverFallback())),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(.72), borderRadius: BorderRadius.circular(6)),
                  child: Image.network(source.sourceLogo, width: 18, height: 18, errorBuilder: (_, __, ___) => const Icon(Icons.public, size: 18, color: Colors.white)),
                ),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(7, 7, 7, 2), child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
          Padding(padding: const EdgeInsets.fromLTRB(7, 0, 7, 7), child: Text(item.sourceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey))),
        ]),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(color: Color(0xFF1E2A27), child: Center(child: Icon(Icons.movie, size: 42)));
}

class AnimeDetailsScreen extends StatefulWidget {
  const AnimeDetailsScreen({required this.item, super.key});
  final AnimeModel item;
  @override State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  late Future<AnimeModel> future;
  @override void initState() { super.initState(); future = animeSourceByKey(widget.item.sourceKey).getAnimeDetails(widget.item.url); }

  String _displayEpisode(EpisodeModel episode) {
    final number = episode.number.isNotEmpty ? episode.number : RegExp(r'\d+').firstMatch(episode.title)?.group(0);
    return number == null ? episode.title : 'الحلقة $number';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.title)),
      body: FutureBuilder<AnimeModel>(
        future: future,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Unable to load details: ${snapshot.error}'));
          final item = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (item.cover.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(item.cover, height: 260, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 260, child: _CoverFallback()))),
              const SizedBox(height: 16),
              Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
              if (item.description.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(item.description)),
              Text('${item.episodes.length} episodes', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...item.episodes.map((episode) => ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(_displayEpisode(episode)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnimePlayerScreen(iframeUrl: episode.url, refererUrl: episode.url, episodeId: episode.id, episodeTitle: episode.title))),
                  )),
            ],
          );
        },
      ),
    );
  }
}
