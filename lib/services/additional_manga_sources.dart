import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'manga_source.dart';
import 'team_x_source.dart';

abstract class HtmlMangaSource implements MangaSource {
  HtmlMangaSource({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Uri get baseUri;
  Map<String, String> get headers => const {
        'User-Agent': 'MangaLord/1.0 (Flutter; source parser)',
        'Accept': 'text/html,application/xhtml+xml,application/json',
        'Accept-Language': 'ar,en;q=0.8',
      };
  Future<String> _get(Uri uri) async {
    final response = await _client.get(uri, headers: {...headers, 'Referer': baseUri.toString()}).timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 400) throw Exception('$sourceName returned HTTP ${response.statusCode}');
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }
  Uri resolve(String value) {
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null) return baseUri;
    return parsed.isAbsolute ? parsed : baseUri.resolve(value.trim());
  }
  String image(dynamic node) {
    if (node == null) return '';
    final imageNode = node.matches('img, source') ? node : (node.querySelector('img, picture source') ?? node.parent?.querySelector('img, picture source') ?? node);
    final attrs = imageNode.attributes as Map<String, String>;
    final srcset = attrs['data-srcset'] ?? attrs['srcset'] ?? '';
    if (srcset.isNotEmpty) return resolve(srcset.split(',').last.trim().split(RegExp(r'\s+')).first).toString();
    for (final key in ['data-src', 'data-lazy-src', 'data-original', 'data-image', 'src']) {
      final value = attrs[key] ?? '';
      if (value.isNotEmpty && !value.startsWith('data:')) return resolve(value).toString();
    }
    return '';
  }
  String text(dynamic node) => (node?.text is String ? node.text as String : '').replaceAll(RegExp(r'\s+'), ' ').trim();
  String number(String value) => RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value)?.group(1) ?? '';
  TeamXManga mangaFrom(dynamic node) {
    final anchor = node.matches('a') ? node : node.querySelector('a');
    final url = resolve(anchor?.attributes['href'] ?? node.attributes['href'] ?? '').toString();
    final title = ((anchor?.attributes['title'] ?? '').trim().isNotEmpty
            ? anchor?.attributes['title']
            : (text(anchor).isNotEmpty ? text(anchor) : text(node)))
        ?.trim() ?? '';
    return TeamXManga(id: url, title: title, url: url, cover: image(node));
  }
  List<TeamXManga> parseCards(String body, List<String> selectors) {
    final doc = html_parser.parse(body);
    final byUrl = <String, TeamXManga>{};
    for (final selector in selectors) {
      for (final node in doc.querySelectorAll(selector)) {
        final item = mangaFrom(node);
        if (item.url.isNotEmpty && item.title.isNotEmpty && item.title.length < 300) byUrl[item.url] = item;
      }
    }
    return byUrl.values.toList();
  }
  @override Future<List<TeamXManga>> latest({int page = 1}) async => parseCards(await _get(baseUri), cardSelectors);
  @override Future<List<TeamXManga>> search(String query, {int page = 1}) async => parseCards(await _get(searchUri(query, page)), cardSelectors);
  Uri searchUri(String query, int page);
  List<String> get cardSelectors => const ['a[href*="/manga/"]', 'a[href*="/series/"]', '.c-tabs-item__content', '.row.c-tabs-item__content'];
  @override Future<TeamXManga> details(String url) async {
    final uri = resolve(url);
    final doc = html_parser.parse(await _get(uri));
    final title = text(doc.querySelector('h1, .post-title, .summary_content h1'));
    final cover = image(doc.querySelector('.summary_image img, .thumbnail img, .manga-thumb img, img'));
    final description = text(doc.querySelector('.description-summary, .summary__content, .description, .story-description, meta[name="description"]'));
    final chapters = <TeamXChapter>[];
    for (final anchor in doc.querySelectorAll('a[href*="chapter"], .wp-manga-chapter a, .chapter a, .c-tabs-item__content a')) {
      final chapterUrl = resolve(anchor.attributes['href'] ?? '').toString();
      if (chapterUrl == uri.toString() || chapterUrl.isEmpty) continue;
      final chapterTitle = text(anchor);
      chapters.add(TeamXChapter(id: chapterUrl, number: number(chapterTitle), title: chapterTitle, publishedAt: '', url: chapterUrl, images: const []));
    }
    final unique = <String, TeamXChapter>{for (final chapter in chapters) chapter.url: chapter};
    return TeamXManga(id: uri.toString(), title: title.isEmpty ? uri.pathSegments.last : title, url: uri.toString(), cover: cover, description: description, chapters: unique.values.toList());
  }
  @override Future<TeamXChapter> chapter(String url, {String? mangaTitle}) async {
    final uri = resolve(url);
    final doc = html_parser.parse(await _get(uri));
    final images = <String>[];
    for (final node in doc.querySelectorAll('img')) {
      final value = image(node);
      final lower = value.toLowerCase();
      if (value.isNotEmpty && !lower.contains('logo') && !lower.contains('avatar') && !lower.contains('icon') && !images.contains(value)) images.add(value);
    }
    if (images.isEmpty) throw Exception('No chapter pages found on $sourceName');
    final title = text(doc.querySelector('h1, .c-breadcrumb-wrapper, title'));
    return TeamXChapter(id: uri.toString(), number: number(title), title: title.isEmpty ? (mangaTitle ?? number(title)) : title, publishedAt: '', url: uri.toString(), images: images);
  }
}

class MangaSwatSource extends HtmlMangaSource {
  @override String get sourceKey => 'manga_swat';
  @override String get sourceName => 'Manga Swat';
  @override String get sourceLogo => 'https://meshmanga.com/favicon.ico';
  @override String get imageReferer => 'https://meshmanga.com/';
  @override Uri get baseUri => Uri.parse('https://meshmanga.com/');
  Uri get _api => Uri.parse('https://appswat.com/v2/api/v2/');
  Future<dynamic> _apiGet(Uri uri) async {
    final response = await _client.get(uri, headers: {...headers, 'Accept': 'application/json'}).timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 400) throw Exception('$sourceName API returned HTTP ${response.statusCode}');
    return jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
  }
  TeamXManga _apiManga(Map item) {
    final id = '${item['id'] ?? ''}';
    final poster = item['poster'];
    final cover = poster is Map ? '${poster['medium'] ?? poster['thumbnail'] ?? ''}' : '';
    return TeamXManga(id: id, title: '${item['title'] ?? ''}', url: baseUri.resolve('series/$id').toString(), cover: cover, description: '${item['story'] ?? ''}');
  }
  Future<List<TeamXManga>> _apiList(Uri uri) async {
    final value = await _apiGet(uri);
    final rows = value is Map ? value['results'] : null;
    return rows is List ? rows.whereType<Map>().map(_apiManga).where((item) => item.title.trim().isNotEmpty).toList() : const [];
  }
  @override Uri searchUri(String query, int page) => _catalogUri('type/manga', query, page);
  Uri _catalogUri(String path, String query, int page) => baseUri.resolve(path).replace(queryParameters: {
    if (query.isNotEmpty) 'search': query,
    if (page > 1) 'page': '$page',
  });
  @override Future<List<TeamXManga>> latest({int page = 1}) async {
    try { return _apiList(_api.resolve('series/').replace(queryParameters: {'page': '$page', 'page_size': '20'})); }
    catch (_) { return parseCards(await _get(_catalogUri('type/manga', '', page)), const ['a[href*="/manga/"]', 'a[href*="/series/"]', '.page-item-detail', '.c-tabs-item__content']); }
  }
  @override Future<List<TeamXManga>> search(String query, {int page = 1}) async {
    try { return _apiList(_api.resolve('series/').replace(queryParameters: {'search': query, 'page': '$page', 'page_size': '20'})); }
    catch (_) {}
    final pages = <String>{
      await _get(_catalogUri('type/manga', query, page)),
      await _get(baseUri.resolve('search').replace(queryParameters: {'q': query, if (page > 1) 'page': '$page'})),
    };
    final merged = <String, TeamXManga>{};
    for (final body in pages) {
      for (final item in parseCards(body, const ['a[href*="/manga/"]', 'a[href*="/series/"]', '.page-item-detail', '.c-tabs-item__content'])) merged[item.url] = item;
    }
    return merged.values.toList();
  }
  @override Future<TeamXManga> details(String url) async {
    final id = RegExp(r'/series/(\d+)$').firstMatch(url)?.group(1) ?? '';
    if (id.isEmpty) return super.details(url);
    final value = await _apiGet(_api.resolve('series/$id/')) as Map;
    final manga = _apiManga(value);
    final chapterValue = await _apiGet(_api.resolve('series/$id/chapters/')) as Map;
    final rows = chapterValue['results'];
    final chapters = rows is List ? rows.whereType<Map>().map((item) {
      final chapterId = '${item['id'] ?? ''}';
      final chapter = '${item['chapter'] ?? item['title'] ?? ''}';
      return TeamXChapter(id: chapterId, number: number(chapter), title: chapter, publishedAt: '${item['created_at_humanized'] ?? ''}', url: baseUri.resolve('chapter/$chapterId').toString(), images: const []);
    }).toList() : <TeamXChapter>[];
    return TeamXManga(id: manga.id, title: manga.title, url: manga.url, cover: manga.cover, description: manga.description, chapters: chapters);
  }
}

class HijalaComSource extends HtmlMangaSource {
  @override String get sourceKey => 'hijala_com';
  @override String get sourceName => 'Hijala';
  @override String get sourceLogo => 'https://hijala.com/wp-content/uploads/2024/10/cropped-hijala-32x32.png';
  @override String get imageReferer => 'https://hijala.com/';
  @override Uri get baseUri => Uri.parse('https://hijala.com/');
  @override Uri searchUri(String query, int page) => baseUri.replace(queryParameters: {'s': query, if (page > 1) 'paged': '$page'});
  List<String> get _selectors => const ['a.series', '.page-item-detail', '.c-tabs-item__content', '.row.c-tabs-item__content', 'article'];
  @override Future<List<TeamXManga>> latest({int page = 1}) async => parseCards(await _get(baseUri.resolve(page == 1 ? 'manga/?order=update' : 'manga/page/$page/?order=update')), _selectors);
  @override Future<List<TeamXManga>> search(String query, {int page = 1}) async {
    return parseCards(await _get(baseUri.replace(queryParameters: {'s': query, if (page > 1) 'paged': '$page'})), _selectors);
  }
}

class DilarTubeSource extends HtmlMangaSource {
  @override String get sourceKey => 'dilar_tube';
  @override String get sourceName => 'Dilar Tube';
  @override String get sourceLogo => 'https://dilar.tube/logo192.png';
  @override String get imageReferer => 'https://dilar.tube/';
  @override Uri get baseUri => Uri.parse('https://dilar.tube/');
  @override Uri searchUri(String query, int page) => _api.resolve('series').replace(queryParameters: {'search': query, 'page': '$page'});
  Uri get _api => baseUri.resolve('api/');
  String _asset(String id, String value) => value.isEmpty ? '' : (value.startsWith('http') ? value : baseUri.resolve('uploads/manga/cover/$id/large_$value').toString());
  TeamXManga _item(Map item) => TeamXManga(id: '${item['id']}', title: '${item['title'] ?? ''}', url: baseUri.resolve('series/${item['id']}').toString(), cover: _asset('${item['id'] ?? ''}', '${item['cover'] ?? ''}'), description: '${item['summary'] ?? ''}');
  Future<Map<String, dynamic>> _json(Uri uri) async {
    final body = await _get(uri);
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) throw Exception('$sourceName returned an invalid API response');
    return decoded;
  }
  List<TeamXManga> _htmlSeries(String body) => parseCards(body, const ['a[href*="/mangas/"]', 'a[href*="/series/"]', '.manga-card', '.series-card']);
  @override Future<List<TeamXManga>> latest({int page = 1}) async {
    try {
      final values = ((await _json(_api.resolve('series').replace(queryParameters: {'page': '$page'})))['series'] as List? ?? const []);
      return values.whereType<Map>().map(_item).where((item) => item.title.trim().isNotEmpty).toList();
    } catch (_) {
      return _htmlSeries(await _get(baseUri.resolve(page == 1 ? 'mangas' : 'mangas?page=$page')));
    }
  }
  @override Future<List<TeamXManga>> search(String query, {int page = 1}) async {
    try {
      final values = ((await _json(_api.resolve('series').replace(queryParameters: {'title': query, 'page': '$page'})))['series'] as List? ?? const []);
      return values.whereType<Map>().map(_item).where((item) => item.title.trim().isNotEmpty).toList();
    } catch (_) {
      return _htmlSeries(await _get(baseUri.resolve('mangas').replace(queryParameters: {'search': query, if (page > 1) 'page': '$page'})));
    }
  }
  @override Future<TeamXManga> details(String url) async {
    final id = resolve(url).pathSegments.last;
    final item = await _json(_api.resolve('series/$id'));
    final chaptersResponse = await _json(_api.resolve('series/$id/chapters'));
    final chapters = ((chaptersResponse['chapters'] as List?) ?? const []).whereType<Map>().map((item) => TeamXChapter(id: '${item['id']}', number: '${item['chapter'] ?? ''}', title: '${item['title'] ?? ''}', publishedAt: '${item['created_at'] ?? ''}', url: baseUri.resolve('series/$id/chapters/${item['id']}').toString(), images: const [])).toList();
    final manga = _item(item); return TeamXManga(id: manga.id, title: manga.title, url: manga.url, cover: manga.cover, description: manga.description, chapters: chapters);
  }
}

final List<MangaSource> additionalMangaSources = <MangaSource>[MangaSwatSource(), HijalaComSource(), DilarTubeSource()];
