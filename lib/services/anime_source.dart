import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'content_models.dart';

abstract class AnimeSource {
  const AnimeSource();
  String get sourceKey;
  String get sourceName;
  Uri get baseUri;
  Map<String, String> get defaultHeaders => const {'User-Agent': 'MangaLord/1.0'};

  Future<List<AnimeTitle>> search(String query, {int page = 1});
  Future<AnimeTitle> details(String url);
  Future<AnimeEpisode> episode(String url, {String? title});

  Future<String> get(String url, {Map<String, String>? headers}) async {
    final response = await http.get(Uri.parse(url), headers: {...defaultHeaders, ...?headers});
    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw SourceFailure(sourceKey, 'HTTP ${response.statusCode}');
    }
    return response.body;
  }

  Future<String> post(String url, Map<String, String> body, {Map<String, String>? headers}) async {
    final response = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/x-www-form-urlencoded', ...defaultHeaders, ...?headers}, body: body);
    if (response.statusCode < 200 || response.statusCode >= 400) throw SourceFailure(sourceKey, 'HTTP ${response.statusCode}');
    return response.body;
  }

  AnimeTitle parseTitle(dynamic node, Uri base, {String? forcedUrl}) {
    final anchor = node.matches('a') ? node : node.querySelector('a');
    final url = resolveSourceUrl(base, forcedUrl ?? htmlAttribute(anchor, 'href'));
    final image = firstImage(node, base);
    final title = firstNonEmpty([
      htmlAttribute(anchor, 'title'),
      htmlAttribute(anchor, 'data-title'),
      htmlText(anchor),
      htmlText(node),
    ]);
    return AnimeTitle(
      id: stableSourceId(sourceKey, url),
      title: title,
      url: url,
      sourceKey: sourceKey,
      sourceName: sourceName,
      poster: image,
      cover: image,
    );
  }

  AnimeEpisode parseEpisode(dynamic node, Uri base) {
    final anchor = node.matches('a') ? node : node.querySelector('a');
    final url = resolveSourceUrl(base, htmlAttribute(anchor, 'href'));
    final title = firstNonEmpty([htmlAttribute(anchor, 'title'), htmlText(anchor), htmlText(node)]);
    return AnimeEpisode(
      id: stableSourceId(sourceKey, url),
      title: title,
      number: extractEpisodeNumber(title),
      url: url,
      sourceKey: sourceKey,
    );
  }

  AnimeEpisode parseEpisodeDocument(String body, Uri base, String url, {String? title}) {
    final document = html_parser.parse(body);
    final text = '$body\n${document.body?.text ?? ''}';
    final servers = <AnimeServer>[];
    for (final element in document.querySelectorAll('[data-server], [data-video], iframe, video, source')) {
      final candidate = firstNonEmpty([
        htmlAttribute(element, 'data-video'),
        htmlAttribute(element, 'data-url'),
        htmlAttribute(element, 'src'),
        htmlAttribute(element, 'data-server'),
      ]);
      final media = extractMediaUrl(candidate, base);
      final resolved = media.isNotEmpty ? media : resolveSourceUrl(base, candidate);
      if (resolved.isNotEmpty && resolved != base.toString()) {
        servers.add(AnimeServer(
          name: firstNonEmpty([
            htmlAttribute(element, 'title'),
            htmlAttribute(element, 'data-server-name'),
            'Server ${servers.length + 1}',
          ]),
          url: resolved,
          sourceKey: sourceKey,
          quality: RegExp(r'(\d{3,4}p)', caseSensitive: false).firstMatch(resolved)?.group(1) ?? '',
          headers: {'Referer': url, ...defaultHeaders},
        ));
      }
    }
    final mediaFromScripts = extractMediaUrl(text, base);
    if (mediaFromScripts.isNotEmpty && !servers.any((server) => server.url == mediaFromScripts)) {
      servers.add(AnimeServer(
        name: sourceName,
        url: mediaFromScripts,
        sourceKey: sourceKey,
        headers: {'Referer': url, ...defaultHeaders},
      ));
    }
    return AnimeEpisode(
      id: stableSourceId(sourceKey, url),
      title: title ?? (document.querySelector('title')?.text.trim() ?? ''),
      number: extractEpisodeNumber(title ?? url),
      url: url,
      sourceKey: sourceKey,
      servers: servers,
    );
  }
}

abstract class HtmlAnimeSource extends AnimeSource {
  const HtmlAnimeSource();
  String get searchPath;
  String get resultSelector;
  String get detailEpisodeSelector;
  Uri searchUri(String query, int page) => baseUri.replace(
        path: searchPath,
        queryParameters: {'q': query, 'page': '$page'},
      );

  @override
  Future<List<AnimeTitle>> search(String query, {int page = 1}) async {
    final body = await get(searchUri(query, page).toString());
    final document = html_parser.parse(body);
    final byUrl = <String, AnimeTitle>{};
    for (final node in document.querySelectorAll(resultSelector)) {
      final item = parseTitle(node, baseUri);
      if (item.url.isNotEmpty && item.title.isNotEmpty) byUrl[item.url] = item;
    }
    return byUrl.values.toList();
  }

  @override
  Future<AnimeTitle> details(String url) async {
    final body = await get(url);
    final document = html_parser.parse(body);
    final title = firstNonEmpty([
      metaContent(document, 'meta[property="og:title"]'),
      document.querySelector('title')?.text ?? '',
    ]);
    final poster = firstNonEmpty([
      metaContent(document, 'meta[property="og:image"]'),
      imageFromElement(document.querySelector('img'), baseUri),
    ]);
    final description = firstNonEmpty([
      metaContent(document, 'meta[name="description"]'),
      htmlText(document.querySelector('.description, .story-description, .summary, [class*="description"]')),
    ]);
    final episodes = document.querySelectorAll(detailEpisodeSelector).map((node) => parseEpisode(node, baseUri)).where((item) => item.url.isNotEmpty).toList();
    return AnimeTitle(
      id: stableSourceId(sourceKey, url),
      title: cleanHtmlText(title),
      url: url,
      sourceKey: sourceKey,
      sourceName: sourceName,
      poster: poster,
      cover: poster,
      description: description,
      episodes: episodes,
    );
  }

  @override
  Future<AnimeEpisode> episode(String url, {String? title}) async =>
      parseEpisodeDocument(await get(url), baseUri, url, title: title);
}
