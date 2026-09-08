import 'team_x_source.dart';

/// Common contract used by the UI, search, notifications, downloads, and reader.
abstract class MangaSource {
  String get sourceKey;
  String get sourceName;
  String get sourceLogo;
  String get imageReferer;

  Future<List<TeamXManga>> latest({int page = 1});
  Future<List<TeamXManga>> search(String query, {int page = 1});
  Future<TeamXManga> details(String url);
  Future<TeamXChapter> chapter(String url, {String? mangaTitle});
}
