import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'content_models.dart';

abstract class AnimeSource {
  const AnimeSource();
  String get sourceKey;
  String get sourceName;
  String get sourceLogo;
  Uri get baseUri;
  Map<String, String> get defaultHeaders => const {'User-Agent': 'MangaLord/1.0'};
  Duration get requestTimeout => const Duration(seconds: 20);
  int get maxRetries => 2;

  Future<List<AnimeTitle>> search(String query, {int page = 1});
  Future<AnimeTitle> details(String url);
  Future<AnimeEpisode> episode(String url, {String? title});
  Future<List<AnimeTitle>> latest({int page = 1}) async => const [];
  Future<List<String>> categories() async => const [];

  Future<String> get(String url, {Map<String, String>? headers}) async {
    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.get(Uri.parse(url), headers: {...defaultHeaders, ...?headers}).timeout(requestTimeout);
        if (response.statusCode >= 200 && response.statusCode < 400) return response.body;
        lastError = 'HTTP ${response.statusCode}';
      } catch (error) { lastError = error; }
      if (attempt < maxRetries) await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }
    throw SourceFailure(sourceKey, 'GET failed: $lastError');
  }

  Future<String> post(String url, Map<String, String> body, {Map<String, String>? headers}) async {
    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/x-www-form-urlencoded', ...defaultHeaders, ...?headers}, body: body).timeout(requestTimeout);
        if (response.statusCode >= 200 && response.statusCode < 400) return response.body;
        lastError = 'HTTP ${response.statusCode}';
      } catch (error) { lastError = error; }
      if (attempt < maxRetries) await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }
    throw SourceFailure(sourceKey, 'POST failed: $lastError');
  }

  AnimeTitle parseTitle(dynamic node, Uri base, {String? forcedUrl}) {
    final anchor = node.matches('a') ? node : node.querySelector('a');
    final url = resolveSourceUrl(base, forcedUrl ?? htmlAttribute(anchor, 'href'));
    final image = firstNonEmpty([firstImage(node, base), imageFromElement(node.querySelector('.poster, [data-style]'), base)]);
    final title = firstNonEmpty([htmlAttribute(anchor, 'title'), htmlAttribute(anchor, 'data-title'), htmlText(anchor), htmlText(node)]);
    final description = htmlText(node.querySelector('.synopsis, .description, .summary, [class*="description"]'));
    final genres = uniqueStrings(node.querySelectorAll('a[href*="/genre/"], .genre, .genres a').map(htmlText));
    return AnimeTitle(id: stableSourceId(sourceKey, url), title: title, url: url, sourceKey: sourceKey, sourceName: sourceName, sourceLogo: sourceLogo, poster: image, cover: image, description: description, genres: genres);
  }

  AnimeEpisode parseEpisode(dynamic node, Uri base) {
    final anchor = node.matches('a') ? node : node.querySelector('a');
    final url = resolveSourceUrl(base, htmlAttribute(anchor, 'href'));
    final title = firstNonEmpty([htmlAttribute(anchor, 'title'), htmlText(anchor), htmlText(node)]);
    return AnimeEpisode(id: stableSourceId(sourceKey, url), title: title, number: extractEpisodeNumber(title), url: url, sourceKey: sourceKey, thumbnail: firstImage(node, base));
  }

  AnimeEpisode parseEpisodeDocument(String body, Uri base, String url, {String? title}) {
    final document = html_parser.parse(body);
    final text = '$body\n${document.body?.text ?? ''}';
    final servers = <AnimeServer>[];
    for (final element in document.querySelectorAll('[data-server], [data-video], iframe, video, source')) {
      final candidate = firstNonEmpty([htmlAttribute(element, 'data-video'), htmlAttribute(element, 'data-url'), htmlAttribute(element, 'src'), htmlAttribute(element, 'data-server')]);
      final media = extractMediaUrl(candidate, base);
      final resolved = media.isNotEmpty ? media : resolveSourceUrl(base, candidate);
      if (resolved.isNotEmpty && resolved != base.toString()) {
        servers.add(AnimeServer(name: firstNonEmpty([htmlAttribute(element, 'title'), htmlAttribute(element, 'data-server-name'), 'Server ${servers.length + 1}']), url: resolved, sourceKey: sourceKey, quality: RegExp(r'(\d{3,4}p)', caseSensitive: false).firstMatch(resolved)?.group(1) ?? '', type: resolved.contains('.m3u8') ? 'hls' : 'video', headers: {'Referer': url, ...defaultHeaders}));
      }
    }
    final mediaFromScripts = extractMediaUrl(text, base);
    if (mediaFromScripts.isNotEmpty && !servers.any((server) => server.url == mediaFromScripts)) servers.add(AnimeServer(name: sourceName, url: mediaFromScripts, sourceKey: sourceKey, type: mediaFromScripts.contains('.m3u8') ? 'hls' : 'video', headers: {'Referer': url, ...defaultHeaders}));
    return AnimeEpisode(id: stableSourceId(sourceKey, url), title: title ?? (document.querySelector('title')?.text.trim() ?? ''), number: extractEpisodeNumber(title ?? url), url: url, sourceKey: sourceKey, servers: servers);
  }
}

abstract class HtmlAnimeSource extends AnimeSource {
  const HtmlAnimeSource();
  String get searchPath;
  String get resultSelector;
  String get detailEpisodeSelector;
  Uri searchUri(String query, int page) => baseUri.replace(path: searchPath, queryParameters: {'q': query, 'page': '$page'});

  @override
  Future<List<AnimeTitle>> search(String query, {int page = 1}) async {
    final document = html_parser.parse(await get(searchUri(query, page).toString()));
    final byUrl = <String, AnimeTitle>{};
    for (final node in document.querySelectorAll(resultSelector)) { final item = parseTitle(node, baseUri); if (item.url.isNotEmpty && item.title.isNotEmpty) byUrl[item.url] = item; }
    return byUrl.values.toList();
  }

  @override
  Future<AnimeTitle> details(String url) async {
    final document = html_parser.parse(await get(url));
    final title = firstNonEmpty([metaContent(document, 'meta[property="og:title"]'), document.querySelector('title')?.text ?? '']);
    final poster = firstNonEmpty([metaContent(document, 'meta[property="og:image"]'), imageFromElement(document.querySelector('img'), baseUri)]);
    final description = firstNonEmpty([metaContent(document, 'meta[name="description"]'), htmlText(document.querySelector('.description, .story-description, .summary, [class*="description"]'))]);
    final genres = uniqueStrings(document.querySelectorAll('a[href*="/genre/"], .genre, .genres a').map(htmlText));
    final status = firstNonEmpty([htmlText(document.querySelector('.status, .anime-status, [class*="status"]')), metaContent(document, 'meta[property="og:status"]')]);
    final year = firstNonEmpty([htmlText(document.querySelector('.year, .release-year, [class*="year"]')), metaContent(document, 'meta[property="anime:release_date"]')]);
    final episodesByUrl = <String, AnimeEpisode>{};
    for (final node in document.querySelectorAll(detailEpisodeSelector)) { final item = parseEpisode(node, baseUri); if (item.url.isNotEmpty) episodesByUrl[item.url] = item; }
    return AnimeTitle(id: stableSourceId(sourceKey, url), title: cleanHtmlText(title), url: url, sourceKey: sourceKey, sourceName: sourceName, sourceLogo: sourceLogo, poster: poster, cover: poster, description: description, genres: genres, status: status, year: year, episodes: episodesByUrl.values.toList());
  }

  @override
  Future<AnimeEpisode> episode(String url, {String? title}) async => parseEpisodeDocument(await get(url), baseUri, url, title: title);
}
