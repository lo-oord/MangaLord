package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaSourceParser
import org.koitharu.kotatsu.parsers.model.ContentType
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.site.madara.MadaraParser

@MangaSourceParser("PROCOMIC", "ProComic", "ar", ContentType.MANGA)
internal class ProComic(context: MangaLoaderContext) :
    MadaraParser(context, MangaParserSource.PROCOMIC, "procomic.net") {
    override val listUrl = "/ar/series/"
}
