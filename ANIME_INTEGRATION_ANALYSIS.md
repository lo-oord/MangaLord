# Anime Integration Analysis

## Inputs
- Target project: `/home/ubuntu/Mlord` (MangaLord), currently using `com.github.clquwu:kotatsu-parsers-redo:434030d481` as a remote dependency.
- Reference archive: `/home/ubuntu/upload/MangaPeak-main.zip`, extracted to `/home/ubuntu/mangapeak-unzip/MangaPeak-main`.
- Both projects carry GPLv3 licensing. Manga Peak includes `NOTICE.md` attributing Kotatsu and kotatsu-parsers and says third-party names/logos/content remain subject to their owners.

## Manga Peak anime implementation
- App layer files: `anime/data/AnimePlaybackRepository.kt`, `anime/data/AnimeStreamSelector.kt`, `anime/player/AnimePlayerActivity.kt` (1161 lines), `download/ui/worker/AnimeHlsPlaylist.kt`, `local/data/output/LocalAnimeOutput.kt`.
- Resources: `layout/activity_anime_player.xml`, `layout/item_player_setting.xml`, `menu/opt_anime_player.xml`, `drawable/bg_player_pill.xml`, `drawable/bg_player_top_scrim.xml`, `drawable/ic_player_speed.xml`.
- Manifest declares `AnimePlayerActivity` with orientation config changes, hardware acceleration, full sensor, and Picture-in-Picture.
- Player uses AndroidX Media3 ExoPlayer + HLS + UI. Features include playback, seek, speed, fit/fill/zoom, quality, server selection, previous/next episode, fullscreen/orientation, control lock, brightness/volume gestures, PiP, loading/errors, stream refresh, saved position and auto-next.
- `AnimePlaybackRepository` is a small interface: `suspend fun getAnimeStreams(episode: MangaChapter): List<AnimeStream>`.
- `ParserMangaRepository` implements it by calling parser `getVideoStreams(episode)`.
- Manga Peak reuses existing `Manga` and `MangaChapter` models for anime; `Manga.isAnime` is determined by source content type or local video extension. Chapters UI routes anime chapters to `AnimePlayerActivity`, otherwise to the existing manga reader.
- Manga Peak adds player settings to AppSettings: speed, resize mode, auto-next, quality height.
- Anime downloads have an `AnimeHlsPlaylist` helper and `LocalAnimeOutput`, but this must be evaluated separately to avoid breaking manga downloads.

## Manga Peak parser
- Manga Peak bundles a local parser composite build under `kotatsu-parsers`; it is not safe to replace MangaLord's current parser wholesale because MangaLord currently relies on the much larger `kotatsu-parsers-redo` source set for manga sources.
- Manga Peak parser adds `ContentType.ANIME`, `AnimeStream`, and `MangaParser.getVideoStreams()` defaulting to empty.
- Actual Arabic anime sources in the archive:
  - `Anime3rb.kt` (390 lines)
  - `AnimePhoenix.kt` (394 lines)
  - `AnimeSlayer.kt` (640 lines)
  - `AnimeWitcher.kt` (957 lines)
  - `RistoAnime.kt` (302 lines)
- These are real parsers with search/listing, details, episodes, and video extraction. Some have source-specific credentials/config:
  - AnimeSlayer uses a client secret from parser build config.
  - AnimeWitcher uses Algolia search key and Firebase API key from parser build config and requires verified account for viewing servers according to its source comments/UI strings.
- Manga Peak parser build generates `ParserBuildConfig.kt` from local properties for those secrets. No user credentials/tokens/cookies may be moved into MangaLord.

## Compatibility findings
- MangaLord's current remote parser at commit `434030d4` has no `ContentType.ANIME` and no `AnimeStream`/`getVideoStreams()` API.
- It does contain other anime-named generic manga parsers, but they are not the Manga Peak anime system and do not establish an anime content type.
- Therefore a simple app-only copy of Manga Peak anime classes will not compile against the current parser artifact.
- The safest architecture is to preserve all current MangaLord manga parser sources and add anime API/source support to a controlled parser source/module (or a compatible published parser artifact), rather than replacing the parser with Manga Peak's small bundled subset.
- MangaLord app and Manga Peak app have approximately 987 common Kotlin relative paths after package normalization; the app architecture is close, so only anime-specific and directly related integration deltas should be ported. Do not wholesale copy unrelated Manga Peak changes.

## Proposed integration sequence
1. Preserve current MangaLord manga parser source set and app behavior.
2. Add parser API compatibility: `ContentType.ANIME`, `AnimeStream`, `MangaParser.getVideoStreams()` and generated source registrations for the five anime parsers, while retaining current manga sources.
3. Add app anime model/source helpers (`Manga.isAnime`, `MangaSource.isAnimeSource`, content type label/summary), source initialization/filtering, and search/navigation separation only where required.
4. Port player and directly required resources, adapting package names to `com.mangalord.app` and reusing existing Media3/OkHttp/WorkManager/Room dependencies where available.
5. Add manifest/player settings and only safe progress/history behavior; avoid changing the existing manga schema unless the current data model proves insufficient.
6. Review and preserve GPLv3/NOTICE attribution and document any source-specific limitations.
7. Run static checks only first. Do not run local Gradle build. Push changes so GitHub Actions performs the Release build.
8. Treat parser/source runtime functionality as incomplete until source-specific tests and GitHub Actions results are reviewed.

## Important limitations found
- AnimeWitcher source is not fully anonymous; it has a verified-account requirement for viewing servers and source-specific secrets. It must not be presented as guaranteed to work without configuration.
- AnimeSlayer and AnimeWitcher require parser build secrets; these must be configured as GitHub/local build secrets or the sources should fail gracefully.
- The user explicitly requested no local build; all builds must go through GitHub Actions.
