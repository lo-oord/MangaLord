import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class StarzSource {
  StarzSource({http.Client? client}) : _client = client ?? http.Client();

  static final Uri baseUri = Uri.parse('https://starzmanga.com/');
  static const sourceName = 'Manga Starz';
  static const sourceLogo = 'https://starz.manga-starz.net/wp-content/uploads/starzmanga.png';
  final http.Client _client;

  Future<String> _get(Uri uri) async {
    final response = await _client.get(uri, headers: const {
      'User-Agent': 'MangaLord/1.0 (Flutter; Manga Starz source)',
      'Accept': 'text/html,application/xhtml+xml',
      'Accept-Language': 'ar,en;q=0.8',
      'Referer': 'https://starzmanga.com/',
    });
    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw Exception('Manga Starz returned HTTP ${response.statusCode}');
    }
    return response.body;
  }

  Future<List<StarzManga>> latest({int page = 1}) async {
    final uri = page <= 1 ? baseUri : Uri.parse('https://starzmanga.com/manga/page/$page/');
    return _parseMangaList(await _get(uri));
  }

  Future<List<StarzManga>> search(String query, {int page = 1}) async {
    final uri = baseUri.replace(queryParameters: {
      's': query,
      'post_type': 'wp-manga',
      if (page > 1) 'paged': '$page',
    });
    return _parseMangaList(await _get(uri));
  }

  Future<StarzManga> details(String url) async {
    final uri = _resolve(url);
    final document = html_parser.parse(await _get(uri));
    final title = _text(document.querySelector('.post-title h1, .post-title, h1.entry-title, h1'))
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cover = _image(document.querySelector('.summary_image img, .tab-summary .summary_image img, .post-content img'));
    final description = _text(document.querySelector('.description-summary, .summary_content, .description-content, .manga-summary'));
    final author = _text(document.querySelector('.author-content, .author, .summary_content .author'));
    final genres = document.querySelectorAll('.genres-content a, .genres a, .manga-genres a').map((e) => _text(e)).where((e) => e.isNotEmpty).join(', ');
    final status = _text(document.querySelector('.post-content_item.manga-status .summary-content, .summary_content .post-content_item'));
    final chapters = _parseChapters(document, uri);
    return StarzManga(
      id: uri.toString(),
      title: title.isEmpty ? uri.pathSegments.where((e) => e.isNotEmpty).last : title,
      url: uri.toString(),
      cover: cover,
      description: description,
      author: author,
      genres: genres,
      status: status,
      chapters: chapters,
    );
  }

  Future<StarzChapter> chapter(String url, {String? mangaTitle}) async {
    final uri = _resolve(url);
    final document = html_parser.parse(await _get(uri));
    final title = _text(document.querySelector('.c-breadcrumb-wrapper .breadcrumb li:last-child, .reading-content h1, h1'));
    final images = <String>[];
    final containers = document.querySelectorAll('.reading-content, #chapter-content, .page-break, .chapter-content');
    final nodes = containers.isEmpty ? document.querySelectorAll('img') : containers.expand((e) => e.querySelectorAll('img'));
    for (final image in nodes) {
      final value = image.attributes['data-src'] ?? image.attributes['data-lazy-src'] ?? image.attributes['data-original'] ?? image.attributes['src'];
      if (value == null || value.trim().isEmpty || value.startsWith('data:')) continue;
      final resolved = _resolve(value).toString();
      if (!images.contains(resolved) && !_isDecoration(resolved)) images.add(resolved);
    }
    if (images.isEmpty) throw Exception('No chapter images found on Manga Starz');
    return StarzChapter(
      id: uri.toString(),
      title: title.isEmpty ? (mangaTitle ?? uri.pathSegments.last) : title,
      url: uri.toString(),
      images: images,
    );
  }

  List<StarzManga> _parseMangaList(String source) {
    final document = html_parser.parse(source);
    final items = <String, StarzManga>{};
    for (final anchor in document.querySelectorAll('a[href*="/manga/"]')) {
      final href = anchor.attributes['href'];
      if (href == null) continue;
      final uri = _resolve(href);
      final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
      if (segments.length != 2 || segments.first != 'manga') continue;
      final container = anchor.closest('.c-tabs-item__content, .page-item-detail, .row.c-tabs-item__content, .item-summary') ?? anchor.parent;
      final imageNode = container?.querySelector('img') ?? anchor.querySelector('img');
      final image = _image(imageNode);
      final title = (anchor.attributes['title'] ?? _text(anchor)).replaceAll(RegExp(r'\s+'), ' ').trim();
      if (title.isEmpty) continue;
      items[uri.toString()] = StarzManga(id: uri.toString(), title: title, url: uri.toString(), cover: image);
    }
    return items.values.toList();
  }

  List<StarzChapter> _parseChapters(dynamic document, Uri mangaUri) {
    final output = <String, StarzChapter>{};
    for (final anchor in document.querySelectorAll('a[href*="/manga/"]')) {
      final href = anchor.attributes['href'];
      if (href == null) continue;
      final uri = _resolve(href);
      final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
      if (segments.length < 3 || segments.first != 'manga') continue;
      final chapterName = _text(anchor);
      if (chapterName.isEmpty) continue;
      output[uri.toString()] = StarzChapter(id: uri.toString(), title: chapterName, url: uri.toString(), images: const []);
    }
    final list = output.values.toList();
    list.sort((a, b) => _chapterNumber(b.title).compareTo(_chapterNumber(a.title)));
    return list;
  }

  double _chapterNumber(String text) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
    return double.tryParse(match?.group(1) ?? '') ?? 0;
  }

  Uri _resolve(String value) => Uri.parse(value).isAbsolute ? Uri.parse(value) : baseUri.resolve(value);

  String _text(dynamic node) => node?.text?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';

  String _image(dynamic node) {
    if (node == null) return '';
    final value = node.attributes['data-src'] ?? node.attributes['data-lazy-src'] ?? node.attributes['data-original'] ?? node.attributes['src'] ?? '';
    return value.isEmpty ? '' : _resolve(value).toString();
  }

  bool _isDecoration(String url) => RegExp(r'logo|avatar|icon|loading|blank', caseSensitive: false).hasMatch(url);
}

class StarzManga {
  const StarzManga({required this.id, required this.title, required this.url, this.cover = '', this.description = '', this.author = '', this.genres = '', this.status = '', this.chapters = const []});
  final String id, title, url, cover, description, author, genres, status;
  final List<StarzChapter> chapters;

  StarzManga copyWith({String? description, String? author, String? genres, String? status, List<StarzChapter>? chapters, String? cover}) => StarzManga(id: id, title: title, url: url, cover: cover ?? this.cover, description: description ?? this.description, author: author ?? this.author, genres: genres ?? this.genres, status: status ?? this.status, chapters: chapters ?? this.chapters);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'url': url, 'cover': cover, 'description': description, 'author': author, 'genres': genres, 'status': status, 'chapters': chapters.map((e) => e.toJson()).toList()};

  factory StarzManga.fromJson(Map<String, dynamic> json) => StarzManga(id: json['id'] as String, title: json['title'] as String, url: json['url'] as String, cover: json['cover'] as String? ?? '', description: json['description'] as String? ?? '', author: json['author'] as String? ?? '', genres: json['genres'] as String? ?? '', status: json['status'] as String? ?? '', chapters: ((json['chapters'] as List?) ?? const []).whereType<Map>().map((e) => StarzChapter.fromJson(Map<String, dynamic>.from(e))).toList());
}

class StarzChapter {
  const StarzChapter({required this.id, required this.title, required this.url, required this.images});
  final String id, title, url;
  final List<String> images;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'url': url, 'images': images};
  factory StarzChapter.fromJson(Map<String, dynamic> json) => StarzChapter(id: json['id'] as String, title: json['title'] as String, url: json['url'] as String, images: (json['images'] as List? ?? const []).cast<String>());
}
