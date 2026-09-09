import 'package:html/parser.dart' as html_parser;
import 'dart:convert';

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
    return utf8.decode(response.bodyBytes, allowMalformed: true);
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
    final title = _mangaTitle(document, uri);
    final description = _cleanHtml(document.querySelector('meta[name="description"]')?.attributes['content'] ?? document.querySelector('meta[property="og:description"]')?.attributes['content'] ?? '');
    // AzoraFly's og:image is a generated social preview, not the manga cover.
    final cover = _coverImage(document);
    final chapterMap = <String, TeamXChapter>{};
    final pendingPages = <Uri>{uri, ..._chapterPageUrls(document, uri)};
    final visitedPages = <Uri>{};
    while (pendingPages.isNotEmpty) {
      final pageUri = pendingPages.first;
      pendingPages.remove(pageUri);
      if (!visitedPages.add(pageUri)) continue;
      final pageDocument = pageUri == uri ? document : html_parser.parse(await _get(pageUri));
      for (final anchor in pageDocument.querySelectorAll('a[href*="/chapter-"]')) {
        final href = anchor.attributes['href'];
        if (href == null) continue;
        final chapterUri = _resolve(href);
        final chapterNumber = _chapterNumber(chapterUri);
        if (chapterNumber.isEmpty) continue;
        chapterMap[chapterUri.toString()] = TeamXChapter(
          id: chapterUri.toString(), number: chapterNumber, title: chapterNumber,
          publishedAt: _chapterDate(anchor), url: chapterUri.toString(), images: const [],
        );
      }
      pendingPages.addAll(_chapterPageUrls(pageDocument, uri).where((next) => !visitedPages.contains(next)));
    }
    final chapters = chapterMap.values.toList()
      ..sort((a, b) => a.numberValue.compareTo(b.numberValue));
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
    for (final image in document.querySelectorAll('img')) {
      final resolved = _image(image);
      if (resolved.isEmpty || !resolved.contains('azorafly.com')) continue;
      final lower = resolved.toLowerCase();
      final alt = (image.attributes['alt'] ?? '').toLowerCase();
      final isReaderImage = image.attributes.containsKey('data-reader-page-image') || image.attributes.containsKey('data-reader-index') || alt.contains('page') || lower.contains('/page-') || lower.contains('/wp-manga/data/') || lower.contains('/upload/series/');
      if (!isReaderImage || lower.contains('/featured/') || lower.contains('/banner/') || lower.contains('logo')) continue;
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
      final imageNode = anchor.querySelector('img[data-src], img[data-lazy-src], img[data-original], img[src], picture source') ?? anchor.parent?.querySelector('img[data-src], img[data-lazy-src], img[data-original], img[src], picture source') ?? anchor;
      final rawTitle = anchor.attributes['title'] ?? imageNode?.attributes['alt'] ?? _text(anchor);
      final title = (rawTitle is String ? rawTitle : '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (title.isEmpty || title.length > 300) continue;
      final image = _image(imageNode ?? anchor);
      final existing = items[uri.toString()];
      // The same series appears as both a poster card and a text link. Keep
      // the poster URL instead of letting the later text link overwrite it.
      items[uri.toString()] = TeamXManga(
        id: uri.toString(),
        title: title,
        url: uri.toString(),
        cover: image.isNotEmpty ? image : (existing?.cover ?? ''),
      );
    }
    return items.values.toList();
  }

  String _chapterNumber(Uri uri) {
    final segment = uri.pathSegments.where((part) => part.isNotEmpty).last;
    return RegExp(r'(\d+(?:\.\d+)?)').firstMatch(segment)?.group(1) ?? '';
  }

  String _mangaTitle(dynamic document, Uri uri) {
    final candidates = [
      _text(document.querySelector('.entry-title, .series-title, .manga-title, .post-title')),
      document.querySelector('meta[property="og:title"]')?.attributes['content'] ?? '',
      document.querySelector('meta[name="twitter:title"]')?.attributes['content'] ?? '',
    ].map((value) => _cleanHtml(value as String)).map((value) => value.replaceFirst(RegExp(r'\s*[|–-]\s*AzoraFly.*$', caseSensitive: false), '').trim()).where((value) => value.isNotEmpty && !_isStatusLabel(value));
    return candidates.isNotEmpty ? candidates.first : _fallbackName(uri);
  }

  bool _isStatusLabel(String value) => RegExp(r'^(الحالة|status|ongoing|completed|مستمر|مكتمل)$', caseSensitive: false).hasMatch(value.trim());

  Set<Uri> _chapterPageUrls(dynamic document, Uri mangaUri) {
    final pages = <Uri>{};
    for (final anchor in document.querySelectorAll('a[href]')) {
      final href = anchor.attributes['href'];
      if (href == null) continue;
      final resolved = _resolve(href);
      final text = _text(anchor).toLowerCase();
      final isPage = resolved.queryParameters.containsKey('page') || resolved.pathSegments.contains('page') || text.contains('next') || text.contains('التالي');
      final mangaPath = mangaUri.pathSegments.where((part) => part.isNotEmpty).join('/');
      final resolvedPath = resolved.pathSegments.where((part) => part.isNotEmpty).join('/');
      if (isPage && resolvedPath.startsWith(mangaPath)) pages.add(resolved);
    }
    return pages;
  }

  String _chapterDate(dynamic anchor) {
    dynamic node = anchor;
    for (var depth = 0; depth < 4 && node != null; depth++) {
      final text = _text(node);
      final match = RegExp(r'(\d+\s*(?:يوم|أسبوع|شهر|سنة)|منذ\s+[^\n]+)', caseSensitive: false).firstMatch(text);
      if (match != null) return match.group(0)!.trim();
      node = node.parent;
    }
    return '';
  }

  String _cleanHtml(String value) {
    final text = html_parser.parseFragment(value).text;
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  String _fallbackName(Uri uri) => uri.pathSegments.last.replaceAll('-', ' ');
  String _coverImage(dynamic document) {
    final candidates = document.querySelectorAll('img');
    for (final image in candidates) {
      final alt = (image.attributes['alt'] ?? '').toLowerCase();
      final raw = _image(image);
      if (raw.isEmpty) continue;
      if (raw.contains('/featured/') || raw.contains('storage.azorafly.com/upload/series/')) return raw;
      if (alt.isNotEmpty && !alt.contains('logo') && !alt.contains('avatar')) return raw;
    }
    return '';
  }
  Uri _resolve(String value) {
    final normalized = value.trim();
    if (normalized.startsWith('//')) return Uri.parse('https:$normalized');
    final parsed = Uri.parse(normalized);
    return parsed.isAbsolute ? parsed : baseUri.resolve(normalized);
  }
  String _text(dynamic node) {
    final text = node?.text;
    return text is String ? text.replaceAll(RegExp(r'\s+'), ' ').trim() : '';
  }

  String _image(dynamic node) {
    if (node == null) return '';
    final attrs = Map<String, String>.from(node.attributes as Map);
    final srcset = attrs['srcset'] ?? attrs['data-srcset'] ?? '';
    if (srcset.trim().isNotEmpty) {
      final values = srcset
          .split(',')
          .map((item) => item.trim().split(RegExp(r'\s+')).first.toString())
          .where((item) => item.isNotEmpty)
          .toList();
      if (values.isNotEmpty) {
        final imageUrl = values[values.length - 1].toString();
        return _resolve(imageUrl).toString();
      }
    }
    final value = attrs['data-src'] ??
        attrs['data-lazy-src'] ??
        attrs['data-original'] ??
        attrs['data-url'] ??
        attrs['content'] ??
        attrs['src'] ??
        '';
    if (value.isEmpty || value.startsWith('data:')) return '';
    return _resolve(value).toString();
  }
}
