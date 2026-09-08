import 'dart:convert';

import 'package:html/parser.dart' as html_parser;

import 'anime_source.dart';
import 'content_models.dart';

class Anime3rbSource extends HtmlAnimeSource {
  const Anime3rbSource();
  @override String get sourceKey => 'anime3rb';
  @override String get sourceName => 'Anime3rb';
  @override Uri get baseUri => Uri.parse('https://anime3rb.com');
  @override String get searchPath => '/titles/list';
  @override String get resultSelector => '.search-results a.simple-title-card[href*="/titles/"], .title-card';
  @override String get detailEpisodeSelector => '.video-list a[href*="/episode/"]';
  @override Future<AnimeEpisode> episode(String url, {String? title}) async {
    final episodeBody = await get(url);
    final document = html_parser.parse(episodeBody);
    final servers = <AnimeServer>[];
    for (final element in document.querySelectorAll('[wire\\:snapshot]')) {
      final raw = htmlAttribute(element, 'wire:snapshot');
      try {
        final snapshot = jsonDecode(raw) as Map<String, dynamic>;
        final videoUrl = '${(snapshot['data'] as Map?)?['video_url'] ?? ''}';
        if (videoUrl.isEmpty) continue;
        final playerBody = await get(videoUrl, headers: {'Referer': url});
        final match = RegExp(r'video_sources\s*=\s*(\[[\s\S]*?\])').firstMatch(playerBody);
        if (match == null) continue;
        final values = jsonDecode(match.group(1)!) as List? ?? const [];
        for (final value in values.whereType<Map>()) {
          if (value['premium'] == true) continue;
          final stream = '${value['src'] ?? ''}';
          if (stream.isEmpty) continue;
          servers.add(AnimeServer(name: 'Anime3rb • ${value['label'] ?? value['res'] ?? 'Auto'}', url: stream, sourceKey: sourceKey, quality: '${value['label'] ?? value['res'] ?? ''}', headers: {'Referer': videoUrl, ...defaultHeaders}));
        }
      } catch (_) {}
    }
    if (servers.isEmpty) return parseEpisodeDocument(episodeBody, baseUri, url, title: title);
    return AnimeEpisode(id: stableSourceId(sourceKey, url), title: title ?? url, number: extractEpisodeNumber(title ?? url), url: url, sourceKey: sourceKey, servers: servers);
  }
}

class RistoAnimeSource extends HtmlAnimeSource {
  const RistoAnimeSource();
  @override String get sourceKey => 'risto_anime';
  @override String get sourceName => 'RistoAnime';
  @override Uri get baseUri => Uri.parse('https://ristoanime.me');
  @override String get searchPath => '/';
  @override String get resultSelector => '.SearchResultInner, .BlocksHolder .MovieItem';
  @override String get detailEpisodeSelector => '.EpisodesList > a[href]';
  @override Map<String, String> get defaultHeaders => const {'User-Agent': 'MangaLord/1.0', 'Referer': 'https://ristoanime.me/'};
  @override Future<List<AnimeTitle>> search(String query, {int page = 1}) async {
    if (page > 1) return const [];
    final body = await post('https://ristoanime.me/wp-content/themes/TopAnime/Ajaxt/Searching.php', {'search': Uri.encodeQueryComponent(query)}, headers: {'X-Requested-With': 'XMLHttpRequest', 'Referer': baseUri.toString()});
    final document = html_parser.parse(body);
    return document.querySelectorAll('.SearchResultInner').map((node) => parseTitle(node, baseUri)).where((item) => item.title.isNotEmpty && item.url.isNotEmpty).toList();
  }
  @override Future<AnimeEpisode> episode(String url, {String? title}) async {
    final watchUrl = '${url.replaceFirst(RegExp(r'/$'), '')}/watch';
    final document = html_parser.parse(await get(watchUrl));
    final servers = <AnimeServer>[];
    for (final element in document.querySelectorAll('#WatchList li[data-watch]')) {
      final embed = resolveSourceUrl(baseUri, htmlAttribute(element, 'data-watch'));
      if (embed.isEmpty) continue;
      final raw = await get(embed, headers: {'Referer': watchUrl});
      final stream = extractMediaUrl(raw, baseUri);
      if (stream.isNotEmpty) servers.add(AnimeServer(name: htmlText(element).isEmpty ? 'RistoAnime' : htmlText(element), url: stream, sourceKey: sourceKey, headers: {'Referer': embed, ...defaultHeaders}));
    }
    return AnimeEpisode(id: stableSourceId(sourceKey, url), title: title ?? url, number: extractEpisodeNumber(title ?? url), url: url, sourceKey: sourceKey, servers: servers);
  }
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
