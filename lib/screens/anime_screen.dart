import 'package:flutter/material.dart';

import '../services/anime_models.dart';
import '../services/anime_sources.dart';
import 'anime_player_screen.dart';

String _displayAnimeTitle(String value) {
  var title = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  for (final separator in ['##', ' | ', ' - مشاهدة', ' مشاهدة وتحميل']) {
    final index = title.indexOf(separator);
    if (index > 0) title = title.substring(0, index).trim();
  }
  return title;
}

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
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(.72), borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.network(source.sourceLogo, width: 18, height: 18, errorBuilder: (_, __, ___) => const Icon(Icons.public, size: 18, color: Colors.white)),
                    const SizedBox(width: 4),
                    Text(source.sourceName == 'Anime Phoenix' ? 'Phoenix' : source.sourceName, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(7, 7, 7, 2), child: Text(_displayAnimeTitle(item.title), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
          const SizedBox(height: 7),
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

class _RelatedAnime extends StatelessWidget {
  const _RelatedAnime({required this.future});
  final Future<List<AnimeModel>> future;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<AnimeModel>>(
        future: future,
        builder: (_, snapshot) {
          final items = snapshot.data ?? const <AnimeModel>[];
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 20),
            const Text('Related', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return SizedBox(width: 108, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: item.cover.isEmpty ? const _CoverFallback() : Image.network(item.cover, width: 108, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _CoverFallback()))),
                    const SizedBox(height: 6),
                    Text(_displayAnimeTitle(item.title), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ]));
                },
              ),
            ),
          ]);
        },
      );
}

class AnimeDetailsScreen extends StatefulWidget {
  const AnimeDetailsScreen({required this.item, super.key});
  final AnimeModel item;
  @override State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  late Future<AnimeModel> future;
  late Future<List<AnimeModel>> relatedFuture;
  @override void initState() { super.initState(); future = animeSourceByKey(widget.item.sourceKey).getAnimeDetails(widget.item.url); relatedFuture = _loadRelated(); }

  String _normalizeDigits(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final char in value.split('')) {
      final arabicIndex = arabic.indexOf(char);
      final persianIndex = persian.indexOf(char);
      if (arabicIndex >= 0) {
        buffer.write(arabicIndex);
      } else if (persianIndex >= 0) {
        buffer.write(persianIndex);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String? _episodeNumber(EpisodeModel episode) {
    final source = _normalizeDigits('${episode.number} ${episode.title}');
    return RegExp(r'\d+(?:\.\d+)?').firstMatch(source)?.group(0);
  }

  List<EpisodeModel> _displayEpisodes(List<EpisodeModel> episodes) {
    final numbered = <String, EpisodeModel>{};
    final unnumbered = <String, EpisodeModel>{};
    for (final episode in episodes) {
      final number = _episodeNumber(episode);
      if (number != null) {
        numbered.putIfAbsent(number, () => episode);
      } else {
        unnumbered.putIfAbsent(episode.url, () => episode);
      }
    }
    final result = numbered.values.toList()
      ..sort((a, b) => (double.tryParse(_episodeNumber(a) ?? '') ?? 0).compareTo(double.tryParse(_episodeNumber(b) ?? '') ?? 0));
    result.addAll(unnumbered.values);
    return result;
  }

  Future<List<AnimeModel>> _loadRelated() async {
    try {
      final results = await searchAllAnimeSources(_displayAnimeTitle(widget.item.title));
      final seen = <String>{};
      return results.where((item) => item.url != widget.item.url && seen.add('${item.sourceKey}:${item.url}')).take(12).toList();
    } catch (_) {
      return const [];
    }
  }

  String _displayEpisode(EpisodeModel episode) {
    final number = _episodeNumber(episode);
    return number == null ? episode.title.trim() : 'الحلقة $number';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_displayAnimeTitle(widget.item.title))),
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
              Text(_displayAnimeTitle(item.title), style: Theme.of(context).textTheme.headlineSmall),
              if (item.description.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(item.description)),
              _RelatedAnime(future: relatedFuture),
              Text('${item.episodes.length} episodes', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._displayEpisodes(item.episodes).map((episode) => ListTile(
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
