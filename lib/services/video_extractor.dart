import 'package:html/parser.dart' as parser;

import 'anime_models.dart';

class VideoExtractor {
  static List<VideoServerModel> extract(String body, Uri baseUrl, String sourceName, String referer, Map<String, String> headers) {
    final doc = parser.parse(body);
    final candidates = <String>[];
    for (final node in doc.querySelectorAll('iframe, video, source, [data-video], [data-url], [data-file], [data-src]')) {
      for (final name in ['data-video', 'data-url', 'data-file', 'data-src', 'src']) {
        final value = node.attributes[name];
        if (value != null && value.isNotEmpty) candidates.add(value);
      }
    }
    final scripts = '${body}\n${doc.querySelectorAll('script').map((e) => e.text).join('\n')}';
    candidates.addAll(_scriptUrls(scripts));
    final servers = <String, VideoServerModel>{};
    for (final raw in candidates) {
      final url = _resolve(baseUrl, raw.replaceAll(r'\/', '/').replaceAll(r'\u0026', '&'));
      if (!_isPlayable(url)) continue;
      final type = url.toLowerCase().contains('.m3u8') ? 'hls' : 'mp4';
      final quality = RegExp(r'(\d{3,4}p)', caseSensitive: false).firstMatch(url)?.group(1) ?? '';
      servers[url] = VideoServerModel(name: '$sourceName${quality.isEmpty ? '' : ' • $quality'}', url: url, quality: quality, type: type, headers: {...headers, 'Referer': referer});
    }
    return servers.values.toList();
  }

  static List<String> _scriptUrls(String value) {
    final result = <String>[];
    for (final pattern in [RegExp(r'''(?:file|src|url|videoUrl|video_url|hls|stream)\s*[:=]\s*["']([^"']+)''', caseSensitive: false), RegExp(r'''["'](?:file|src|url|source)["']\s*:\s*["']([^"']+)''', caseSensitive: false)]) {
      result.addAll(pattern.allMatches(value).map((match) => match.group(1) ?? ''));
    }
    return result;
  }

  static String _resolve(Uri base, String value) {
    if (value.startsWith('//')) return 'https:$value';
    final uri = Uri.tryParse(value);
    return uri?.isAbsolute == true ? value : base.resolve(value).toString();
  }

  static bool _isPlayable(String url) {
    final value = url.toLowerCase();
    return value.contains('.m3u8') || value.contains('.mp4') || value.contains('dood') || value.contains('mp4upload');
  }
}
