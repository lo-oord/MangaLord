import 'package:html/parser.dart' as html_parser;

import 'anime_source.dart';
import 'content_models.dart';

/// Anime3rb is intentionally the only enabled anime provider for now.
/// Additional providers can be added later as isolated adapters.
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
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/122.0 Mobile Safari/537.36',
        'Accept-Language': 'ar,en;q=0.8',
        'Referer': 'https://anime3rb.com/',
      };

  @override
  String get searchPath => '/titles/list';

  @override
  String get resultSelector => 'a[href*="/titles/"]';

  @override
  String get detailEpisodeSelector => 'a[href*="/episode/"]';

  bool _isAnimeTitleUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    return path.startsWith('/titles/') &&
        path.split('/').where((part) => part.isNotEmpty).length == 2 &&
        !path.endsWith('/list');
  }

  AnimeTitle _titleFromAnchor(dynamic anchor) {
    final url = resolveSourceUrl(baseUri, htmlAttribute(anchor, 'href'));
    final title = firstNonEmpty([
      htmlText(anchor.querySelector('h2, h3, h4, .title-name')),
      htmlAttribute(anchor, 'title'),
      htmlText(anchor),
    ]);
    final image = firstImage(anchor, baseUri);
    return AnimeTitle(
      id: stableSourceId(sourceKey, url),
      title: title,
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

  @override
  Future<List<AnimeTitle>> search(String query, {int page = 1}) async {
    final uri = baseUri.resolve('/titles/list').replace(queryParameters: {
      'page': '$page',
      'q': query.trim(),
    });
    final document = html_parser.parse(await get(uri.toString()));
    final results = <String, AnimeTitle>{};
    for (final anchor in document.querySelectorAll(resultSelector)) {
      final item = _titleFromAnchor(anchor);
      if (_isAnimeTitleUrl(item.url) && item.title.isNotEmpty) {
        results[item.url] = item;
      }
    }
    return results.values.toList();
  }

  @override
  Future<List<AnimeTitle>> latest({int page = 1}) async {
    final uri = baseUri.resolve('/titles/list').replace(queryParameters: {
      'page': '$page',
      'sort_by': 'addition_date',
      'sort_dir': 'desc',
    });
    final document = html_parser.parse(await get(uri.toString()));
    final results = <String, AnimeTitle>{};
    for (final anchor in document.querySelectorAll(resultSelector)) {
      final item = _titleFromAnchor(anchor);
      if (_isAnimeTitleUrl(item.url) && item.title.isNotEmpty) {
        results[item.url] = item;
      }
    }
    return results.values.toList();
  }

  @override
  Future<AnimeTitle> details(String url) async {
    final document = html_parser.parse(await get(url));
    final title = firstNonEmpty([
      metaContent(document, 'meta[property="og:title"]'),
      htmlText(document.querySelector('h1, h2')),
      document.querySelector('title')?.text ?? '',
    ]);
    final poster = firstNonEmpty([
      metaContent(document, 'meta[property="og:image"]'),
      imageFromElement(document.querySelector('main img, article img, img'), baseUri),
    ]);
    final description = firstNonEmpty([
      metaContent(document, 'meta[name="description"]'),
      htmlText(document.querySelector('.description, .story-description, .summary, [class*="description"]')),
    ]);
    final episodes = <String, AnimeEpisode>{};
    for (final anchor in document.querySelectorAll(detailEpisodeSelector)) {
      final episodeUrl = resolveSourceUrl(baseUri, htmlAttribute(anchor, 'href'));
      if (!episodeUrl.contains('/episode/')) continue;
      final episodeTitle = firstNonEmpty([
        htmlText(anchor.querySelector('h3, h4, .title, .episode-title')),
        htmlAttribute(anchor, 'title'),
        htmlText(anchor),
      ]);
      episodes[episodeUrl] = AnimeEpisode(
        id: stableSourceId(sourceKey, episodeUrl),
        title: episodeTitle,
        number: extractEpisodeNumber(episodeTitle),
        url: episodeUrl,
        sourceKey: sourceKey,
        thumbnail: firstImage(anchor, baseUri),
      );
    }
    return AnimeTitle(
      id: stableSourceId(sourceKey, url),
      title: cleanHtmlText(title),
      url: url,
      sourceKey: sourceKey,
      sourceName: sourceName,
      sourceLogo: sourceLogo,
      poster: poster,
      cover: poster,
      description: cleanHtmlText(description),
      genres: uniqueStrings(document.querySelectorAll('a[href*="/genre/"], .genre, .genres a').map(htmlText)),
      episodes: episodes.values.toList(),
    );
  }

  @override
  Future<AnimeEpisode> episode(String url, {String? title}) async {
    final body = await get(url);
    final document = html_parser.parse(body);
    final servers = <AnimeServer>[];

    // Anime3rb currently exposes signed direct MP4 download URLs on the episode
    // page. They are refreshed on every request and work with video_player.
    for (final anchor in document.querySelectorAll('a[href*="/download/"]')) {
      final downloadUrl = resolveSourceUrl(baseUri, htmlAttribute(anchor, 'href'));
      if (downloadUrl.isEmpty) continue;
      final label = htmlText(anchor);
      final quality = RegExp(r'(\d{3,4}p)', caseSensitive: false)
              .firstMatch('$label $downloadUrl')
              ?.group(1) ??
          '';
      if (servers.any((server) => server.url == downloadUrl)) continue;
      servers.add(AnimeServer(
        name: quality.isEmpty ? 'Anime3rb' : 'Anime3rb • $quality',
        url: downloadUrl,
        sourceKey: sourceKey,
        quality: quality,
        type: 'video',
        headers: {...defaultHeaders, 'Referer': url},
      ));
    }

    // Keep support for an embedded/player stream if Anime3rb changes its page.
    final fallback = parseEpisodeDocument(body, baseUri, url, title: title);
    for (final server in fallback.servers) {
      if (!servers.any((item) => item.url == server.url)) servers.add(server);
    }
    return AnimeEpisode(
      id: stableSourceId(sourceKey, url),
      title: title ?? cleanHtmlText(document.querySelector('h1, title')?.text ?? url),
      number: extractEpisodeNumber(title ?? url),
      url: url,
      sourceKey: sourceKey,
      servers: servers,
    );
  }
}

const List<AnimeSource> enabledAnimeSources = <AnimeSource>[Anime3rbSource()];

Future<List<AnimeTitle>> searchAllAnimeSources(String query, {int page = 1}) async {
  final results = await isolateSourceFailures(
    enabledAnimeSources.map((source) => () => source.search(query, page: page)),
  );
  final byUrl = <String, AnimeTitle>{};
  for (final item in results) byUrl['${item.sourceKey}:${item.url}'] = item;
  return byUrl.values.toList();
}

Future<List<AnimeTitle>> latestAnimeFromAllSources({int page = 1}) async {
  final results = await isolateSourceFailures(
    enabledAnimeSources.map((source) => () => source.latest(page: page)),
  );
  final byUrl = <String, AnimeTitle>{};
  for (final item in results) byUrl['${item.sourceKey}:${item.url}'] = item;
  return byUrl.values.toList();
}

AnimeSource animeSourceByKey(String key) => enabledAnimeSources.firstWhere(
      (source) => source.sourceKey == key,
      orElse: () => throw StateError('Unknown anime source: $key'),
    );
