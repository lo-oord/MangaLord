class AnimeModel {
  const AnimeModel({required this.id, required this.title, required this.url, this.cover = '', this.description = '', this.sourceKey = '', this.sourceName = '', this.episodes = const []});
  final String id, title, url, cover, description, sourceKey, sourceName;
  final List<EpisodeModel> episodes;
  AnimeModel copyWith({String? description, String? cover, List<EpisodeModel>? episodes}) => AnimeModel(id: id, title: title, url: url, cover: cover ?? this.cover, description: description ?? this.description, sourceKey: sourceKey, sourceName: sourceName, episodes: episodes ?? this.episodes);
}

class EpisodeModel {
  const EpisodeModel({required this.id, required this.title, required this.url, this.number = '', this.thumbnail = '', this.sourceKey = ''});
  final String id, title, url, number, thumbnail, sourceKey;
}

class VideoServerModel {
  const VideoServerModel({required this.name, required this.url, this.quality = '', this.type = '', this.headers = const {}});
  final String name, url, quality, type;
  final Map<String, String> headers;
}
