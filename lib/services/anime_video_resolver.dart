import 'package:html/parser.dart' as html_parser;

import 'anime_source.dart';
import 'content_models.dart';

/// Resolves playable media without coupling providers to one player format.
/// It intentionally returns only direct MP4/HLS URLs that MangaLord's player
/// can open, while keeping the episode page as the Referer for protected hosts.
List<AnimeServer> resolveAnimeVideoServers({
  required String body,
  required Uri baseUri,
  required String sourceKey,
  required String sourceName,
  required String referer,
  Map<String, String> headers = const {},
}) {
  final document = html_parser.parse(body);
  final candidates = <_VideoCandidate>[];

  for (final element in document.querySelectorAll('video, source, [data-video], [data-url], [data-file], [data-src]')) {
    final value = firstNonEmpty([
      htmlAttribute(element, 'data-video'),
      htmlAttribute(element, 'data-url'),
      htmlAttribute(element, 'data-file'),
      htmlAttribute(element, 'data-src'),
      htmlAttribute(element, 'src'),
    ]);
    if (value.isNotEmpty) candidates.add(_VideoCandidate(value, htmlText(element), htmlAttribute(element, 'label')));
  }

  final scripts = document.querySelectorAll('script').map((script) => script.text).join('\n');
  final searchable = '$body\n$scripts';
  candidates.addAll(_extractScriptCandidates(searchable));
  candidates.addAll(extractMediaUrls(searchable, baseUri).map((url) => _VideoCandidate(url, '', '')));

  final unique = <String, AnimeServer>{};
  for (final candidate in candidates) {
    final url = resolveSourceUrl(baseUri, candidate.value);
    if (!_isPlayable(url)) continue;
    final quality = RegExp(r'(\d{3,4}p)', caseSensitive: false).firstMatch('${candidate.label} ${candidate.name} $url')?.group(1) ?? '';
    unique[url] = AnimeServer(
      name: candidate.name.trim().isEmpty ? '$sourceName${quality.isEmpty ? '' : ' • $quality'}' : candidate.name.trim(),
      url: url,
      sourceKey: sourceKey,
      quality: quality,
      type: url.toLowerCase().contains('.m3u8') ? 'hls' : 'video',
      headers: {...headers, 'Referer': referer},
    );
  }
  return unique.values.toList();
}

List<_VideoCandidate> _extractScriptCandidates(String value) {
  final candidates = <_VideoCandidate>[];
  final patterns = [
    RegExp(r'''(?:file|src|url|source|videoUrl|video_url|hls|stream)\s*[:=]\s*["']([^"']+)["']''', caseSensitive: false),
    RegExp(r'''["'](?:file|src|url|source|videoUrl|video_url|hls|stream)["']\s*:\s*["']([^"']+)["']''', caseSensitive: false),
  ];
  for (final pattern in patterns) {
    for (final match in pattern.allMatches(value)) {
      final raw = match.group(1) ?? '';
      candidates.add(_VideoCandidate(raw.replaceAll(r'\/', '/').replaceAll(r'\u0026', '&'), '', ''));
    }
  }
  return candidates;
}

bool _isPlayable(String url) {
  final lower = url.toLowerCase();
  return url.isNotEmpty && (lower.contains('.m3u8') || lower.contains('.mp4') || lower.contains('/download/'));
}

class _VideoCandidate {
  const _VideoCandidate(this.value, this.name, this.label);
  final String value;
  final String name;
  final String label;
}
