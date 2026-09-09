import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class AnimePlayerScreen extends StatefulWidget {
  const AnimePlayerScreen({required this.url, this.headers = const {}, this.title = 'Anime', super.key});
  final String url, title;
  final Map<String, String> headers;
  @override State<AnimePlayerScreen> createState() => _AnimePlayerScreenState();
}

class _AnimePlayerScreenState extends State<AnimePlayerScreen> {
  late final Player player;
  late final VideoController videoController;

  @override
  void initState() {
    super.initState();
    player = Player();
    videoController = VideoController(player);
    player.open(Media(widget.url, httpHeaders: widget.headers));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        backgroundColor: Colors.black,
        body: Center(
          child: Video(controller: videoController, controls: MaterialVideoControls),
        ),
      );
}
