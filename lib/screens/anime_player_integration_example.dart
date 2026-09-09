import 'package:flutter/material.dart';

import 'anime_player_screen.dart';

/// Example episode action; adapt the model fields to the existing episode UI.
void openEpisodePlayer(
  BuildContext context, {
  required String iframeUrl,
  required String refererUrl,
  required String episodeId,
  required String episodeTitle,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AnimePlayerScreen(
        iframeUrl: iframeUrl,
        refererUrl: refererUrl,
        episodeId: episodeId,
        episodeTitle: episodeTitle,
      ),
    ),
  );
}

// Example button:
// ElevatedButton(
//   onPressed: () => openEpisodePlayer(
//     context,
//     iframeUrl: server.url,
//     refererUrl: episode.url,
//     episodeId: episode.id,
//     episodeTitle: episode.title,
//   ),
//   child: const Text('مشاهدة'),
// )
