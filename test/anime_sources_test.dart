import 'package:flutter_test/flutter_test.dart';
import 'package:manga_lord/services/anime_models.dart';
import 'package:manga_lord/services/anime_source.dart';
import 'package:manga_lord/services/anime_sources.dart';
import 'package:manga_lord/services/video_extractor.dart';

void main() {
  test('registers the requested independent sources', () {
    expect(enabledAnimeSources.map((source) => source.sourceKey).toSet(), {'anime3rb', 'risto_anime', 'anime_phoenix'});
    expect(enabledAnimeSources.map((source) => source.sourceName).toSet(), {'Anime3rb', 'Resto Anime', 'Anime Phoenix'});
  });

  test('keeps the new normalized data contract', () {
    const anime = AnimeModel(id: 'id', title: 'Demo', url: 'https://example.test');
    const episode = EpisodeModel(id: 'episode', title: 'Episode 1', url: 'https://example.test/1', number: '1');
    const server = VideoServerModel(name: 'DoodStream', url: 'https://cdn.example.test/video.m3u8', type: 'hls', headers: {'Referer': 'https://example.test'});
    expect(anime.title, 'Demo');
    expect(episode.number, '1');
    expect(server.headers['Referer'], 'https://example.test');
  });

  test('extracts direct media URLs from HTML and scripts', () {
    final servers = VideoExtractor.extract('<script>var file="https://cdn.example.test/video.m3u8";</script>', Uri.parse('https://example.test'), 'Demo', 'https://example.test/episode', const {'User-Agent': 'MangaLord'});
    expect(servers.single.url, 'https://cdn.example.test/video.m3u8');
    expect(servers.single.headers['Referer'], 'https://example.test/episode');
  });

  test('isolates failed providers', () async {
    final values = await safeSourceCalls<int>([
      () async => [1, 2],
      () async => throw const SourceException('broken', 'offline'),
      () async => [3],
    ]);
    expect(values, [1, 2, 3]);
  });
}
