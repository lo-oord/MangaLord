import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

import 'anime_source.dart';
import 'content_models.dart';

class Anime3rbSource extends HtmlAnimeSource {
  const Anime3rbSource();

  @override
  String get sourceKey => 'anime3rb';
  @override
  String get sourceName => 'Anime3rb';
  @override
  String get sourceLogo => 'https://anime3rb.com/favicon.ico';
  @override
  Uri get baseUri => Uri.parse('https://anime3rb.com');
  @override
  Map<String, String> get defaultHeaders => const {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/122.0 Mobile Safari/537.36',
        'Accept-Language': 'ar,en;q=0.8',
        'Referer': 'https://anime3rb.com/',
      };
  @override
  String get searchPath => '/titles/list';
  @override
  String get resultSelector => 'a[href*="/titles/"]';
  @override
  String get detailEpisodeSelector => 'a[href*="/episode/"]';

  bool _isTitleUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    return path.startsWith('/titles/') && path.split('/').where((part) => part.isNotEmpty).length == 2 && !path.endsWith('/list');
  }

  AnimeTitle _title(dynamic anchor) {
    final url = resolveSourceUrl(baseUri, htmlAttribute(anchor, 'href'));
    final image = firstImage(anchor, baseUri);
    return AnimeTitle(
      id: stableSourceId(sourceKey, url),
      title: firstNonEmpty([htmlText(anchor.querySelector('h2, h3, h4, .title-name')), htmlAttribute(anchor, 'title'), htmlText(anchor)]),
      url: url,
      sourceKey: sourceKey,
      sourceName: sourceName,
      sourceLogo: sourceLogo,
      poster: image,
      cover: image,
      description: htmlText(anchor.querySelector('.synopsis, .description, .summary')),
      genres: uniqueStrings(anchor.querySelectorAll('.genres a, .genre').map(htmlText)),
    );
  }

  Future<List<AnimeTitle>> _list(Uri uri) async {
    final document = html_parser.parse(await get(uri.toString()));
    final values = <String, AnimeTitle>{};
    for (final anchor in document.querySelectorAll(resultSelector)) {
      final item = _title(anchor);
      if (_isTitleUrl(item.url) && item.title.isNotEmpty) values[item.url] = item;
    }
    return values.values.toList();
  }

  @override
  Future<List<AnimeTitle>> search(String query, {int page = 1}) => _list(baseUri.resolve('/titles/list').replace(queryParameters: {'page': '$page', 'q': query.trim()}));

  @override
  Future<List<AnimeTitle>> latest({int page = 1}) => _list(baseUri.resolve('/titles/list').replace(queryParameters: {'page': '$page', 'sort_by': 'addition_date', 'sort_dir': 'desc'}));

  @override
  Future<AnimeTitle> details(String url) async {
    final document = html_parser.parse(await get(url));
    final poster = firstNonEmpty([metaContent(document, 'meta[property="og:image"]'), imageFromElement(document.querySelector('main img, article img, img'), baseUri)]);
    final episodes = <String, AnimeEpisode>{};
    for (final anchor in document.querySelectorAll(detailEpisodeSelector)) {
      final episodeUrl = resolveSourceUrl(baseUri, htmlAttribute(anchor, 'href'));
      if (!episodeUrl.contains('/episode/')) continue;
      final title = firstNonEmpty([htmlText(anchor.querySelector('h3, h4, .title, .episode-title')), htmlAttribute(anchor, 'title'), htmlText(anchor)]);
      episodes[episodeUrl] = AnimeEpisode(id: stableSourceId(sourceKey, episodeUrl), title: title, number: extractEpisodeNumber(title), url: episodeUrl, sourceKey: sourceKey, thumbnail: firstImage(anchor, baseUri));
    }
    return AnimeTitle(id: stableSourceId(sourceKey, url), title: cleanHtmlText(firstNonEmpty([metaContent(document, 'meta[property="og:title"]'), htmlText(document.querySelector('h1, h2')), document.querySelector('title')?.text ?? ''])), url: url, sourceKey: sourceKey, sourceName: sourceName, sourceLogo: sourceLogo, poster: poster, cover: poster, description: cleanHtmlText(firstNonEmpty([metaContent(document, 'meta[name="description"]'), htmlText(document.querySelector('.description, .story-description, .summary, [class*="description"]'))])), genres: uniqueStrings(document.querySelectorAll('a[href*="/genre/"], .genre, .genres a').map(htmlText)), episodes: episodes.values.toList());
  }

  @override
  Future<AnimeEpisode> episode(String url, {String? title}) async {
    final body = await get(url);
    final document = html_parser.parse(body);
    final servers = <AnimeServer>[];
    for (final anchor in document.querySelectorAll('a[href*="/download/"]')) {
      final stream = resolveSourceUrl(baseUri, htmlAttribute(anchor, 'href'));
      if (stream.isEmpty || servers.any((server) => server.url == stream)) continue;
      final label = htmlText(anchor);
      final quality = RegExp(r'(\d{3,4}p)', caseSensitive: false).firstMatch('$label $stream')?.group(1) ?? '';
      servers.add(AnimeServer(name: quality.isEmpty ? sourceName : '$sourceName • $quality', url: stream, sourceKey: sourceKey, quality: quality, type: 'video', headers: {...defaultHeaders, 'Referer': url}));
    }
    final fallback = parseEpisodeDocument(body, baseUri, url, title: title);
    for (final server in fallback.servers) {
      if (!servers.any((item) => item.url == server.url)) servers.add(server);
    }
    return AnimeEpisode(id: stableSourceId(sourceKey, url), title: title ?? cleanHtmlText(document.querySelector('h1, title')?.text ?? url), number: extractEpisodeNumber(title ?? url), url: url, sourceKey: sourceKey, servers: servers);
  }
}

class RistoAnimeSource extends HtmlAnimeSource {
  const RistoAnimeSource();

  @override
  String get sourceKey => 'risto_anime';
  @override
  String get sourceName => 'Resto Anime';
  @override
  String get sourceLogo => 'https://ristoanime.me/favicon.ico';
  @override
  Uri get baseUri => Uri.parse('https://ristoanime.me');
  @override
  Map<String, String> get defaultHeaders => const {'User-Agent': 'MangaLord/1.0', 'Referer': 'https://ristoanime.me/'};
  @override
  String get searchPath => '/';
  @override
  String get resultSelector => '.SearchResultInner, .BlocksHolder .MovieItem';
  @override
  String get detailEpisodeSelector => '.EpisodesList a[href], a[href*="الحلقة"], a[href*="episode"]';

  AnimeTitle _item(dynamic node) => parseTitle(node, baseUri);

  @override
  Future<List<AnimeTitle>> latest({int page = 1}) async {
    if (page > 1) return const [];
    final document = html_parser.parse(await get(baseUri.toString()));
    return document.querySelectorAll('.BlocksHolder .MovieItem, .MovieList .MovieItem, article, .post').map(_item).where((item) => item.title.isNotEmpty && item.url.isNotEmpty).toList();
  }

  @override
  Future<List<AnimeTitle>> search(String query, {int page = 1}) async {
    if (page > 1) return const [];
    final body = await post('https://ristoanime.me/wp-content/themes/TopAnime/Ajaxt/Searching.php', {'search': query.trim()}, headers: {'X-Requested-With': 'XMLHttpRequest', 'Referer': baseUri.toString()});
    final document = html_parser.parse(body);
    return document.querySelectorAll('.SearchResultInner, .BlocksHolder .MovieItem').map(_item).where((item) => item.title.isNotEmpty && item.url.isNotEmpty).toList();
  }

  @override
  Future<AnimeTitle> details(String url) async {
    final document = html_parser.parse(await get(url));
    final episodes = <String, AnimeEpisode>{};
    for (final anchor in document.querySelectorAll(detailEpisodeSelector)) {
      final episodeUrl = resolveSourceUrl(baseUri, htmlAttribute(anchor, 'href'));
      if (episodeUrl.isEmpty) continue;
      final title = firstNonEmpty([htmlText(anchor.querySelector('h3, h4, .title')), htmlAttribute(anchor, 'title'), htmlText(anchor)]);
      episodes[episodeUrl] = AnimeEpisode(id: stableSourceId(sourceKey, episodeUrl), title: title, number: extractEpisodeNumber(title), url: episodeUrl, sourceKey: sourceKey, thumbnail: firstImage(anchor, baseUri));
    }
    final title = cleanHtmlText(firstNonEmpty([metaContent(document, 'meta[property="og:title"]'), htmlText(document.querySelector('h1, h2')), document.querySelector('title')?.text ?? '']));
    final poster = firstNonEmpty([metaContent(document, 'meta[property="og:image"]'), imageFromElement(document.querySelector('img'), baseUri)]);
    return AnimeTitle(id: stableSourceId(sourceKey, url), title: title, url: url, sourceKey: sourceKey, sourceName: sourceName, sourceLogo: sourceLogo, poster: poster, cover: poster, description: metaContent(document, 'meta[name="description"]'), episodes: episodes.values.toList());
  }

  @override
  Future<AnimeEpisode> episode(String url, {String? title}) async {
    final document = html_parser.parse(await get(url));
    final servers = <AnimeServer>[];
    for (final node in document.querySelectorAll('[data-watch], iframe, video, source')) {
      final embed = resolveSourceUrl(baseUri, firstNonEmpty([htmlAttribute(node, 'data-watch'), htmlAttribute(node, 'data-url'), htmlAttribute(node, 'src')]));
      if (embed.isEmpty) continue;
      if (embed.contains('.m3u8') || embed.contains('.mp4')) {
        servers.add(AnimeServer(name: htmlText(node).isEmpty ? sourceName : htmlText(node), url: embed, sourceKey: sourceKey, type: embed.contains('.m3u8') ? 'hls' : 'video', headers: {...defaultHeaders, 'Referer': url}));
        continue;
      }
      try {
        final body = await get(embed, headers: {'Referer': url});
        for (final stream in extractMediaUrls(body, baseUri)) {
          if (!servers.any((item) => item.url == stream)) servers.add(AnimeServer(name: sourceName, url: stream, sourceKey: sourceKey, type: stream.contains('.m3u8') ? 'hls' : 'video', headers: {...defaultHeaders, 'Referer': embed}));
        }
      } catch (_) {}
    }
    final fallback = parseEpisodeDocument(await get(url), baseUri, url, title: title);
    for (final server in fallback.servers) {
      if (!servers.any((item) => item.url == server.url)) servers.add(server);
    }
    return AnimeEpisode(id: stableSourceId(sourceKey, url), title: title ?? url, number: extractEpisodeNumber(title ?? url), url: url, sourceKey: sourceKey, servers: servers);
  }
}

class AnimePhoenixSource extends HtmlAnimeSource {
  const AnimePhoenixSource();

  @override
  String get sourceKey => 'anime_phoenix';
  @override
  String get sourceName => 'Anime Phoenix';
  @override
  String get sourceLogo => 'https://anime-phoenix.com/favicon.ico';
  @override
  Uri get baseUri => Uri.parse('https://anime-phoenix.com');
  @override
  Map<String, String> get defaultHeaders => const {'User-Agent': 'MangaLord/1.0', 'Referer': 'https://anime-phoenix.com/'};
  @override
  String get searchPath => '/search/';
  @override
  String get resultSelector => 'a[href*="/animes/"], .anime-card, .post';
  @override
  String get detailEpisodeSelector => 'a[href*="episode"], a[href*="watch"], .episodes a';

  @override
  Future<List<AnimeTitle>> latest({int page = 1}) async {
    if (page > 1) return const [];
    final document = html_parser.parse(await get(baseUri.toString()));
    return document.querySelectorAll(resultSelector).map((node) => parseTitle(node, baseUri)).where((item) => item.title.isNotEmpty && item.url.isNotEmpty).toList();
  }

  @override
  Future<List<AnimeTitle>> search(String query, {int page = 1}) async {
    final document = html_parser.parse(await get(baseUri.resolve('/search/').replace(queryParameters: {'q': query, 'page': '$page'}).toString()));
    return document.querySelectorAll(resultSelector).map((node) => parseTitle(node, baseUri)).where((item) => item.title.isNotEmpty && item.url.isNotEmpty).toList();
  }

  @override
  Future<AnimeEpisode> episode(String url, {String? title}) async {
    final body = await get(url);
    final document = html_parser.parse(body);
    final servers = <AnimeServer>[];
    for (final node in document.querySelectorAll('iframe, video, source, [data-video], [data-url]')) {
      final candidate = resolveSourceUrl(baseUri, firstNonEmpty([htmlAttribute(node, 'data-video'), htmlAttribute(node, 'data-url'), htmlAttribute(node, 'src')]));
      if (candidate.isEmpty) continue;
      if (candidate.contains('.m3u8') || candidate.contains('.mp4')) {
        servers.add(AnimeServer(name: sourceName, url: candidate, sourceKey: sourceKey, type: candidate.contains('.m3u8') ? 'hls' : 'video', headers: {...defaultHeaders, 'Referer': url}));
      } else {
        try {
          for (final stream in extractMediaUrls(await get(candidate, headers: {'Referer': url}), baseUri)) {
            if (!servers.any((item) => item.url == stream)) servers.add(AnimeServer(name: sourceName, url: stream, sourceKey: sourceKey, type: stream.contains('.m3u8') ? 'hls' : 'video', headers: {...defaultHeaders, 'Referer': candidate}));
          }
        } catch (_) {}
      }
    }
    final fallback = parseEpisodeDocument(body, baseUri, url, title: title);
    for (final server in fallback.servers) {
      if (!servers.any((item) => item.url == server.url)) servers.add(server);
    }
    return AnimeEpisode(id: stableSourceId(sourceKey, url), title: title ?? cleanHtmlText(document.querySelector('h1, title')?.text ?? url), number: extractEpisodeNumber(title ?? url), url: url, sourceKey: sourceKey, servers: servers);
  }
}

const List<AnimeSource> enabledAnimeSources = <AnimeSource>[Anime3rbSource(), RistoAnimeSource(), AnimePhoenixSource()];

Future<List<AnimeSource>> _activeAnimeSources() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList('mangalord.enabled_anime_sources');
  if (saved == null || saved.isEmpty) return enabledAnimeSources;
  final keys = saved.toSet();
  final active = enabledAnimeSources.where((source) => keys.contains(source.sourceKey)).toList();
  return active.isEmpty ? enabledAnimeSources : active;
}

Future<List<AnimeTitle>> searchAllAnimeSources(String query, {int page = 1}) async {
  final sources = await _activeAnimeSources();
  final results = await isolateSourceFailures(sources.map((source) => () => source.search(query, page: page)));
  final bySourceAndUrl = <String, AnimeTitle>{};
  for (final item in results) bySourceAndUrl['${item.sourceKey}:${item.url}'] = item;
  return bySourceAndUrl.values.toList();
}

Future<List<AnimeTitle>> latestAnimeFromAllSources({int page = 1}) async {
  final sources = await _activeAnimeSources();
  final results = await isolateSourceFailures(sources.map((source) => () => source.latest(page: page)));
  final bySourceAndUrl = <String, AnimeTitle>{};
  for (final item in results) bySourceAndUrl['${item.sourceKey}:${item.url}'] = item;
  return bySourceAndUrl.values.toList();
}

AnimeSource animeSourceByKey(String key) => enabledAnimeSources.firstWhere((source) => source.sourceKey == key, orElse: () => throw StateError('Unknown anime source: $key'));
