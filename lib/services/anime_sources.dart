import 'anime_source.dart';

class Anime3rbSource extends HtmlAnimeSource {
  const Anime3rbSource();
  @override String get sourceKey => 'anime3rb';
  @override String get sourceName => 'Anime3rb';
  @override Uri get baseUri => Uri.parse('https://anime3rb.com');
  @override String get searchPath => '/titles/list';
  @override String get resultSelector => 'a[href*="/titles/"], .title-item, .anime-card';
  @override String get detailEpisodeSelector => 'a[href*="episode"], a[href*="watch"], .episode a';
}

class RistoAnimeSource extends HtmlAnimeSource {
  const RistoAnimeSource();
  @override String get sourceKey => 'risto_anime';
  @override String get sourceName => 'RistoAnime';
  @override Uri get baseUri => Uri.parse('https://ristoanime.me');
  @override String get searchPath => '/';
  @override String get resultSelector => 'a[href*="/series/"], .anime-card, .post';
  @override String get detailEpisodeSelector => 'a[href*="episode"], a[href*="watch"], .episodes a';
  @override Map<String, String> get defaultHeaders => const {'User-Agent': 'MangaLord/1.0', 'Referer': 'https://ristoanime.me/'};
}

class AnimePhoenixSource extends HtmlAnimeSource {
  const AnimePhoenixSource();
  @override String get sourceKey => 'anime_phoenix';
  @override String get sourceName => 'Anime Phoenix';
  @override Uri get baseUri => Uri.parse('https://anime-phoenix.com');
  @override String get searchPath => '/search/';
  @override String get resultSelector => 'a[href*="/animes/"], .anime-card, .post';
  @override String get detailEpisodeSelector => 'a[href*="episode"], a[href*="watch"], .episodes a';
}

const List<AnimeSource> enabledAnimeSources = <AnimeSource>[Anime3rbSource(), RistoAnimeSource(), AnimePhoenixSource()];

Future<List<AnimeTitle>> searchAllAnimeSources(String query, {int page = 1}) => isolateSourceFailures(enabledAnimeSources.map((source) => () => source.search(query, page: page)));

AnimeSource animeSourceByKey(String key) => enabledAnimeSources.firstWhere((source) => source.sourceKey == key, orElse: () => throw StateError('Unknown anime source: $key'));
