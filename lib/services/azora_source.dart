import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'manga_source.dart';
import 'team_x_source.dart';

class AzoraSource implements MangaSource {
  AzoraSource({http.Client? client}) : _client = client ?? http.Client();

  static final Uri baseUri = Uri.parse('https://azorafly.com/');
  static const _userAgent = 'MangaLord/1.0 (Flutter; AzoraFly source)';
  static const _logo = 'https://azorafly.com/favicon-32x32.png';
  final http.Client _client;

  @override
  String get sourceKey => 'azora_fly';
  @override
  String get sourceName => 'AzoraFly';
  @override
  String get sourceLogo => _logo;
  @override
  String get imageReferer => baseUri.toString();

  Future<String> _get(Uri uri) async {
    final response = await _client.get(uri, headers: const {
      'User-Agent': _userAgent,
      'Accept': 'text/html,application/xhtml+xml',
      'Accept-Language': 'ar,en;q=0.8',
      'Referer': 'https://azorafly.com/',
    }).timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw Exception('AzoraFly returned HTTP ${response.statusCode}');
    }
    return response.body;
  }

  @override
  Future<List<TeamXManga>> latest({int page = 1}) async {
    final uri = baseUri.resolve('series/').replace(queryParameters: {
      if (page > 1) 'page': '$page',
    });
    return _parseMangaList(await _get(uri));
  }

  @override
  Future<List<TeamXManga>> search(String query, {int page = 1}) async {
    final uri = baseUri.resolve('series/').replace(queryParameters: {
      'searchTerm': query,
      if (page > 1) 'page': '$page',
    });
    return _parseMangaList(await _get(uri));
  }

  @override
  Future<TeamXManga> details(String url) async {
    final uri = _resolve(url);
    final document = html_parser.parse(await _get(uri));
    final title = _text(document.querySelector('h1'));
    final description = document
            .querySelector('meta[name="description"]')
            ?.attributes['content'] ??
        '';
    final cover = document.querySelector('meta[property="og:image"]')?.attributes['content'] ??
        _image(document.querySelector('img'));
    final chapterMap = <String, TeamXChapter>{};
    for (final anchor in document.querySelectorAll('a[href*="/chapter-"]')) {
      final href = anchor.attributes['href'];
      if (href == null) continue;
      final chapterUri = _resolve(href);
      final chapterNumber = _chapterNumber(chapterUri);
      if (chapterNumber.isEmpty) continue;
      chapterMap[chapterUri.toString()] = TeamXChapter(
        id: chapterUri.toString(),
        number: chapterNumber,
        title: chapterNumber,
        publishedAt: '',
        url: chapterUri.toString(),
        images: const [],
      );
    }
    final chapters = chapterMap.values.toList()
      ..sort((a, b) => b.numberValue.compareTo(a.numberValue));
    return TeamXManga(
      id: uri.toString(),
      title: title.isEmpty ? _fallbackName(uri) : title,
      url: uri.toString(),
      cover: cover,
      description: description,
      chapters: chapters,
    );
  }

  @override
  Future<TeamXChapter> chapter(String url, {String? mangaTitle}) async {
    final uri = _resolve(url);
    final document = html_parser.parse(await _get(uri));
    final images = <String>[];
    for (final image in document.querySelectorAll('img[data-reader-page-image], img[data-reader-index]')) {
      final resolved = _image(image);
      if (resolved.isEmpty ||
          !resolved.contains('storage.azorafly.com') ||
          (!resolved.contains('/WP-manga/data/') && !resolved.contains('/upload/series/'))) {
        continue;
      }
      if (!images.contains(resolved)) images.add(resolved);
    }
    if (images.isEmpty) throw Exception('No chapter images found on AzoraFly');
    final number = _chapterNumber(uri);
    return TeamXChapter(
      id: uri.toString(),
      number: number,
      title: number.isEmpty ? (mangaTitle ?? _fallbackName(uri)) : number,
      publishedAt: '',
      url: uri.toString(),
      images: images,
    );
  }

  List<TeamXManga> _parseMangaList(String source) {
    final document = html_parser.parse(source);
    final items = <String, TeamXManga>{};
    for (final anchor in document.querySelectorAll('a[href*="/series/"]')) {
      final href = anchor.attributes['href'];
      if (href == null) continue;
      final uri = _resolve(href);
      final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
      if (parts.length != 2 || parts.first != 'series') continue;
      final imageNode = anchor.querySelector('img');
      final title = (anchor.attributes['title'] ??
              imageNode?.attributes['alt'] ??
              _text(anchor))
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (title.isEmpty || title.length > 300) continue;
      final image = _image(imageNode);
      items[uri.toString()] = TeamXManga(
        id: uri.toString(),
        title: title,
        url: uri.toString(),
        cover: image,
      );
    }
    return items.values.toList();
  }

  String _chapterNumber(Uri uri) {
    final segment = uri.pathSegments.where((part) => part.isNotEmpty).last;
    return RegExp(r'(\d+(?:\.\d+)?)').firstMatch(segment)?.group(1) ?? '';
  }

  String _fallbackName(Uri uri) => uri.pathSegments.last.replaceAll('-', ' ');
  Uri _resolve(String value) => Uri.parse(value).isAbsolute ? Uri.parse(value) : baseUri.resolve(value);
  String _text(dynamic node) => node?.text?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';

  String _image(dynamic node) {
    if (node == null) return '';
    final value = node.attributes['data-src'] ??
        node.attributes['data-lazy-src'] ??
        node.attributes['content'] ??
        node.attributes['src'] ??
        '';
    if (value.isEmpty || value.startsWith('data:')) return '';
    return _resolve(value).toString();
  }
}
