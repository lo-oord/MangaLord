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
    final imageNode = node.querySelector('img, picture source') ?? node;
    final attrs = imageNode.attributes as Map<String, String>;
    final srcset = attrs['data-srcset'] ?? attrs['srcset'] ?? '';
    if (srcset.isNotEmpty) return resolve(srcset.split(',').last.trim().split(RegExp(r'\s+')).first).toString();
    for (final key in ['data-src', 'data-lazy-src', 'data-original', 'src']) {
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
  @override String get sourceLogo => 'https://appswat.com/favicon-32x32.png';
  @override String get imageReferer => 'https://appswat.com/';
  @override Uri get baseUri => Uri.parse('https://appswat.com/');
  @override Uri searchUri(String query, int page) => Uri.parse('https://appswat.com/v2/api/v2/series/').replace(queryParameters: {'page_size': '20', 'offset': '${(page - 1) * 20}', 'search': query});
  @override Future<List<TeamXManga>> search(String query, {int page = 1}) async {
    final body = await _getJson(searchUri(query, page));
    final json = jsonDecode(body) as Map<String, dynamic>;
    final results = (json['results'] as List? ?? const []).whereType<Map>().map((item) => TeamXManga(id: '${item['id']}', title: '${item['title'] ?? ''}', url: '${item['url'] ?? 'https://appswat.com/series/${item['id']}'}', cover: '${(item['poster'] as Map?)?['medium'] ?? ''}')).toList();
    return results;
  }
  Future<String> _getJson(Uri uri) async {
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 400) throw Exception('$sourceName returned HTTP ${response.statusCode}');
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }
}

class HijalaComSource extends HtmlMangaSource {
  @override String get sourceKey => 'hijala_com';
  @override String get sourceName => 'HijalaCom';
  @override String get sourceLogo => 'https://hijala.com/favicon.ico';
  @override String get imageReferer => 'https://hijala.com/';
  @override Uri get baseUri => Uri.parse('https://hijala.com/');
  @override Uri searchUri(String query, int page) => baseUri.resolve('search/').replace(queryParameters: {'keyword': query, 'page': '$page'});
}

class ProChanSource extends HtmlMangaSource {
  @override String get sourceKey => 'pro_chan';
  @override String get sourceName => 'Pro Chan';
  @override String get sourceLogo => 'https://prochan.pro/favicon.ico';
  @override String get imageReferer => 'https://prochan.pro/';
  @override Uri get baseUri => Uri.parse('https://prochan.pro/');
  @override Uri searchUri(String query, int page) => Uri.parse('https://prochan.pro/api/public/series/search/').replace(queryParameters: {'q': query, 'page': '$page'});
  @override Future<List<TeamXManga>> search(String query, {int page = 1}) async {
    final root = jsonDecode(await _get(searchUri(query, page))) as Map<String, dynamic>;
    final values = (root['data'] as List?) ?? (root['results'] as List?) ?? const [];
    return values.whereType<Map>().map((item) {
      final id = '${item['id'] ?? item['slug'] ?? ''}';
      final slug = '${item['slug'] ?? ''}'.trim();
      final url = '${item['url'] ?? item['public_url'] ?? (slug.isNotEmpty ? 'https://procomic.pro/ar/series/$slug' : 'https://procomic.pro/ar/series/$id')}';
      final cover = '${item['thumbnail_url'] ?? item['thumbnail'] ?? item['coverImage'] ?? item['cover_url'] ?? item['poster'] ?? ''}';
      return TeamXManga(id: url, title: '${item['title_ar'] ?? item['title'] ?? item['name'] ?? ''}'.trim(), url: url, cover: cover);
    }).where((item) => item.title.isNotEmpty && item.url.isNotEmpty).toList();
  }
}

/// The requested “Dailr Tube” source is represented by the current public Dilar Tube domain.
class DailrTubeSource extends HtmlMangaSource {
  @override String get sourceKey => 'dailr_tube';
  @override String get sourceName => 'Dailr Tube';
  @override String get sourceLogo => 'https://dilar.tube/favicon.ico';
  @override String get imageReferer => 'https://dilar.tube/';
  @override Uri get baseUri => Uri.parse('https://dilar.tube/');
  @override Uri searchUri(String query, int page) => baseUri.resolve('mangas').replace(queryParameters: {'search': query, 'page': '$page'});
}

final List<MangaSource> additionalMangaSources = <MangaSource>[MangaSwatSource(), HijalaComSource(), ProChanSource(), DailrTubeSource()];
