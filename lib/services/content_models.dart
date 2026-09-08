import 'package:html/parser.dart' as html_parser;

class SourceManga {
  const SourceManga({required this.id, required this.title, required this.url, required this.sourceKey, required this.sourceName, this.cover = '', this.description = '', this.author = '', this.genres = const <String>[], this.status = '', this.chapters = const <SourceChapter>[]});
  final String id, title, url, sourceKey, sourceName, cover, description, author, status;
  final List<String> genres;
  final List<SourceChapter> chapters;
}
class SourceChapter {
  const SourceChapter({required this.id, required this.title, required this.url, required this.sourceKey, this.number = '', this.pages = const <String>[]});
  final String id, title, url, sourceKey, number;
  final List<String> pages;
}
class AnimeTitle {
  const AnimeTitle({required this.id, required this.title, required this.url, required this.sourceKey, required this.sourceName, this.sourceLogo = '', this.poster = '', this.cover = '', this.description = '', this.genres = const <String>[], this.status = '', this.year = '', this.episodes = const <AnimeEpisode>[]});
  final String id, title, url, sourceKey, sourceName, sourceLogo, poster, cover, description, status, year;
  final List<String> genres;
  final List<AnimeEpisode> episodes;
}
class AnimeEpisode {
  const AnimeEpisode({required this.id, required this.title, required this.url, required this.sourceKey, this.number = '', this.servers = const <AnimeServer>[]});
  final String id, title, url, sourceKey, number;
  final List<AnimeServer> servers;
}
class AnimeServer {
  const AnimeServer({required this.name, required this.url, required this.sourceKey, this.quality = '', this.headers = const <String, String>{}, this.subtitles = const <AnimeSubtitle>[]});
  final String name, url, sourceKey, quality;
  final Map<String, String> headers;
  final List<AnimeSubtitle> subtitles;
}
class AnimeSubtitle {
  const AnimeSubtitle({required this.language, required this.url});
  final String language, url;
}
String cleanHtmlText(String value) => (html_parser.parseFragment(value).text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
String firstNonEmpty(Iterable<String> values) => values.map((value) => value.trim()).firstWhere((value) => value.isNotEmpty, orElse: () => '');
String stableSourceId(String sourceKey, String url) => '$sourceKey:${Uri.tryParse(url)?.toString() ?? url}';
String resolveSourceUrl(Uri base, String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.startsWith('data:')) return '';
  if (normalized.startsWith('//')) return 'https:$normalized';
  final parsed = Uri.tryParse(normalized);
  return parsed?.isAbsolute == true ? parsed.toString() : base.resolve(normalized).toString();
}
String imageFromElement(dynamic element, Uri base) {
  if (element == null) return '';
  final attrs = element.attributes as Map<String, String>;
  final srcset = firstNonEmpty([attrs['data-srcset'] ?? '', attrs['srcset'] ?? '']);
  if (srcset.isNotEmpty) {
    final resolved = srcset.split(',').map((item) => resolveSourceUrl(base, item.trim().split(RegExp(r'\s+')).first)).where((item) => item.isNotEmpty).toList();
    if (resolved.isNotEmpty) return resolved.last;
  }
  return resolveSourceUrl(base, firstNonEmpty([attrs['data-src'] ?? '', attrs['data-lazy-src'] ?? '', attrs['data-original'] ?? '', attrs['src'] ?? '']));
}
String firstImage(dynamic node, Uri base) => imageFromElement(node?.querySelector('img'), base);
String htmlAttribute(dynamic node, String name) => node == null ? '' : (node.attributes[name] ?? '').trim();
String htmlText(dynamic node) => node?.text is String ? cleanHtmlText(node.text as String) : '';
String metaContent(dynamic document, String selector) => htmlAttribute(document.querySelector(selector), 'content');
String extractMediaUrl(String value, Uri base) {
  final urls = extractMediaUrls(value, base);
  return urls.isEmpty ? '' : urls.first;
}
List<String> extractMediaUrls(String value, Uri base) {
  final decoded = value.replaceAll(r'\/', '/').replaceAll(r'\u0026', '&').replaceAll('&amp;', '&');
  return RegExp(r'''(?:https?:)?//[^\s"'<>\\]+(?:\.m3u8|\.mp4)(?:\?[^\s"'<>\\]*)?''', caseSensitive: false)
      .allMatches(decoded)
      .map((match) => resolveSourceUrl(base, match.group(0)!))
      .where((url) => url.isNotEmpty)
      .toSet()
      .toList();
}
String extractEpisodeNumber(String value) => RegExp(r'(?:episode|الحلقة|ep)[^\d]*(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(value)?.group(1) ?? RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value)?.group(1) ?? '';
List<String> uniqueStrings(Iterable<String> values) => values.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet().toList();
class SourceFailure implements Exception {
  const SourceFailure(this.sourceKey, this.message);
  final String sourceKey, message;
  @override String toString() => '$sourceKey: $message';
}
Future<List<T>> isolateSourceFailures<T>(Iterable<Future<List<T>> Function()> requests) async {
  final output = <T>[];
  for (final request in requests) {
    try { output.addAll(await request()); } catch (_) {}
  }
  return output;
}
