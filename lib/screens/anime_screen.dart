import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/anime_source.dart';
import '../services/anime_sources.dart';
import '../services/content_models.dart';

const accentGreen = Color(0xFF3DDC97);
const mutedText = Color(0xFF8FA39C);

class AnimeScreen extends StatefulWidget {
  const AnimeScreen({super.key});

  @override
  State<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends State<AnimeScreen> {
  final queryController = TextEditingController();
  List<AnimeTitle> results = const [];
  bool loading = false;
  String? error;
  String lastQuery = '';
  Timer? refreshTimer;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadLatest();
    refreshTimer = Timer.periodic(const Duration(hours: 1), (_) {
      if (lastQuery.isNotEmpty && !loading) search();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    queryController.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final query = queryController.text.trim();
    if (query.isEmpty) return _loadLatest();
    final generation = ++_requestGeneration;
    lastQuery = query;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await searchAllAnimeSources(query);
      if (mounted && generation == _requestGeneration && query == queryController.text.trim()) {
        setState(() {
          results = value;
          loading = false;
          error = value.isEmpty ? 'No results returned. Check Anime source switches and network access.' : null;
        });
      }
    } catch (e) {
      if (mounted && generation == _requestGeneration) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  Future<void> _loadLatest() async {
    final generation = ++_requestGeneration;
    if (mounted) setState(() { loading = true; error = null; lastQuery = ''; });
    try {
      final value = await latestAnimeFromAllSources();
      if (mounted && generation == _requestGeneration) setState(() { results = value; loading = false; error = value.isEmpty ? 'No latest anime is available.' : null; });
    } catch (e) {
      if (mounted && generation == _requestGeneration) setState(() { loading = false; error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anime')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: queryController,
              onSubmitted: (_) => search(),
              decoration: InputDecoration(
                hintText: 'Search anime...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: search,
                  icon: const Icon(Icons.search),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: results.isEmpty && !loading
                ? const Center(
                    child: Text(
                      'Search Anime3rb',
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: .58,
                    ),
                    itemCount: results.length,
                    itemBuilder: (_, i) => AnimeCard(item: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class AnimeCard extends StatelessWidget {
  const AnimeCard({required this.item, super.key});

  final AnimeTitle item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AnimeDetailsScreen(item: item)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.poster.isEmpty
                        ? const ColoredBox(color: Color(0xFF1E2A27), child: Icon(Icons.movie, size: 42))
                        : Image.network(item.poster, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1E2A27), child: Icon(Icons.broken_image, size: 42))),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(.72), borderRadius: BorderRadius.circular(8)),
                        child: item.sourceLogo.isEmpty ? const Icon(Icons.movie, color: Colors.white, size: 16) : Image.network(item.sourceLogo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.language, color: Colors.white, size: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(item.sourceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: mutedText, fontSize: 11)),
                    if (item.genres.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.genres.take(2).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: accentGreen, fontSize: 10)),
                    ],
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: mutedText)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimeDetailsScreen extends StatefulWidget {
  const AnimeDetailsScreen({required this.item, super.key});

  final AnimeTitle item;

  @override
  State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  late Future<AnimeTitle> details;

  @override
  void initState() {
    super.initState();
    details = animeSourceByKey(widget.item.sourceKey).details(widget.item.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.sourceName)),
      body: FutureBuilder<AnimeTitle>(
        future: details,
        builder: (context, snapshot) {
          final item = snapshot.data ?? widget.item;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Unable to load anime details.\n${snapshot.error}', textAlign: TextAlign.center)));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (item.poster.isNotEmpty)
                Center(
                  child: Image.network(
                    item.poster,
                    height: 260,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 12),
              Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
              if (item.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(item.description),
                ),
              const Divider(),
              ...item.episodes.map(
                (episode) => ListTile(
                  title: Text(episode.title),
                  subtitle: Text('Episode ${episode.number}'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimeEpisodeScreen(
                        sourceKey: item.sourceKey,
                        episode: episode,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AnimeEpisodeScreen extends StatefulWidget {
  const AnimeEpisodeScreen({required this.sourceKey, required this.episode, super.key});

  final String sourceKey;
  final AnimeEpisode episode;

  @override
  State<AnimeEpisodeScreen> createState() => _AnimeEpisodeScreenState();
}

class _AnimeEpisodeScreenState extends State<AnimeEpisodeScreen> {
  late Future<AnimeEpisode> loaded;

  @override
  void initState() {
    super.initState();
    loaded = animeSourceByKey(widget.sourceKey).episode(
      widget.episode.url,
      title: widget.episode.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.episode.title)),
      body: FutureBuilder<AnimeEpisode>(
        future: loaded,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Unable to load episode servers.\n${snapshot.error}', textAlign: TextAlign.center)));
            return const Center(child: CircularProgressIndicator());
          }
          final episode = snapshot.data!;
          if (episode.servers.isEmpty) {
            return const Center(child: Text('No playable server was found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Servers', style: Theme.of(context).textTheme.titleLarge),
              ...episode.servers.map(
                (server) => ListTile(
                  title: Text(server.name),
                  subtitle: Text(
                    server.quality.isEmpty ? server.url : server.quality,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimePlayerScreen(server: server),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AnimePlayerScreen extends StatefulWidget {
  const AnimePlayerScreen({required this.server, super.key});

  final AnimeServer server;

  @override
  State<AnimePlayerScreen> createState() => _AnimePlayerScreenState();
}

class _AnimePlayerScreenState extends State<AnimePlayerScreen> {
  VideoPlayerController? controller;
  Object? playerError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final value = VideoPlayerController.networkUrl(
      Uri.parse(widget.server.url),
      httpHeaders: widget.server.headers,
    );
    controller = value;
    try {
      await value.initialize();
      await value.play();
      if (mounted) setState(() {});
    } catch (error) {
      await value.dispose();
      if (mounted) setState(() => playerError = error);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = controller;
    return Scaffold(
      appBar: AppBar(title: Text(widget.server.name)),
      body: Center(
        child: playerError != null
            ? Padding(padding: const EdgeInsets.all(24), child: Text('Unable to play this server. Try another server.\n$playerError', textAlign: TextAlign.center))
            : value == null || !value.value.isInitialized
            ? const CircularProgressIndicator()
            : AspectRatio(
                aspectRatio: value.value.aspectRatio,
                child: VideoPlayer(value),
              ),
      ),
    );
  }
}
