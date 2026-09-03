package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaSourceParser
import org.koitharu.kotatsu.parsers.model.ContentType
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.site.madara.MadaraParser

@MangaSourceParser("ARABSEED", "Arab Seed", "ar", ContentType.MOVIES_SERIES)
internal class ArabSeed(context: MangaLoaderContext) :
    MadaraParser(context, MangaParserSource.ARABSEED, "arabseed.social") {
    override val listUrl = "/home/"
}
