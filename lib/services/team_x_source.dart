import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class TeamXSource {
  TeamXSource({http.Client? client}) : _client = client ?? http.Client();

  static final Uri baseUri = Uri.parse('https://olympustaff.com/');
  static const sourceName = 'Team X';
  static const sourceLogo = 'https://olympustaff.com/images/TeamX.png';
  static const _userAgent = 'MangaLord/1.0 (Flutter; Team X source)';
  final http.Client _client;

  Future<String> _get(Uri uri) async {
    final response = await _client.get(uri, headers: const {
      'User-Agent': _userAgent,
      'Accept': 'text/html,application/xhtml+xml',
      'Accept-Language': 'ar,en;q=0.8',
      'Referer': 'https://olympustaff.com/',
    }).timeout(const Duration(seconds: 20));
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
    final body = await _get(uri);
    final results = _parseMangaList(body);
    if (results.isNotEmpty) return results;
    final fallback = baseUri.resolve('series').replace(queryParameters: {
      'search': query,
      if (page > 1) 'page': '$page',
    });
    return _parseMangaList(await _get(fallback));
  }

  Future<TeamXManga> details(String url) async {
    final uri = _resolve(url);
    final document = html_parser.parse(await _get(uri));
    final title = _text(document.querySelector('h1, .entry-title, .post-title'));
    final cover = _image(document.querySelector(
      'img[alt="Manga Image"], .manga-image img, .series-image img, .thumb img, img',
    ));
    final description = _text(document.querySelector(
      '.description, .summary, .story, .synopsis, .manga-description, .post-content',
    ));
    final author = _metadata(document, ['author', 'المؤلف', 'الكاتب']);
    final artist = _metadata(document, ['artist', 'الرسام', 'الفنان']);
    final genres = document.querySelectorAll(
      'a[href*="genre="], .genres a, .genre a, .manga-genres a',
    ).map(_text).where((value) => value.isNotEmpty).toSet().join(', ');
    final status = _metadata(document, ['status', 'الحالة']);
    final chapters = _parseChapters(document, uri);
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
      title: title.isEmpty ? (mangaTitle ?? _fallbackName(uri)) : title,
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
      final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
      if (segments.length != 2 || segments.first != 'series') continue;
      final title = (anchor.attributes['title'] ?? _text(anchor)).replaceAll(RegExp(r'\s+'), ' ').trim();
      if (title.isEmpty || title.length > 300) continue;
      final image = _image(_nearbyImage(anchor));
      items[uri.toString()] = TeamXManga(
        id: uri.toString(), title: title, url: uri.toString(), cover: image,
      );
    }
    return items.values.toList();
  }

  List<TeamXChapter> _parseChapters(dynamic document, Uri mangaUri) {
    final output = <String, TeamXChapter>{};
    for (final anchor in document.querySelectorAll('a[href*="/series/"]')) {
      final href = anchor.attributes['href'];
      if (href == null) continue;
      final uri = _resolve(href);
      final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
      if (segments.length != 3 || segments.first != 'series') continue;
      if (segments[1] != _seriesSlug(mangaUri)) continue;
      final title = _text(anchor);
      if (title.isEmpty) continue;
      output[uri.toString()] = TeamXChapter(
        id: uri.toString(), title: title, url: uri.toString(), images: const [],
      );
    }
    final chapters = output.values.toList();
    chapters.sort((a, b) => _chapterNumber(b.title).compareTo(_chapterNumber(a.title)));
    return chapters;
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
    for (final node in document.querySelectorAll('li, .post-content_item, .summary_content, .metadata, p, div')) {
      final text = _text(node);
      if (!labels.any((label) => text.toLowerCase().contains(label.toLowerCase()))) continue;
      final value = text.replaceFirst(RegExp('${labels.join('|')}\\s*[:：]?\\s*', caseSensitive: false), '').trim();
      if (value.isNotEmpty && value.length < 300) return value;
    }
    return '';
  }

  double _chapterNumber(String text) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
    return double.tryParse(match?.group(1) ?? '') ?? 0;
  }

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
  const TeamXChapter({required this.id, required this.title, required this.url, required this.images});
  final String id, title, url;
  final List<String> images;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'url': url, 'images': images};
  factory TeamXChapter.fromJson(Map<String, dynamic> json) => TeamXChapter(id: json['id'] as String? ?? json['url'] as String, title: json['title'] as String? ?? '', url: json['url'] as String, images: (json['images'] as List? ?? const []).whereType<String>().toList());
}
