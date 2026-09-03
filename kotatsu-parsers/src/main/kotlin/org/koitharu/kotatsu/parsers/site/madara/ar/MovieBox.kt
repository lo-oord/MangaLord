package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaSourceParser
import org.koitharu.kotatsu.parsers.model.ContentType
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.model.AnimeStream

@MangaSourceParser("MOVIE_BOX", "Movie Box", "", ContentType.MOVIES_SERIES)
internal class MovieBox(context: MangaLoaderContext) :
    ArabicVideoParser(context, MangaParserSource.MOVIE_BOX, "movie-box.co") {
    override val listUrl = "/web/movie"

    override suspend fun getVideoStreams(chapter: org.koitharu.kotatsu.parsers.model.MangaChapter): List<AnimeStream> =
        extractDirectStreams(chapter)
}
