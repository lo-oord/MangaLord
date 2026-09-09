import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
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
String _image(Element node, Uri base) {
  final image = node.querySelector('img');
  final style = node.querySelector('.poster, [data-style]');
  final rawStyle = _attr(style, 'data-style') + _attr(style, 'style');
  final match = RegExp(r'''url\((?:["']?)([^)"']+)''').firstMatch(rawStyle);
  return _absolute(base, match?.group(1) ?? _attr(image, 'data-src').ifEmpty(_attr(image, 'src')));
}
extension on String { String ifEmpty(String fallback) => isEmpty ? fallback : this; }
String _episodeNumber(String value) => RegExp(r'(?:episode|ep|الحلقة)[^\d]*(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(value)?.group(1) ?? RegExp(r'\d+(?:\.\d+)?').firstMatch(value)?.group(0) ?? '';
String _id(String source, String url) => '$source:${Uri.tryParse(url)?.toString() ?? url}';
String _cleanTitle(String value) => value.replaceAll(RegExp(r'^(مشاهدة|انمي|مسلسلات انمي)\s*', caseSensitive: false), '').replaceAll(RegExp(r'\s*(الحلقة|episode|ep)\s*\d+.*$', caseSensitive: false), '').replaceAll(RegExp(r'\s+'), ' ').trim();

abstract class _HtmlSource extends AnimeSource {
  const _HtmlSource();
  AnimeModel item(Element node) {
    final anchor = node.localName == 'a' ? node : node.querySelector('a');
    final url = _absolute(baseUrl, _attr(anchor, 'href'));
    final title = _cleanTitle(_attr(anchor, 'title').ifEmpty(_text(node.querySelector('.title h4, .title, h2, h3, h4')).ifEmpty(_text(anchor))));
    return AnimeModel(id: _id(sourceKey, url), title: title, url: url, cover: _image(node, baseUrl), sourceKey: sourceKey, sourceName: sourceName);
  }
  List<AnimeModel> parseCards(String body, String selector) {
    final doc = parser.parse(body);
    final result = <String, AnimeModel>{};
    for (final node in doc.querySelectorAll(selector)) { final value = item(node); if (value.url.isNotEmpty && value.title.isNotEmpty) result[value.url] = value; }
    return result.values.toList();
  }
  @override Future<AnimeModel> getAnimeDetails(String animeUrl) async {
    final doc = parser.parse(await getHtml(animeUrl));
    final episodes = <EpisodeModel>[];
    for (final node in doc.querySelectorAll('a[href*="episode"], a[href*="episodes/"], a[href*="الحلقة"], .episodes a, .EpisodesList a, .Episode a, a[href*="/watch/"]')) {
      final anchor = node.localName == 'a' ? node : node.querySelector('a');
      final url = _absolute(baseUrl, _attr(anchor, 'href'));
      final title = _cleanTitle(_text(anchor).ifEmpty(_attr(anchor, 'title')));
      if (url.isNotEmpty) episodes.add(EpisodeModel(id: _id(sourceKey, url), title: title, url: url, number: _episodeNumber(title), sourceKey: sourceKey, thumbnail: _image(node, baseUrl)));
    }
    final title = _text(doc.querySelector('h1, .anime-title, .FJ-Phoenix-Anastasia-Title, title')).ifEmpty(_attr(doc.querySelector('meta[property="og:title"]'), 'content'));
    final cover = _attr(doc.querySelector('meta[property="og:image"]'), 'content').ifEmpty(_attr(doc.querySelector('img[alt], .poster img, .FJ-Phoenix-Anastasia-Hero-Img'), 'src')).ifEmpty(_image(doc.querySelector('main, body') ?? doc.documentElement!, baseUrl));
    final description = _attr(doc.querySelector('meta[name="description"]'), 'content').ifEmpty(_text(doc.querySelector('.description, .summary, .story-description')));
    if (episodes.isEmpty && sourceKey == 'risto_anime') {
      final episodeTitle = _cleanTitle(title);
      episodes.add(EpisodeModel(id: _id(sourceKey, animeUrl), title: episodeTitle.isEmpty ? title : episodeTitle, url: animeUrl, number: _episodeNumber(title), sourceKey: sourceKey));
    }
    episodes.sort((a, b) => (double.tryParse(a.number) ?? 0).compareTo(double.tryParse(b.number) ?? 0));
    return AnimeModel(id: _id(sourceKey, animeUrl), title: _cleanTitle(title), url: animeUrl, cover: _absolute(baseUrl, cover), description: description, sourceKey: sourceKey, sourceName: sourceName, episodes: episodes);
  }
  @override Future<List<VideoServerModel>> getVideoExtractors(String episodeUrl) async {
    final body = await getHtml(episodeUrl, headers: {'Referer': baseUrl.toString()});
    final pages = <String>{episodeUrl};
    final document = parser.parse(body);
    for (final node in document.querySelectorAll('iframe[src], [data-video], [data-url], [data-watch], a.FJ-DL-Server-Btn[href], a[data-server-hash][href]')) {
      final value = _attr(node, 'src').ifEmpty(_attr(node, 'data-video')).ifEmpty(_attr(node, 'data-url')).ifEmpty(_attr(node, 'data-watch')).ifEmpty(_attr(node, 'href'));
      final resolved = _absolute(baseUrl, value);
      if (resolved.isNotEmpty && !resolved.contains('.mp4') && !resolved.contains('.m3u8')) pages.add(resolved);
    }
    final servers = <String, VideoServerModel>{};
    for (final page in pages) {
      try {
        final pageBody = page == episodeUrl ? body : await getHtml(page, headers: {'Referer': episodeUrl});
        for (final server in VideoExtractor.extract(pageBody, baseUrl, sourceName, page == episodeUrl ? episodeUrl : page, {...defaultHeaders, 'Referer': episodeUrl})) servers[server.url] = server;
      } catch (_) {}
    }
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

  @override
  Future<AnimeModel> getAnimeDetails(String animeUrl) async {
    final current = await super.getAnimeDetails(animeUrl);
    final seriesTitle = _cleanTitle(current.title);
    final collected = <String, EpisodeModel>{for (final episode in current.episodes) episode.url: episode};
    try {
      final searchBody = await getHtml(baseUrl.replace(queryParameters: {'s': seriesTitle}).toString());
      for (final node in parser.parse(searchBody).querySelectorAll('.MovieItem')) {
        final anchor = node.querySelector('a');
        final url = _absolute(baseUrl, _attr(anchor, 'href'));
        final title = _cleanTitle(_text(node.querySelector('.title h4, .title')).ifEmpty(_text(anchor)));
        if (url.isNotEmpty && title.isNotEmpty && (title.toLowerCase().contains(seriesTitle.toLowerCase()) || seriesTitle.toLowerCase().contains(_cleanTitle(title).toLowerCase()))) {
          collected[url] = EpisodeModel(id: _id(sourceKey, url), title: title, url: url, number: _episodeNumber(title), sourceKey: sourceKey, thumbnail: _image(node, baseUrl));
        }
      }
    } catch (_) {}
    final episodes = collected.values.toList()..sort((a, b) => (double.tryParse(a.number) ?? 0).compareTo(double.tryParse(b.number) ?? 0));
    return current.copyWith(episodes: episodes);
  }
}

class AnimePhoenixSource extends _HtmlSource {
  const AnimePhoenixSource();
  @override String get sourceKey => 'anime_phoenix';
  @override String get sourceName => 'Anime Phoenix';
  @override String get sourceLogo => 'https://anime-phoenix.com/favicon.ico';
  @override Uri get baseUrl => Uri.parse('https://anime-phoenix.com/');
  @override Future<List<AnimeModel>> fetchLatestAnime(int page) async => parseCards(await getHtml(baseUrl.toString()), 'a[href*="/animes/"], .anime-card');
  @override Future<List<AnimeModel>> searchAnime(String query, int page) async => parseCards(await getHtml(baseUrl.resolve('/search/').replace(queryParameters: {'q': query, 'page': '$page'}).toString()), 'a[href*="/animes/"], .anime-card');

  @override
  Future<AnimeModel> getAnimeDetails(String animeUrl) async {
    final current = await super.getAnimeDetails(animeUrl);
    final episodes = <String, EpisodeModel>{for (final episode in current.episodes) episode.url: episode};
    try {
      final body = await getHtml('${animeUrl.replaceFirst(RegExp(r'/$'), '')}/episodes');
      for (final node in parser.parse(body).querySelectorAll('a.FJ-episode-wrap, a[href*="/episodes/"]')) {
        final url = _absolute(baseUrl, _attr(node, 'href'));
        final title = _cleanTitle(_text(node.querySelector('.FJ-Phoenix-Anastasia-EpCard-Tooltip, .FJ-episode-info')).ifEmpty(_text(node)));
        if (url.isNotEmpty) episodes[url] = EpisodeModel(id: _id(sourceKey, url), title: title, url: url, number: _episodeNumber(title), sourceKey: sourceKey, thumbnail: _attr(node.querySelector('img'), 'src'));
      }
    } catch (_) {}
    final fullEpisodes = episodes.values.toList()..sort((a, b) => (double.tryParse(a.number) ?? 0).compareTo(double.tryParse(b.number) ?? 0));
    return current.copyWith(episodes: fullEpisodes);
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
