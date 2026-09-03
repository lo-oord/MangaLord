package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaSourceParser
import org.koitharu.kotatsu.parsers.model.ContentType
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.model.AnimeStream

@MangaSourceParser("ANIMERCO", "Animerco", "ar", ContentType.ANIME)
internal class Animerco(context: MangaLoaderContext) :
    ArabicVideoParser(context, MangaParserSource.ANIMERCO, "det.animerco.org") {
    override val listUrl = "animes/"

    override suspend fun getVideoStreams(chapter: org.koitharu.kotatsu.parsers.model.MangaChapter): List<AnimeStream> =
        extractDirectStreams(chapter)
}
