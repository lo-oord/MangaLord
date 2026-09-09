import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:shared_preferences/shared_preferences.dart';

import 'anime_models.dart';
import 'anime_source.dart';
import 'video_extractor.dart';

String _text(Element? e) => e?.text.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
String _attr(Element? e, String name) => e?.attributes[name]?.trim() ?? '';
String _absolute(Uri base, String value) {
  if (value.isEmpty) return '';
  if (value.startsWith('//')) return 'https:$value';
  final uri = Uri.tryParse(value);
  return uri?.isAbsolute == true ? value : base.resolve(value).toString();
}
String _decodeServerLink(String raw) {
  try {
    final padded = raw.padRight(raw.length + ((4 - raw.length % 4) % 4), '=');
    final decoded = utf8.decode(base64.decode(padded));
    final value = jsonDecode(Uri.decodeComponent(decoded));
    if (value is Map) {
      for (final key in ['link', 'url', 'src', 'file']) {
        final link = value[key]?.toString() ?? '';
        if (link.isNotEmpty) return link.replaceAll(r'\/', '/');
      }
    }
  } catch (_) {}
  return '';
}
bool _isDirectMedia(String value) {
  final lower = value.toLowerCase();
  return lower.contains('.m3u8') || lower.contains('.mp4');
}
String _image(Element node, Uri base) {
  final image = node.localName == 'img'
      ? node
      : node.querySelector('img') ?? node.parent?.querySelector('img');
  final style = node.querySelector('.poster, [data-style]');
  final rawStyle = _attr(style, 'data-style') + _attr(style, 'style');
  final match = RegExp(r'''url\((?:["']?)([^)"']+)''').firstMatch(rawStyle);
  final srcset = _attr(image, 'data-srcset').ifEmpty(_attr(image, 'srcset'));
  final firstSrcset = srcset.split(',').first.trim().split(RegExp(r'\s+')).first;
  final raw = match?.group(1) ??
      _attr(image, 'data-src')
          .ifEmpty(_attr(image, 'data-lazy-src'))
          .ifEmpty(_attr(image, 'data-original'))
          .ifEmpty(firstSrcset)
          .ifEmpty(_attr(image, 'src'));
  return _absolute(base, raw);
}
extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
String _normalizeDigits(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  return value.split('').map((char) {
    final a = arabic.indexOf(char);
    if (a >= 0) return '$a';
    final p = persian.indexOf(char);
    return p >= 0 ? '$p' : char;
  }).join();
}
String _episodeNumber(String value) {
  final normalized = _normalizeDigits(value);
  return RegExp(r'(?:episode|ep|الحلقة|حلقة)[^\d]*(\d+(?:\.\d+)?)', caseSensitive: false)
          .firstMatch(normalized)
          ?.group(1) ??
      RegExp(r'\d+(?:\.\d+)?').firstMatch(normalized)?.group(0) ??
      '';
}
String _id(String source, String url) => '$source:${Uri.tryParse(url)?.toString() ?? url}';
String _cleanTitle(String value) => value
    .replaceAll(RegExp(r'^(مشاهدة|انمي|مسلسلات انمي)\s*', caseSensitive: false), '')
    .replaceAll(RegExp(r'\s*(الحلقة|episode|ep)\s*\d+.*$', caseSensitive: false), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
String _episodeTitle(String rawTitle, String number) =>
    number.isEmpty ? _cleanTitle(rawTitle) : 'الحلقة $number';

abstract class _HtmlSource extends AnimeSource {
  const _HtmlSource();
  AnimeModel item(Element node) {
    final anchor = node.localName == 'a' ? node : node.querySelector('a');
    final url = _absolute(baseUrl, _attr(anchor, 'href'));
    final title = _cleanTitle(_attr(anchor, 'title').ifEmpty(
        _text(node.querySelector('.title h4, .title, h2, h3, h4')).ifEmpty(_text(anchor))));
    return AnimeModel(id: _id(sourceKey, url), title: title, url: url,
        cover: _image(node, baseUrl), sourceKey: sourceKey, sourceName: sourceName);
  }
  List<AnimeModel> parseCards(String body, String selector) {
    final result = <String, AnimeModel>{};
    for (final node in parser.parse(body).querySelectorAll(selector)) {
      final value = item(node);
      if (value.url.isNotEmpty && value.title.isNotEmpty) result[value.url] = value;
    }
    return result.values.toList();
  }
  EpisodeModel? episodeFrom(Element node) {
    final anchor = node.localName == 'a' ? node : node.querySelector('a');
    final url = _absolute(baseUrl, _attr(anchor, 'href'));
    final rawTitle = _text(anchor).ifEmpty(_attr(anchor, 'title'));
    final number = _episodeNumber(rawTitle);
    if (url.isEmpty || number.isEmpty) return null;
    return EpisodeModel(id: _id(sourceKey, url), title: _episodeTitle(rawTitle, number),
        url: url, number: number, sourceKey: sourceKey, thumbnail: _image(node, baseUrl));
  }
  void addEpisodes(Document doc, Map<String, EpisodeModel> output, String selector) {
    for (final node in doc.querySelectorAll(selector)) {
      final episode = episodeFrom(node);
      if (episode != null) output[episode.url] = episode;
    }
  }
  List<EpisodeModel> sortedEpisodes(Iterable<EpisodeModel> values) {
    final result = values.toList();
    result.sort((a, b) {
      final byNumber = (double.tryParse(a.number) ?? 0).compareTo(double.tryParse(b.number) ?? 0);
      return byNumber != 0 ? byNumber : a.url.compareTo(b.url);
    });
    return result;
  }
  @override
  Future<AnimeModel> getAnimeDetails(String animeUrl) async {
    final doc = parser.parse(await getHtml(animeUrl));
    final episodesByUrl = <String, EpisodeModel>{};
    addEpisodes(doc, episodesByUrl, 'a[href*="episode"], a[href*="episodes/"], a[href*="الحلقة"], .episodes a, .EpisodesList a, .Episode a, a[href*="/watch/"]');
    final title = _text(doc.querySelector('h1, .anime-title, .FJ-Phoenix-Anastasia-Title, title')).ifEmpty(_attr(doc.querySelector('meta[property="og:title"]'), 'content'));
    final cover = _attr(doc.querySelector('meta[property="og:image"]'), 'content').ifEmpty(_attr(doc.querySelector('img[alt], .poster img, .FJ-Phoenix-Anastasia-Hero-Img'), 'src')).ifEmpty(_image(doc.querySelector('main, body') ?? doc.documentElement!, baseUrl));
    final description = _attr(doc.querySelector('meta[name="description"]'), 'content').ifEmpty(_text(doc.querySelector('.description, .summary, .story-description')));
    return AnimeModel(id: _id(sourceKey, animeUrl), title: _cleanTitle(title), url: animeUrl,
        cover: _absolute(baseUrl, cover), description: description, sourceKey: sourceKey,
        sourceName: sourceName, episodes: sortedEpisodes(episodesByUrl.values));
  }
  @override
  Future<List<VideoServerModel>> getVideoExtractors(String episodeUrl) async {
    final body = await getHtml(episodeUrl, headers: {'Referer': baseUrl.toString()});
    final pages = <String>{episodeUrl};
    final servers = <String, VideoServerModel>{};
    final document = parser.parse(body);
    for (final node in document.querySelectorAll('iframe[src], [data-server], [data-video], [data-url], [data-watch], a.FJ-DL-Server-Btn[href], a[data-server-hash][href]')) {
      final value = _decodeServerLink(_attr(node, 'data-server')).ifEmpty(_attr(node, 'src')).ifEmpty(_attr(node, 'data-video')).ifEmpty(_attr(node, 'data-url')).ifEmpty(_attr(node, 'data-watch')).ifEmpty(_attr(node, 'href'));
      final resolved = _absolute(baseUrl, value);
      if (resolved.isEmpty) continue;
      if (_isDirectMedia(resolved)) {
        servers[resolved] = VideoServerModel(name: sourceName, url: resolved, type: resolved.toLowerCase().contains('.m3u8') ? 'hls' : 'mp4', headers: {...defaultHeaders, 'Referer': episodeUrl});
      } else {
        pages.add(resolved);
      }
    }
    for (final page in pages) {
      if (page != episodeUrl) servers.putIfAbsent(page, () => VideoServerModel(name: '$sourceName • WebView', url: page, type: 'iframe', headers: {...defaultHeaders, 'Referer': episodeUrl}));
      try {
        final pageBody = page == episodeUrl ? body : await getHtml(page, headers: {'Referer': episodeUrl});
        for (final server in VideoExtractor.extract(pageBody, baseUrl, sourceName, page == episodeUrl ? episodeUrl : page, {...defaultHeaders, 'Referer': episodeUrl})) servers[server.url] = server;
      } catch (_) {}
    }
    if (servers.isEmpty) servers[episodeUrl] = VideoServerModel(name: '$sourceName • WebView', url: episodeUrl, type: 'webview', headers: {...defaultHeaders, 'Referer': baseUrl.toString()});
    return servers.values.toList();
  }
}

class Anime3rbSource extends _HtmlSource {
  const Anime3rbSource();
  @override String get sourceKey => 'anime3rb';
  @override String get sourceName => 'Anime3rb';
  @override String get sourceLogo => 'https://anime3rb.com/favicon.ico';
  @override Uri get baseUrl => Uri.parse('https://anime3rb.com');
  List<AnimeModel> _filtered(String body) => parseCards(body, 'a[href*="/titles/"]').where((item) { final path = Uri.tryParse(item.url)?.path ?? ''; return path.startsWith('/titles/') && path.split('/').where((part) => part.isNotEmpty).length == 2 && !path.contains('/list'); }).toList();
  @override Future<List<AnimeModel>> fetchLatestAnime(int page) async => _filtered(await getHtml(baseUrl.resolve('/titles/list?page=$page').toString()));
  @override Future<List<AnimeModel>> searchAnime(String query, int page) async => _filtered(await getHtml(baseUrl.resolve('/titles/list').replace(queryParameters: {'q': query, 'page': '$page'}).toString()));
}

class RestoAnimeSource extends _HtmlSource {
  const RestoAnimeSource();
  @override String get sourceKey => 'risto_anime';
  @override String get sourceName => 'Resto Anime';
  @override String get sourceLogo => 'https://ristoanime.me/favicon.ico';
  @override Uri get baseUrl => Uri.parse('https://ristoanime.me/');
  @override Future<List<AnimeModel>> fetchLatestAnime(int page) async => parseCards(await getHtml(page == 1 ? baseUrl.toString() : '${baseUrl}page/$page/'), '.BlocksHolder .MovieItem');
  @override Future<List<AnimeModel>> searchAnime(String query, int page) async => parseCards(await getHtml(baseUrl.replace(queryParameters: {'s': query, 'paged': '$page'}).toString()), '.SearchResultInner, .MovieItem');
  String _watchUrl(String url) {
    final normalized = url.replaceFirst(RegExp(r'/+$'), '');
    return normalized.endsWith('/watch') ? normalized : '$normalized/watch';
  }
  @override Future<AnimeModel> getAnimeDetails(String animeUrl) async {
    final current = await super.getAnimeDetails(animeUrl);
    final collected = <String, EpisodeModel>{
      for (final e in current.episodes)
        _watchUrl(e.url): EpisodeModel(id: e.id, title: e.title, url: _watchUrl(e.url), number: e.number, sourceKey: e.sourceKey, thumbnail: e.thumbnail),
    };
    final title = _cleanTitle(current.title);
    // Resto publishes episodes as separate MovieItem pages. Follow all search
    // pagination pages until a page contributes no new matching episode.
    for (var page = 1; page <= 50; page++) {
      try {
        final body = await getHtml(baseUrl.replace(queryParameters: {'s': title, 'paged': '$page'}).toString());
        var added = 0;
        for (final node in parser.parse(body).querySelectorAll('.SearchResultInner .MovieItem, .MovieItem')) {
          final anchor = node.querySelector('a');
          final url = _absolute(baseUrl, _attr(anchor, 'href'));
          final raw = _text(node.querySelector('.title h4, .title')).ifEmpty(_text(anchor));
          final number = _episodeNumber(raw);
          if (url.isNotEmpty && number.isNotEmpty && !collected.containsKey(url)) {
            final watchUrl = _watchUrl(url);
            collected[watchUrl] = EpisodeModel(id: _id(sourceKey, watchUrl), title: _episodeTitle(raw, number), url: watchUrl, number: number, sourceKey: sourceKey, thumbnail: _image(node, baseUrl));
            added++;
          }
        }
        if (added == 0 && page > 1) break;
      } catch (_) { break; }
    }
    return current.copyWith(episodes: sortedEpisodes(collected.values));
  }
}

class AnimePhoenixSource extends _HtmlSource {
  const AnimePhoenixSource();
  @override String get sourceKey => 'anime_phoenix';
  @override String get sourceName => 'Anime Phoenix';
  @override String get sourceLogo => 'https://anime-phoenix.com/favicon.ico';
  @override Uri get baseUrl => Uri.parse('https://anime-phoenix.com/');
  @override Future<List<AnimeModel>> fetchLatestAnime(int page) async => parseCards(await getHtml(page == 1 ? baseUrl.toString() : '${baseUrl}page/$page'), 'a[href*="/animes/"], .anime-card');
  @override Future<List<AnimeModel>> searchAnime(String query, int page) async => parseCards(await getHtml(baseUrl.resolve('/search/').replace(queryParameters: {'q': query, 'page': '$page'}).toString()), 'a[href*="/animes/"], .anime-card');
  @override Future<AnimeModel> getAnimeDetails(String animeUrl) async {
    final current = await super.getAnimeDetails(animeUrl);
    final collected = <String, EpisodeModel>{for (final e in current.episodes) e.url: e};
    // The source exposes the complete episode grid on the anime page. The
    // optional /episodes endpoint is retained only for installations that use it.
    final urls = <String>{animeUrl, '${animeUrl.replaceFirst(RegExp(r'/$'), '')}/episodes'};
    for (final pageUrl in urls) {
      try {
        final doc = parser.parse(await getHtml(pageUrl));
        addEpisodes(doc, collected, 'a.FJ-EpPill, a.FJ-episode-wrap, a[href*="/episodes/"]');
      } catch (_) {}
    }
    return current.copyWith(episodes: sortedEpisodes(collected.values));
  }
}

const List<AnimeSource> enabledAnimeSources = [Anime3rbSource(), RestoAnimeSource(), AnimePhoenixSource()];
Future<List<AnimeSource>> activeAnimeSources() async {
  final prefs = await SharedPreferences.getInstance();
  final selected = prefs.getStringList('mangalord.enabled_anime_sources');
  if (selected == null || selected.isEmpty) return enabledAnimeSources;
  final result = enabledAnimeSources.where((source) => selected.contains(source.sourceKey)).toList();
  return result.isEmpty ? enabledAnimeSources : result;
}
Future<List<AnimeModel>> latestAnimeFromAllSources({int page = 1}) async { final sources = await activeAnimeSources(); return safeSourceCalls(sources.map((source) => () => source.fetchLatestAnime(page))); }
Future<List<AnimeModel>> searchAllAnimeSources(String query, {int page = 1}) async { final sources = await activeAnimeSources(); return safeSourceCalls(sources.map((source) => () => source.searchAnime(query, page))); }
AnimeSource animeSourceByKey(String key) => enabledAnimeSources.firstWhere((source) => source.sourceKey == key, orElse: () => enabledAnimeSources.first);
