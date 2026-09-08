import 'package:flutter_test/flutter_test.dart';
import 'package:manga_lord/services/anime_sources.dart';
import 'package:manga_lord/services/content_models.dart';

void main() {
  test('registers the three requested independent anime sources', () {
    expect(enabledAnimeSources.map((source) => source.sourceKey).toSet(), {'anime3rb', 'risto_anime', 'anime_phoenix'});
    expect(enabledAnimeSources.map((source) => source.sourceKey).length, 3);
    expect(enabledAnimeSources.map((source) => source.sourceName).toSet(), {'Anime3rb', 'Resto Anime', 'Anime Phoenix'});
  });

  test('keeps source identity in normalized ids and media metadata', () {
    final id = stableSourceId('anime3rb', 'https://anime3rb.com/titles/demo');
    expect(id, startsWith('anime3rb:'));
    expect(extractEpisodeNumber('الحلقة 12'), '12');
    expect(extractMediaUrls('src="https://cdn.example.test/video.m3u8"', Uri.parse('https://anime3rb.com')), ['https://cdn.example.test/video.m3u8']);
  });

  test('isolates failed providers while preserving successful results', () async {
    final values = await isolateSourceFailures<int>([
      () async => [1, 2],
      () async => throw StateError('source unavailable'),
      () async => [3],
    ]);
    expect(values, [1, 2, 3]);
  });
}
