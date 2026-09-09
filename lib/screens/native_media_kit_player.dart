import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoQualityOption {
  const VideoQualityOption({required this.label, required this.url});

  final String label;
  final String url;
}

class NativeMediaKitPlayer extends StatefulWidget {
  const NativeMediaKitPlayer({
    required this.url,
    required this.headers,
    required this.episodeId,
    this.episodeTitle = 'Anime',
    this.quality = 'Auto',
    this.qualityOptions = const [],
    super.key,
  });

  final String url;
  final Map<String, String> headers;
  final String episodeId;
  final String episodeTitle;
  final String quality;
  final List<VideoQualityOption> qualityOptions;

  @override
  State<NativeMediaKitPlayer> createState() => _NativeMediaKitPlayerState();
}

class _NativeMediaKitPlayerState extends State<NativeMediaKitPlayer> {
  late final Player _player;
  late final VideoController _videoController;
  StreamSubscription<Duration>? _positionSubscription;
  Duration _position = Duration.zero;
  bool _fullscreen = false;
  bool _resumePromptShown = false;
  bool _loadingQuality = false;
  double _rate = 1;
  String _quality = 'Auto';
  List<VideoQualityOption> _qualities = const [];
  Timer? _saveTimer;

  String get _progressKey => 'anime_progress_${widget.episodeId}';

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _quality = widget.quality;
    _qualities = widget.qualityOptions;
    _positionSubscription = _player.stream.position.listen((value) {
      if (!mounted) return;
      setState(() => _position = value);
    });
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());
    _open();
  }

  Future<void> _open() async {
    await _player.open(Media(widget.url, httpHeaders: widget.headers));
    if (_qualities.isEmpty && widget.url.toLowerCase().contains('.m3u8')) {
      await _loadHlsQualities();
    }
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt(_progressKey) ?? 0;
    if (seconds > 10 && mounted && !_resumePromptShown) {
      _resumePromptShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resume from ${_format(Duration(seconds: seconds))}?'),
          action: SnackBarAction(label: 'Resume', onPressed: () => _player.seek(Duration(seconds: seconds))),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _loadHlsQualities() async {
    try {
      final response = await http.get(Uri.parse(widget.url), headers: widget.headers).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300 || !response.body.contains('#EXT-X-STREAM-INF')) return;
      final lines = response.body.split(RegExp(r'\r?\n'));
      final found = <VideoQualityOption>[];
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index].trim();
        if (!line.startsWith('#EXT-X-STREAM-INF:') || index + 1 >= lines.length) continue;
        final media = lines[index + 1].trim();
        if (media.isEmpty || media.startsWith('#')) continue;
        final resolution = RegExp(r'RESOLUTION=\d+x(\d+)', caseSensitive: false).firstMatch(line)?.group(1);
        final bandwidth = RegExp(r'BANDWIDTH=(\d+)', caseSensitive: false).firstMatch(line)?.group(1);
        final label = resolution == null ? (bandwidth == null ? 'Auto' : '${(int.parse(bandwidth) / 1000).round()} kbps') : '${resolution}p';
        final absolute = Uri.parse(widget.url).resolve(media).toString();
        if (!found.any((item) => item.url == absolute)) found.add(VideoQualityOption(label: label, url: absolute));
      }
      if (mounted && found.isNotEmpty) setState(() => _qualities = found);
    } catch (_) {}
  }

  Future<void> _selectQuality(VideoQualityOption option) async {
    if (_loadingQuality || option.url == widget.url) return;
    setState(() {
      _loadingQuality = true;
      _quality = option.label;
    });
    final resumeAt = _position;
    try {
      await _player.open(Media(option.url, httpHeaders: widget.headers));
      await _player.seek(resumeAt);
    } finally {
      if (mounted) setState(() => _loadingQuality = false);
    }
  }

  Future<void> _saveProgress() async {
    if (_position.inSeconds <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_progressKey, _position.inSeconds);
  }

  String _format(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _fullscreen = !_fullscreen);
    await SystemChrome.setPreferredOrientations(
      _fullscreen ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight] : DeviceOrientation.values,
    );
    await SystemChrome.setEnabledSystemUIMode(_fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  Future<void> _setRate(double rate) async {
    setState(() => _rate = rate);
    await _player.setRate(rate);
  }

  Future<void> _seekBy(int seconds) async {
    final duration = _player.state.duration;
    final next = _position + Duration(seconds: seconds);
    await _player.seek(next < Duration.zero ? Duration.zero : (next > duration ? duration : next));
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _positionSubscription?.cancel();
    _saveProgress();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controls = Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTapDown: (details) {
          final width = MediaQuery.sizeOf(context).width;
          _seekBy(details.localPosition.dx < width / 2 ? -10 : 10);
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(onPressed: () => _seekBy(-10), icon: const Icon(Icons.replay_10, color: Colors.white)),
                  IconButton(onPressed: () => _seekBy(10), icon: const Icon(Icons.forward_10, color: Colors.white)),
                  Text(_format(_position), style: const TextStyle(color: Colors.white)),
                  const Spacer(),
                  if (_loadingQuality) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  if (_qualities.isNotEmpty)
                    PopupMenuButton<VideoQualityOption>(
                      tooltip: 'Quality',
                      onSelected: _selectQuality,
                      itemBuilder: (context) => _qualities.map((quality) => PopupMenuItem(value: quality, child: Text(quality.label))).toList(),
                      child: Padding(padding: const EdgeInsets.all(8), child: Text(_quality, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    )
                  else
                    Text(_quality, style: const TextStyle(color: Colors.white70)),
                  PopupMenuButton<double>(
                    initialValue: _rate,
                    tooltip: 'Playback speed',
                    onSelected: _setRate,
                    itemBuilder: (context) => [0.5, 1.0, 1.25, 1.5, 2.0].map((rate) => PopupMenuItem(value: rate, child: Text('${rate}x'))).toList(),
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.speed, color: Colors.white)),
                  ),
                  IconButton(onPressed: _toggleFullscreen, icon: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: _fullscreen,
      appBar: _fullscreen ? null : AppBar(title: Text(widget.episodeTitle), backgroundColor: Colors.black),
      body: _fullscreen
          ? SizedBox.expand(child: Stack(children: [Video(controller: _videoController), controls]))
          : Center(child: AspectRatio(aspectRatio: 16 / 9, child: Stack(children: [Video(controller: _videoController), controls]))),
    );
  }
}
