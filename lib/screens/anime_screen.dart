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
  List<AnimeModel> items = [];
  bool loading = false;
  String? error;
  int request = 0;

  @override
  void initState() {
    super.initState();
    if (widget.loadLatestOnStart) _loadLatest();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> _loadLatest() async {
    final token = ++request;
    setState(() { loading = true; error = null; });
    try {
      final value = await latestAnimeFromAllSources();
      if (!mounted || token != request) return;
      setState(() {
        items = value;
        loading = false;
        error = value.isEmpty ? 'No anime was returned. Check your connection or source availability.' : null;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = '$e'; });
    }
  }

  Future<void> _search() async {
    final value = query.text.trim();
    if (value.isEmpty) return _loadLatest();
    final token = ++request;
    setState(() { loading = true; error = null; });
    try {
      final result = await searchAllAnimeSources(value);
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
      body: Column(
        children: [
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
            child: items.isEmpty && !loading
                ? RefreshIndicator(onRefresh: _loadLatest, child: ListView(children: const [SizedBox(height: 240), Center(child: Text('No anime available'))]))
                : GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .62),
                    itemCount: items.length,
                    itemBuilder: (_, index) => _AnimeCard(item: items[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnimeCard extends StatelessWidget {
  const _AnimeCard({required this.item});
  final AnimeModel item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnimeDetailsScreen(item: item))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: item.cover.isEmpty
                  ? const ColoredBox(color: Color(0xFF1E2A27), child: Center(child: Icon(Icons.movie, size: 42)))
                  : Image.network(
                      item.cover,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFF1E2A27),
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
            ),
            Padding(padding: const EdgeInsets.all(10), child: Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
            if (item.sourceName.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 10), child: Text(item.sourceName, style: const TextStyle(fontSize: 11, color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}

class AnimeDetailsScreen extends StatefulWidget {
  const AnimeDetailsScreen({required this.item, super.key});
  final AnimeModel item;
  @override State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  late Future<AnimeModel> future;
  @override void initState() { super.initState(); future = animeSourceByKey(widget.item.sourceKey).getAnimeDetails(widget.item.url); }

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
              if (item.cover.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(item.cover, height: 260, fit: BoxFit.cover)),
              const SizedBox(height: 16),
              Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
              if (item.description.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(item.description)),
              Text('${item.episodes.length} episodes', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...item.episodes.map((episode) => ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(episode.title),
                    subtitle: Text(episode.number.isEmpty ? '' : 'Episode ${episode.number}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnimePlayerScreen(
                          iframeUrl: episode.url,
                          refererUrl: item.url,
                          episodeId: episode.id,
                          episodeTitle: episode.title,
                        ),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
