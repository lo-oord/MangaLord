import 'package:flutter/material.dart';

import 'm3u8_sniffer_web_view.dart';
import 'native_media_kit_player.dart';

/// Resolves the episode in a hidden WebView and plays the captured stream
/// exclusively with the native media_kit player.
class AnimePlayerScreen extends StatefulWidget {
  const AnimePlayerScreen({
    this.iframeUrl,
    this.refererUrl = '',
    this.episodeId,
    this.episodeTitle = 'Anime',
    this.url,
    this.headers = const {},
    this.title,
    super.key,
  }) : assert(iframeUrl != null || url != null, 'iframeUrl or url is required');

  final String? iframeUrl;
  final String refererUrl;
  final String? episodeId;
  final String episodeTitle;

  /// Backwards-compatible direct stream API.
  final String? url;
  final Map<String, String> headers;
  final String? title;

  @override
  State<AnimePlayerScreen> createState() => _AnimePlayerScreenState();
}

class _AnimePlayerScreenState extends State<AnimePlayerScreen> {
  String? _videoUrl;
  Map<String, String> _capturedHeaders = const {};
  String? _error;
  int _attempt = 0;

  String get _sourceUrl => widget.iframeUrl ?? widget.url!;
  String get _episodeId => widget.episodeId ?? _sourceUrl;
  String get _title => widget.title ?? widget.episodeTitle;

  bool get _isDirectStream {
    final value = _sourceUrl.toLowerCase();
    return value.contains('.m3u8') || value.contains('.mp4');
  }

  @override
  void initState() {
    super.initState();
    if (_isDirectStream) {
      _videoUrl = _sourceUrl;
      _capturedHeaders = widget.headers;
    }
  }

  void _onCaptured(String url, Map<String, String> headers) {
    if (!mounted) return;
    setState(() {
      _videoUrl = url;
      _capturedHeaders = headers;
      _error = null;
    });
  }

  void _retry() => setState(() {
        _attempt++;
        _videoUrl = null;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final videoUrl = _videoUrl;
    if (videoUrl != null) {
      return NativeMediaKitPlayer(
        key: ValueKey(videoUrl),
        url: videoUrl,
        headers: {...widget.headers, ..._capturedHeaders},
        episodeId: _episodeId,
        episodeTitle: _title,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(_title), backgroundColor: Colors.black),
      body: Stack(
        children: [
          // This WebView is deliberately hidden behind the native loading UI.
          // It is only a resolver, never a surface for watching the website.
          SizedBox(
            width: 1,
            height: 1,
            child: Opacity(
              opacity: 0,
              child: M3u8SnifferWebView(
              key: ValueKey(_attempt),
              iframeUrl: _sourceUrl,
              refererUrl: widget.refererUrl,
              onUrlCaptured: _onCaptured,
              onSniffingFailed: () {
                if (mounted) setState(() => _error = 'تعذر استخراج رابط الفيديو');
              },
            ),
            ),
          ),
          Center(
            child: _error == null
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 18),
                      Text('جاري تجهيز الحلقة...', style: TextStyle(color: Colors.white70)),
                    ],
                  )
                : _ErrorView(onRetry: _retry),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 52),
          const SizedBox(height: 14),
          const Text('تعذر تجهيز الفيديو', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
        ],
      );
}
