import 'package:http/http.dart' as http;

import 'anime_models.dart';

abstract class AnimeSource {
  const AnimeSource();
  String get sourceKey;
  String get sourceName;
  String get sourceLogo;
  Uri get baseUrl;

  Future<List<AnimeModel>> fetchLatestAnime(int page);
  Future<List<AnimeModel>> searchAnime(String query, int page);
  Future<AnimeModel> getAnimeDetails(String animeUrl);
  Future<List<VideoServerModel>> getVideoExtractors(String episodeUrl);

  Future<String> getHtml(String url, {Map<String, String>? headers}) async {
    final response = await http.get(Uri.parse(url), headers: {...defaultHeaders, ...?headers}).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 400) throw SourceException(sourceKey, 'HTTP ${response.statusCode}');
    return response.body;
  }

  Map<String, String> get defaultHeaders => const {'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/124.0 Mobile Safari/537.36', 'Accept-Language': 'ar,en;q=0.8'};
}

class SourceException implements Exception {
  const SourceException(this.source, this.message);
  final String source, message;
  @override String toString() => '$source: $message';
}

Future<List<T>> safeSourceCalls<T>(Iterable<Future<List<T>> Function()> calls) async {
  final values = await Future.wait(calls.map((call) async { try { return await call(); } catch (_) { return <T>[]; } }));
  return values.expand((items) => items).toList();
}
