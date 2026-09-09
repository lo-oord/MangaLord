import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'manga_source.dart';

class TeamXSource implements MangaSource {
  TeamXSource({http.Client? client}) : _client = client ?? http.Client();

  static final Uri baseUri = Uri.parse('https://olympustaff.com/');
  static const teamXSourceName = 'Team X';
  static const teamXSourceLogo = 'https://olympustaff.com/images/TeamX.png';
  static const _userAgent = 'MangaLord/1.0 (Flutter; Team X source)';
  final http.Client _client;

  @override
  String get sourceKey => 'team_x';
  @override
  String get sourceName => TeamXSource.teamXSourceName;
  @override
  String get sourceLogo => TeamXSource.teamXSourceLogo;
  @override
  String get imageReferer => baseUri.toString();

  Future<String> _get(Uri uri) async {
    final response = await _client.get(uri, headers: const {
      'User-Agent': _userAgent,
      'Accept': 'text/html,application/xhtml+xml',
      'Accept-Language': 'ar,en;q=0.8',
      'Referer': 'https://olympustaff.com/',
    }).timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw Exception('Team X returned HTTP ${response.statusCode}');
    }
    return response.body;
  }

  Future<List<TeamXManga>> latest({int page = 1}) async {
    final uri = page <= 1 ? baseUri : baseUri.resolve('series?page=$page');
    return _parseMangaList(await _get(uri));
  }

  Future<List<TeamXManga>> search(String query, {int page = 1}) async {
    final uri = baseUri.resolve('search').replace(queryParameters: {
      'keyword': query,
      if (page > 1) 'page': '$page',
    });
    final results = _parseMangaList(await _get(uri));
    if (results.isNotEmpty) return results;
    final fallback = baseUri.resolve('series').replace(queryParameters: {
      'search': query,
      if (page > 1) 'page': '$page',
    });
    return _parseMangaList(await _get(fallback));
  }

  Future<TeamXManga> details(String url) async {
    final uri = _resolve(url);
    final firstDocument = html_parser.parse(await _get(uri));
    final title = _text(firstDocument.querySelector('.author-info-title h1, h1'));
    final cover = _image(firstDocument.querySelector(
      'img[alt="Manga Image"], .col-md-3 .whitebox img, .manga-image img',
    ));
    final description = _text(firstDocument.querySelector(
      '.review-content p, .review-content, .description, .synopsis',
    ));
    final author = _metadata(firstDocument, ['author', 'المؤلف', 'الكاتب']);
    final artist = _metadata(firstDocument, ['artist', 'الرسام', 'الفنان']);
    final genres = firstDocument.querySelectorAll(
      'a[href*="genre="], .review-author-info a, .genres a',
    ).map(_text).where((value) => value.isNotEmpty).toSet().join(', ');
    final status = _metadata(firstDocument, ['status', 'الحالة']);

    final allChapters = <String, TeamXChapter>{};
    _parseChapters(firstDocument, uri).forEach((chapter) {
      allChapters[chapter.url] = chapter;
    });

    // Team X renders a fixed page of chapters and exposes the remaining pages
    // through links such as ?page=2. Fetch every page so a 200-chapter manga
    // is not silently truncated to the first 40 entries.
    final pendingPages = <Uri>{..._chapterPageUrls(firstDocument, uri)};
    final visitedPages = <Uri>{uri};
    while (pendingPages.isNotEmpty) {
      final pageUrl = pendingPages.first;
      pendingPages.remove(pageUrl);
      if (!visitedPages.add(pageUrl)) continue;
      final pageDocument = html_parser.parse(await _get(pageUrl));
      for (final chapter in _parseChapters(pageDocument, uri)) {
        allChapters[chapter.url] = chapter;
      }
      pendingPages.addAll(_chapterPageUrls(pageDocument, uri).where((next) => !visitedPages.contains(next)));
    }
    final chapters = allChapters.values.toList()
      ..sort((a, b) => a.numberValue.compareTo(b.numberValue));

    return TeamXManga(
      id: uri.toString(),
      title: title.isEmpty ? _fallbackName(uri) : title,
      url: uri.toString(),
      cover: cover,
      description: description,
      author: [author, artist].where((value) => value.isNotEmpty).join(' / '),
      genres: genres,
      status: status,
      chapters: chapters,
    );
  }

  Future<TeamXChapter> chapter(String url, {String? mangaTitle}) async {
    final uri = _resolve(url);
    final document = html_parser.parse(await _get(uri));
    final number = _chapterNumberFromUrl(uri);
    final title = _text(document.querySelector('h1, .chapter-title, .entry-title'));
    final containers = document.querySelectorAll(
      '#chapter-content, .reading-content, .chapter-content, .page-break, .reading-area',
    );
    final nodes = containers.isEmpty
        ? document.querySelectorAll('img[alt*="episode" i], img[src*="/uploads/"]')
        : containers.expand((node) => node.querySelectorAll('img'));
    final images = <String>[];
    for (final image in nodes) {
      final resolved = _image(image);
      if (resolved.isEmpty || _isDecoration(resolved) || images.contains(resolved)) continue;
      images.add(resolved);
    }
    if (images.isEmpty) throw Exception('No chapter images found on Team X');
    return TeamXChapter(
      id: uri.toString(),
      number: number,
      title: number.isEmpty ? (title.isEmpty ? (mangaTitle ?? _fallbackName(uri)) : title) : number,
      publishedAt: '',
      url: uri.toString(),
      images: images,
    );
  }

  List<TeamXManga> _parseMangaList(String source) {
    final document = html_parser.parse(source);
    final items = <String, TeamXManga>{};
    for (final card in document.querySelectorAll('a[href*="/series/"]')) {
      final href = card.attributes['href'];
      if (href == null) continue;
      final uri = _resolve(href);
      final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
      if (segments.length != 2 || segments.first != 'series') continue;
      final image = _image(_nearbyImage(card));
      final titleNode = card.querySelector('.series-title, .manga-title, h3, h4, .title');
      final title = _cleanTitle(card.attributes['title'] ?? card.attributes['aria-label'] ?? _text(titleNode ?? card));
      if (title.isEmpty || title.length > 300) continue;
      items[uri.toString()] = TeamXManga(
        id: uri.toString(), title: title, url: uri.toString(), cover: image,
      );
    }
    return items.values.toList();
  }

  List<TeamXChapter> _parseChapters(dynamic document, Uri mangaUri) {
    final output = <String, TeamXChapter>{};
    for (final card in document.querySelectorAll('.chapter-card')) {
      final anchor = card.querySelector('a.chapter-link, a[href*="/series/"]');
      final href = anchor?.attributes['href'];
      if (href == null) continue;
      final uri = _resolve(href);
      final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
      if (segments.length != 3 || segments.first != 'series') continue;
      if (segments[1] != _seriesSlug(mangaUri)) continue;
      final number = _cleanChapterNumber(card.attributes['data-number'] ?? _text(card.querySelector('.chapter-number')));
      final date = _text(card.querySelector('.chapter-date'));
      output[uri.toString()] = TeamXChapter(
        id: uri.toString(),
        number: number.isEmpty ? _chapterNumberFromUrl(uri) : number,
        title: number.isEmpty ? _chapterNumberFromUrl(uri) : number,
        publishedAt: date,
        url: uri.toString(),
        images: const [],
      );
    }
    return output.values.toList();
  }

  Set<Uri> _chapterPageUrls(dynamic document, Uri mangaUri) {
    final urls = <Uri>{};
    for (final anchor in document.querySelectorAll('a[href*="page="]')) {
      final href = anchor.attributes['href'];
      if (href == null) continue;
      final uri = _resolve(href);
      if (uri.pathSegments.contains('series') && uri.pathSegments.length >= 2 && uri.pathSegments[1] == _seriesSlug(mangaUri)) {
        urls.add(uri);
      }
    }
    return urls;
  }

  dynamic _nearbyImage(dynamic anchor) {
    dynamic current = anchor;
    for (var depth = 0; depth < 6 && current != null; depth++) {
      final image = current.querySelector('img');
      if (image != null) return image;
      current = current.parent;
    }
    return null;
  }

  String _metadata(dynamic document, List<String> labels) {
    for (final node in document.querySelectorAll('.full-list-info, li, .metadata')) {
      final valueNode = node.querySelector('a, span');
      final text = _text(node);
      if (!labels.any((label) => text.toLowerCase().contains(label.toLowerCase()))) continue;
      final value = _text(valueNode).trim();
      if (value.isNotEmpty && value.length < 300) return value;
    }
    return '';
  }

  String _chapterNumberFromUrl(Uri uri) => uri.pathSegments.where((part) => part.isNotEmpty).last;
  String _cleanChapterNumber(String value) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value);
    return match?.group(1) ?? '';
  }
  String _cleanTitle(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
  String _seriesSlug(Uri uri) => uri.pathSegments.where((part) => part.isNotEmpty).elementAt(1);
  String _fallbackName(Uri uri) => uri.pathSegments.where((part) => part.isNotEmpty).last.replaceAll('-', ' ');
  Uri _resolve(String value) => Uri.parse(value).isAbsolute ? Uri.parse(value) : baseUri.resolve(value);
  String _text(dynamic node) => node?.text?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';

  String _image(dynamic node) {
    if (node == null) return '';
    final srcset = node.attributes['srcset'] as String?;
    if (srcset != null && srcset.trim().isNotEmpty) {
      final candidates = srcset.split(',').map((item) => item.trim().split(RegExp(r'\s+')).first).where((item) => item.isNotEmpty).toList();
      if (candidates.isNotEmpty) return _resolve(candidates.last).toString();
    }
    final value = node.attributes['data-src'] ?? node.attributes['data-lazy-src'] ?? node.attributes['data-original'] ?? node.attributes['src'] ?? '';
    return value.isEmpty || value.startsWith('data:') ? '' : _resolve(value).toString();
  }

  bool _isDecoration(String url) => RegExp(r'logo|avatar|icon|loading|blank|advert', caseSensitive: false).hasMatch(url);
}

class TeamXManga {
  const TeamXManga({required this.id, required this.title, required this.url, this.cover = '', this.description = '', this.author = '', this.genres = '', this.status = '', this.chapters = const []});
  final String id, title, url, cover, description, author, genres, status;
  final List<TeamXChapter> chapters;
  TeamXManga copyWith({String? description, String? author, String? genres, String? status, List<TeamXChapter>? chapters, String? cover}) => TeamXManga(id: id, title: title, url: url, cover: cover ?? this.cover, description: description ?? this.description, author: author ?? this.author, genres: genres ?? this.genres, status: status ?? this.status, chapters: chapters ?? this.chapters);
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'url': url, 'cover': cover, 'description': description, 'author': author, 'genres': genres, 'status': status, 'chapters': chapters.map((e) => e.toJson()).toList()};
  factory TeamXManga.fromJson(Map<String, dynamic> json) => TeamXManga(id: json['id'] as String? ?? json['url'] as String, title: json['title'] as String? ?? '', url: json['url'] as String, cover: json['cover'] as String? ?? '', description: json['description'] as String? ?? '', author: json['author'] as String? ?? '', genres: json['genres'] as String? ?? '', status: json['status'] as String? ?? '', chapters: ((json['chapters'] as List?) ?? const []).whereType<Map>().map((e) => TeamXChapter.fromJson(Map<String, dynamic>.from(e))).toList());
}

class TeamXChapter {
  const TeamXChapter({required this.id, required this.number, required this.title, required this.publishedAt, required this.url, required this.images});
  final String id, number, title, publishedAt, url;
  final List<String> images;
  double get numberValue => double.tryParse(number) ?? 0;
  Map<String, dynamic> toJson() => {'id': id, 'number': number, 'title': title, 'publishedAt': publishedAt, 'url': url, 'images': images};
  factory TeamXChapter.fromJson(Map<String, dynamic> json) => TeamXChapter(id: json['id'] as String? ?? json['url'] as String, number: json['number'] as String? ?? json['title'] as String? ?? '', title: json['title'] as String? ?? '', publishedAt: json['publishedAt'] as String? ?? '', url: json['url'] as String, images: (json['images'] as List? ?? const []).whereType<String>().toList());
}
