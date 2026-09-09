import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Loads a provider iframe and reports the first playable media request.
class M3u8SnifferWebView extends StatefulWidget {
  const M3u8SnifferWebView({
    required this.iframeUrl,
    required this.refererUrl,
    required this.onUrlCaptured,
    required this.onSniffingFailed,
    this.onWebViewCreated,
    super.key,
  });

  final String iframeUrl;
  final String refererUrl;
  final void Function(String videoUrl, Map<String, String> headers) onUrlCaptured;
  final VoidCallback onSniffingFailed;
  final void Function(InAppWebViewController controller)? onWebViewCreated;

  @override
  State<M3u8SnifferWebView> createState() => _M3u8SnifferWebViewState();
}

class _M3u8SnifferWebViewState extends State<M3u8SnifferWebView> {
  static const _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

  Timer? _timeout;
  bool _captured = false;

  String get _snifferScript => '''
(function() {
  if (window.__mangaLordSnifferInstalled) return;
  window.__mangaLordSnifferInstalled = true;
  const looksPlayable = (url) => /\\.(m3u8|mp4)(?:[?#]|$)|master\\.m3u8/i.test(String(url || ''));
  const report = (url, headers) => {
    if (!looksPlayable(url)) return;
    window.flutter_inappwebview.callHandler('mangaLordMediaCaptured', {
      url: String(url),
      headers: headers || {}
    });
  };
  const originalFetch = window.fetch;
  window.fetch = function(input, init) {
    try {
      const url = typeof input === 'string' ? input : input.url;
      const headers = (init && init.headers) || {};
      report(url, headers);
    } catch (_) {}
    return originalFetch.apply(this, arguments).then(function(response) {
      try { report(response.url, {}); } catch (_) {}
      return response;
    });
  };
  const originalOpen = XMLHttpRequest.prototype.open;
  const originalSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.open = function(method, url) {
    this.__mangaLordUrl = url;
    return originalOpen.apply(this, arguments);
  };
  XMLHttpRequest.prototype.send = function() {
    try { report(this.__mangaLordUrl, {}); } catch (_) {}
    return originalSend.apply(this, arguments);
  };
})();
''';

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(seconds: 15), () {
      if (!_captured && mounted) widget.onSniffingFailed();
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  void _capture(dynamic value) {
    if (_captured || value is! Map) return;
    final url = value['url']?.toString() ?? '';
    if (url.isEmpty) return;
    _captured = true;
    _timeout?.cancel();
    final headers = <String, String>{'Referer': widget.refererUrl, 'User-Agent': _desktopUserAgent};
    final rawHeaders = value['headers'];
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, headerValue) {
        if (headerValue is String) headers[key.toString()] = headerValue;
      });
    }
    widget.onUrlCaptured(url, headers);
  }

  @override
  Widget build(BuildContext context) => InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(widget.iframeUrl),
          headers: {'Referer': widget.refererUrl, 'User-Agent': _desktopUserAgent},
        ),
        initialUserScripts: [
          UserScript(source: _snifferScript, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
        ],
        onWebViewCreated: (controller) {
          widget.onWebViewCreated?.call(controller);
          controller.addJavaScriptHandler(
            handlerName: 'mangaLordMediaCaptured',
            callback: (args) => args.isEmpty ? null : _capture(args.first),
          );
        },
        onCreateWindow: (controller, createWindowAction) async => false,
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final target = navigationAction.request.url?.toString() ?? '';
          final current = widget.iframeUrl;
          if (target.isNotEmpty && !target.startsWith(current)) return NavigationActionPolicy.CANCEL;
          return NavigationActionPolicy.ALLOW;
        },
        onLoadStop: (controller, url) async {
          await controller.evaluateJavascript(source: _snifferScript);
        },
        onReceivedError: (controller, request, error) {
          if (!_captured && mounted) widget.onSniffingFailed();
        },
      );
}

/// Keeps the import useful for projects that expose JSON headers in logs.
String encodeSnifferHeaders(Map<String, String> headers) => jsonEncode(headers);
