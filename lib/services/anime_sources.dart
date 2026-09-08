import 'dart:convert';

import 'anime_source.dart';
import 'content_models.dart';

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
  @override Future<List<AnimeTitle>> search(String query, {int page = 1}) async {
    final searchPage = await get(baseUri.resolve('/search/').toString());
    final nonce = RegExp(r'''(?i)(?:nonce|security)["'\s:]+([a-zA-Z0-9_-]+)''').firstMatch(searchPage)?.group(1) ?? '';
    final ajax = RegExp(r'''(?i)(https?[^"']*admin-ajax\.php)''').firstMatch(searchPage)?.group(1) ?? baseUri.resolve('/wp-admin/admin-ajax.php').toString();
    if (nonce.isEmpty) return super.search(query, page: page);
    final body = await post(ajax, {'action': 'phoenix_search', 'nonce': nonce, 'q': query, 'type': 'tvshow', 'page': '$page', 'per_page': '20', 'dropdown': '0'}, headers: {'Referer': baseUri.resolve('/search/').toString()});
    final root = jsonDecode(body) as Map<String, dynamic>;
    final results = ((root['data'] as Map?)?['results'] as List?) ?? const [];
    return results.whereType<Map>().map((item) {
      final url = '${item['url'] ?? ''}'.trim();
      final fallback = '${item['slug'] ?? ''}'.trim();
      final publicUrl = url.isNotEmpty ? url : baseUri.resolve('/animes/$fallback').toString();
      final poster = '${item['thumbnail_url'] ?? ''}';
      return AnimeTitle(id: stableSourceId(sourceKey, publicUrl), title: '${item['title_ar'] ?? item['title'] ?? ''}'.trim(), url: publicUrl, sourceKey: sourceKey, sourceName: sourceName, poster: poster, cover: poster);
    }).where((item) => item.title.isNotEmpty && item.url.isNotEmpty).toList();
  }
}

const List<AnimeSource> enabledAnimeSources = <AnimeSource>[Anime3rbSource(), RistoAnimeSource(), AnimePhoenixSource()];

Future<List<AnimeTitle>> searchAllAnimeSources(String query, {int page = 1}) => isolateSourceFailures(enabledAnimeSources.map((source) => () => source.search(query, page: page)));

AnimeSource animeSourceByKey(String key) => enabledAnimeSources.firstWhere((source) => source.sourceKey == key, orElse: () => throw StateError('Unknown anime source: $key'));
