package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaSourceParser
import org.koitharu.kotatsu.parsers.model.ContentType
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.model.AnimeStream

@MangaSourceParser("ANIMELEK", "AnimeLek", "ar", ContentType.ANIME)
internal class AnimeLek(context: MangaLoaderContext) :
    ArabicVideoParser(context, MangaParserSource.ANIMELEK, "animedar.net") {
    override val listUrl = "/anime-p/"

    override suspend fun getVideoStreams(chapter: org.koitharu.kotatsu.parsers.model.MangaChapter): List<AnimeStream> =
        extractDirectStreams(chapter)
}
