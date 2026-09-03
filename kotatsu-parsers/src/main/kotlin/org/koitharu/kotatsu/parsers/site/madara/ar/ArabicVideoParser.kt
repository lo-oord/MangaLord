package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.model.AnimeStream
import org.koitharu.kotatsu.parsers.model.MangaChapter
import org.koitharu.kotatsu.parsers.site.madara.MadaraParser
import org.koitharu.kotatsu.parsers.util.parseHtml
import org.koitharu.kotatsu.parsers.util.toAbsoluteUrl

internal abstract class ArabicVideoParser(
    context: MangaLoaderContext,
    source: org.koitharu.kotatsu.parsers.model.MangaParserSource,
    domain: String,
    pageSize: Int = 12,
) : MadaraParser(context, source, domain, pageSize) {

    protected suspend fun extractDirectStreams(chapter: MangaChapter): List<AnimeStream> {
        val page = webClient.httpGet(chapter.url.toAbsoluteUrl(domain)).parseHtml()
        return page.select("video source[src], video[src], source[src], a[href]")
            .mapNotNull { element ->
                val url = element.attr("src").ifBlank { element.attr("href") }
                    .toAbsoluteUrl(domain)
                val lower = url.lowercase()
                if (!lower.contains(".m3u8") && !lower.contains(".mp4")) return@mapNotNull null
                AnimeStream(
                    name = element.attr("label").ifBlank { element.attr("title") }.ifBlank { source.title },
                    url = url,
                    headers = mapOf("Referer" to "https://$domain/"),
                    quality = element.attr("label").ifBlank { null },
                )
            }
            .distinctBy { it.url }
    }
}
