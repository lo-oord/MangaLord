import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/anime_source.dart';
import '../services/anime_sources.dart';
import '../services/content_models.dart';

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

  Future<void> search() async {
    final query = queryController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await searchAllAnimeSources(query);
      if (mounted) {
        setState(() {
          results = value;
          loading = false;
          error = value.isEmpty ? 'No results returned by the enabled Anime sources.' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
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
                      'Search Anime3rb, RistoAnime, or Anime Phoenix',
                    ),
                  )
                : ListView.builder(
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
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: ListTile(
        leading: item.poster.isEmpty
            ? const Icon(Icons.movie)
            : Image.network(
                item.poster,
                width: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.sourceName),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AnimeDetailsScreen(item: item)),
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
    await value.initialize();
    await value.play();
    if (mounted) setState(() {});
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
        child: value == null || !value.value.isInitialized
            ? const CircularProgressIndicator()
            : AspectRatio(
                aspectRatio: value.value.aspectRatio,
                child: VideoPlayer(value),
              ),
      ),
    );
  }
}
