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

abstract class _HtmlSource extends AnimeSource {
  const _HtmlSource();
  AnimeModel item(Element node) {
    final anchor = node.localName == 'a' ? node : node.querySelector('a');
    final url = _absolute(baseUrl, _attr(anchor, 'href'));
    final title = (_attr(anchor, 'title').ifEmpty(_text(anchor))).trim();
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
    for (final node in doc.querySelectorAll('a[href*="episode"], a[href*="الحلقة"], .episodes a, .Episode a')) {
      final anchor = node.localName == 'a' ? node : node.querySelector('a');
      final url = _absolute(baseUrl, _attr(anchor, 'href'));
      final title = _text(anchor).ifEmpty(_attr(anchor, 'title'));
      if (url.isNotEmpty) episodes.add(EpisodeModel(id: _id(sourceKey, url), title: title, url: url, number: _episodeNumber(title), sourceKey: sourceKey, thumbnail: _image(node, baseUrl)));
    }
    final title = _text(doc.querySelector('h1, .title, title')).ifEmpty(_attr(doc.querySelector('meta[property="og:title"]'), 'content'));
    final cover = _attr(doc.querySelector('meta[property="og:image"]'), 'content').ifEmpty(_image(doc.querySelector('main, body') ?? doc.documentElement!, baseUrl));
    final description = _attr(doc.querySelector('meta[name="description"]'), 'content').ifEmpty(_text(doc.querySelector('.description, .summary, .story-description')));
    return AnimeModel(id: _id(sourceKey, animeUrl), title: title, url: animeUrl, cover: cover, description: description, sourceKey: sourceKey, sourceName: sourceName, episodes: episodes);
  }
  @override Future<List<VideoServerModel>> getVideoExtractors(String episodeUrl) async {
    final body = await getHtml(episodeUrl, headers: {'Referer': baseUrl.toString()});
    return VideoExtractor.extract(body, baseUrl, sourceName, episodeUrl, defaultHeaders);
  }
}

class Anime3rbSource extends _HtmlSource {
  const Anime3rbSource();
  @override String get sourceKey => 'anime3rb';
  @override String get sourceName => 'Anime3rb';
  @override String get sourceLogo => 'https://anime3rb.com/favicon.ico';
  @override Uri get baseUrl => Uri.parse('https://anime3rb.com');
  @override Future<List<AnimeModel>> fetchLatestAnime(int page) async => parseCards(await getHtml(baseUrl.resolve('/titles/list?page=$page').toString()), 'a[href*="/titles/"]');
  @override Future<List<AnimeModel>> searchAnime(String query, int page) async => parseCards(await getHtml(baseUrl.resolve('/titles/list').replace(queryParameters: {'q': query, 'page': '$page'}).toString()), 'a[href*="/titles/"]');
}

class RestoAnimeSource extends _HtmlSource {
  const RestoAnimeSource();
  @override String get sourceKey => 'risto_anime';
  @override String get sourceName => 'Resto Anime';
  @override String get sourceLogo => 'https://ristoanime.me/favicon.ico';
  @override Uri get baseUrl => Uri.parse('https://ristoanime.me/');
  @override Future<List<AnimeModel>> fetchLatestAnime(int page) async => parseCards(await getHtml(page == 1 ? baseUrl.toString() : '${baseUrl}page/$page/'), '.BlocksHolder .MovieItem');
  @override Future<List<AnimeModel>> searchAnime(String query, int page) async => parseCards(await getHtml(baseUrl.replace(queryParameters: {'s': query, 'paged': '$page'}).toString()), '.SearchResultInner, .MovieItem');
}

class AnimePhoenixSource extends _HtmlSource {
  const AnimePhoenixSource();
  @override String get sourceKey => 'anime_phoenix';
  @override String get sourceName => 'Anime Phoenix';
  @override String get sourceLogo => 'https://anime-phoenix.com/favicon.ico';
  @override Uri get baseUrl => Uri.parse('https://anime-phoenix.com/');
  @override Future<List<AnimeModel>> fetchLatestAnime(int page) async => parseCards(await getHtml(baseUrl.toString()), 'a[href*="/animes/"], .anime-card');
  @override Future<List<AnimeModel>> searchAnime(String query, int page) async => parseCards(await getHtml(baseUrl.resolve('/search/').replace(queryParameters: {'q': query, 'page': '$page'}).toString()), 'a[href*="/animes/"], .anime-card');
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
