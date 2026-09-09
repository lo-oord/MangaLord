import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'm3u8_sniffer_web_view.dart';
import 'native_media_kit_player.dart';

/// Coordinates provider sniffing, native playback, and the WebView fallback.
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

  /// Backwards-compatible direct stream API used by older callers.
  final String? url;
  final Map<String, String> headers;
  final String? title;

  @override
  State<AnimePlayerScreen> createState() => _AnimePlayerScreenState();
}

class _AnimePlayerScreenState extends State<AnimePlayerScreen> {
  String? _videoUrl;
  Map<String, String> _headers = const {};
  bool _failed = false;
  bool _openWebView = false;
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
      _headers = widget.headers;
    }
  }

  void _captured(String url, Map<String, String> headers) {
    if (!mounted) return;
    setState(() {
      _videoUrl = url;
      _headers = headers;
      _failed = false;
    });
  }

  void _retry() => setState(() {
        _attempt++;
        _failed = false;
        _openWebView = false;
        _videoUrl = null;
      });

  @override
  Widget build(BuildContext context) {
    if (_videoUrl != null) {
      return NativeMediaKitPlayer(
        key: ValueKey(_videoUrl),
        url: _videoUrl!,
        headers: {...widget.headers, ..._headers},
        episodeId: _episodeId,
        episodeTitle: _title,
      );
    }
    if (_openWebView) return _directWebView();
    return Scaffold(
      backgroundColor: const Color(0xff101014),
      appBar: AppBar(title: Text(_title), backgroundColor: Colors.transparent),
      body: Stack(
        children: [
          M3u8SnifferWebView(
            key: ValueKey(_attempt),
            iframeUrl: _sourceUrl,
            refererUrl: widget.refererUrl,
            onUrlCaptured: _captured,
            onSniffingFailed: () => mounted ? setState(() => _failed = true) : null,
          ),
          if (!_failed) const _LoadingOverlay(),
          if (_failed) _ErrorOverlay(onRetry: _retry, onWebView: () => setState(() => _openWebView = true)),
        ],
      ),
    );
  }

  Widget _directWebView() => Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [IconButton(onPressed: _retry, icon: const Icon(Icons.refresh))],
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_sourceUrl), headers: {'Referer': widget.refererUrl}),
          onCreateWindow: (controller, action) async => false,
          shouldOverrideUrlLoading: (controller, action) async => NavigationActionPolicy.ALLOW,
        ),
      );
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          color: const Color(0xff101014).withOpacity(.92),
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 18), Text('جاري تجهيز الفيديو...', style: TextStyle(color: Colors.white70))]),
          ),
        ),
      );
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.onRetry, required this.onWebView});

  final VoidCallback onRetry;
  final VoidCallback onWebView;

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xff101014),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white54, size: 52),
            const SizedBox(height: 16),
            const Text('تعذر التقاط رابط الفيديو', style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry Sniffing')),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: onWebView, icon: const Icon(Icons.open_in_browser), label: const Text('Open in Web View Mode')),
          ],
        ),
      );
}
