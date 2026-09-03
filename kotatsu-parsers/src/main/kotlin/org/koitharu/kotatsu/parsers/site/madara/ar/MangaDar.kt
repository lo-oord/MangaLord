package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaSourceParser
import org.koitharu.kotatsu.parsers.model.ContentType
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.site.madara.MadaraParser

@MangaSourceParser("MANGADAR", "MangaDar", "ar", ContentType.MANGA)
internal class MangaDar(context: MangaLoaderContext) :
    MadaraParser(context, MangaParserSource.MANGADAR, "mangadar.com") {
    override val listUrl = "/manga/"
    override val tagPrefix = "genres/"
    override val datePattern = "MMMM d, yyyy"
}
