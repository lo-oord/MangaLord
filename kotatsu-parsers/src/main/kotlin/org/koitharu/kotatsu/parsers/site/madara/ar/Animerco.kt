package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaSourceParser
import org.koitharu.kotatsu.parsers.model.ContentType
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.site.madara.MadaraParser

@MangaSourceParser("ANIMERCO", "Animerco", "ar", ContentType.ANIME)
internal class Animerco(context: MangaLoaderContext) :
    MadaraParser(context, MangaParserSource.ANIMERCO, "det.animerco.org") {
    override val listUrl = "/animes/"
}
